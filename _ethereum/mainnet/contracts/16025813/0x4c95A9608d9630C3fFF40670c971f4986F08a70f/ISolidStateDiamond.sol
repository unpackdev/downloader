// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./ISafeOwnable.sol";
import "./IERC165.sol";
import "./IDiamondBase.sol";
import "./IDiamondReadable.sol";
import "./IDiamondWritable.sol";

interface ISolidStateDiamond is
    IDiamondBase,
    IDiamondReadable,
    IDiamondWritable,
    ISafeOwnable,
    IERC165
{
    receive() external payable;

    /**
     * @notice get the address of the fallback contract
     * @return fallback address
     */
    function getFallbackAddress() external view returns (address);

    /**
     * @notice set the address of the fallback contract
     * @param fallbackAddress fallback address
     */
    function setFallbackAddress(address fallbackAddress) external;
}
