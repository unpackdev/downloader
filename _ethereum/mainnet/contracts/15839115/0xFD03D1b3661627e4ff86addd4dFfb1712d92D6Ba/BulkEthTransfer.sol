// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ReentrancyGuard.sol";

/**
 * @title HeyMint Launchpad Bulk ETH Transfer Contract
 * @author Mai Akiyoshi & Ben Yu (https://twitter.com/mai_on_chain & https://twitter.com/intenex) from HeyMint (https://twitter.com/heymintxyz)
 * @notice This contract handles the bulk transfer of ETH to a list of addresses.
 */
contract BulkEthTransfer is ReentrancyGuard {

    mapping (address => uint256) public balances;

    constructor() {
    }

    /**
     * @notice Deposit ETH to the contract to be spent later on transfers
     */
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /**
     * @notice Bulk transfer ETH to a list of addresses with a list of amounts
     */
    function bulkEthTransfer(address payable[] calldata _to, uint256[] calldata _value) external payable nonReentrant {
        if (msg.value > 0) {
            balances[msg.sender] += msg.value;
        }
        require(_to.length == _value.length, "Arrays must be of equal length");
        uint256 totalValue = 0;
        for (uint256 i = 0; i < _value.length; i++) {
            totalValue += _value[i];
        }
        require(balances[msg.sender] >= totalValue, "Insufficient balance");
        balances[msg.sender] -= totalValue;
        for (uint i = 0; i < _to.length; i++) {
            _to[i].transfer(_value[i]);
        }
    }

    /**
     * @notice Bulk transfer the same amount of ETH to a list of addresses
     */
    function bulkEthTransferSingleAmount(address payable[] calldata _to, uint256 _value) external payable nonReentrant {
        if (msg.value > 0) {
            balances[msg.sender] += msg.value;
        }
        uint256 totalValue = _value * _to.length;
        require(balances[msg.sender] >= totalValue, "Insufficient balance");
        balances[msg.sender] -= totalValue;
        for (uint i = 0; i < _to.length; i++) {
            _to[i].transfer(_value);
        }
    }

    /**
     * @notice Withdraw any outstanding ETH balance from the contract
     */
    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}
