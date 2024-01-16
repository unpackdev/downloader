// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

library Constant {
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant UNISWAP_ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address public constant FEED_REGISTRY = 0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf;
    uint public constant BLOCK_NUMBER_IN_SECOND = 12;
    uint public constant STALE_PRICE_DELAY = 86400;
}
