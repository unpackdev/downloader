// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./ISafeOwnable.sol";
import "./IERC165.sol";
import "./IDiamondBase.sol";
import "./IDiamondFallback.sol";
import "./IDiamondReadable.sol";
import "./IDiamondWritable.sol";

interface ISolidStateDiamond is
    IDiamondBase,
    IDiamondFallback,
    IDiamondReadable,
    IDiamondWritable,
    ISafeOwnable,
    IERC165
{
    receive() external payable;
}
