// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IcbETH.sol";
import "./IRateProvider.sol";

/**
 * @title Coinbase wrapped staked Eth Rate Provider
 * @notice Returns value of cbEth in terms of Eth.
 * cbEth is built on Coinbase's wrapped token contract.
 * https://github.com/coinbase/wrapped-tokens-os. Coinbase
 * controls the oracle's address and updates exchangeRate
 * every 24 hours at 4pm UTC. This update cadende may change
 * in the future.
 */
contract CbEthRateProvider is IRateProvider {
    IcbETH public immutable cbETH;

    constructor(IcbETH _cbETH) {
        cbETH = _cbETH;
    }

    /**
     * @return value of cbETH in terms of Eth scaled by 10**18
     */
    function getRate() public view override returns (uint256) {
        return cbETH.exchangeRate();
    }
}
