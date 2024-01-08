// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./CrvsBTCPoolStrategy.sol";

//solhint-disable no-empty-blocks
contract CrvsBTCStrategyWBTC is CrvsBTCPoolStrategy {
    string public constant NAME = "Curve-sBTC-WBTC-Strategy";
    string public constant VERSION = "3.0.14";

    constructor(address _pool, address _swapManager) CrvsBTCPoolStrategy(_pool, _swapManager, 1) {}

    function convertFrom18(uint256 amount) public pure override returns (uint256) {
        return amount / (10**10);
    }
}
