// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ForeverLibrary.sol";

contract ForeverLibraryTest is Test {
    ForeverLibrary public foreverLibrary;
    address public deployer;
    address public user1;
    address public user2;

    // Sample token URI
    string constant SAMPLE_URI = "ipfs://QmXsMLpKjznF3z1KwVVWtyNUW1j3pX8QMeRzQYQwbBhVEu";
    string constant UPDATED_URI = "ipfs://QmNewURIHash";

    function setUp() public {
        deployer = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Deploy the contract
        foreverLibrary = new ForeverLibrary();

        // Fund test users
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

    // Test basic minting functionality
    function test_Mint() public {
        // Mint as user1
        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI);

        // Check ownership
        assertEq(foreverLibrary.ownerOf(1), user1);

        // Check token URI
        assertEq(foreverLibrary.tokenURI(1), SAMPLE_URI);
    }

    // Test updating token URI as the creator
    function test_SetTokenURI() public {
        // Mint as user1
        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI);

        // Update URI as the creator (user1)
        vm.prank(user1);
        foreverLibrary.setTokenURI(1, UPDATED_URI);

        // Check updated URI
        assertEq(foreverLibrary.tokenURI(1), UPDATED_URI);
    }

    // Test that non-creators cannot update token URI
    function test_RevertWhen_NonCreatorUpdatesURI() public {
        // Mint as user1
        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI);

        // Try to update URI as non-creator (user2) - should revert
        vm.prank(user2);
        vm.expectRevert("Only token creator can modify");
        foreverLibrary.setTokenURI(1, UPDATED_URI);
    }

    // Test that metadata is locked after 24 hours
    function test_RevertWhen_MetadataLocked() public {
        // Mint as user1
        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI);

        // Fast forward 25 hours
        skip(25 hours);

        // Try to update URI after lock period - should revert
        vm.prank(user1);
        vm.expectRevert("Metadata locked after 24 hours");
        foreverLibrary.setTokenURI(1, UPDATED_URI);
    }

    // Test external renderer functionality
    function test_ExternalRenderer() public {
        // Create a mock external renderer
        MockExternalRenderer mockRenderer = new MockExternalRenderer();

        // Mint as user1
        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI);

        // Set external renderer
        vm.prank(user1);
        foreverLibrary.setExternalRenderer(1, address(mockRenderer));

        // Enable external renderer
        vm.prank(user1);
        foreverLibrary.toggleExternalRenderer(1, true);

        // Check that tokenURI now comes from external renderer
        assertEq(foreverLibrary.tokenURI(1), "MOCK_EXTERNAL_URI_1");
    }

    // Test that external renderer can be toggled off
    function test_ToggleExternalRenderer() public {
        // Create a mock external renderer
        MockExternalRenderer mockRenderer = new MockExternalRenderer();

        // Mint as user1
        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI);

        // Set external renderer
        vm.prank(user1);
        foreverLibrary.setExternalRenderer(1, address(mockRenderer));

        // Enable external renderer
        vm.prank(user1);
        foreverLibrary.toggleExternalRenderer(1, true);

        // Check that tokenURI comes from external renderer
        assertEq(foreverLibrary.tokenURI(1), "MOCK_EXTERNAL_URI_1");

        // Disable external renderer
        vm.prank(user1);
        foreverLibrary.toggleExternalRenderer(1, false);

        // Check that tokenURI now comes from original URI
        assertEq(foreverLibrary.tokenURI(1), SAMPLE_URI);
    }

    // Test that contract rejects Ether
    function test_RevertWhen_EtherSent() public {
        // Try to send Ether to the contract - should revert
        vm.expectRevert(ForeverLibrary.EtherNotAccepted.selector);
        (bool success,) = address(foreverLibrary).call{value: 1 ether}("");
        require(success, "Call failed");
    }

    // Test contract URI for marketplaces
    function test_ContractURI() public view {
        // Get contract URI
        string memory uri = foreverLibrary.contractURI();

        // Verify it's a data URI
        assertTrue(bytes(uri).length > 0);
        assertStringStartsWith(uri, "data:application/json;base64,");
    }

    // Test empty URI reverts
    function test_RevertWhen_EmptyURI() public {
        vm.prank(user1);
        vm.expectRevert(ForeverLibrary.EmptyURI.selector);
        foreverLibrary.mint("");
    }

    // Test URI too long reverts
    function test_RevertWhen_URITooLong() public {
        // Create a very long URI (over 2048 characters)
        string memory longURI = _createLongString(2049);

        vm.prank(user1);
        vm.expectRevert(ForeverLibrary.URITooLong.selector);
        foreverLibrary.mint(longURI);
    }

    // Test getting mint data
    function test_GetMintData() public {
        // Mint as user1
        vm.prank(user1);
        foreverLibrary.mint(SAMPLE_URI);

        // Get mint data
        ForeverLibrary.MintData memory data = foreverLibrary.getMintData(1);

        // Verify data
        assertEq(data.creator, user1);
        assertEq(data.tokenURI, SAMPLE_URI);
    }

    // Helper function to create a long string
    function _createLongString(uint256 length) internal pure returns (string memory) {
        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = "a";
        }
        return string(result);
    }

    // Helper function to check if a string starts with a prefix
    function assertStringStartsWith(string memory str, string memory prefix) internal pure {
        bytes memory strBytes = bytes(str);
        bytes memory prefixBytes = bytes(prefix);

        require(strBytes.length >= prefixBytes.length, "String shorter than prefix");

        for (uint256 i = 0; i < prefixBytes.length; i++) {
            assertEq(strBytes[i], prefixBytes[i]);
        }
    }
}

// Mock external renderer for testing
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
