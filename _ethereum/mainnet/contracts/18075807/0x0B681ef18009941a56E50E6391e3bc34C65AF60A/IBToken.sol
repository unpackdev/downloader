// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./IERC20Upgradeable.sol";

interface IBToken is IERC20Upgradeable {
    /**
     * @dev Returns the address of the underlying asset of this bToken
     **/
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    function scaledBalanceOf(address user) external view returns (uint256);
}
