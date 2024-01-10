// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;


interface EGovernanceInterface {
    function kotketWallet() external view returns (address);
    function kotketFundWallet() external view returns (address);
    function kotketTokenAddress() external view returns (address);
    function kotketNFTAddress() external view returns (address);
    function kotketGatewayOracleAddress() external view returns (address);
    function kotketNFTFactoryAddress() external view returns (address);
    function kotketNFTMarketPlaceAddress() external view returns (address);
    function kotketNFTRentalMarketAddress() external view returns (address);
    function kotketNFTPlatformRentingAddress() external view returns (address);
    function usdtAddress() external view returns (address);
}