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

import "./SafeERC20.sol";
import "./Pausable.sol";
import "./RegistryAccessor.sol";
import "./Decimal.sol";
import "./Interfaces.sol";

/**
 * @title Migrator
 * @notice Migration contract that allows users to burn their ESD v1 assets into Continuous ESDS
 * @dev Migration Properties:
 *       - The ESDS:ESD ratio will be fixed once bonding is disabled by one of the migration preparation v1 EIPs
 *       - All v1 ESD that is bonded will be burned as part of the migration process
 *       - There will perpetually be outstanding v1 assets in the form of:
 *         (1) Circulating v1 ESD
 *         (2) Unredeemed underlying coupons
 *         (3) ESDS stake in the v1 DAO
 *
 *     This contract allows the batched conversion of a user's (1) circulating ESD and (3) ESDS stake, but
 *     does not support directly converting from (2) unredeemed coupons (a user must redeem these beforehand)
 *
 *     In order to initialize this contract, the Continuous ESD protocol must fund it with ESDS such that all
 *     v1 assets can be redeemed. This should not be initialized until the v1 supply is fixed (e.g. regulation
 *     paused, epoch advancement turned off, and governance frozen). In the event that this is not possible,
 *     this contract may be topped up via governance after initialization if there is insufficient available ESDS.
 */
contract Migrator is RegistryAccessor, Pausable {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;
    using SafeERC20 for IERC20;

    /**
     * @notice Emitted when `owner` initialized this contract after funding with at least `outstandingStake` ESDS
     */
    event Initialized(address owner, uint256 outstandingStake);

    /**
     * @notice Emitted when `account` migrates `dollarAmount` v1 ESD and `stakeAmount` v1 ESDS
     */
    event Migration(address account, uint256 dollarAmount, uint256 stakeAmount);

    /**
     * @notice Emitted when the owner withdraws `amount` ESDS to the reserve due to excess funding
     */
    event Withdrawal(uint256 amount);

    /**
     * @notice Ratio of ESDS granted for ESD burned
     * @dev Determined based on the final bonding exchange rate in the v1 DAO
     */
    Decimal.D256 public ratio;

    /**
     * @notice Address of the v1 ESD DAO
     */
    IDAO public dao;

    /**
     * @notice Address of the v1 ESD stablecoin
     */
    address public dollar;

    /**
     * @notice Construct the Migrator contract
     * @param ratio_ Ratio of ESDS granted for ESD burned
     * @param dao_ Address of the v1 ESD DAO
     * @param dollar_ Address of the v1 ESD stablecoin
     * @param registry_ Address of the Continuous ESDS contract registry
     */
    constructor(uint256 ratio_, IDAO dao_, address dollar_, address registry_) public {
        ratio = Decimal.D256({value: ratio_});
        dao = dao_;
        dollar = dollar_;
        setRegistry(registry_);

        pause();
    }

    // ADMIN

    /**
     * @notice Initializes and unpauses the migrator contract for use
     * @dev Owner only - governance hook
     *      Verifies that this contract is sufficiently funded - reverts if not
     */
    function initialize() external onlyOwner {
        _verifyBalance();
        unpause();

        emit Initialized(owner(), outstandingStake());
    }

    /**
     * @notice ESDS-equivalent value of the total outstanding v1 assets
     * @return Total ESDS value outstanding
     */
    function outstandingStake() public view returns (uint256) {
        // Total supply of ESDS from bonded ESD
        uint256 bondedStake = dao.totalSupply();

        // Total circulating ESD
        uint256 circulatingDollar = IERC20(dollar).totalSupply();
        // Total ESD locked as coupon underlying
        uint256 circulatingCouponUnderlying = dao.totalCouponUnderlying();
        // Convertible ESDS from total ESD supply
        uint256 circulatingStake = ratio.mul(circulatingDollar.add(circulatingCouponUnderlying)).asUint256();

        return bondedStake.add(circulatingStake);
    }

    /**
     * @notice Allows the owner to withdraw `amount` ESDS to the reserve
     * @dev Owner only - governance hook
     *      Verifies that this contract is sufficiently funded - reverts if not
     */
    function withdraw(uint256 amount) external onlyOwner {
        IERC20(registry.stake()).safeTransfer(registry.reserve(), amount);
        _verifyBalance();

        emit Withdrawal(amount);
    }

    /**
     * @notice Check that this contract is sufficiently funded with Continuous ESDS for the remaining
     *         {outstandingStake}
     * @dev Internal only - helper
     *      Verifies that this contract is sufficiently funded - reverts if not
     */
    function _verifyBalance() private view {
        require(IERC20(registry.stake()).balanceOf(address(this)) >= outstandingStake(), "Migrator: insufficient funds");
    }

    // MIGRATE

    /**
     * @notice Migrates `dollarAmount` v1 ESD and `stakeAmount` v1 ESDS for the caller to Continuous ESDS
     * @dev Contract must be initialized to call
     * @param dollarAmount Amount of v1 ESD to migrate
     * @param stakeAmount Amount of v1 ESDS to migrate
     */
    function migrate(uint256 dollarAmount, uint256 stakeAmount) external whenNotPaused {
        _migrateDollar(msg.sender, dollarAmount);
        _migrateStake(msg.sender, stakeAmount);

        emit Migration(msg.sender, dollarAmount, stakeAmount);
    }

    /**
     * @notice Migrates `dollarAmount` v1 ESD for `account` to Continuous ESDS
     * @dev Internal only - helper
     * @param account Account to migrate funds for
     * @param dollarAmount Amount of v1 ESD to migrate
     */
    function _migrateDollar(address account, uint256 dollarAmount) private {
        IERC20(dollar).safeTransferFrom(account, address(this), dollarAmount);
        IManagedToken(dollar).burn(dollarAmount);
        IERC20(registry.stake()).safeTransfer(account, ratio.mul(dollarAmount).asUint256());
    }

    /**
     * @notice Migrates `stakeAmount` v1 ESDS for `account` to Continuous ESDS
     * @dev Internal only - helper
     * @param account Account to migrate funds for
     * @param stakeAmount Amount of v1 ESDS to migrate
     */
    function _migrateStake(address account, uint256 stakeAmount) private {
        dao.burn(account, stakeAmount);
        IERC20(registry.stake()).safeTransfer(account, stakeAmount);
    }
}

/**
 * @title IDAO
 * @notice Interface for applicable functions on the v1 ESD DAO
 */
interface IDAO {
    /**
     * @notice Burns the `amount` v1 ESDS from `account`
     * @dev callable by the migrator contract only
     * @param account Account to burn funds from
     * @param amount Amount of v1 ESDS to burn
     */
    function burn(address account, uint256 amount) external;

    /**
     * @notice Total supply of v1 ESDS tokens
     * @return v1 ESDS total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Total amount of unredeemed v1 coupon underlying
     * @return v1 Total coupon underlying
     */
    function totalCouponUnderlying() external view returns (uint256);
}