// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "./ChainlinkDollarSpendingConsumer.sol";

contract ChainlinkDollarSpendingConsumerMainnet is ChainlinkDollarSpendingConsumer {
  function initialize() public override initializer {
    oracle = 0x049Bd8C3adC3fE7d3Fc2a44541d955A537c2A484;
    jobId ="74295b9df3264781bf904d9e596a2e57";
    fee = 1 * 10 ** 18;
    setChainlinkToken(0x514910771AF9Ca656af840dff83E8264EcF986CA);
    setChainlinkOracle(oracle);
    _admin = msg.sender;
  }
}
