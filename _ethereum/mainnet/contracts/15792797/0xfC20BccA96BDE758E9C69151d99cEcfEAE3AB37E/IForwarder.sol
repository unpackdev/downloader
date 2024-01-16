// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import "./Token18.sol";
import "./Token6.sol";
import "./UFixed18.sol";
import "./IBatcher.sol";
import "./ICollateral.sol";

interface IForwarder {
    error ForwarderNotContractAddressError();

    event WrapAndDeposit(address indexed account, IProduct indexed product, UFixed18 amount);

    function USDC() external view returns (Token6); // solhint-disable-line func-name-mixedcase
    function DSU() external view returns (Token18); // solhint-disable-line func-name-mixedcase
    function batcher() external view returns (IBatcher);
    function collateral() external view returns (ICollateral);
    function wrapAndDeposit(address account, IProduct product, UFixed18 amount) external;
}
