// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC1155Upgradeable.sol";

/// @title ERC1155ForMetamask Contract
/// @dev setApproveForAll function fails in metamask for some collections.
///      https://github.com/MetaMask/metamask-extension/issues/18507
///      if proxy contract supports IERC20 and IERC1155 or ERC721 interfaces and imported the ERC20 token on metamask,
///      approving ERC1155 or ERC721 fails on metamask extenstion.
///      so Metamask_ApprovalForAll function can approve collection without error on metamask.

contract ERC1155ForMetamask is ERC1155Upgradeable {
    function Metamask_ApprovalForAll(address operator, bool approved) external {
        _setApprovalForAll(msg.sender, operator, approved);
    }
}
