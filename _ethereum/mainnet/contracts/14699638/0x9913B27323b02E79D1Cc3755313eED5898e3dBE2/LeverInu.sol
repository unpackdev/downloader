// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

contract LeverInu is ERC20, Ownable {

    uint256 public maxTxnAmount;
    bool public limitedTransactionAmount;

    uint256 _totalSupply = 1 * 1e9 * 1e18; // 1 Billion

    constructor() ERC20("Lever Inu", "LEVERINU") {

        limitedTransactionAmount = true;
        maxTxnAmount = _totalSupply * 5 / 1000; // 0.5% maxTransaction Amount at a time

        _mint(msg.sender, _totalSupply);
    }

    function removeTransactionLimit() external onlyOwner
    {
        limitedTransactionAmount = false;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {

        if(limitedTransactionAmount && _from != owner() && _to != owner()) {
            require(_amount <= maxTxnAmount, "transfer amount exceeds the maxTransactionAmount.");
        }

        super._transfer(_from, _to, _amount);
    }
}