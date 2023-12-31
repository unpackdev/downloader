// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./Ownable.sol";

contract KenEscrow is Ownable {
    error InsufficientBalance(address);
    error InsufficientAllowance(address);
    error CallerIsNotAnOperator();
    error OperationExpired();

    mapping(address => bool) public operators;
    IERC20 public immutable tokenContract;

    // Only acessible by designated opertors (and the owner)
    modifier onlyOperator() {
        if (!operators[_msgSender()] && _msgSender() != owner())
            revert CallerIsNotAnOperator();
        _;
    }

    constructor(address tokenAddress, address operatorAddress) {
        tokenContract = IERC20(tokenAddress);
        operators[operatorAddress] = true;
    }

    // Add or remove operator
    function setOperator(address wallet, bool isOperator) public onlyOwner {
        operators[wallet] = isOperator;
    }

    // Add or remove operators
    function setOperators(
        address[] calldata wallets,
        bool isOperator
    ) public onlyOwner {
        for (uint i = 0; i < wallets.length; i++) {
            operators[wallets[i]] = isOperator;
        }
    }

    // Collect funds from players
    function collect(
        address[] calldata wallets,
        uint amount,
        uint expiry
    ) public onlyOperator {
        if (expiry > 0 && block.timestamp > expiry) revert OperationExpired();
        for (uint i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            if (tokenContract.balanceOf(wallet) < amount)
                revert InsufficientBalance(wallet);
            if (tokenContract.allowance(wallet, address(this)) < amount)
                revert InsufficientAllowance(wallet);

            tokenContract.transferFrom(wallet, address(this), amount);
        }
    }

    // Utility function to get balance + allowance
    function getBalances(
        address[] calldata wallets
    ) public view returns (uint[] memory balances, uint[] memory allowances) {
        balances = new uint[](wallets.length);
        allowances = new uint[](wallets.length);
        for (uint i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            balances[i] = tokenContract.balanceOf(wallet);
            allowances[i] = tokenContract.allowance(wallet, address(this));
        }
    }

    // Send $KEN to one address
    function send(address wallet, uint amount) public onlyOperator {
        tokenContract.transfer(wallet, amount);
    }

    // Send $KEN to multiple addresses
    function send(
        address[] memory wallets,
        uint[] memory amounts
    ) public onlyOperator {
        for (uint i = 0; i < wallets.length; i++) {
            tokenContract.transfer(wallets[i], amounts[i]);
        }
    }
}
