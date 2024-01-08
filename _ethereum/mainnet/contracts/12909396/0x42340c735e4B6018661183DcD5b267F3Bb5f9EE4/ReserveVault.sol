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
import "./SafeERC20.sol";

import "./Interfaces.sol";
import "./Decimal.sol";
import "./ReserveState.sol";

/**
 * @title ReserveVault
 * @notice Logic to passively manage USDC reserve with low-risk strategies
 * @dev Currently uses Compound to lend idle USDC in the reserve
 */
contract ReserveVault is ReserveAccessors {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Decimal for Decimal.D256;

    /**
     * @notice Emitted when `amount` USDC is supplied to the vault
     */
    event SupplyVault(uint256 amount);

    /**
     * @notice Emitted when `amount` USDC is redeemed from the vault
     */
    event RedeemVault(uint256 amount);

    /**
     * @notice Total value of the assets managed by the vault
     * @dev Denominated in USDC
     * @return Total value of the vault
     */
    function _balanceOfVault() internal view returns (uint256) {
        ICErc20 cUsdc = ICErc20(registry().cUsdc());

        Decimal.D256 memory exchangeRate = Decimal.D256({value: cUsdc.exchangeRateStored()});
        return exchangeRate.mul(cUsdc.balanceOf(address(this))).asUint256();
    }

    /**
     * @notice Supplies `amount` USDC to the external protocol for reward accrual
     * @dev Supplies to the Compound USDC lending pool
     * @param amount Amount of USDC to supply
     */
    function _supplyVault(uint256 amount) internal {
        address cUsdc = registry().cUsdc();

        IERC20(registry().usdc()).safeApprove(cUsdc, amount);
        require(ICErc20(cUsdc).mint(amount) == 0, "ReserveVault: supply failed");

        emit SupplyVault(amount);
    }

    /**
     * @notice Redeems `amount` USDC from the external protocol for reward accrual
     * @dev Redeems from the Compound USDC lending pool
     * @param amount Amount of USDC to redeem
     */
    function _redeemVault(uint256 amount) internal {
        require(ICErc20(registry().cUsdc()).redeemUnderlying(amount) == 0, "ReserveVault: redeem failed");

        emit RedeemVault(amount);
    }

    /**
     * @notice Claims all available governance rewards from the external protocol
     * @dev Owner only - governance hook
     *      Claims COMP accrued from lending on the USDC pool
     */
    function claimVault() external onlyOwner {
        ICErc20(registry().cUsdc()).comptroller().claimComp(address(this));
    }

    /**
     * @notice Delegates voting power to `delegatee` for `token` governance token held by the reserve
     * @dev Owner only - governance hook
     *      Works for all COMP-based governance tokens
     * @param token Governance token to delegate voting power
     * @param delegatee Account to receive reserve's voting power
     */
    function delegateVault(address token, address delegatee) external onlyOwner {
        IGovToken(token).delegate(delegatee);
    }
}

/**
 * @title ICErc20
 * @dev Compound ICErc20 interface
 */
contract ICErc20 {
    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(uint mintAmount) external returns (uint256);

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint redeemAmount) external returns (uint256);

    /**
     * @notice Get the token balance of the `account`
     * @param account The address of the account to query
     * @return The number of tokens owned by `account`
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() external view returns (uint256);

    /**
      * @notice Contract which oversees inter-cToken operations
      */
    function comptroller() public view returns (IComptroller);
}

/**
 * @title IComptroller
 * @dev Compound IComptroller interface
 */
contract IComptroller {

    /**
     * @notice Claim all the comp accrued by holder in all markets
     * @param holder The address to claim COMP for
     */
    function claimComp(address holder) public;
}