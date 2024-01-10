// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;


interface EKotketNFTFactoryInterface {
    function checkKotketPrice(uint8 _gene) external view returns(uint uKotketToken, uint eWei);
}