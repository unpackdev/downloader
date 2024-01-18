// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ICommonState {
    struct CommonStateInitParams {
        address factory;
        address WETH;
    }

    function WETH() external returns (address); // solhint-disable-line func-name-mixedcase

    function factory() external returns (address);
}
