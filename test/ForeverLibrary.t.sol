// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ForeverLibrary.sol";

contract ForeverLibraryTest is Test {
    ForeverLibrary public foreverLibrary;
    address public deployer;
    address public user1;
    address public user2;

    string constant SAMPLE_URI = "ipfs://QmXsMLpKjznF3z1KwVVWtyNUW1j3pX8QMeRzQYQwbBhVEu";
    string constant UPDATED_URI = "ipfs://QmNewURIHash";
    string constant ARTIST_NAME = "Test Artist";
    string constant TITLE = "Test Title";
    string constant MEDIA_TYPE = "Digital Art";
    uint96 constant DEFAULT_ROYALTY = 1000; // 10%
    uint256 constant TEST_SALE_PRICE = 10000;

    function setUp() public {
        deployer = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        foreverLibrary = new ForeverLibrary();

        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

    function test_Mint() public {
        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);

        assertEq(foreverLibrary.ownerOf(1), user1);
        assertEq(foreverLibrary.tokenURI(1), SAMPLE_URI);
    }

    function test_MultipleTokens() public {
        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);
        vm.prank(user2);
        foreverLibrary.mint(UPDATED_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);

        assertEq(foreverLibrary.ownerOf(1), user1);
        assertEq(foreverLibrary.ownerOf(2), user2);
        assertEq(foreverLibrary.tokenURI(1), SAMPLE_URI);
        assertEq(foreverLibrary.tokenURI(2), UPDATED_URI);
    }

    function test_SetTokenURI() public {
        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);

        vm.prank(user1);
        foreverLibrary.setTokenURI(1, UPDATED_URI);

        assertEq(foreverLibrary.tokenURI(1), UPDATED_URI);
    }

    function test_RevertWhen_NonCreatorUpdatesURI() public {
        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);

        vm.prank(user2);
        vm.expectRevert(ForeverLibrary.NotTokenCreator.selector);
        foreverLibrary.setTokenURI(1, UPDATED_URI);
    }

    function test_RevertWhen_MetadataLocked() public {
        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);

        skip(25 hours);

        vm.prank(user1);
        vm.expectRevert(ForeverLibrary.MetadataLocked.selector);
        foreverLibrary.setTokenURI(1, UPDATED_URI);
    }

    function test_ExternalRenderer() public {
        MockExternalRenderer mockRenderer = new MockExternalRenderer();

        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);

        vm.prank(user1);
        foreverLibrary.setExternalRenderer(1, address(mockRenderer));

        vm.prank(user1);
        foreverLibrary.toggleExternalRenderer(1, true);

        assertEq(foreverLibrary.tokenURI(1), "MOCK_EXTERNAL_URI_1");
    }

    function test_RevertWhen_ExternalRendererLocked() public {
        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);

        skip(25 hours);

        MockExternalRenderer mockRenderer = new MockExternalRenderer();

        vm.prank(user1);
        vm.expectRevert(ForeverLibrary.MetadataLocked.selector);
        foreverLibrary.setExternalRenderer(1, address(mockRenderer));

        vm.prank(user1);
        vm.expectRevert(ForeverLibrary.MetadataLocked.selector);
        foreverLibrary.toggleExternalRenderer(1, true);

        assertEq(foreverLibrary.ownerOf(1), user1);
        assertEq(foreverLibrary.tokenURI(1), SAMPLE_URI);
    }

    function test_RevertWhen_InvalidRendererAddress() public {
        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);

        vm.prank(user1);
        vm.expectRevert(ForeverLibrary.InvalidRendererAddress.selector);
        foreverLibrary.setExternalRenderer(1, address(0));
    }

    function test_MetadataHash() public {
        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);

        ForeverLibrary.MintData memory data = foreverLibrary.getMintData(1);
        assertEq(data.metadataHash, keccak256(bytes(SAMPLE_URI)));
    }

    function test_RevertWhen_NonExistentToken() public {
        vm.expectRevert(abi.encodeWithSignature("ERC721NonexistentToken(uint256)", 999));
        foreverLibrary.tokenURI(999);
    }

    function test_RevertWhen_TokenNotFound() public {
        vm.expectRevert(ForeverLibrary.TokenNotFound.selector);
        foreverLibrary.getMintData(999);
    }

    function test_RevertWhen_EtherSent() public {
        vm.expectRevert(ForeverLibrary.EtherNotAccepted.selector);
        (bool success,) = address(foreverLibrary).call{value: 1 ether}("");
        require(success, "Call failed");
    }

    function test_ContractURI() public view {
        string memory uri = foreverLibrary.contractURI();

        assertTrue(bytes(uri).length > 0);
        assertStringStartsWith(uri, "data:application/json;base64,");
    }

    function test_RevertWhen_EmptyURI() public {
        vm.prank(user1);
        vm.expectRevert(ForeverLibrary.EmptyURI.selector);
        foreverLibrary.mint("", ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);
    }

    function test_RevertWhen_URITooLong() public {
        string memory longURI = _createLongString(2049);

        vm.prank(user1);
        vm.expectRevert(ForeverLibrary.URITooLong.selector);
        foreverLibrary.mint(longURI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);
    }

    function test_SetTokenRoyalty() public {
        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);

        uint96 newRoyalty = 2000; // 20%
        vm.prank(user1);
        foreverLibrary.updateTokenRoyalty(1, newRoyalty);

        (address receiver, uint256 royaltyAmount) = foreverLibrary.royaltyInfo(1, TEST_SALE_PRICE);
        assertEq(receiver, user1);
        assertEq(royaltyAmount, 2000); // 20% of 10000
    }

    function test_RevertWhen_NonCreatorUpdatesRoyalty() public {
        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);

        vm.prank(user2);
        vm.expectRevert(ForeverLibrary.NotTokenCreator.selector);
        foreverLibrary.updateTokenRoyalty(1, 2000);
    }

    function test_RevertWhen_InvalidRoyaltyPercentage() public {
        vm.prank(user1);
        vm.expectRevert(ForeverLibrary.InvalidRoyaltyPercentage.selector);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, 10001);
    }

    function test_RevertWhen_InvalidRoyaltyPercentageUpdate() public {
        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);

        vm.prank(user1);
        vm.expectRevert(ForeverLibrary.InvalidRoyaltyPercentage.selector);
        foreverLibrary.updateTokenRoyalty(1, 10001);
    }

    function test_RoyaltyInfo() public {
        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);

        (address receiver, uint256 royaltyAmount) = foreverLibrary.royaltyInfo(1, TEST_SALE_PRICE);
        assertEq(receiver, user1);
        assertEq(royaltyAmount, 1000);
    }

    function test_TotalSupply() public {
        assertEq(foreverLibrary.totalSupply(), 0);

        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);
        assertEq(foreverLibrary.totalSupply(), 1);

        vm.prank(user2);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);
        assertEq(foreverLibrary.totalSupply(), 2);
    }

    function test_TokenByIndex() public {
        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);
        vm.prank(user2);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);

        assertEq(foreverLibrary.tokenByIndex(0), 1);
        assertEq(foreverLibrary.tokenByIndex(1), 2);

        vm.expectRevert("ERC721Enumerable: global index out of bounds");
        foreverLibrary.tokenByIndex(2);
    }

    function test_TokenOfOwnerByIndex() public {
        // Mint tokens for user1
        vm.startPrank(user1);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);
        vm.stopPrank();

        // Mint tokens for user2
        vm.startPrank(user2);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);
        foreverLibrary.mint(SAMPLE_URI, ARTIST_NAME, TITLE, MEDIA_TYPE, DEFAULT_ROYALTY);
        vm.stopPrank();

        assertEq(foreverLibrary.tokenOfOwnerByIndex(user1, 0), 1);
        assertEq(foreverLibrary.tokenOfOwnerByIndex(user1, 1), 2);
        assertEq(foreverLibrary.tokenOfOwnerByIndex(user1, 2), 3);

        assertEq(foreverLibrary.tokenOfOwnerByIndex(user2, 0), 4);
        assertEq(foreverLibrary.tokenOfOwnerByIndex(user2, 1), 5);

        vm.expectRevert("ERC721Enumerable: owner index out of bounds");
        foreverLibrary.tokenOfOwnerByIndex(user1, 3);

        vm.expectRevert("ERC721Enumerable: owner index out of bounds");
        foreverLibrary.tokenOfOwnerByIndex(user2, 2);
    }

    function test_SupportsInterface() public view {
        assertTrue(foreverLibrary.supportsInterface(type(IERC721Enumerable).interfaceId));
        assertTrue(foreverLibrary.supportsInterface(type(IERC721).interfaceId));
        assertTrue(foreverLibrary.supportsInterface(type(IERC2981).interfaceId));
        assertFalse(foreverLibrary.supportsInterface(0x12345678));
    }

    function _createLongString(uint256 length) internal pure returns (string memory) {
        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = "a";
        }
        return string(result);
    }

    function assertStringStartsWith(string memory str, string memory prefix) internal pure {
        bytes memory strBytes = bytes(str);
        bytes memory prefixBytes = bytes(prefix);

        require(strBytes.length >= prefixBytes.length, "String shorter than prefix");

        for (uint256 i = 0; i < prefixBytes.length; i++) {
            assertEq(strBytes[i], prefixBytes[i]);
        }
    }
}

contract MockExternalRenderer is IExternalRenderer {
    function tokenURI(uint256 tokenId) external pure override returns (string memory) {
        return string(abi.encodePacked("MOCK_EXTERNAL_URI_", uint2str(tokenId)));
    }

    // Helper function to convert uint to string
    function uint2str(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }
}
