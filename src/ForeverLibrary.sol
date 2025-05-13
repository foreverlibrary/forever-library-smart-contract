// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IExternalRenderer {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/// @title Forever Library
/// @notice A fully immutable, non-upgradeable NFT contract with open minting and permanent metadata.
contract ForeverLibrary is ERC721, ReentrancyGuard, ERC2981, IERC721Enumerable {
    string public constant VERSION = "1.0.0";
    address public immutable DEPLOYER;

    uint256 private _currentTokenId;

    string private _collectionName;
    string private _collectionDescription;
    string private _collectionImage;

    struct MintData {
        address creator; // 20 bytes
        uint64 timestamp; // 8 bytes
        uint64 blockNumber; // 8 bytes
        bytes32 metadataHash; // 32 bytes
        string tokenURI; // dynamic
    }

    mapping(uint256 => MintData) private _mintData;
    mapping(uint256 => uint256) public mintTimestamp;

    mapping(uint256 => bool) public usesExternalRenderer;
    mapping(uint256 => address) public externalRendererAddresses;

    event TokenMinted(
        address indexed creator,
        uint256 indexed tokenId,
        address indexed minter,
        string tokenURI,
        bytes32 metadataHash,
        uint256 timestamp,
        uint256 blockNumber,
        string artistName,
        string title,
        string mediaType
    );

    event RoyaltyUpdated(uint256 indexed tokenId, uint96 royaltyPercentage);

    error EmptyURI();
    error URITooLong();
    error EtherNotAccepted();
    error NotTokenCreator();
    error InvalidRendererAddress();
    error MetadataLocked();
    error TokenNotFound();
    error EmptyArtistName();
    error EmptyTitle();
    error EmptyMediaType();
    error InvalidRoyaltyPercentage();

    constructor() ERC721("Forever Library", "FL") {
        DEPLOYER = msg.sender;

        _currentTokenId = 1;

        _collectionName = "Forever Library";
        _collectionDescription =
            "A fully immutable, non-upgradeable NFT contract with open minting and permanent metadata.";

        _collectionImage =
            "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMzY1LjMiIGhlaWdodD0iMTM2NS4zIiB2aWV3Qm94PSIwIDAgMTAyNCAxMDI0Ij48cGF0aCBkPSJNMCAwaDEwMjR2MTAyNEgwVjBaIi8+PHBhdGggZmlsbD0iI2ZmZiIgZD0iTTY0OSAyMzNhNjMgNjMgMCAwIDEgNTEgNTFjMiAxMS0yIDIyLTExIDI5LTQgNC0xMiA0LTE3IDEtMy0yLTUtNi00LTEwIDAtNSAyLTkgNC0xNHMyLTExIDAtMTZjLTItOS03LTE4LTE0LTI0LTYtNS0xMy05LTIwLTktMTIgMC0yMyAzLTMzIDktMTEgNy0yMCAxOS0yNSAzMS0xMCAyMi0xNCA0NS0xNiA2OWwtMTQgMTI2LTEgMTMgMzQtMjMgMTAtOWM1LTkgNy0yMCA0LTMxLTEtNi0zLTEzIDEtMTkgMy01IDktNiAxNC00IDUgMSA4IDUgMTAgOSA1IDkgNCAyMi0xIDMxLTMgNy05IDEyLTE1IDE2LTE2IDEzLTMyIDI1LTQ5IDM2bC05IDYtMSA2LTggNzZjLTIgMjYtNiA1MS0xNCA3Ni04IDI4LTIxIDUzLTM5IDc1bC0yMCAyM2MtMTUgMTUtMzMgMjgtNTQgMzRhNjcgNjcgMCAwIDEtNzYtMjggODAgODAgMCAwIDEtMTEtNTBjMS0xNiAzLTMxIDgtNDYgNC0xMyAxMS0yNCAxOS0zNSAxMS0xNSAyNS0yOCAzOS00MGwzMy0yMiA0OS0zMWMxLTEgNC0yIDQtNGwyLTE0IDE5LTE4MCAzLTIxYzItMTAgNi0yMCAxMS0yOSAxMS0xOCAyOC0zMSA0Ni00MmExMzYgMTM2IDAgMCAxIDkxLTE2WiIvPjxwYXRoIGQ9Im00NzUgNTQ5LTEgMTgtMTggMTYzYy0xIDctMSAxNC01IDIwLTUgMTAtMTUgMTgtMjUgMjMtOSA1LTE5IDctMjkgNS00IDAtMTAtMi0xMS03LTItMyAwLTggMC0xMmwxNS0xMzggMy0xOGMyLTUgNS05IDktMTMgNS01IDExLTggMTctMTBsMjktMTkgMTYtMTBaIi8+PC9zdmc+";
    }

    modifier onlyTokenCreator(uint256 tokenId) {
        if (_mintData[tokenId].creator != msg.sender) revert NotTokenCreator();
        _;
    }

    function mint(
        string calldata finalTokenURI,
        string calldata artistName,
        string calldata title,
        string calldata mediaType,
        uint96 royaltyPercentage
    ) external nonReentrant {
        if (bytes(finalTokenURI).length == 0) revert EmptyURI();
        if (bytes(finalTokenURI).length > 2048) revert URITooLong();
        if (bytes(artistName).length == 0) revert EmptyArtistName();
        if (bytes(title).length == 0) revert EmptyTitle();
        if (bytes(mediaType).length == 0) revert EmptyMediaType();
        if (royaltyPercentage > 10000) revert InvalidRoyaltyPercentage(); // Max 100%

        uint256 tokenId = _currentTokenId;
        unchecked {
            _currentTokenId++;
        }

        _mintData[tokenId] = MintData({
            creator: msg.sender,
            timestamp: uint64(block.timestamp),
            blockNumber: uint64(block.number),
            metadataHash: keccak256(bytes(finalTokenURI)),
            tokenURI: finalTokenURI
        });

        _setTokenRoyalty(tokenId, msg.sender, royaltyPercentage);

        _safeMint(msg.sender, tokenId);

        emit TokenMinted(
            msg.sender,
            tokenId,
            msg.sender,
            finalTokenURI,
            keccak256(bytes(finalTokenURI)),
            block.timestamp,
            block.number,
            artistName,
            title,
            mediaType
        );
    }

    function updateTokenRoyalty(uint256 tokenId, uint96 royaltyPercentage) external onlyTokenCreator(tokenId) {
        if (royaltyPercentage > 10000) revert InvalidRoyaltyPercentage(); // Max 100%

        _setTokenRoyalty(tokenId, _mintData[tokenId].creator, royaltyPercentage);
        emit RoyaltyUpdated(tokenId, royaltyPercentage);
    }

    function getMintData(uint256 _tokenId) public view returns (MintData memory) {
        if (_mintData[_tokenId].creator == address(0)) revert TokenNotFound();
        return _mintData[_tokenId];
    }

    function setTokenURI(uint256 tokenId, string memory _uri) external onlyTokenCreator(tokenId) {
        if (block.timestamp > _mintData[tokenId].timestamp + 24 hours) revert MetadataLocked();

        _mintData[tokenId].tokenURI = _uri;
    }

    function totalSupply() public view override returns (uint256) {
        if (_currentTokenId == 0) return 0;
        return _currentTokenId - 1;
    }

    function tokenByIndex(uint256 index) public view override returns (uint256) {
        if (index >= totalSupply()) revert("ERC721Enumerable: global index out of bounds");
        return index + 1;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view override returns (uint256) {
        if (index >= balanceOf(owner)) revert("ERC721Enumerable: owner index out of bounds");

        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= totalSupply(); i++) {
            if (ownerOf(i) == owner) {
                if (currentIndex == index) {
                    return i;
                }
                currentIndex++;
            }
        }
        revert("ERC721Enumerable: owner index out of bounds");
    }

    function setExternalRenderer(uint256 tokenId, address renderer) external onlyTokenCreator(tokenId) {
        if (renderer == address(0)) revert InvalidRendererAddress();
        if (block.timestamp > _mintData[tokenId].timestamp + 24 hours) revert MetadataLocked();

        externalRendererAddresses[tokenId] = renderer;
    }

    function toggleExternalRenderer(uint256 tokenId, bool enabled) external onlyTokenCreator(tokenId) {
        if (block.timestamp > _mintData[tokenId].timestamp + 24 hours) revert MetadataLocked();

        usesExternalRenderer[tokenId] = enabled;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        ownerOf(tokenId); // This will revert with ERC721NonexistentToken if token doesn't exist

        if (usesExternalRenderer[tokenId] && externalRendererAddresses[tokenId] != address(0)) {
            return IExternalRenderer(externalRendererAddresses[tokenId]).tokenURI(tokenId);
        }

        return _mintData[tokenId].tokenURI;
    }

    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            _collectionName,
                            '","description":"',
                            _collectionDescription,
                            '","image":"',
                            _collectionImage,
                            '"}'
                        )
                    )
                )
            )
        );
    }

    // The following functions are overrides required by Solidity
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 amount) internal override(ERC721) {
        super._increaseBalance(account, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981, IERC165) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    receive() external payable {
        revert EtherNotAccepted();
    }

    fallback() external payable {
        revert EtherNotAccepted();
    }
}
