// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./Initializable.sol";

///@title  Bumper Liquidity Provision Program (LPP) - bUSDC ERC20 Token
///@notice This suite of contracts is intended to be replaced with the Bumper 1b launch in Q4 2021.
///@dev onlyOwner for BUSDC will be BumpMarket
interface IBUSDC is IERC20Upgradeable {
    function unlockTimestamp() external returns (uint256);

    function pause() external;

    function unpause() external;

    function mint(address account, uint256 amount) external;

    function decimals() external returns (uint8);

    function updateUnlockTimestamp(uint256 _unlockTimestamp) external;

    function burn(address account, uint256 amount) external;
}
