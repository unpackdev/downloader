// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ChainRunnersTypes.sol";

interface IChainRunners {
    function getDna(uint256 _tokenId) external view returns (uint256);
}
