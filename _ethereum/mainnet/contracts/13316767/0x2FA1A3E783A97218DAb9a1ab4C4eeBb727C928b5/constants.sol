// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

abstract contract DeploymentConstants {
    address public constant ADDRESS_REGISTRY_PROXY_ADMIN = 
        0xFbF6c940c1811C3ebc135A9c4e39E042d02435d1;
    address public constant ADDRESS_REGISTRY_PROXY = 0x7EC81B7035e91f8435BdEb2787DCBd51116Ad303;

    address public constant DAI_ADDRESS =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC_ADDRESS =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT_ADDRESS =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public constant POOL_PROXY_ADMIN =
        0x7965283631253DfCb71Db63a60C656DEDF76234f;
    address public constant DAI_POOL_PROXY =
        0x75CE0E501e2E6776FcAAa514f394a88a772A8970;
    address public constant USDC_POOL_PROXY =
        0xe18b0365D5D09F394f84eE56ed29DD2d8D6Fba5f;
    address public constant USDT_POOL_PROXY =
        0xeA9c5a2717D5Ab75afaAC340151e73a7e37d99A7;

    address public constant TVL_AGG_ADDRESS =
        0xDb299D394817D8e7bBe297E84AFfF7106CF92F5f;
    address public constant DAI_USD_AGG_ADDRESS =
        0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;
    address public constant USDC_USD_AGG_ADDRESS =
        0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    address public constant USDT_USD_AGG_ADDRESS =
        0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
}
