// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./IERC3156FlashBorrower.sol";
import "./Math.sol";

import "./AggregatorV3Interface.sol";

import "./AaveLibraries.sol";
import "./AaveInterfaces.sol";
import "./BaseStrategyUpgradeable.sol";
import "./ComputeProfitability.sol";

/// @title AaveFlashloanStrategy
/// @author Yearn Finance (https://etherscan.io/address/0xd4E94061183b2DBF24473F28A3559cf4dE4459Db#code)
/// but heavily reviewed and modified by Angle Core Team
/// @notice This strategy is used to optimize lending yield on Aave by taking some form or recursivity that is to say
/// by borrowing to maximize Aave rewards
/// @dev Angle strategies computes the optimal collateral ratio based on AAVE rewards for deposits and borrows
// solhint-disable-next-line max-states-count
contract AaveFlashloanStrategy is BaseStrategyUpgradeable, IERC3156FlashBorrower {
    using SafeERC20 for IERC20;
    using Address for address;

    // =========================== Constant Addresses ==============================

    /// @notice Router used for swaps
    address private constant _oneInch = 0x1111111254fb6c44bAC0beD2854e76F90643097d;
    /// @notice Chainlink oracle used to fetch data
    AggregatorV3Interface private constant _chainlinkOracle =
        AggregatorV3Interface(0x547a514d5e3769680Ce22B2361c10Ea13619e8a9);

    // ========================== Aave Protocol Addresses ==========================

    IAaveIncentivesController private constant _incentivesController =
        IAaveIncentivesController(0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5);
    ILendingPool private constant _lendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    IProtocolDataProvider private constant _protocolDataProvider =
        IProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);

    // ============================== Token Addresses ==============================

    address private constant _aave = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    IStakedAave private constant _stkAave = IStakedAave(0x4da27a545c0c5B758a6BA100e3a049001de870f5);
    address private constant _weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant _dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    // ============================== Ops Constants ================================

    uint256 private constant _DEFAULT_COLLAT_TARGET_MARGIN = 0.02 ether;
    uint256 private constant _DEFAULT_COLLAT_MAX_MARGIN = 0.005 ether;
    uint256 private constant _LIQUIDATION_WARNING_THRESHOLD = 0.01 ether;
    uint256 private constant _BPS_WAD_RATIO = 1e14;
    uint256 private constant _COLLATERAL_RATIO_PRECISION = 1 ether;
    uint16 private constant _referral = 0;

    // ========================= Aave Protocol Parameters ==========================

    IReserveInterestRateStrategy private _interestRateStrategyAddress;
    uint256 public cooldownSeconds;
    uint256 public unstakeWindow;
    int256 public reserveFactor;
    int256 public slope1;
    int256 public slope2;
    int256 public r0;
    int256 public uOptimal;

    // =============================== Parameters and Variables ====================

    /// @notice Maximum the Aave protocol will let us borrow
    uint256 public maxBorrowCollatRatio;
    /// @notice LTV the strategy is going to lever up to
    uint256 public targetCollatRatio;
    /// @notice Closest to liquidation we'll risk
    uint256 public maxCollatRatio;
    /// @notice Parameter used for flash mints
    uint256 public daiBorrowCollatRatio;
    /// @notice Minimum amount to be moved before a deposit or a borrow
    uint256 public minWant;
    /// @notice Minimum gap between the collat ratio and the target collat ratio before
    /// rectifying it
    uint256 public minRatio;
    /// @notice Discount factor applied to the StkAAVE price
    uint256 public discountFactor;
    /// @notice Max number of iterations possible for the computation of the optimal lever
    uint8 public maxIterations;

    struct BoolParams {
        // Whether collateral ratio will be automatically computed
        bool automaticallyComputeCollatRatio;
        // Whether Flash mint is active
        bool isFlashMintActive;
        // Whether we should check withdrawals
        bool withdrawCheck;
        // Whether StkAAVE should be sent to cooldown or simply swapped for Aave all the time
        bool cooldownStkAave;
    }
    /// @notice Struct with some boolean parameters of the contract
    /// These parameters are packed in a struct for efficiency of SLOAD operations
    BoolParams public boolParams;

    // ========================= Supply and Borrow Tokens ==========================

    IAToken private _aToken;
    IVariableDebtToken private _debtToken;

    // ============================ Initializer ====================================

    /// @notice Constructor of the `Strategy`
    /// @param _poolManager Address of the `PoolManager` lending to this strategy
    /// @param interestRateStrategyAddress_ Address of the `InterestRateStrategy` defining borrow rates for the collateral
    /// @param governor Governor address of the protocol
    /// @param guardian Address of the guardian
    /// @param keepers List of the addresses with keeper privilege
    function initialize(
        address _poolManager,
        IReserveInterestRateStrategy interestRateStrategyAddress_,
        address governor,
        address guardian,
        address[] memory keepers
    ) external {
        _initialize(_poolManager, governor, guardian, keepers);

        // Then initializing operational state
        maxIterations = 6;
        // Setting mins
        minWant = 100;
        minRatio = 0.005 ether;
        discountFactor = 9000;

        boolParams = BoolParams({
            automaticallyComputeCollatRatio: true,
            isFlashMintActive: true,
            withdrawCheck: false,
            cooldownStkAave: true
        });

        _interestRateStrategyAddress = interestRateStrategyAddress_;
        // Setting reward params
        _setAavePoolVariables();

        // Set AAVE tokens
        (address aToken_, , address debtToken_) = _protocolDataProvider.getReserveTokensAddresses(address(want));
        _aToken = IAToken(aToken_);
        _debtToken = IVariableDebtToken(debtToken_);

        // Let collateral targets
        (uint256 ltv, uint256 liquidationThreshold) = _getProtocolCollatRatios(address(want));
        targetCollatRatio = liquidationThreshold - _DEFAULT_COLLAT_TARGET_MARGIN;
        maxCollatRatio = liquidationThreshold - _DEFAULT_COLLAT_MAX_MARGIN;
        maxBorrowCollatRatio = ltv - _DEFAULT_COLLAT_MAX_MARGIN;
        (uint256 daiLtv, ) = _getProtocolCollatRatios(_dai);
        daiBorrowCollatRatio = daiLtv - _DEFAULT_COLLAT_MAX_MARGIN;

        // Performing all the different approvals possible
        _approveMaxSpend(address(want), address(_lendingPool));
        _approveMaxSpend(aToken_, address(_lendingPool));
        // Approve flashloan spend
        _approveMaxSpend(_dai, FlashMintLib.LENDER);
        // Approve swap router spend
        _approveMaxSpend(address(_stkAave), _oneInch);
        _approveMaxSpend(_aave, _oneInch);
        if (address(want) != _dai) {
            _approveMaxSpend(_dai, address(_lendingPool));
        }
    }

    // ======================= Helper View Functions ===============================

    /// @notice Estimates the total assets controlled by the strategy
    /// @dev It sums the effective deposit amount to the rewards accumulated
    function estimatedTotalAssets() public view override returns (uint256) {
        (uint256 deposits, uint256 borrows) = getCurrentPosition();
        return
            _balanceOfWant() +
            deposits -
            borrows +
            _estimatedStkAaveToWant(
                _balanceOfStkAave() +
                    _balanceOfAave() +
                    _incentivesController.getRewardsBalance(_getAaveAssets(), address(this))
            );
    }

    /// @notice Get the current position of the strategy: that is to say the amount deposited
    /// and the amount borrowed on Aave
    /// @dev The actual amount brought is `deposits - borrows`
    function getCurrentPosition() public view returns (uint256 deposits, uint256 borrows) {
        deposits = _balanceOfAToken();
        borrows = _balanceOfDebtToken();
    }

    // ====================== Internal Strategy Functions ==========================

    /// @notice Frees up profit plus `_debtOutstanding`.
    /// @param _debtOutstanding Amount to withdraw
    /// @return _profit Profit freed by the call
    /// @return _loss Loss discovered by the call
    /// @return _debtPayment Amount freed to reimburse the debt
    /// @dev If `_debtOutstanding` is more than we can free we get as much as possible.
    function _prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        // account for profit / losses
        uint256 totalDebt = poolManager.strategies(address(this)).totalStrategyDebt;

        // Assets immediately convertible to want only
        uint256 amountAvailable = _balanceOfWant();
        (uint256 deposits, uint256 borrows) = getCurrentPosition();
        uint256 totalAssets = amountAvailable + deposits - borrows;

        if (totalDebt > totalAssets) {
            // we have losses
            _loss = totalDebt - totalAssets;
        } else {
            // we have profit
            _profit = totalAssets - totalDebt;
        }

        // free funds to repay debt + profit to the strategy
        uint256 amountRequired = _debtOutstanding + _profit;

        if (amountRequired > amountAvailable) {
            // we need to free funds
            // we dismiss losses here, they cannot be generated from withdrawal
            // but it is possible for the strategy to unwind full position
            (amountAvailable, ) = _liquidatePosition(amountRequired, amountAvailable, deposits, borrows);

            if (amountAvailable >= amountRequired) {
                _debtPayment = _debtOutstanding;
                // profit remains unchanged unless there is not enough to pay it
                if (amountRequired - _debtPayment < _profit) {
                    _profit = amountRequired - _debtPayment;
                }
            } else {
                // we were not able to free enough funds
                if (amountAvailable < _debtOutstanding) {
                    // available funds are lower than the repayment that we need to do
                    _profit = 0;
                    _debtPayment = amountAvailable;
                    // we dont report losses here as the strategy might not be able to return in this harvest
                    // but it will still be there for the next harvest
                } else {
                    // NOTE: amountRequired is always equal or greater than _debtOutstanding
                    // important to use amountRequired just in case amountAvailable is > amountAvailable
                    _debtPayment = _debtOutstanding;
                    _profit = amountAvailable - _debtPayment;
                }
            }
        } else {
            _debtPayment = _debtOutstanding;
            // profit remains unchanged unless there is not enough to pay it
            if (amountRequired - _debtPayment < _profit) {
                _profit = amountRequired - _debtPayment;
            }
        }
    }

    /// @notice Function called by _harvest()
    function _adjustPosition() internal override {
        _adjustPosition(type(uint256).max);
    }

    /// @notice Function called by _adjustPosition()
    /// @param guessedBorrow First guess to the borrow amount to maximise revenue
    /// @dev It computes the optimal collateral ratio and adjusts deposits/borrows accordingly
    function _adjustPosition(uint256 guessedBorrow) internal override {
        uint256 _debtOutstanding = poolManager.debtOutstanding();

        uint256 wantBalance = _balanceOfWant();
        // deposit available want as collateral
        if (wantBalance > _debtOutstanding && wantBalance - _debtOutstanding > minWant) {
            _depositCollateral(wantBalance - _debtOutstanding);
            // Updating the `wantBalance` value
            wantBalance = _balanceOfWant();
        }

        (uint256 deposits, uint256 borrows) = getCurrentPosition();
        guessedBorrow = (guessedBorrow == type(uint256).max) ? borrows : guessedBorrow;
        uint256 _targetCollatRatio;
        if (boolParams.automaticallyComputeCollatRatio) {
            _targetCollatRatio = _computeOptimalCollatRatio(
                wantBalance + deposits - borrows,
                deposits,
                borrows,
                guessedBorrow
            );
        } else {
            _targetCollatRatio = targetCollatRatio;
        }

        // check current position
        uint256 currentCollatRatio = _getCollatRatio(deposits, borrows);

        // Either we need to free some funds OR we want to be max levered
        if (_debtOutstanding > wantBalance) {
            // we should free funds
            uint256 amountRequired = _debtOutstanding - wantBalance;

            // NOTE: vault will take free funds during the next harvest
            _freeFunds(amountRequired, deposits, borrows);
        } else if (currentCollatRatio < _targetCollatRatio) {
            // we should lever up
            if (_targetCollatRatio - currentCollatRatio > minRatio) {
                // we only act on relevant differences
                _leverMax(deposits, borrows);
            }
        } else if (currentCollatRatio > _targetCollatRatio) {
            if (currentCollatRatio - _targetCollatRatio > minRatio) {
                uint256 newBorrow = _getBorrowFromSupply(deposits - borrows, _targetCollatRatio);
                _leverDownTo(newBorrow, deposits, borrows);
            }
        }
    }

    /// @notice Liquidates `_amountNeeded` from a position
    /// @dev For gas efficiency this function calls another internal function
    function _liquidatePosition(uint256 _amountNeeded) internal override returns (uint256, uint256) {
        (uint256 deposits, uint256 borrows) = getCurrentPosition();
        return _liquidatePosition(_amountNeeded, _balanceOfWant(), deposits, borrows);
    }

    /// @notice Withdraws `_amountNeeded` of `want` from Aave
    /// @param _amountNeeded Amount of `want` to free
    /// @return _liquidatedAmount Amount of `want` available
    /// @return _loss Difference between `_amountNeeded` and what is actually available
    function _liquidatePosition(
        uint256 _amountNeeded,
        uint256 wantBalance,
        uint256 deposits,
        uint256 borrows
    ) internal returns (uint256 _liquidatedAmount, uint256 _loss) {
        // NOTE: Maintain invariant `want.balanceOf(this) >= _liquidatedAmount`
        // NOTE: Maintain invariant `_liquidatedAmount + _loss <= _amountNeeded`
        if (wantBalance > _amountNeeded) {
            // if there is enough free want, let's use it
            return (_amountNeeded, 0);
        }

        // we need to free funds
        uint256 amountRequired = _amountNeeded - wantBalance;
        _freeFunds(amountRequired, deposits, borrows);
        // Updating the `wantBalance` variable
        wantBalance = _balanceOfWant();
        if (_amountNeeded > wantBalance) {
            _liquidatedAmount = wantBalance;
            uint256 diff = _amountNeeded - _liquidatedAmount;
            if (diff <= minWant) {
                _loss = diff;
            }
        } else {
            _liquidatedAmount = _amountNeeded;
        }

        if (boolParams.withdrawCheck) {
            require(_amountNeeded == _liquidatedAmount + _loss, "54"); // dev: withdraw safety check
        }
    }

    /// @notice Withdraw as much as we can from Aave
    /// @return _amountFreed Amount successfully freed
    function _liquidateAllPositions() internal override returns (uint256 _amountFreed) {
        (_amountFreed, ) = _liquidatePosition(type(uint256).max);
    }

    function _protectedTokens() internal view override returns (address[] memory) {}

    // ============================== Setters ======================================

    /// @notice Sets collateral targets and value for collateral ratio
    function setCollateralTargets(
        uint256 _targetCollatRatio,
        uint256 _maxCollatRatio,
        uint256 _maxBorrowCollatRatio,
        uint256 _daiBorrowCollatRatio
    ) external onlyRole(GUARDIAN_ROLE) {
        (uint256 ltv, uint256 liquidationThreshold) = _getProtocolCollatRatios(address(want));
        (uint256 daiLtv, ) = _getProtocolCollatRatios(_dai);
        require(
            _targetCollatRatio < liquidationThreshold &&
                _maxCollatRatio < liquidationThreshold &&
                _targetCollatRatio < _maxCollatRatio &&
                _maxBorrowCollatRatio < ltv &&
                _daiBorrowCollatRatio < daiLtv,
            "8"
        );

        targetCollatRatio = _targetCollatRatio;
        maxCollatRatio = _maxCollatRatio;
        maxBorrowCollatRatio = _maxBorrowCollatRatio;
        daiBorrowCollatRatio = _daiBorrowCollatRatio;
    }

    /// @notice Sets `minWant`, `minRatio` and `maxItrations` values
    function setMinsAndMaxs(
        uint256 _minWant,
        uint256 _minRatio,
        uint8 _maxIterations
    ) external onlyRole(GUARDIAN_ROLE) {
        require(_minRatio < maxBorrowCollatRatio && _maxIterations > 0 && _maxIterations < 16, "8");
        minWant = _minWant;
        minRatio = _minRatio;
        maxIterations = _maxIterations;
    }

    /// @notice Sets all boolean parameters related to cooldown, withdraw check, flash loan and so on
    function setBoolParams(BoolParams memory _boolParams) external onlyRole(GUARDIAN_ROLE) {
        boolParams = _boolParams;
    }

    /// @notice Sets the discount factor for the StkAAVE price
    function setDiscountFactor(uint256 _discountFactor) external onlyRole(GUARDIAN_ROLE) {
        require(_discountFactor < 10000, "4");
        discountFactor = _discountFactor;
    }

    /// @notice Retrieves lending pool variables for `want`. Those variables are mostly used in the function
    /// to compute the optimal borrow amount
    /// @dev No access control needed because they fetch the values from Aave directly.
    /// If it changes there, it will need to be updated here too
    /// @dev We expect the values concerned not to be often modified
    function setAavePoolVariables() external {
        _setAavePoolVariables();
    }

    // ========================== External Actions =================================

    /// @notice Emergency function that we can use to deleverage manually if something is broken
    /// @param amount Amount of `want` to withdraw/repay
    function manualDeleverage(uint256 amount) external onlyRole(GUARDIAN_ROLE) {
        _withdrawCollateral(amount);
        _repayWant(amount);
    }

    /// @notice Emergency function that we can use to deleverage manually if something is broken
    /// @param amount Amount of `want` to withdraw
    function manualReleaseWant(uint256 amount) external onlyRole(GUARDIAN_ROLE) {
        _withdrawCollateral(amount);
    }

    /// @notice Adds a new guardian address
    /// @param _guardian New guardian address
    function addGuardian(address _guardian) external override onlyRole(POOLMANAGER_ROLE) {
        // Granting the new role
        // Access control for this contract
        _grantRole(GUARDIAN_ROLE, _guardian);
    }

    /// @notice Revokes the guardian role
    /// @param guardian Old guardian address to revoke
    function revokeGuardian(address guardian) external override onlyRole(POOLMANAGER_ROLE) {
        _revokeRole(GUARDIAN_ROLE, guardian);
    }

    /// @notice Swap earned stkAave or Aave for `want` through 1Inch
    /// @param minAmountOut Minimum amount of `want` to receive for the swap to happen
    /// @param payload Bytes needed for 1Inch API. Tokens swapped should be: stkAave -> `want` or Aave -> `want`
    function sellRewards(uint256 minAmountOut, bytes memory payload) external onlyRole(KEEPER_ROLE) {
        //solhint-disable-next-line
        (bool success, bytes memory result) = _oneInch.call(payload);
        if (!success) _revertBytes(result);

        uint256 amountOut = abi.decode(result, (uint256));
        require(amountOut >= minAmountOut, "15");
    }

    /// @notice Flashload callback, as defined by EIP-3156
    /// @notice We check that the call is coming from the DAI lender and then execute the load logic
    /// @dev If everything went smoothly, will return `keccak256("ERC3156FlashBorrower.onFlashLoan")`
    function onFlashLoan(
        address initiator,
        address,
        uint256 amount,
        uint256,
        bytes calldata data
    ) external override returns (bytes32) {
        require(msg.sender == FlashMintLib.LENDER && initiator == address(this), "1");
        (bool deficit, uint256 amountWant) = abi.decode(data, (bool, uint256));

        return FlashMintLib.loanLogic(deficit, amountWant, amount, address(want));
    }

    // ========================== Internal Actions =================================

    /// @notice Claim earned stkAAVE (only called at `harvest`)
    /// @dev stkAAVE require a "cooldown" period of 10 days before being claimed
    function _claimRewards() internal returns (uint256 stkAaveBalance) {
        stkAaveBalance = _balanceOfStkAave();
        uint256 cooldownStatus;
        if (stkAaveBalance > 0) {
            cooldownStatus = _checkCooldown(); // don't check status if we have no stkAave
        }

        // If it's the claim period claim
        if (stkAaveBalance > 0 && cooldownStatus == 1) {
            // redeem AAVE from stkAave
            _stkAave.claimRewards(address(this), type(uint256).max);
            _stkAave.redeem(address(this), stkAaveBalance);
        }

        // claim stkAave from lending and borrowing, this will reset the cooldown
        _incentivesController.claimRewards(_getAaveAssets(), type(uint256).max, address(this));

        stkAaveBalance = _balanceOfStkAave();

        // request start of cooldown period, if there's no cooldown in progress
        if (boolParams.cooldownStkAave && stkAaveBalance > 0 && cooldownStatus == 0) {
            _stkAave.cooldown();
        }
    }

    function claimRewards() external onlyRole(KEEPER_ROLE) {
        _claimRewards();
    }

    /// @notice Reduce exposure by withdrawing funds and repaying debt
    /// @param amountToFree Amount of `want` to withdraw/repay
    /// @return balance Current balance of `want`
    /// @dev `deposits` and `borrows` are always computed prior to the call
    function _freeFunds(
        uint256 amountToFree,
        uint256 deposits,
        uint256 borrows
    ) internal returns (uint256) {
        if (amountToFree == 0) return 0;

        uint256 realAssets = deposits - borrows;
        uint256 newBorrow = _getBorrowFromSupply(realAssets - Math.min(amountToFree, realAssets), targetCollatRatio);

        // repay required amount
        _leverDownTo(newBorrow, deposits, borrows);

        return _balanceOfWant();
    }

    /// @notice Get exposure up to `targetCollatRatio`
    function _leverMax(uint256 deposits, uint256 borrows) internal {
        uint256 totalAmountToBorrow = _getBorrowFromSupply(deposits - borrows, targetCollatRatio) - borrows;

        if (boolParams.isFlashMintActive) {
            // The best approach is to lever up using regular method, then finish with flash loan
            totalAmountToBorrow = totalAmountToBorrow - _leverUpStep(totalAmountToBorrow, deposits, borrows);

            if (totalAmountToBorrow > minWant) {
                totalAmountToBorrow = totalAmountToBorrow - _leverUpFlashLoan(totalAmountToBorrow);
            }
        } else {
            for (uint8 i = 0; i < maxIterations && totalAmountToBorrow > minWant; i++) {
                totalAmountToBorrow = totalAmountToBorrow - _leverUpStep(totalAmountToBorrow, deposits, borrows);
                deposits = 0;
                borrows = 0;
            }
        }
    }

    /// @notice Use a flashloan to increase our exposure in `want` on Aave
    /// @param amount Amount we will deposit and borrow on Aave
    /// @return amount Actual amount deposited/borrowed
    /// @dev Amount returned should equal `amount` but can be lower if we try to flashloan more than `maxFlashLoan` authorized
    function _leverUpFlashLoan(uint256 amount) internal returns (uint256) {
        (uint256 deposits, uint256 borrows) = getCurrentPosition();
        uint256 depositsToMeetLtv = _getDepositFromBorrow(borrows, maxBorrowCollatRatio, deposits);
        uint256 depositsDeficitToMeetLtv = 0;
        if (depositsToMeetLtv > deposits) {
            depositsDeficitToMeetLtv = depositsToMeetLtv - deposits;
        }
        return FlashMintLib.doFlashMint(false, amount, address(want), daiBorrowCollatRatio, depositsDeficitToMeetLtv);
    }

    /// @notice Increase exposure in `want`
    /// @param amount Amount of `want` to borrow
    /// @return amount Amount of `want` that was borrowed
    function _leverUpStep(
        uint256 amount,
        uint256 deposits,
        uint256 borrows
    ) internal returns (uint256) {
        if (deposits == 0 && borrows == 0) (deposits, borrows) = getCurrentPosition();

        uint256 wantBalance = _balanceOfWant();

        uint256 canBorrow = _getBorrowFromDeposit(deposits + wantBalance, maxBorrowCollatRatio);

        if (canBorrow <= borrows) {
            return 0;
        }
        canBorrow = canBorrow - borrows;

        if (canBorrow < amount) {
            amount = canBorrow;
        }

        _depositCollateral(wantBalance);
        _borrowWant(amount);
        _depositCollateral(amount);

        return amount;
    }

    /// @notice Reduce our exposure to `want` on Aave
    /// @param newAmountBorrowed Total amount we want to be borrowing
    /// @param deposits Amount currently lent
    /// @param currentBorrowed Amount currently borrowed
    function _leverDownTo(
        uint256 newAmountBorrowed,
        uint256 deposits,
        uint256 currentBorrowed
    ) internal {
        if (currentBorrowed > newAmountBorrowed) {
            uint256 totalRepayAmount = currentBorrowed - newAmountBorrowed;

            if (boolParams.isFlashMintActive) {
                totalRepayAmount = totalRepayAmount - _leverDownFlashLoan(totalRepayAmount, currentBorrowed);
            }

            uint256 _maxCollatRatio = maxCollatRatio;

            // in case the flashloan didn't repay the entire amount we have to repay it "manually"
            // by withdrawing a bit of collateral and then repaying the debt with it
            for (uint8 i = 0; i < maxIterations && totalRepayAmount > minWant; i++) {
                _withdrawExcessCollateral(_maxCollatRatio, 0, 0);
                uint256 toRepay = totalRepayAmount;
                uint256 wantBalance = _balanceOfWant();
                if (toRepay > wantBalance) {
                    toRepay = wantBalance;
                }
                uint256 repaid = _repayWant(toRepay);
                totalRepayAmount = totalRepayAmount - repaid;
            }
            (deposits, currentBorrowed) = getCurrentPosition();
        }

        // Deposit back to get `targetCollatRatio` (we always need to leave this in this ratio)
        uint256 _targetCollatRatio = targetCollatRatio;
        uint256 targetDeposit = _getDepositFromBorrow(currentBorrowed, _targetCollatRatio, deposits);
        if (targetDeposit > deposits) {
            uint256 toDeposit = targetDeposit - deposits;
            if (toDeposit > minWant) {
                _depositCollateral(Math.min(toDeposit, _balanceOfWant()));
            }
        } else {
            if (deposits - targetDeposit > minWant) {
                _withdrawExcessCollateral(_targetCollatRatio, deposits, currentBorrowed);
            }
        }
    }

    /// @notice Use a flashloan to reduce our exposure in `want` on Aave
    /// @param amount Amount we will need to withdraw and repay to Aave
    /// @return amount Actual amount repaid
    /// @dev Amount returned should equal `amount` but can be lower if we try to flashloan more than `maxFlashLoan` authorized
    /// @dev `amount` will be withdrawn from deposits and then used to repay borrows
    function _leverDownFlashLoan(uint256 amount, uint256 borrows) internal returns (uint256) {
        if (amount <= minWant) return 0;
        if (amount > borrows) {
            amount = borrows;
        }
        return FlashMintLib.doFlashMint(true, amount, address(want), daiBorrowCollatRatio, 0);
    }

    /// @notice Adjusts the deposits based on the wanted collateral ratio (does not touch the borrow)
    /// @param collatRatio Collateral ratio to target
    function _withdrawExcessCollateral(
        uint256 collatRatio,
        uint256 deposits,
        uint256 borrows
    ) internal returns (uint256 amount) {
        if (deposits == 0 && borrows == 0) (deposits, borrows) = getCurrentPosition();
        uint256 theoDeposits = _getDepositFromBorrow(borrows, collatRatio, deposits);
        if (deposits > theoDeposits) {
            uint256 toWithdraw = deposits - theoDeposits;
            return _withdrawCollateral(toWithdraw);
        }
    }

    /// @notice Deposit `want` tokens in Aave and start earning interests
    /// @param amount Amount to be deposited
    /// @return amount The amount deposited
    function _depositCollateral(uint256 amount) internal returns (uint256) {
        if (amount == 0) return 0;
        _lendingPool.deposit(address(want), amount, address(this), _referral);
        return amount;
    }

    /// @notice Withdraw `want` tokens from Aave
    /// @param amount Amount to be withdrawn
    /// @return amount The amount withdrawn
    function _withdrawCollateral(uint256 amount) internal returns (uint256) {
        if (amount == 0) return 0;
        _lendingPool.withdraw(address(want), amount, address(this));
        return amount;
    }

    /// @notice Repay what we borrowed of `want` from Aave
    /// @param amount Amount to repay
    /// @return amount The amount repaid
    /// @dev `interestRateMode` is set to variable rate (2)
    function _repayWant(uint256 amount) internal returns (uint256) {
        if (amount == 0) return 0;
        return _lendingPool.repay(address(want), amount, 2, address(this));
    }

    /// @notice Borrow `want` from Aave
    /// @param amount Amount of `want` we are borrowing
    /// @return amount The amount borrowed
    /// @dev The third variable is the `interestRateMode`
    /// @dev set at 2 which means we will get a variable interest rate on our borrowed tokens
    function _borrowWant(uint256 amount) internal returns (uint256) {
        _lendingPool.borrow(address(want), amount, 2, _referral, address(this));
        return amount;
    }

    /// @notice Computes the optimal collateral ratio based on current interests and incentives on Aave
    /// @notice It modifies the state by updating the `targetCollatRatio`
    function _computeOptimalCollatRatio(
        uint256 balanceExcludingRewards,
        uint256 deposits,
        uint256 currentBorrowed,
        uint256 guessedBorrow
    ) internal returns (uint256) {
        uint256 borrow = _computeMostProfitableBorrow(
            balanceExcludingRewards,
            deposits,
            currentBorrowed,
            guessedBorrow
        );
        uint256 _collatRatio = _getCollatRatio(balanceExcludingRewards + borrow, borrow);
        uint256 _maxCollatRatio = maxCollatRatio;
        if (_collatRatio > _maxCollatRatio) {
            _collatRatio = _maxCollatRatio;
        }
        targetCollatRatio = _collatRatio;
        return _collatRatio;
    }

    /// @notice Approve `spender` maxuint of `token`
    /// @param token Address of token to approve
    /// @param spender Address of spender to approve
    function _approveMaxSpend(address token, address spender) internal {
        IERC20(token).safeApprove(spender, type(uint256).max);
    }

    /// @notice Internal version of the `_setAavePoolVariables`
    function _setAavePoolVariables() internal {
        (, , , , uint256 reserveFactor_, , , , , ) = _protocolDataProvider.getReserveConfigurationData(address(want));
        cooldownSeconds = IStakedAave(_stkAave).COOLDOWN_SECONDS();
        unstakeWindow = IStakedAave(_stkAave).UNSTAKE_WINDOW();
        reserveFactor = int256(reserveFactor_ * 10**23);
        slope1 = int256(_interestRateStrategyAddress.variableRateSlope1());
        slope2 = int256(_interestRateStrategyAddress.variableRateSlope2());
        r0 = int256(_interestRateStrategyAddress.baseVariableBorrowRate());
        uOptimal = int256(_interestRateStrategyAddress.OPTIMAL_UTILIZATION_RATE());
    }

    // ========================= Internal View Functions ===========================

    /// @notice Computes the optimal amounts to borrow based on current interest rates and incentives
    /// @dev Returns optimal `borrow` amount in base of `want`
    function _computeMostProfitableBorrow(
        uint256 balanceExcludingRewards,
        uint256 deposits,
        uint256 currentBorrow,
        uint256 guessedBorrow
    ) internal view returns (uint256 borrow) {
        // This works if `wantBase < 10**27` which we should expect to be very the case for the strategies we are
        // launching at the moment
        uint256 normalizationFactor = 10**27 / wantBase;

        ComputeProfitability.SCalculateBorrow memory parameters;

        {
            (
                uint256 availableLiquidity,
                uint256 totalStableDebt,
                uint256 totalVariableDebt,
                ,
                ,
                ,
                uint256 averageStableBorrowRate,
                ,
                ,

            ) = _protocolDataProvider.getReserveData(address(want));

            parameters = ComputeProfitability.SCalculateBorrow({
                reserveFactor: reserveFactor,
                totalStableDebt: int256(totalStableDebt * normalizationFactor),
                totalVariableDebt: int256((totalVariableDebt - currentBorrow) * normalizationFactor),
                totalDeposits: int256(
                    (availableLiquidity +
                        totalStableDebt +
                        totalVariableDebt +
                        // to adapt to our future balance
                        // add the wantBalance and remove the currentBorrowed from the optimisation
                        balanceExcludingRewards -
                        deposits) * normalizationFactor
                ),
                stableBorrowRate: int256(averageStableBorrowRate),
                rewardDeposit: 0,
                rewardBorrow: 0,
                strategyAssets: int256(balanceExcludingRewards * normalizationFactor),
                guessedBorrowAssets: int256(guessedBorrow * normalizationFactor),
                slope1: slope1,
                slope2: slope2,
                r0: r0,
                uOptimal: uOptimal
            });
        }

        {
            uint256 stkAavePriceInWant = _estimatedStkAaveToWant(1 ether);

            (uint256 emissionPerSecondAToken, , ) = _incentivesController.assets(address(_aToken));
            (uint256 emissionPerSecondDebtToken, , ) = _incentivesController.assets(address(_debtToken));

            parameters.rewardDeposit = int256(
                (emissionPerSecondAToken * 86400 * 365 * stkAavePriceInWant * 10**9) / wantBase
            );
            parameters.rewardBorrow = int256(
                (emissionPerSecondDebtToken * 86400 * 365 * stkAavePriceInWant * 10**9) / wantBase
            );
        }

        borrow = uint256(ComputeProfitability.computeProfitability(parameters)) / normalizationFactor;
    }

    function estimatedAPR() public view returns (uint256) {
        (
            ,
            ,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            ,
            ,
            ,
            ,

        ) = _protocolDataProvider.getReserveData(address(want));

        uint256 _totalAssets = _balanceOfWant() + _balanceOfAToken() - _balanceOfDebtToken();
        if (_totalAssets == 0 || totalVariableDebt == 0 || _aToken.totalSupply() == 0) return 0;

        (uint256 deposits, uint256 borrows) = getCurrentPosition();
        uint256 yearlyRewardsATokenInUSDC;
        uint256 yearlyRewardsDebtTokenInUSDC;
        {
            uint256 stkAavePriceInWant = _estimatedStkAaveToWant(1 ether);
            (uint256 emissionPerSecondAToken, , ) = (_aToken.getIncentivesController()).assets(address(_aToken));
            (uint256 emissionPerSecondDebtToken, , ) = (_debtToken.getIncentivesController()).assets(
                address(_debtToken)
            );

            uint256 yearlyEmissionsAToken = emissionPerSecondAToken * 60 * 60 * 24 * 365; // BASE: 18
            uint256 yearlyEmissionsDebtToken = emissionPerSecondDebtToken * 60 * 60 * 24 * 365; // BASE: 18
            yearlyRewardsATokenInUSDC = ((deposits * yearlyEmissionsAToken * stkAavePriceInWant * 10**9) /
                _aToken.totalSupply()); // BASE 27 + want
            yearlyRewardsDebtTokenInUSDC = ((borrows * yearlyEmissionsDebtToken * stkAavePriceInWant * 10**9) /
                totalVariableDebt); // BASE 27 + want
        }

        return
            (liquidityRate *
                deposits +
                yearlyRewardsATokenInUSDC +
                yearlyRewardsDebtTokenInUSDC -
                variableBorrowRate *
                borrows) /
            _totalAssets /
            10**9; // BASE 18
    }

    /// @notice Returns the `want` balance
    function _balanceOfWant() internal view returns (uint256) {
        return want.balanceOf(address(this));
    }

    /// @notice Returns the `aToken` balance
    function _balanceOfAToken() internal view returns (uint256) {
        return _aToken.balanceOf(address(this));
    }

    /// @notice Returns the `debtToken` balance
    function _balanceOfDebtToken() internal view returns (uint256) {
        return _debtToken.balanceOf(address(this));
    }

    /// @notice Returns the `AAVE` balance
    function _balanceOfAave() internal view returns (uint256) {
        return IERC20(_aave).balanceOf(address(this));
    }

    /// @notice Returns the `StkAAVE` balance
    function _balanceOfStkAave() internal view returns (uint256) {
        return IERC20(address(_stkAave)).balanceOf(address(this));
    }

    /// @notice Estimate the amount of `want` we will get out by swapping it for AAVE
    /// @param amount Amount of AAVE we want to exchange (in base 18)
    /// @return amount Amount of `want` we are getting. We include a discount to account for slippage equal to 9000
    /// @dev Uses Chainlink spot price. Return value will be in base of `want` (6 for USDC)
    function _estimatedStkAaveToWant(uint256 amount) internal view returns (uint256) {
        (, int256 aavePriceUSD, , , ) = _chainlinkOracle.latestRoundData(); // stkAavePriceUSD is in base 8
        // `aavePriceUSD` is in base 8, and the discount factor is in base 4, so ultimately we need to divide
        // by `1e(18+8+4)
        return (uint256(aavePriceUSD) * amount * wantBase * discountFactor) / 1e30;
    }

    /// @notice Verifies the cooldown status for earned stkAAVE
    /// @return cooldownStatus Status of the coolDown: if it is 0 then there is no cooldown Status, if it is 1 then
    /// the strategy should claim
    function _checkCooldown() internal view returns (uint256 cooldownStatus) {
        uint256 cooldownStartTimestamp = IStakedAave(_stkAave).stakersCooldowns(address(this));
        uint256 nextClaimStartTimestamp = cooldownStartTimestamp + cooldownSeconds;
        if (cooldownStartTimestamp == 0) {
            return 0;
        }
        if (block.timestamp > nextClaimStartTimestamp && block.timestamp <= nextClaimStartTimestamp + unstakeWindow) {
            return 1;
        }
        if (block.timestamp < nextClaimStartTimestamp) {
            return 2;
        }
    }

    /// @notice Get the deposit and debt token for our `want` token
    function _getAaveAssets() internal view returns (address[] memory assets) {
        assets = new address[](2);
        assets[0] = address(_aToken);
        assets[1] = address(_debtToken);
    }

    /// @notice Get Aave ratios for a token in order to compute later our collateral ratio
    /// @param token Address of the token for which to check the ratios (usually `want` token)
    /// @dev `getReserveConfigurationData` returns values in base 4. So here `ltv` and `liquidationThreshold` are returned in base 18
    function _getProtocolCollatRatios(address token) internal view returns (uint256 ltv, uint256 liquidationThreshold) {
        (, ltv, liquidationThreshold, , , , , , , ) = _protocolDataProvider.getReserveConfigurationData(token);
        // convert bps to wad
        ltv = ltv * _BPS_WAD_RATIO;
        liquidationThreshold = liquidationThreshold * _BPS_WAD_RATIO;
    }

    // ========================= Internal Pure Functions ===========================

    /// @notice Get target borrow amount based on deposit and collateral ratio
    /// @param deposit Current total deposited on Aave
    /// @param collatRatio Collateral ratio to target
    function _getBorrowFromDeposit(uint256 deposit, uint256 collatRatio) internal pure returns (uint256) {
        return (deposit * collatRatio) / _COLLATERAL_RATIO_PRECISION;
    }

    /// @notice Get target deposit amount based on borrow and collateral ratio
    /// @param borrow Current total borrowed on Aave
    /// @param collatRatio Collateral ratio to target
    /// @param deposits Current deposit amount: this is what the function should return if the `collatRatio` is null
    function _getDepositFromBorrow(
        uint256 borrow,
        uint256 collatRatio,
        uint256 deposits
    ) internal pure returns (uint256) {
        if (collatRatio > 0) return (borrow * _COLLATERAL_RATIO_PRECISION) / collatRatio;
        else return deposits;
    }

    /// @notice Get target borrow amount based on supply (deposits - borrow) and collateral ratio
    /// @param supply = deposits - borrows. The supply is what is "actually" deposited in Aave
    /// @param collatRatio Collateral ratio to target
    function _getBorrowFromSupply(uint256 supply, uint256 collatRatio) internal pure returns (uint256) {
        return (supply * collatRatio) / (_COLLATERAL_RATIO_PRECISION - collatRatio);
    }

    /// @notice Computes the position collateral ratio from deposits and borrows
    function _getCollatRatio(uint256 deposits, uint256 borrows) internal pure returns (uint256 currentCollatRatio) {
        if (deposits > 0) {
            currentCollatRatio = (borrows * _COLLATERAL_RATIO_PRECISION) / deposits;
        }
    }

    /// @notice Processes 1Inch revert messages
    function _revertBytes(bytes memory errMsg) internal pure {
        if (errMsg.length > 0) {
            //solhint-disable-next-line
            assembly {
                revert(add(32, errMsg), mload(errMsg))
            }
        }
        revert("117");
    }
}
