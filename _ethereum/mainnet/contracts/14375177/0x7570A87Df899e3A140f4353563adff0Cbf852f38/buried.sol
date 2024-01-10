// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC1155CreatorExtensionApproveTransfer.sol";
import "./IERC1155CreatorCore.sol";

contract buried is ERC1155CreatorExtensionApproveTransfer {    
    function approveTransfer(address from, address to, uint256[] calldata tokenIds, uint256[] calldata amounts) external returns (bool) {
        if (from == address(0) || to == address(0) || isAdmin(from) || isAdmin(to)) {
            return true;
        }
        return false;
    }

    bool created = false;
    function mint(address creator, address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) external adminRequired {        
        IERC1155CreatorCore(creator).mintExtensionExisting(to, tokenIds, amounts);
    }

    function create(address creator, address[] calldata to, uint256[] calldata amounts, string[] calldata uris) external adminRequired {
        IERC1155CreatorCore(creator).mintExtensionNew(to, amounts, uris);
    } 
}