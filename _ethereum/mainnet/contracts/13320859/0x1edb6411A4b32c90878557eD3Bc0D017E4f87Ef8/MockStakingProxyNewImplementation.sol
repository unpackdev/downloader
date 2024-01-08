// SPDX-License-Identifier: ISC

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./StakingProxy.sol";

contract MockStakingProxyNewImplementation is StakingProxy {
    uint256 public constant NUMBER = 100;
}
