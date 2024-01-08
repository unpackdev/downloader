/*
    Copyright 2021 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./Interfaces.sol";
import "./ReserveState.sol";

/**
 * @title ReserveIssuer
 * @notice Logic to manage the supply of ESDS
 */
contract ReserveIssuer is ReserveAccessors {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    /**
      * @notice Emitted when `account` mints `amount` of ESDS
      */
    event MintStake(address account, uint256 mintAmount);

    /**
      * @notice Emitted when `amount` of ESDS is burned from the reserve
      */
    event BurnStake(uint256 burnAmount);

    /**
     * @notice Mints new ESDS tokens to a specified `account`
     * @dev Non-reentrant
     *      Owner only - governance hook
     *      ESDS maxes out at ~79b total supply (2^96/10^18) due to its 96-bit limitation
     *      Will revert if totalSupply exceeds this maximum
     * @param account Account to mint ESDS to
     * @param amount Amount of ESDS to mint
     */
    function mintStake(address account, uint256 amount) public onlyOwner {
        address stake = registry().stake();

        IManagedToken(stake).mint(amount);
        IERC20(stake).safeTransfer(account, amount);

        emit MintStake(account, amount);
    }

    /**
     * @notice Burns all reserve-held ESDS tokens
     * @dev Non-reentrant
     *      Owner only - governance hook
     */
    function burnStake() public onlyOwner {
        address stake = registry().stake();

        uint256 stakeBalance = IERC20(stake).balanceOf(address(this));
        IManagedToken(stake).burn(stakeBalance);

        emit BurnStake(stakeBalance);
    }
}