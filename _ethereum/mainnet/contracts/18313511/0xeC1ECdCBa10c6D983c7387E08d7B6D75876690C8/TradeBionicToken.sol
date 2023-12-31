// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract TradeBionicToken is ERC20, Ownable {
    mapping(address => bool) public isLp;

    uint public sellTax;
    uint public buyTax;
    address public treasury;

    error ZeroAddress();
    error BasisPointsOutOfRange(uint newBasisPoints);

    constructor(
        address _treasury,
        address _newOwner,
        uint _sellTax,
        uint _buyTax
    ) ERC20("TradeBionic", "ONIC") Ownable(_newOwner) {
        if (_sellTax > 10_000) {
            revert BasisPointsOutOfRange(_sellTax);
        }

        if (_buyTax > 10_000) {
            revert BasisPointsOutOfRange(_buyTax);
        }

        if (_treasury == address(0)) {
            revert ZeroAddress();
        }

        _mint(_newOwner, 10_000_000 * 10 ** decimals());

        sellTax = _sellTax;
        buyTax = _buyTax;
        treasury = _treasury;
    }

    function changeSellTax(uint _newSellTax) external onlyOwner {
        if (_newSellTax > 10_000) {
            revert BasisPointsOutOfRange(_newSellTax);
        }

        sellTax = _newSellTax;
    }

    function changeBuyTax(uint _newBuyTax) external onlyOwner {
        if (_newBuyTax > 10_000) {
            revert BasisPointsOutOfRange(_newBuyTax);
        }

        buyTax = _newBuyTax;
    }

    function changeTreasury(address _newTreasury) external onlyOwner {
        if (_newTreasury == address(0)) {
            revert ZeroAddress();
        }

        treasury = _newTreasury;
    }

    function modifyLp(address lp, bool isPool) external onlyOwner {
        if (lp == address(0)) {
            revert ZeroAddress();
        }
        isLp[lp] = isPool;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint tax;
        uint toTransfer = amount;
        if (isLp[from]) {
            tax = (amount * buyTax) / 10_000;
            toTransfer = amount - tax;
        } else if (isLp[to]) {
            tax = (amount * sellTax) / 10_000;
            toTransfer = amount - tax;
        }

        if (tax != 0) {
            super._transfer(from, treasury, tax);
        }
        super._transfer(from, to, toTransfer);
    }
}
