// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import "./ProxyOFTV2.sol";
import "./SystemVersionId.sol";

/**
 * @title InterportTokenProxyOFT
 * @notice The Interport token proxy OFT contract
 */
contract InterportTokenProxyOFT is ProxyOFTV2, SystemVersionId {
    /**
     * @notice Deploys the InterportTokenProxyOFT contract
     * @param _token The address of the underlying token
     * @param _lzEndpoint The address of the LayerZero endpoint
     */
    constructor(address _token, address _lzEndpoint) ProxyOFTV2(_token, 8, _lzEndpoint) {}
}
