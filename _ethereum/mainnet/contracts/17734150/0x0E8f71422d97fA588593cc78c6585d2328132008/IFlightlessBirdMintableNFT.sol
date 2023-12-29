// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IFlightlessBirdMintableNFT {
    function mint(uint256 _amount, address _receiver) external payable;
}
