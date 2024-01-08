// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./Address.sol";
import "./IERC20.sol";
import "./console.sol";

contract Splitter {
    mapping(address => mapping(uint256 => uint256)) private _released;
    mapping(address => uint256) private _totalReleased;
    uint256 private _totalShares;
    address[] private _payees;
    uint256[] private _shares;

    constructor(address[] memory payees, uint256[] memory shares) {
        _payees = payees;
        _shares = shares;

        for (uint256 i = 0; i < payees.length; i++) {
            _totalShares += shares[i];
        }
    }

    receive() external payable {
        if (address(this).balance > 1 ether && gasleft() >= 129_100) {
            withdraw();
        }
    }

    function withdraw() public {
        require(address(this).balance > 0, 'No balance');
        uint256 totalReceived = address(this).balance +
            _totalReleased[address(0)];
        for (uint256 i = 0; i < _payees.length; i++) {
            uint256 payment = (totalReceived * _shares[i]) /
                _totalShares -
                _released[address(0)][i];
            if (payment > 0) {
                _released[address(0)][i] += payment;
                _totalReleased[address(0)] += payment;

                Address.sendValue(payable(_payees[i]), payment);
            }
        }
    }

    function withdraw(address token) public {
        require(token != address(0) && token != address(this), 'Invalid token');
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, 'No balance');

        uint256 totalReceived = balance + _totalReleased[token];
        for (uint256 i = 0; i < _payees.length; i++) {
            uint256 payment = (totalReceived * _shares[i]) /
                _totalShares -
                _released[token][i];
            if (payment > 0) {
                _released[token][i] += payment;
                _totalReleased[token] += payment;

                IERC20(token).transfer(_payees[i], payment);
            }
        }
    }
}
