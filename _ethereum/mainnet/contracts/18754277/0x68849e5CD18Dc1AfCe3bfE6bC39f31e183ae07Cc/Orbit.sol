// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./OFTV2.sol";
import "./ERC20Permit.sol";

/**
 * @title  Orbit
 * @notice Orbit token contract
 * @notice This contract is an ERC20 implementation of a BRC20 token, bridged via Orbit Protocol
 */
contract Orbit is OFTV2, ERC20Permit {
    /**
     * @param _layerZeroEndpoint LayerZero endpoint on the chain where this contract is deployed
     * @param _sharedDecimals shared decimals for all Orbit tokens across all LayerZero chains (EVM & Non-EVM)
     * @notice the mint amount is 21,090,109.42069 ORBIT, which represents:
     *         1) 21mil totalBTC
     *         2) BTC 0.1.0 launch on 09 January 2009
     *         3) 420 + 69 for the meme/lols
     */
    constructor(address _layerZeroEndpoint, uint8 _sharedDecimals)
        OFTV2("Orbit", "ORBIT", _sharedDecimals, _layerZeroEndpoint)
        ERC20Permit("Orbit")
    {
        _mint(_msgSender(), 21_090_109_420_690_000_000_000_000);
    }
}
