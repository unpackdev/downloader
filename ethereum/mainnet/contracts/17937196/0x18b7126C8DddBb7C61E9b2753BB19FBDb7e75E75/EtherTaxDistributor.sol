// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EtherTaxDistributor
 * @dev A contract that distributes received Ether to three predefined wallets.
 */
contract EtherTaxDistributor {
    enum DistributionState { DISABLED, ENABLED }

    address public owner;
    address payable public wallet1;
    address payable public wallet2;
    address payable public wallet3;
    DistributionState public distributionState;

    event FundsReceived(address indexed sender, uint256 amount);
    // event FundsDistributed(address indexed wallet, uint256 amount);
    event FundsDistributed(address indexed wallet1, uint256 amountToWallet1, address indexed wallet2, uint256 amountToWallet2, address indexed wallet3, uint256 amountToWallet3);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(
        address payable _wallet1,
        address payable _wallet2,
        address payable _wallet3
    ) payable {
        // Ensure valid wallet addresses are provided
        require(_wallet1 != address(0) && _wallet2 != address(0) && _wallet3 != address(0), "Invalid wallet address");

        owner = msg.sender;
        wallet1 = _wallet1;
        wallet2 = _wallet2;
        wallet3 = _wallet3;
        distributionState = DistributionState.ENABLED;
    }

    /**
     * @dev Fallback function to receive Ether
     */
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    /**
     * @dev Modifier to restrict a function to be called only by the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    /**
     * @dev Set wallet addresses to distribute funds
     */
    function setWallets(address payable _newWallet1, address payable _newWallet2, address payable _newWallet3) public onlyOwner {
        require(_newWallet1 != address(0) && _newWallet2 != address(0) && _newWallet3 != address(0), "Invalid wallet addresses");
        wallet1 = _newWallet1;
        wallet2 = _newWallet2;
        wallet3 = _newWallet3;
    }

    /**
     * @dev Change the contract owner
     * @param newOwner The new owner's address
     */
    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Withdraw any excess Ether from the contract
     */
    function withdrawExcessFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to withdraw excess funds.");
    }

    /**
     * @dev Destroy the contract and send any remaining balance to the contract owner
     */
    function destroyContract() public onlyOwner {
        selfdestruct(payable(owner));
    }

    /**
     * @dev Check if it's possible to make distribution
     */
    modifier distributionEnabled() {
        require(distributionState == DistributionState.ENABLED, "Ether distribution is currently disabled");
        _;
    }

    /**
     * @dev Toggle the distribution state of the contract.
     * @param enabled Whether distribution should be enabled or disabled.
     */
    function toggleDistribution(bool enabled) public onlyOwner {
        distributionState = enabled ? DistributionState.ENABLED : DistributionState.DISABLED;
    }

    /**
     * @dev Trigger the distribution of funds to the predefined wallets
     */
    function distributeFunds() public distributionEnabled {
        uint256 thisBalance = address(this).balance;

        uint256 amountToWallet1 = (thisBalance * 3685) / 10000;
        uint256 amountToWallet2 = (thisBalance * 3300) / 10000;
        uint256 amountToWallet3 = (thisBalance * 3015) / 10000;

        distributionState = DistributionState.DISABLED;

        _safeTransfer(wallet1, amountToWallet1);
        _safeTransfer(wallet2, amountToWallet2);
        _safeTransfer(wallet3, amountToWallet3);

        distributionState = DistributionState.ENABLED;

        emit FundsDistributed(wallet1, amountToWallet1, wallet2, amountToWallet2, wallet3, amountToWallet3);

    }

    function _safeTransfer(address payable recipient, uint256 amount) private {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
    }
}