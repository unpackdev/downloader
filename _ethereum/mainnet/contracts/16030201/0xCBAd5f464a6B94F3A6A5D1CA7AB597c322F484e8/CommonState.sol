// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Initializable.sol";

import "./ICommonState.sol";

/**
 * @title Base contract for commonly used state
 * @author Jonas Sota
 */
abstract contract CommonState is ICommonState, Initializable {
    address public factory;
    address public WETH; // solhint-disable-line var-name-mixedcase

    // solhint-disable-next-line func-name-mixedcase, var-name-mixedcase
    function __CommonState_init(address factory_, address WETH_)
        internal
        onlyInitializing
    {
        factory = factory_;
        WETH = WETH_;
    }

    uint256[18] private __gap;
}
