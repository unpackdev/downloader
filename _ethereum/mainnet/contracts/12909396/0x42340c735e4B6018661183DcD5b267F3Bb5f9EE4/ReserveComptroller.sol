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
import "./Decimal.sol";
import "./TimeUtils.sol";
import "./ReserveState.sol";
import "./ReserveVault.sol";

/**
 * @title ReserveComptroller
 * @notice Reserve accounting logic for managing the ESD stablecoin.
 */
contract ReserveComptroller is ReserveAccessors, ReserveVault {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;
    using SafeERC20 for IERC20;

    /**
     * @notice Emitted when `account` purchases `mintAmount` ESD from the reserve for `costAmount` USDC
     */
    event Mint(address indexed account, uint256 mintAmount, uint256 costAmount);

    /**
     * @notice Emitted when `account` sells `costAmount` ESD to the reserve for `redeemAmount` USDC
     */
    event Redeem(address indexed account, uint256 costAmount, uint256 redeemAmount);

    /**
     * @notice Helper constant to convert ESD to USDC and vice versa
     */
    uint256 private constant USDC_DECIMAL_DIFF = 1e12;

    // EXTERNAL

    /**
     * @notice The total value of the reserve-owned assets denominated in USDC
     * @return Reserve total value
     */
    function reserveBalance() public view returns (uint256) {
        uint256 internalBalance = _balanceOf(registry().usdc(), address(this));
        uint256 vaultBalance = _balanceOfVault();
        return internalBalance.add(vaultBalance);
    }

    /**
     * @notice The ratio of the {reserveBalance} to total ESD issuance
     * @dev Assumes 1 ESD = 1 USDC, normalizing for decimals
     * @return Reserve ratio
     */
    function reserveRatio() public view returns (Decimal.D256 memory) {
        uint256 issuance = _totalSupply(registry().dollar());
        return issuance == 0 ? Decimal.one() : Decimal.ratio(_fromUsdcAmount(reserveBalance()), issuance);
    }

    /**
     * @notice The price that one ESD can currently be sold to the reserve for
     * @dev Returned as a Decimal.D256
     *      Normalizes for decimals (e.g. 1.00 USDC == Decimal.one())
     *      Equivalent to the current reserve ratio less the current redemption tax (if any)
     * @return Current ESD redemption price
     */
    function redeemPrice() public view returns (Decimal.D256 memory) {
        return Decimal.min(reserveRatio(), Decimal.one());
    }

    /**
     * @notice Mints `amount` ESD to the caller in exchange for an equivalent amount of USDC
     * @dev Non-reentrant
     *      Normalizes for decimals
     *      Caller must approve reserve to transfer USDC
     * @param amount Amount of ESD to mint
     */
    function mint(uint256 amount) external nonReentrant {
        uint256 costAmount = _toUsdcAmount(amount);

        // Take the ceiling to ensure no "free" ESD is minted
        costAmount = _fromUsdcAmount(costAmount) == amount ? costAmount : costAmount.add(1);

        _transferFrom(registry().usdc(), msg.sender, address(this), costAmount);
        _supplyVault(costAmount);
        _mintDollar(msg.sender, amount);

        emit Mint(msg.sender, amount, costAmount);
    }

    /**
     * @notice Burns `amount` ESD from the caller in exchange for USDC at the rate of {redeemPrice}
     * @dev Non-reentrant
     *      Normalizes for decimals
     *      Caller must approve reserve to transfer ESD
     * @param amount Amount of ESD to mint
     */
    function redeem(uint256 amount) external nonReentrant {
        uint256 redeemAmount = _toUsdcAmount(redeemPrice().mul(amount).asUint256());

        _transferFrom(registry().dollar(), msg.sender, address(this), amount);
        _burnDollar(amount);
        _redeemVault(redeemAmount);
        _transfer(registry().usdc(), msg.sender, redeemAmount);

        emit Redeem(msg.sender, amount, redeemAmount);
    }

    // INTERNAL

    /**
     * @notice Mints `amount` ESD to `account`
     * @dev Internal only
     * @param account Account to receive minted ESD
     * @param amount Amount of ESD to mint
     */
    function _mintDollar(address account, uint256 amount) internal {
        address dollar = registry().dollar();

        IManagedToken(dollar).mint(amount);
        IERC20(dollar).safeTransfer(account, amount);
    }

    /**
     * @notice Burns `amount` ESD held by the reserve
     * @dev Internal only
     * @param amount Amount of ESD to burn
     */
    function _burnDollar(uint256 amount) internal {
        IManagedToken(registry().dollar()).burn(amount);
    }

    /**
     * @notice `token` balance of `account`
     * @dev Internal only
     * @param token Token to get the balance for
     * @param account Account to get the balance of
     */
    function _balanceOf(address token, address account) internal view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }

    /**
     * @notice Total supply of `token`
     * @dev Internal only
     * @param token Token to get the total supply of
     */
    function _totalSupply(address token) internal view returns (uint256) {
        return IERC20(token).totalSupply();
    }

    /**
     * @notice Safely transfers `amount` `token` from the caller to `receiver`
     * @dev Internal only
     * @param token Token to transfer
     * @param receiver Account to receive the tokens
     * @param amount Amount to transfer
     */
    function _transfer(address token, address receiver, uint256 amount) internal {
        IERC20(token).safeTransfer(receiver, amount);
    }

    /**
     * @notice Safely transfers `amount` `token` from the `sender` to `receiver`
     * @dev Internal only
            Requires `amount` allowance from `sender` for caller
     * @param token Token to transfer
     * @param sender Account to send the tokens
     * @param receiver Account to receive the tokens
     * @param amount Amount to transfer
     */
    function _transferFrom(address token, address sender, address receiver, uint256 amount) internal {
        IERC20(token).safeTransferFrom(sender, receiver, amount);
    }

    /**
     * @notice Converts ESD amount to USDC amount
     * @dev Private only
     *      Converts an 18-decimal ERC20 amount to a 6-decimals ERC20 amount
     * @param dec18Amount 18-decimal ERC20 amount
     * @return 6-decimals ERC20 amount
     */
    function _toUsdcAmount(uint256 dec18Amount) internal pure returns (uint256) {
        return dec18Amount.div(USDC_DECIMAL_DIFF);
    }

    /**
     * @notice Convert USDC amount to ESD amount
     * @dev Private only
     *      Converts a 6-decimal ERC20 amount to an 18-decimals ERC20 amount
     * @param usdcAmount 6-decimal ERC20 amount
     * @return 18-decimals ERC20 amount
     */
    function _fromUsdcAmount(uint256 usdcAmount) internal pure returns (uint256) {
        return usdcAmount.mul(USDC_DECIMAL_DIFF);
    }
}