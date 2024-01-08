// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "./IOilerOptionBase.sol";
import "./IOilerRegistry.sol";
import "./IBRouter.sol";

interface IOilerOptionsRouter {
    // TODO add expiration?
    struct Permit {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function registry() external view returns (IOilerRegistry);

    function bRouter() external view returns (IBRouter);

    function setUnlimitedApprovals(IOilerOptionBase _option) external;

    function write(IOilerOptionBase _option, uint256 _amount) external;

    function write(
        IOilerOptionBase _option,
        uint256 _amount,
        Permit calldata _permit
    ) external;

    function writeAndAddLiquidity(
        IOilerOptionBase _option,
        uint256 _amount,
        uint256 _liquidityProviderCollateralAmount
    ) external;

    function writeAndAddLiquidity(
        IOilerOptionBase _option,
        uint256 _amount,
        uint256 _liquidityProviderCollateralAmount,
        Permit calldata _writePermit,
        Permit calldata _liquidityAddPermit
    ) external;
}
