// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Constants {
    /// Addresses
    address internal constant CURVE_ROUTER = 0x99a58482BD75cbab83b27EC03CA68fF489b5788f;
    address internal constant BEAN = 0xBEA0000029AD1c77D3d5D23Ba2D8893dB9d1Efab;
    address internal constant ETHER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant TRI_CRYPTO_POOL = 0xD51a44d3FaE010294C616388b506AcdA1bfAAE46;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal constant CURVE_BEAN_METAPOOL = 0xc9C32cd16Bf7eFB85Ff14e0c8603cc90F6F2eE49;
    address internal constant BEANSTALK_PRICE = 0xF2C2b7eabcB353bF6f2128a7f8e1e32Eeb112530;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant ZERO = 0x0000000000000000000000000000000000000000;
    address internal constant BEANSTALK = 0xC1E088fC1323b20BCBee9bd1B9fC9546db5624C5;
    address internal constant FERTILIZER = 0x402c84De2Ce49aF88f5e2eF3710ff89bFED36cB6;

    /// @notice time out to get price from chainlink
    /// @dev should update before deploying on mainnet
    uint256 internal constant GRACE_PERIOD_TIME = 72000000;

    /// underlying decimals
    uint256 internal constant D18 = 1e18;
    // tranche nft is fractionalized with decimals 6
    uint8 internal constant TRANCHE_DECIMALS = 6;
    uint8 internal constant WATER_DECIMALS = 18;    

    bytes internal constant EMPTY = "";

    /// function selectors
    bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
}
