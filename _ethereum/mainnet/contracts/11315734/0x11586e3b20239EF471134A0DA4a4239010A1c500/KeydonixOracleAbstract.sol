// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov (az@unit.xyz).
*/
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;
import { UniswapOracle } from  '@keydonix/uniswap-oracle-contracts/source/UniswapOracle.sol';


/**
 * @title KeydonixOracleAbstract
 * @author Unit Protocol: Artem Zakharov (az@unit.xyz), Alexander Ponomorev (@bcngod)
 **/
abstract contract KeydonixOracleAbstract {

    uint public immutable Q112 = 2 ** 112;

    function assetToUsd(
        address asset,
        uint amount,
        UniswapOracle.ProofData memory proofData
    ) public virtual view returns (uint) {}
}
