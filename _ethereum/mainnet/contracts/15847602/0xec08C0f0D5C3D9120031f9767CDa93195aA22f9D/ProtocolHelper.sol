// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./DodoV1Helper.sol";
import "./HashflowHelper.sol";
import "./UniswapV2Helper.sol";

/**
 * @title ProtocolHelper
 * @notice Aggregated helper that includes all other helpers for simplicity sake
 */
// solhint-disable-next-line no-empty-blocks
contract ProtocolHelper is
    DodoV1Helper,
    UniswapV2Helper,
    HashflowHelper
{

}
