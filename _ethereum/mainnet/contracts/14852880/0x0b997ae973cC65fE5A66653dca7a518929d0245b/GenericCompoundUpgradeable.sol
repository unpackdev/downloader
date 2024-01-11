// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "./AggregatorV3Interface.sol";

import "./CErc20I.sol";
import "./IComptroller.sol";
import "./InterestRateModel.sol";

import "./GenericLenderBaseUpgradeable.sol";

/// @title GenericCompoundV3
/// @author Forked from here: https://github.com/Grandthrax/yearnV2-generic-lender-strat/blob/master/contracts/GenericLender/GenericCompound.sol
contract GenericCompoundUpgradeable is GenericLenderBaseUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address;

    uint256 public constant BLOCKS_PER_YEAR = 2_350_000;

    AggregatorV3Interface public constant oracle = AggregatorV3Interface(0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5);
    IComptroller public constant comptroller = IComptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    address public constant comp = 0xc00e94Cb662C3520282E6f5717214004A7f26888;

    // ======================== References to contracts ============================

    CErc20I public cToken;
    uint256 private dust;

    // =============================== Errors ======================================

    error FailedToMint();
    error FailedToRecoverETH();
    error FailedToRedeem();
    error InvalidOracleValue();
    error WrongCToken();

    // ============================= Constructor ===================================

    /// @notice Initializer of the `GenericCompound`
    /// @param _strategy Reference to the strategy using this lender
    /// @param _cToken Address of the cToken
    /// @param governorList List of addresses with governor privilege
    /// @param keeperList List of addresses with keeper privilege
    /// @param guardian Address of the guardian
    function initialize(
        address _strategy,
        string memory _name,
        address _cToken,
        address[] memory governorList,
        address guardian,
        address[] memory keeperList
    ) external {
        _initialize(_strategy, _name, governorList, guardian, keeperList);

        cToken = CErc20I(_cToken);
        if (CErc20I(_cToken).underlying() != address(want)) revert WrongCToken();

        want.safeApprove(_cToken, type(uint256).max);
        IERC20(comp).safeApprove(oneInch, type(uint256).max);
    }

    // ===================== External Strategy Functions ===========================

    /// @notice Deposits the current balance of the contract to the lending platform
    function deposit() external override onlyRole(STRATEGY_ROLE) {
        uint256 balance = want.balanceOf(address(this));
        if (cToken.mint(balance) != 0) revert FailedToMint();
    }

    /// @notice Withdraws a given amount from lender
    /// @param amount The amount the caller wants to withdraw
    /// @return Amount actually withdrawn
    function withdraw(uint256 amount) external override onlyRole(STRATEGY_ROLE) returns (uint256) {
        return _withdraw(amount);
    }

    /// @notice Withdraws as much as possible from the lending platform
    /// @return Whether everything was withdrawn or not
    function withdrawAll() external override onlyRole(STRATEGY_ROLE) returns (bool) {
        uint256 invested = _nav();
        uint256 returned = _withdraw(invested);
        return returned >= invested;
    }

    // ========================== External View Functions ==========================

    /// @notice Helper function the current balance of cTokens
    function underlyingBalanceStored() public view override returns (uint256 balance) {
        uint256 currentCr = cToken.balanceOf(address(this));
        if (currentCr == 0) {
            balance = 0;
        } else {
            //The current exchange rate as an unsigned integer, scaled by 1e18.
            balance = (currentCr * cToken.exchangeRateStored()) / 1e18;
        }
    }

    /// @notice Returns an estimation of the current Annual Percentage Rate after a new deposit
    /// of `amount`
    /// @param amount Amount to add to the lending platform, and that we want to take into account
    /// in the apr computation
    function aprAfterDeposit(uint256 amount) external view override returns (uint256) {
        uint256 cashPrior = want.balanceOf(address(cToken));

        uint256 borrows = cToken.totalBorrows();

        uint256 reserves = cToken.totalReserves();

        uint256 reserverFactor = cToken.reserveFactorMantissa();

        InterestRateModel model = cToken.interestRateModel();

        // The supply rate is derived from the borrow rate, reserve factor and the amount of total borrows.
        uint256 supplyRate = model.getSupplyRate(cashPrior + amount, borrows, reserves, reserverFactor);
        // Adding the yield from comp
        return supplyRate * BLOCKS_PER_YEAR + _incentivesRate(amount);
    }

    // ================================= Governance ================================

    /// @notice Withdraws as much as possible in case of emergency and sends it to the `PoolManager`
    /// @param amount Amount to withdraw
    /// @dev Does not check if any error occurs or if the amount withdrawn is correct
    function emergencyWithdraw(uint256 amount) external override onlyRole(GUARDIAN_ROLE) {
        // Do not care about errors here, what is important is to withdraw what is possible
        cToken.redeemUnderlying(amount);

        want.safeTransfer(address(poolManager), want.balanceOf(address(this)));
    }

    /// @notice Allow to modify the dust amount
    /// @param dust_ Amount under which the contract do not try to redeem from Compouns
    /// @dev Set in a function because contract was already initalized
    function setDust(uint256 dust_) external onlyRole(GUARDIAN_ROLE) {
        dust = dust_;
    }

    // ============================= Internal Functions ============================

    /// @notice See `apr`
    function _apr() internal view override returns (uint256) {
        return cToken.supplyRatePerBlock() * BLOCKS_PER_YEAR + _incentivesRate(0);
    }

    /// @notice See `withdraw`
    function _withdraw(uint256 amount) internal returns (uint256) {
        uint256 balanceUnderlying = cToken.balanceOfUnderlying(address(this));
        uint256 looseBalance = want.balanceOf(address(this));
        uint256 total = balanceUnderlying + looseBalance;

        if (amount > total) {
            // Can't withdraw more than we own
            amount = total;
        }

        if (looseBalance >= amount) {
            want.safeTransfer(address(strategy), amount);
            return amount;
        }

        // Not state changing but OK because of previous call
        uint256 liquidity = want.balanceOf(address(cToken));

        if (liquidity > 1) {
            uint256 toWithdraw = amount - looseBalance;
            // If amount is too low then do not try to withdraw it
            // Risk being: the tx can revert because the cToken needed to be sent == 0
            if (toWithdraw >= dust) {
                if (toWithdraw <= liquidity) {
                    // We can take all
                    if (cToken.redeemUnderlying(toWithdraw) != 0) revert FailedToRedeem();
                } else {
                    // Take all we can
                    if (cToken.redeemUnderlying(liquidity) != 0) revert FailedToRedeem();
                }
            }
        }
        address[] memory holders = new address[](1);
        CTokenI[] memory cTokens = new CTokenI[](1);
        holders[0] = address(this);
        cTokens[0] = cToken;
        comptroller.claimComp(holders, cTokens, true, true);

        looseBalance = want.balanceOf(address(this));
        want.safeTransfer(address(strategy), looseBalance);
        return looseBalance;
    }

    /// @notice Calculates APR from Compound's Liquidity Mining Program
    /// @param amountToAdd Amount to add to the `totalSupplyInWant` (for the `aprAfterDeposit` function)
    function _incentivesRate(uint256 amountToAdd) internal view returns (uint256) {
        uint256 supplySpeed = comptroller.compSupplySpeeds(address(cToken));
        uint256 totalSupplyInWant = (cToken.totalSupply() * cToken.exchangeRateStored()) / 1e18 + amountToAdd;
        // `supplySpeed` is in `COMP` unit -> the following operation is going to put it in `want` unit
        supplySpeed = _comptoWant(supplySpeed);
        uint256 incentivesRate;
        // Added for testing purposes and to handle the edge case where there is nothing left in a market
        if (totalSupplyInWant == 0) {
            incentivesRate = supplySpeed * BLOCKS_PER_YEAR;
        } else {
            // `incentivesRate` is expressed in base 18 like all APR
            incentivesRate = (supplySpeed * BLOCKS_PER_YEAR * 1e18) / totalSupplyInWant;
        }
        return (incentivesRate * 9500) / 10000; // 95% of estimated APR to avoid overestimations
    }

    /// @notice Estimates the value of `_amount` COMP tokens
    /// @param _amount Amount of comp to compute the `want` price of
    /// @dev This function uses a ChainLink oracle to easily compute the price
    function _comptoWant(uint256 _amount) internal view returns (uint256) {
        if (_amount == 0) {
            return 0;
        }
        (uint80 roundId, int256 ratio, , , uint80 answeredInRound) = oracle.latestRoundData();
        if (ratio == 0 || roundId > answeredInRound) revert InvalidOracleValue();
        uint256 castedRatio = uint256(ratio);

        // Checking whether we should multiply or divide by the ratio computed
        return (_amount * castedRatio * wantBase) / 1e26;
    }

    /// @notice Specifies the token managed by this contract during normal operation
    function _protectedTokens() internal view override returns (address[] memory) {
        address[] memory protected = new address[](2);
        protected[0] = address(want);
        protected[1] = address(cToken);
        return protected;
    }

    /// @notice Recovers ETH from the contract
    /// @param amount Amount to be recovered
    function recoverETH(address to, uint256 amount) external onlyRole(GUARDIAN_ROLE) {
        if (!payable(to).send(amount)) revert FailedToRecoverETH();
    }

    receive() external payable {}
}
