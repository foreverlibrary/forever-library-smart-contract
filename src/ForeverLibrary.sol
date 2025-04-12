// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IExternalRenderer {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/// @title Forever Library
/// @notice A fully immutable, non-upgradeable NFT contract with open minting and permanent metadata.
contract ForeverLibrary is ERC721, ReentrancyGuard {
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
        string artistName; // dynamic
        string title; // dynamic
        string mediaType; // dynamic
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
        string calldata mediaType
    ) external nonReentrant {
        if (bytes(finalTokenURI).length == 0) revert EmptyURI();
        if (bytes(finalTokenURI).length > 2048) revert URITooLong();
        if (bytes(artistName).length == 0) revert EmptyArtistName();
        if (bytes(title).length == 0) revert EmptyTitle();
        if (bytes(mediaType).length == 0) revert EmptyMediaType();

        uint256 tokenId = _currentTokenId;
        unchecked {
            _currentTokenId++;
        }

        _mintData[tokenId] = MintData({
            creator: msg.sender,
            timestamp: uint64(block.timestamp),
            blockNumber: uint64(block.number),
            metadataHash: keccak256(bytes(finalTokenURI)),
            tokenURI: finalTokenURI,
            artistName: artistName,
            title: title,
            mediaType: mediaType
        });

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

    function getMintData(uint256 _tokenId) public view returns (MintData memory) {
        if (_mintData[_tokenId].creator == address(0)) revert TokenNotFound();
        return _mintData[_tokenId];
    }

    function setTokenURI(uint256 tokenId, string memory _uri) external onlyTokenCreator(tokenId) {
        if (block.timestamp > _mintData[tokenId].timestamp + 24 hours) revert MetadataLocked();

        _mintData[tokenId].tokenURI = _uri;
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

    // Split the JSON generation into helper functions to reduce stack depth
    function _generateAttributesJSON(MintData memory data) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                '{"trait_type":"Artist","value":"',
                data.artistName,
                '"},{"trait_type":"Title","value":"',
                data.title,
                '"},{"trait_type":"Media Type","value":"',
                data.mediaType,
                '"},{"trait_type":"Creator","value":"',
                Strings.toHexString(uint160(data.creator), 20),
                '"}'
            )
        );
    }

    function _generateMetadataJSON(MintData memory data) private view returns (string memory) {
        string memory attributes = _generateAttributesJSON(data);

        return string(
            abi.encodePacked(
                '{"name":"',
                data.title,
                '","description":"',
                _collectionDescription,
                '","image":"',
                data.tokenURI,
                '","artist":"',
                data.artistName,
                '","title":"',
                data.title,
                '","media_type":"',
                data.mediaType,
                '","creator":"',
                Strings.toHexString(uint160(data.creator), 20),
                '","attributes":[',
                attributes,
                "]}"
            )
        );
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        ownerOf(tokenId); // This will revert with ERC721NonexistentToken if token doesn't exist

        if (usesExternalRenderer[tokenId] && externalRendererAddresses[tokenId] != address(0)) {
            return IExternalRenderer(externalRendererAddresses[tokenId]).tokenURI(tokenId);
        }

        MintData memory data = _mintData[tokenId];
        string memory json = _generateMetadataJSON(data);

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
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

    receive() external payable {
        revert EtherNotAccepted();
    }

    fallback() external payable {
        revert EtherNotAccepted();
    }
}
