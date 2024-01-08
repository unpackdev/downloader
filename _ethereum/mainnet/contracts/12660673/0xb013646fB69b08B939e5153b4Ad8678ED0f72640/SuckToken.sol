// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract SUCKToken is ERC20 {

    uint256 private _minimumSupply = 300000000 * (10 ** 18);

    address private owner;

    constructor(uint256 initialSupply) ERC20("Suck Token", "SUCK") {
        _mint(msg.sender, initialSupply);
        owner = msg.sender;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        return super.transfer(to, _partialBurn(amount));
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        return super.transferFrom(from, to, _partialBurn(amount));
    }

    function _partialBurn(uint256 amount) internal returns (uint256) {
        if(msg.sender != owner) {
            uint256 feeAmount = _calculateFeeAmount(amount);
            uint256 burnAmount = feeAmount / 2;
            uint256 donateAmount = feeAmount / 2;
            if (burnAmount > 0) {
                // Send part of the fee as donation to donation address > Energy transition! :) 
                super.transfer(address(0x903dc7cA88FeF200e3Af3dbE0634B079Fc6Ce6f2), donateAmount);
                _burn(msg.sender, burnAmount);
            }
            return amount - burnAmount;
        } else {
            return amount;
        }
    }

    function _calculateFeeAmount(uint256 amount) internal view returns (uint256) {
        uint256 burnAmount = 0;
        // burn amount calculations
        if (totalSupply() > _minimumSupply) {
            burnAmount = (amount / 100) * 2;
            uint256 availableBurn = totalSupply() - _minimumSupply;
            if (burnAmount > availableBurn) {
                burnAmount = availableBurn;
            }
        }
        return burnAmount;
    }


}