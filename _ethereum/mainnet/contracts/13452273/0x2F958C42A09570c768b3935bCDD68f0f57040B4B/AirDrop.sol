//contracts/EVRY.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC20.sol";

contract AirDrop {
    ERC20 public token;

    constructor(ERC20 _token) {
        token = _token;
    }

    function rewardTokenEqual(address[] calldata _addresses, uint256 _amount)
        external
    {
        uint256 _amountSum = _amount * _addresses.length;

        token.transferFrom(msg.sender, address(this), _amountSum);
        for (uint8 i; i < _addresses.length; i++) {
            token.transfer(_addresses[i], _amount);
        }
    }

    function reward(address[] calldata _addresses, uint256[] calldata _amount)
        external
    {
        uint256 _amountSum = 0;
        for (uint8 i; i < _amount.length; i++) {
            _amountSum = _amount[i] + _amountSum;
        }

        token.transferFrom(msg.sender, address(this), _amountSum);
        for (uint8 i; i < _addresses.length; i++) {
            token.transfer(_addresses[i], _amount[i]);
        }
    }
}
