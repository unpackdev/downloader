// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";

contract DelegateERC721 {
    function ownerOf(address target, uint256 tokenID) public view returns(address) {
        try IERC721(target).ownerOf(tokenID) returns (address owner) {
            return owner;
        } catch  {
            return address(0);
        }
    }

    function tokenURI(address target, uint256 tokenID) public view returns (string memory) {
        try IERC721(target).tokenURI(tokenID) returns (string memory uri) {
            return uri;
        } catch {
            return "";
        }
    }
}