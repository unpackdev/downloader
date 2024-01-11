// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IERC20.sol";
import "./Ownable.sol";


/// @title Spread Dapp, Edition Ethereum.
/// @author @dadogg80, Viken Blockchain Solutions.
/// @notice Transfer your cryptocurrency to multiple accounts in one transaction.
/// @dev The purpose of this smart-contract was to create an updated dapp
///      of what is already available on the blockchain network.


contract Spread is Ownable {
    
    /// @dev authentication error.
    error Error_1();

    /// @dev thrown by receive function.
    error Error_2();

    /// @dev thrown if zero values.
    error ZeroValues();

    constructor() {
    }

    modifier noZeroValues(address[] calldata recipients, uint256[] calldata values) {
      if (recipients.length <= 0 ||  values.length <= 0) revert ZeroValues();
      _;
    }

    /// @dev Receive function.
    receive() external payable {
        revert Error_2();
    } 

    /// This will allow you to batch transfers of an mainnet asset like Ethereum, Matic, etc, to multiple accounts.
    /// @param recipients List with the recipient accounts.
    /// @param values List with the values to transfer to the corresponding recipient.
    /// @dev Address example: ["address","address","address"].
    /// @dev Value example: ["value","value","value"].
    function spreadAsset(address[] calldata recipients, uint256[] calldata values) external payable noZeroValues(recipients, values) {
            for (uint256 i = 0; i < recipients.length; i++)
                payable(recipients[i]).transfer(values[i]);
    }

    /// This will allow you to batch transfers of erc20 tokens, to multiple accounts.
    /// @param token The ERC20 contract address
    /// @param recipients List with the recipient accounts.
    /// @param values List with values to transfer to the corresponding recipient.
    /// @dev Address example: ["address","address","address"].
    /// @dev Value example: [value,value,value].
    function spreadERC20(IERC20 token, address[] calldata recipients, uint256[] calldata values) external noZeroValues(recipients, values) {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));
    }

    /// This is a cheaper way to batch transfer erc20 tokens, to multiple accounts.
    /// @param token The ERC20 contract address
    /// @param recipients List with the recipient accounts.
    /// @param values List with values to transfer to the corresponding recipient.
    /// @dev Address example: ["address","address","address"].
    /// @dev Value example: [value, value, value].
    function spreadERC20Simple(IERC20 token, address[] calldata recipients, uint256[] calldata values) external noZeroValues(recipients, values) {
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transferFrom(msg.sender, recipients[i], values[i]));
    }

    /// This will allow the owner account to save any stuck erc20 tokens.
    /// @param token The ERC20 contract address.
    /// @dev Restricted by onlyOwner modifier.
    function saveERC20(IERC20 token) external onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        require(token.transfer(address(msg.sender), amount));
    }

    /// This will allow the owner account to save any stuck main asset.
    /// @dev Restricted by onlyOwner modifier.
    function saveAsset() external onlyOwner {
        uint256 asset = address(this).balance;
        payable(msg.sender).transfer(asset);
    }
}