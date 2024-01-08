//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeMath.sol";

contract RoyaltiesSplitter {
    using SafeMath for uint256;

    uint256 public constant DENOMINATOR = 10000;

    receive() external payable {
        uint256 totalReceived = msg.value;
        payable(0x402A07f0dD37b6209588B63a75EA21B823fAF30e).call{
            value: (totalReceived * 600) / DENOMINATOR
        }("");
        payable(0x2909Cbe186e86798d45C0b3C2ABf1989e287c7D3).call{
            value: (totalReceived * 800) / DENOMINATOR
        }("");
        payable(0x8E12127a6cC135d5479C6DD1B0776ada92D94FAF).call{
            value: (totalReceived * 600) / DENOMINATOR
        }("");
        payable(0x65D3E3D1E940f1f7a848E742a3E44D5A6227DA53).call{
            value: (totalReceived * 8000) / DENOMINATOR
        }("");
    }
}
