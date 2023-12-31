// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./IERC20.sol";
import "./ERC20Upgradeable.sol";
import "./ErrorLib.sol";
import "./Strings.sol";
import "./ITroveManager.sol";
import "./ISortedTroves.sol";
import "./IBorrowerOperations.sol";

/// @title TroveHandler contract.
/// @author Spaceshard team 2023.
/// @notice The contract handels the interactions with liquity contract.
/// @dev UTILIZE EXISTING AZTECT LIQUITY BRIDGE CONTRACT
/// THE MORE WE RE-USE EXISTING CODE, THE BETTER
contract TroveHandler is ERC20Upgradeable {
    using Strings for uint256;

    /// @notice Trove status taken from TroveManager.sol
    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation,
        closedByRedemption
    }

    /// @notice troveManager the trove manager interface.
    ITroveManager internal troveManager;

    /// @notice sortedManager the sorted manager interface.
    ISortedTroves internal sortedManager;

    /// @notice borrowerOperations the borrower operations interface.
    IBorrowerOperations internal borrowerOperations;

    /// @notice The individual collateral rate.
    uint256 public INITIAL_ICR;

    /// @notice The amount of dust to leave in the contract.
    /// @dev Optimization based on EIP-1087.
    uint256 public constant DUST = 1;

    /// @notice Initial debt supply to create a trove.
    uint256 public initialSupply;

    /// @notice Used to check whether collateral has already been claimed during redemptions.
    bool private collateralClaimed;

    /// @notice initialize the trove handler.
    /// @param _troveManager the trove manager interface.
    /// @param _sortedManager the sorted manager interface.
    /// @param _borrowerOperations the borrower operations interface.
    /// @param _initialICRPerc Collateral ratio denominated in percents to be used when opening the Trove
    function initializeTroveHandler(
        address _troveManager,
        address _sortedManager,
        address _borrowerOperations,
        uint256 _initialICRPerc
    ) internal {
        __ERC20_init("TroveDebt", string(abi.encodePacked("TD-", _initialICRPerc.toString())));
        troveManager = ITroveManager(_troveManager);
        sortedManager = ISortedTroves(_sortedManager);
        borrowerOperations = IBorrowerOperations(_borrowerOperations);
        INITIAL_ICR = _initialICRPerc * 1e16;
        _mint(address(this), DUST);
    }

    /// @notice Borrow LUSD
    /// @param _collateral Amount of ETH denominated in Wei
    /// @param _maxFee Maximum borrowing fee
    /// @return lusdBorrowed Amount of LUSD borrowed.
    function _borrow(uint256 _collateral, uint64 _maxFee) internal returns (uint256 lusdBorrowed) {
        ITroveManager troveManagerMem = troveManager;
        lusdBorrowed = computeAmtToBorrow(_collateral); // LUSD amount to borrow
        (uint256 debtBefore, , , ) = troveManagerMem.getEntireDebtAndColl(address(this));

        (address upperHint, address lowerHint) = _getHints();
        borrowerOperations.adjustTrove{value: _collateral}(
            _maxFee,
            0,
            lusdBorrowed,
            true,
            upperHint,
            lowerHint
        );
        (uint256 debtAfter, , , ) = troveManagerMem.getEntireDebtAndColl(address(this));
        // tbMinted = amount of TB to mint = (debtIncrease [LUSD] / debtBefore [LUSD]) * tbTotalSupply
        // debtIncrease = debtAfter - debtBefore
        // In case no redistribution took place (TB/LUSD = 1) then debt_before = TB_total_supply
        // and debt_increase amount of TB is minted.
        // In case there was redistribution, 1 TB corresponds to more than 1 LUSD and the amount of TB minted
        // will be lower than the amount of LUSD borrowed.
        uint256 tbMinted = ((debtAfter - debtBefore) * totalSupply()) / debtBefore;
        _mint(address(this), tbMinted);
    }

    /// @notice Repay debt.
    /// @param _amountLUSD Amount of LUSD.
    /// @return collateral Amount of collateral withdrawn.
    function _repay(uint256 _amountLUSD) internal returns (uint256 collateral) {
        (uint256 debtBefore, uint256 collBefore, , ) = troveManager.getEntireDebtAndColl(
            address(this)
        );
        uint256 tbTotalSupply = totalSupply(); // SLOAD optimization
        uint256 tbToBurn = (_amountLUSD * tbTotalSupply) / debtBefore;
        uint256 collToWithdraw = computeCollateralAmountOut(_amountLUSD, debtBefore, collBefore);

        (address upperHint, address lowerHint) = _getHints();
        uint256 beforeBalance = address(this).balance;

        borrowerOperations.adjustTrove(0, collToWithdraw, _amountLUSD, false, upperHint, lowerHint);
        uint256 afterBalance = address(this).balance;
        collateral = afterBalance - beforeBalance;

        _burn(address(this), tbToBurn);
    }

    /// @notice A function which opens the trove.
    /// @param _upperHint Address of a Trove with a position in the sorted list before the correct insert position.
    /// @param _lowerHint Address of a Trove with a position in the sorted list after the correct insert position.
    /// See https://github.com/liquity/dev#supplying-hints-to-trove-operations for more details about hints.
    /// @param _maxFee Maximum borrower fee.
    /// @dev Sufficient amount of ETH has to be send so that at least 2000 LUSD gets borrowed. 2000 LUSD is a minimum
    /// amount allowed by Liquity.
    function _openTrove(
        address _lusd,
        address _upperHint,
        address _lowerHint,
        uint256 _maxFee
    ) internal {
        ITroveManager troveManagerMem = troveManager;
        // Checks whether the trove can be safely opened/reopened
        if (totalSupply() != 0) revert ErrorLib.NonZeroTotalSupply();

        uint256 amtToBorrow = computeAmtToBorrow(msg.value);

        (uint256 debtBefore, , , ) = troveManagerMem.getEntireDebtAndColl(address(this));
        borrowerOperations.openTrove{value: msg.value}(
            _maxFee,
            amtToBorrow,
            _upperHint,
            _lowerHint
        );
        (uint256 debtAfter, , , ) = troveManagerMem.getEntireDebtAndColl(address(this));

        IERC20(_lusd).transfer(msg.sender, IERC20(_lusd).balanceOf(address(this)) - DUST);
        initialSupply = debtAfter - debtBefore;

        // I mint TB token to msg.sender to be able to track collateral ownership. Minted amount equals debt increase.
        _mint(msg.sender, debtAfter - debtBefore);
    }

    /// @notice Compute how much LUSD to borrow against collateral in order to keep ICR constant and by how much total
    /// trove debt will increase.
    /// @param _collateral Amount of ETH denominated in Wei
    /// @return amtToBorrow Amount of LUSD to borrow to keep ICR constant.
    /// + borrowing fee)
    /// @dev I don"t use view modifier here because the function updates PriceFeed state.
    ///
    /// Since the Trove opening and adjustment processes have desired amount of LUSD to borrow on the input and not
    /// the desired ICR I have to do the computation of borrowing fee "backwards". Here are the operations I did in order
    /// to get the final formula:
    ///      1) debtIncrease = amtToBorrow + amtToBorrow * BORROWING_RATE / DECIMAL_PRECISION + 200LUSD
    ///      2) debtIncrease - 200LUSD = amtToBorrow * (1 + BORROWING_RATE / DECIMAL_PRECISION)
    ///      3) amtToBorrow = (debtIncrease - 200LUSD) / (1 + BORROWING_RATE / DECIMAL_PRECISION)
    ///      4) amtToBorrow = (debtIncrease - 200LUSD) * DECIMAL_PRECISION / (DECIMAL_PRECISION + BORROWING_RATE)
    /// Note1: For trove adjustments (not opening) remove the 200 LUSD fee compensation from the formulas above.
    /// Note2: Step 4 is necessary to avoid loss of precision. BORROWING_RATE / DECIMAL_PRECISION was rounded to 0.
    /// Note3: The borrowing fee computation is on this line in Liquity code: https://github.com/liquity/dev/blob/cb583ddf5e7de6010e196cfe706bd0ca816ea40e/packages/contracts/contracts/TroveManager.sol#L1433
    function computeAmtToBorrow(uint256 _collateral) public returns (uint256 amtToBorrow) {
        ITroveManager troveManagerMem = troveManager;

        uint256 price = troveManagerMem.priceFeed().fetchPrice();
        if (troveManagerMem.getTroveStatus(address(this)) == 1) {
            // Trove is active - use current ICR and not the initial one
            uint256 icr = troveManagerMem.getCurrentICR(address(this), price);
            amtToBorrow = (_collateral * price) / icr;
        } else {
            // Trove is inactive - I will use initial ICR to compute debt
            // 200e18 - 200 LUSD gas compensation to liquidators
            amtToBorrow = (_collateral * price) / INITIAL_ICR - 200e18;
        }

        if (!troveManagerMem.checkRecoveryMode(price)) {
            // Liquity is not in recovery mode so borrowing fee applies
            uint256 borrowingRate = troveManagerMem.getBorrowingRateWithDecay();
            amtToBorrow = (amtToBorrow * 1e18) / (borrowingRate + 1e18);
        }
    }

    /// @notice Compute how much ETH is received after paying LUSD amount.
    /// @param _amountLUSD amount LUSD.
    /// @param _troveDebt trove debt.
    /// @param _troveColl trove coll.
    /// @return _collateral received ETH collateral.
    function computeCollateralAmountOut(
        uint256 _amountLUSD,
        uint256 _troveDebt,
        uint256 _troveColl
    ) public pure returns (uint256 _collateral) {
        return (_amountLUSD * _troveColl) / _troveDebt;
    }

    /// @notice Get lower and upper insertion hints.
    /// @return upperHint Upper insertion hint.
    /// @return lowerHint Lower insertion hint.
    /// @dev See https://github.com/liquity/dev#supplying-hints-to-trove-operations for more details on hints.
    function _getHints() internal view returns (address upperHint, address lowerHint) {
        ISortedTroves sortedManagerMem = sortedManager;
        return (sortedManagerMem.getPrev(address(this)), sortedManagerMem.getNext(address(this)));
    }

    /// @inheritdoc	ERC20Upgradeable
    function totalSupply() public view override(ERC20Upgradeable) returns (uint256) {
        return super.totalSupply() - DUST;
    }

    /// @notice Get the trove status.
    /// @return status the trove status.
    function getTroveStatus() public view returns (Status) {
        return Status(troveManager.getTroveStatus(address(this)));
    }

    /// @notice A function which closes the trove.
    /// @dev LUSD allowance has to be at least (remaining debt - 200 LUSD).
    function _closeTrove(address _lusd) internal {
        address payable owner = payable(msg.sender);
        uint256 ownerTBBalance = balanceOf(owner);
        if (ownerTBBalance != totalSupply()) revert ErrorLib.OwnerNotLast();

        _burn(owner, ownerTBBalance);

        Status troveStatus = Status(troveManager.getTroveStatus(address(this)));
        if (troveStatus == Status.active) {
            (uint256 remainingDebt, , , ) = troveManager.getEntireDebtAndColl(address(this));
            // 200e18 is a part of debt which gets repaid from LUSD_GAS_COMPENSATION.
            if (!IERC20(_lusd).transferFrom(owner, address(this), remainingDebt - 200e18)) {
                revert ErrorLib.TransferFailed(_lusd);
            }
            borrowerOperations.closeTrove();
        } else if (
            troveStatus == Status.closedByRedemption || troveStatus == Status.closedByLiquidation
        ) {
            if (!collateralClaimed) {
                borrowerOperations.claimCollateral();
            } else {
                collateralClaimed = false;
            }
        }
        owner.transfer(address(this).balance);
    }

    /// @notice A function which closes the trove.
    receive() external payable {}
}
