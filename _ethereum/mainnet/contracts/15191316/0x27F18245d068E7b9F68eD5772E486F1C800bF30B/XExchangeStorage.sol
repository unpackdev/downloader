// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IWeth.sol";
import "./ITransferManagerSelector.sol";
import "./IRoyaltyEngine.sol";
import "./IMarketplaceFeeEngine.sol";
import "./IStrategyManager.sol";
import "./ICurrencyManager.sol";

contract XExchangeStorage {
    bytes32 public domainSeperator;
    IWeth public weth;

    ITransferManagerSelector public transferManager;
    IRoyaltyEngine public royaltyEngine;
    IMarketplaceFeeEngine public marketplaceFeeEngine;
    IStrategyManager public strategyManager;
    ICurrencyManager public currencyManager;
    mapping(address => uint256) public userMinNonce;
    mapping(bytes32 => bool) public orderStatus;
}
