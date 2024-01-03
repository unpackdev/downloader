// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./ISyntheticToken.sol";
import "./IMintableToken.sol";
import "./IERC20.sol";

import "./IOracle.sol";

import "./Adminable.sol";
import "./Decimal.sol";
import "./Math.sol";
import "./Amount.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./MozartStorage.sol";
import {MozartTypes} from  "./MozartTypes.sol";

/**
 * @title MoazartV1
 * @author Kerman Kohli
 * @notice This contract holds both the implementation logic and storage (indirectly).
 *         The key optimization of this contract is around simplicity and the actions
 *         a user can call. In addition, the architecture is designed for safety around upgrades
 *         where new storage variables are introduced through the inherited storage contract pattern.
 */
contract MozartV1 is Adminable, MozartStorage {

    /* ========== Libraries ========== */

    using SafeMath for uint256;
    using Math for uint256;
    using Amount for Amount.Principal;

    /* ========== Constants ========== */

    uint256 constant BASE = 10**18;

    /* ========== Types ========== */

    enum Operation {
        Open,
        Borrow,
        Repay,
        Liquidate,
        TransferOwnership
    }

    struct OperationParams {
        uint256 id;
        uint256 amountOne;
        uint256 amountTwo;
        address addressOne;
    }

    /* ========== Events ========== */

    event ActionOperated(
        uint8 operation,
        OperationParams params,
        MozartTypes.Position updatedPosition
    );

    event ExcessTokensWithdrawn(
        address token,
        uint256 amount,
        address destination
    );

    event FeesUpdated(
        Decimal.D256 _liquidationUserFee,
        Decimal.D256 _liquidationArcRatio
    );

    event LimitsUpdated(
        uint256 _collateralLimit,
        uint256 _positionCollateralMinimum
    );

    event GlobalOperatorSet(
        address _operator,
        bool _status
    );

    event PositionOperatorSet(
        uint256 _positionId,
        address _operator,
        bool _status
    );

    event IndexUpdated(
        uint256 newIndex,
        uint256 lastUpdateTime
    );

    event RateUpdated(uint256 value);

    event OracleUpdated(address value);

    event CollateralRatioUpdated(Decimal.D256 value);

    event PrinterUpdated(address value);

    event PauseStatusUpdated(bool value);

    event InterestSetterUpdated(address value);

    /* ========== Modifiers ========== */

    /**
     * @dev Check if a user is authorized to act on behalf of another user's position.
     *      Main checks are if:
     *      - The address is the actual owner of the position
     *      - The address is a valid global operator
     *      - The address is a valid operator for that particular position
     *
     * @param _positionId The position in question here
     */
    modifier isAuthorized(uint256 _positionId) {
        MozartTypes.Position memory position = positions[_positionId];

        require(
            position.owner == msg.sender ||
            isGlobalOperator(msg.sender) ||
            isPositionOperator(_positionId, msg.sender),
            "D2Core: msg.sender is not the owner or position/global operator"
        );
        _;
    }

    /* ========== Constructor ========== */

    constructor()
        public
    {
        paused = true;
    }

    /* ========== Admin Setters ========== */

    /**
     * @dev Intitialise the protocol with the appropriate parameters. Can only be called once.
     *
     * @param _collateralDecimals  How many decimals does the collateral contain
     * @param _collateralAddress   The address of the collateral to be used
     * @param _syntheticAddress    The address of the synthetic token proxy
     * @param _oracleAddress       Address of the IOracle conforming contract
     * @param _interestSetter      Address which can update interest rates
     * @param _collateralRatio     How much colalteral is needed to borrow
     * @param _liquidationUserFee  How much is a user penalised if they go below their c-ratio
     * @param _liquidationArcRatio How much of the liquidation profit should ARC take
     */
    function init(
        uint8   _collateralDecimals,
        address _collateralAddress,
        address _syntheticAddress,
        address _oracleAddress,
        address _interestSetter,
        Decimal.D256 memory _collateralRatio,
        Decimal.D256 memory _liquidationUserFee,
        Decimal.D256 memory _liquidationArcRatio
    )
        public
    {
        require(
            collateralAsset == address(0),
            "MozartV1: cannot re-call init()"
        );

        precisionScalar = 10 ** (18 - uint256(_collateralDecimals));
        collateralAsset = _collateralAddress;
        syntheticAsset = _syntheticAddress;

        borrowIndex = uint256(10**18);
        indexLastUpdate = currentTimestamp();

        setOracle(_oracleAddress);
        setCollateralRatio(_collateralRatio);
        setInterestSetter(_interestSetter);

        setFees(
            _liquidationUserFee,
            _liquidationArcRatio
        );
    }

    /**
     * @dev Update the interest rate of the protocol. Since this rate is compounded
     *      every second rather than being purely linear, the calculate for r is expressed
     *      as the following (assuming you want 5% APY):
     *
     *      r^N = 1.005
     *      since N = 364 * 24 * 60 * 60 (number of seconds in a year)
     *      r = 1.000000000158153903837946258002097
     *      rate = 1000000000158153903 (18 decimal places solidity value)
     *
     * @notice Can only be called by the interest setter of the protocol and the maximum
     *         rate settable by the admin is 99% (21820606489)
     *
     * @param _rate The interest rate expressed per second
     */
    function setInterestRate(
        uint256 _rate
    )
        public
    {
        require(
            msg.sender == interestSetter,
            "MozartV1: only callable by interest setter"
        );

        require(
            _rate <= 21820606489,
            "MozartV1: interest rate cannot be set to over 99%"
        );

        interestRate = _rate;
        emit RateUpdated(_rate);
    }

    /**
     * @dev Set the instance of the oracle to report prices from. Must conform to IOracle.sol
     *
     * @notice Can only be called by the admin of the proxy.
     *
     * @param _oracle The address of the IOracle instance
     */
    function setOracle(
        address _oracle
    )
        public
        onlyAdmin
    {
        oracle = IOracle(_oracle);
        emit OracleUpdated(_oracle);
    }

    /**
     * @dev Set the collateral ratio of value to debt.
     *
     * @notice Can only be called by the admin of the proxy.
     *
     * @param _collateralRatio The ratio expressed up to 18 decimal places
     */
    function setCollateralRatio(
        Decimal.D256 memory _collateralRatio
    )
        public
        onlyAdmin
    {
        require(
            _collateralRatio.value < BASE.mul(10) &&
            _collateralRatio.value > BASE,
            "setCollateralRatio(): must be between 100% and 1000%"
        );

        collateralRatio = _collateralRatio;
        emit CollateralRatioUpdated(_collateralRatio);
    }

    /**
     * @dev Set the fees in the system.
     *
     * @notice Can only be called by the admin of the proxy.
     *
     * @param _liquidationUserFee Determines the penalty a user must pay by discounting
     *                            their collateral to provide a profit incentive for liquidators
     * @param _liquidationArcRatio The amount ARC earns from the profit earned from the liquidation.
     */
    function setFees(
        Decimal.D256 memory _liquidationUserFee,
        Decimal.D256 memory _liquidationArcRatio
    )
        public
        onlyAdmin
    {
        liquidationUserFee = _liquidationUserFee;
        liquidationArcRatio = _liquidationArcRatio;

        emit FeesUpdated(
            liquidationUserFee,
            liquidationArcRatio
        );
    }

    /**
     * @dev Set the limits of the system to ensure value can be capped.
     *
     * @notice Can only be called by the admin of the proxy
     *
     * @param _collateralLimit Maximum amount of collateral that can be held in the system.
     *                         This should be expressed as 18 decimal places since the precision
     *                         scalar will handle the rest.
     * @param _positionCollateralMinimum The minimum of collateral per position
     */
    function setLimits(
        uint256 _collateralLimit,
        uint256 _positionCollateralMinimum
    )
        public
        onlyAdmin
    {
        collateralLimit = _collateralLimit;
        positionCollateralMinimum = _positionCollateralMinimum;

        emit LimitsUpdated(
            collateralLimit,
            positionCollateralMinimum
        );
    }

    /**
     * @dev Set the address which can set interest rates
     *
     * @notice Can only be called by the admin of the proxy
     *
     * @param _setter The address of the new interest rate setter
     */
    function setInterestSetter(
        address _setter
    )
        public
        onlyAdmin
    {
        interestSetter = _setter;

        emit InterestSetterUpdated(_setter);
    }

    /**
     * @dev Set an address to be able to manage any user's position.
     *
     * @notice Can only be called by the admin of the proxy
     *
     * @param _operator Address of the new operator
     * @param _status True indicates they are a valid address, false means they are not
     */
    function setGlobalOperatorStatus(
        address _operator,
        bool    _status
    )
        public
        onlyAdmin
    {
        globalOperators[_operator] = _status;

        emit GlobalOperatorSet(_operator, _status);
    }

    /* ========== Public Functions ========== */

    /**
     * @dev Add/remove an address to operate a position on the owner's behalf. This will include
     *      the ability to borrow and repay on their behalf as well.
     *
     * @param _positionId The position to become an operator for
     * @param _operator The address set to become the operator
     * @param _status The ability to s
     */
    function setPositionOperatorStatus(
        uint256 _positionId,
        address _operator,
        bool    _status
    )
        public
    {
        MozartTypes.Position memory position = positions[_positionId];

        require(
            position.owner == msg.sender || isGlobalOperator(msg.sender),
            "setPositionOperatorStatus(): must be owner or global operator"
        );

        positionOperators[_positionId][_operator] = _status;

        emit PositionOperatorSet(
            _positionId,
            _operator,
            _status
        );
    }

    /**
     * @dev This is the only function that can be called by user's of the system
     *      and uses an enum and struct to parse the args. This structure guarantees
     *      the state machine will always meet certain properties
     *
     * @param operation An enum of the operation to execute
     * @param params Parameters to exceute the operation against
     */
    function operateAction(
        Operation operation,
        OperationParams memory params
    )
        public
    {
        require(
            paused == false,
            "operateAction(): contracts cannot be paused"
        );

        MozartTypes.Position memory operatedPosition;

        // Get the price now since certain contracts consume a lot.
        Decimal.D256 memory currentPrice = oracle.fetchCurrentPrice();

        // Update the index to calculate how much interest has accrued
        // And then subsequently mint more of the synth to the printer
        updateIndex();

        if (operation == Operation.Open) {
            (operatedPosition, params.id) = openPosition(
                params.amountOne,
                params.amountTwo,
                currentPrice
            );
        } else if (operation == Operation.Borrow) {
            operatedPosition = borrow(
                params.id,
                params.amountOne,
                params.amountTwo,
                currentPrice
            );
        } else if (operation == Operation.Repay) {
            operatedPosition = repay(
                params.id,
                params.amountOne,
                params.amountTwo,
                currentPrice
            );
        } else if (operation == Operation.Liquidate) {
            operatedPosition = liquidate(
                params.id,
                currentPrice
            );
        } else if (operation == Operation.TransferOwnership) {
            operatedPosition = transferOwnership(
                params.id,
                params.addressOne
            );
        } else {
            revert("operateAction(): invalid action");
        }

        // Ensure that the operated action is collateralised again, unless a liquidation
        // has occured in which case the position might be under-collataralised
        require(
            isCollateralized(operatedPosition, currentPrice) == true || operation == Operation.Liquidate,
            "operateAction(): the operated position is undercollateralised"
        );

        // Ensure the amount supplied is less than the collateral limit of the system
        require(
            totalSupplied <= collateralLimit || collateralLimit == 0,
            "operateAction(): collateral locked cannot be greater than limit"
        );

        // Collateral should never be expressed as negative since it means value has been drained
        assert(operatedPosition.collateralAmount.sign == true);

        // Debt should never be expressed as positive since it means the protocol is in debt to the user
        assert(operatedPosition.borrowedAmount.sign == false);

        emit ActionOperated(
            uint8(operation),
            params,
            operatedPosition
        );
    }

    /**
     * @dev Update the index of the contracts to compute the current interest rate.
     *      This function simply calculates the last time this function was called
     *      (in seconds) then multiplied by the interest rate. The result is then
     *      multiplied by the totalBorrowed amount.
    */
    function updateIndex()
        public
        returns (uint256)
    {
        if (currentTimestamp() == indexLastUpdate) {
            return borrowIndex;
        }

        if (totalBorrowed == 0 || interestRate == 0) {
            indexLastUpdate = currentTimestamp();

            emit IndexUpdated(
                borrowIndex,
                indexLastUpdate
            );

            return borrowIndex;
        }

        // Set the borrowed index to the latest index
        borrowIndex = currentBorrowIndex();

        // Update the total borrows based on the proportional rate of interest applied
        // to the entire system
        totalBorrowed = totalBorrowed.mul(borrowIndex).div(BASE);

        // Set the last time the index was updated to now
        indexLastUpdate = currentTimestamp();

        emit IndexUpdated(
            borrowIndex,
            indexLastUpdate
        );

        return borrowIndex;
    }

    /* ========== Admin Functions ========== */

    /**
     * @dev Withdraw tokens owned by the proxy. This will never include depositor funds
     *      since all the collateral is held by the synthetic token itself. The only funds
     *      that will accrue based on CoreV1 & StateV1 is the liquidation fees.
     *
     * @param token Address of the token to withdraw
     * @param destination Destination to withdraw to
     * @param amount The total amount of tokens withdraw
     */
    function withdrawTokens(
        address token,
        address destination,
        uint256 amount
    )
        external
        onlyAdmin
    {
        SafeERC20.safeTransfer(
            IERC20(token),
            destination,
            amount
        );
    }

    function setPause(bool value)
        external
        onlyAdmin
    {
        paused = value;

        emit PauseStatusUpdated(value);
    }

    /* ========== Internal Functions ========== */

    /**
     * @dev Open a new position.
     *
     * @param collateralAmount Collateral deposit amount
     * @param borrowAmount How much would you'd like to borrow/mint
     * @param currentPrice The current price of the collateral
     *
     * @return The new position and the ID of the opened position
     */
    function openPosition(
        uint256 collateralAmount,
        uint256 borrowAmount,
        Decimal.D256 memory currentPrice
    )
        internal
        returns (MozartTypes.Position memory, uint256)
    {
        // CHECKS:
        // 1. No checks required as it's all processed in borrow()

        // EFFECTS:
        // 1. Create a new Position struct with the basic fields filled out and save it to storage
        // 2. Call `borrow()`

        require(
            collateralAmount >= positionCollateralMinimum,
            "openPosition(): must exceed minimum collateral amount"
        );

        MozartTypes.Position memory newPosition = MozartTypes.Position({
            owner: msg.sender,
            collateralAmount: Amount.zero(),
            borrowedAmount: Amount.zero()
        });

        // This position is saved to storage to make the logic around borrowing
        // uniform. This is slightly gas inefficient but ok given the ability to
        // ensure no diverging logic.

        uint256 positionId = positionCount;
        positions[positionCount] = newPosition;
        positionCount = positionCount.add(1);

        newPosition = borrow(
            positionId,
            collateralAmount,
            borrowAmount,
            currentPrice
        );

        return (
            newPosition,
            positionId
        );
    }

    /**
     * @dev Borrow against an existing position.
     *
     * @param positionId ID of the position you'd like to borrow against
     * @param collateralAmount Collateral deposit amount
     * @param borrowAmount How much would you'd like to borrow/mint
     * @param currentPrice The current price of the collateral
     */
    function borrow(
        uint256 positionId,
        uint256 collateralAmount,
        uint256 borrowAmount,
        Decimal.D256 memory currentPrice
    )
        private
        isAuthorized(positionId)
        returns (MozartTypes.Position memory)
    {
        // CHECKS:
        // 1. Ensure that the position actually exists
        // 2. Convert the borrow amount to a Principal value
        // 3. Ensure the position is collateralised before borrowing against it
        // 4. Ensure that msg.sender == owner of position (done in the modifier)
        // 5. Determine if there's enough liquidity of the `borrowAsset`
        // 6. Calculate the amount of collateral actually needed given the `collateralRatio`
        // 7. Ensure the user has provided enough of the collateral asset

        // EFFECTS:
        // 1. Increase the collateral amount to calculate the maximum the amount the user can borrow
        // 2. Calculate the proportional new par value based on the borrow amount
        // 3. Update the total supplied collateral amount
        // 4. Calculate the collateral needed and ensuring the position has that much

        // INTERACTIONS:
        // 1. Mint the synthetic asset
        // 2. Transfer the collateral to the synthetic token itself.
        //    This ensures on Etherscan people can see how much collateral is backing
        //    the synthetic

        // Get the current position
        MozartTypes.Position storage position = positions[positionId];

        // Increase the user's collateral amount & increase the global supplied amount
        position = setCollateralAmount(
            positionId,
            position.collateralAmount.add(
                Amount.Principal({
                    sign: true,
                    value: collateralAmount.mul(precisionScalar)
                })
            )
        );

        // Sometimes a user may want to only deposit more collateral and not borrow more
        // so in that case we don't need to recheck any borrowing requirements
        if (borrowAmount > 0) {
            // Calculate the principal amount based on the current index of the market
            Amount.Principal memory convertedPrincipal = Amount.calculatePrincipal(
                borrowAmount,
                borrowIndex,
                false
            );

            // Set the total new borrowed amount. We need to use this function
            // in order to adjust the total borrowed amount proportionally as well.
            position = setBorrowAmount(
                positionId,
                position.borrowedAmount.add(convertedPrincipal)
            );

            // Check how much collateral they need based on their new position details
            Amount.Principal memory collateralRequired = calculateCollateralRequired(
                position.borrowedAmount.calculateAdjusted(borrowIndex),
                currentPrice
            );

            // Ensure the user's collateral amount is greater than the collateral needed
            require(
                position.collateralAmount.value >= collateralRequired.value,
                "borrowPosition(): not enough collateral provided"
            );
        }

        IERC20 syntheticAsset = IERC20(syntheticAsset);
        IERC20 collateralAsset = IERC20(collateralAsset);

        // Transfer the collateral asset to the synthetic contract
        SafeERC20.safeTransferFrom(
            collateralAsset,
            msg.sender,
            address(syntheticAsset),
            collateralAmount
        );

        ISyntheticToken(address(syntheticAsset)).mint(
            msg.sender,
            borrowAmount
        );

        return position;
    }

    /**
     * @dev Repay money against a borrowed position. When this process occurs the position's
     *      debt will be reduced and in turn will allow them to withdraw their collateral should they choose.
     *
     * @param positionId ID of the position to repay
     * @param repayAmount Amount of debt to repay
     * @param withdrawAmount Amount of collateral to withdraw
     * @param currentPrice The current price of the collateral
     */
    function repay(
        uint256 positionId,
        uint256 repayAmount,
        uint256 withdrawAmount,
        Decimal.D256 memory currentPrice
    )
        private
        isAuthorized(positionId)
        returns (MozartTypes.Position memory)
    {
        // CHECKS:
        // 1. Ensure the position actually exists by ensuring the owner == msg.sender (done in the modifier)
        // 2. The position does not have to be collateralised since we want people to repay
        //    before a liquidator does if they do actually have a chance

        // EFFECTS:
        // 1. Calculate the new par value of the position based on the amount they're going to repay
        // 2. Update the user's borrow amount by calling the setBorrowAmount() function
        // 3. Calculate how much collateral they can withdraw based on their new borrow amount
        // 4. Check if the amount being withdrawn is enough given their borrowing requirement
        // 5. Update the user's collateral amount by calling the setCollateralAmount() function

        // INTERACTIONS:
        // 1. Burn the synths being repaid directly from their wallet
        // 2. Transfer the collateral back to the user

        MozartTypes.Position storage position = positions[positionId];

        uint256 scaledWithdrawAmount = withdrawAmount.mul(precisionScalar);

        // Calculate the principal amount based on the current index of the market
        Amount.Principal memory convertedPrincipal = Amount.calculatePrincipal(
            repayAmount,
            borrowIndex,
            true
        );

        // Set the user's new borrow amount by decreasing their debt amount.
        // A positive par value will increase a negative par value.
        position = setBorrowAmount(
            positionId,
            position.borrowedAmount.add(convertedPrincipal)
        );

        // Calculate how much the user is allowed to withdraw given their debt was repaid
        Amount.Principal memory collateralDelta = calculateCollateralDelta(
            position.collateralAmount,
            position.borrowedAmount.calculateAdjusted(borrowIndex),
            currentPrice
        );

        // Ensure that the amount they are trying to withdraw is less than their limit
        // Also, make sure that the delta is positive (aka collateralized).
        require(
            collateralDelta.sign == true && scaledWithdrawAmount <= collateralDelta.value,
            "repay(): cannot withdraw more than allowed"
        );

        // Decrease the user's collateral amount by adding a negative principal amount
        position = setCollateralAmount(
            positionId,
            position.collateralAmount.add(
                Amount.Principal({
                    sign: false,
                    value: scaledWithdrawAmount
                })
            )
        );

        ISyntheticToken synthetic = ISyntheticToken(syntheticAsset);
        IERC20 collateralAsset = IERC20(collateralAsset);

        synthetic.burn(
            msg.sender,
            repayAmount
        );

        // Transfer collateral back to the user
        bool transferResult = synthetic.transferCollateral(
            address(collateralAsset),
            msg.sender,
            withdrawAmount
        );

        require(
            transferResult == true,
            "repay(): collateral failed to transfer"
        );

        return position;
    }

    /**
     * @dev Liquidate a user's position. When this process occurs you're essentially
     *      purchasing the users's debt at a discount (liquidation spread) in exchange
     *      for the collateral they have deposited inside their position.
     *
     * @param positionId ID of the position to liquidate
     * @param currentPrice The current price of the collateral
     */
    function liquidate(
        uint256 positionId,
        Decimal.D256 memory currentPrice
    )
        private
        returns (MozartTypes.Position memory)
    {
        // CHECKS:
        // 1. Ensure that the position is valid (check if there is a non-0x0 owner)
        // 2. Ensure that the position is indeed undercollateralized

        // EFFECTS:
        // 1. Calculate the liquidation price based on the liquidation penalty
        // 2. Calculate how much the user is in debt by
        // 3. Add the liquidation penalty to the liquidation amount so there's
        //    a buffer that exists to ensure they can't get liquidated again
        // 4. If the collateral to liquidate is greater than the collateral, bound it.
        // 5. Calculate how much of the borrowed asset is to be liquidated
        // 5. Decrease the user's debt obligation
        // 6. Decrease the user's collateral amount

        // INTERACTIONS:
        // 1. Burn the synthetic from the liquidator
        // 2. Tranfer the collateral from the synthetic token to the liquidator
        // 3. Transfer a portion to the ARC Core contract as a fee

        MozartTypes.Position storage position = positions[positionId];

        require(
            position.owner != address(0),
            "liquidatePosition(): must be a valid position"
        );

        // Ensure that the position is not collateralized
        require(
            isCollateralized(position, currentPrice) == false,
            "liquidatePosition(): position is collateralised"
        );

        // Get the liquidation price of the asset (discount for liquidator)
        Decimal.D256 memory liquidationPrice = calculateLiquidationPrice(currentPrice);

        // Calculate how much the user is in debt by to be whole again at a discounted price
        (Amount.Principal memory liquidationCollateralDelta) = calculateCollateralDelta(
            position.collateralAmount,
            position.borrowedAmount.calculateAdjusted(borrowIndex),
            liquidationPrice
        );

        // Liquidate a slight bit more to ensure the user is guarded against futher price drops
        liquidationCollateralDelta.value = Decimal.mul(
            liquidationCollateralDelta.value,
            Decimal.add(
                liquidationUserFee,
                Decimal.one().value
            )
        );

        // Calculate how much collateral this is going to cost the liquidator
        // The sign is negative since we need to subtract from the liquidation delta
        // which is a negative sign and subtracting a negative will actually add it

        // Calculate the amount of collateral actually needed in order to perform this liquidation.
        // Since the liquidationUserFee is the penalty, by multiplying (1-fee) we can get the
        // actual collateral amount needed. We'll ultimately be adding this amount to the
        // liquidation delta (which is negative) to give us the profit amount.
        (Amount.Principal memory liquidatorCollateralCost) = Amount.Principal({
            sign: true,
            value: Decimal.mul(
                liquidationCollateralDelta.value,
                Decimal.sub(
                    Decimal.one(),
                    liquidationUserFee.value
                )
            )
        });

        // If the maximum they're down by is greater than their collateral, bound to the maximum
        // This case will only arise if the position has truly become under-collateralized.

        // This check also ensures that no one can create a position which can drain the system
        // for more collateral than the position itself has.
        if (liquidationCollateralDelta.value > position.collateralAmount.value) {
            liquidationCollateralDelta.value = position.collateralAmount.value;

            // If the the original collateral delta is to be the same as the
            // collateral amount. What this does is that the profit calculated
            // will be 0 since the liquidationCollateralDelta less the
            // originalCollateralDelta will be the same.
            liquidatorCollateralCost.value = position.collateralAmount.value;
        }

        // Calculate how much borrowed assets to liquidate (at a discounted price)
        // We can use the liquidationCollateralDelta.value since it's already using
        // interest-adjusted values rather than principal values
        uint256 borrowToLiquidate = Decimal.mul(
            liquidationCollateralDelta.value,
            liquidationPrice
        );

        // Decrease the user's debt amout by the principal amount
        position = setBorrowAmount(
            positionId,
            position.borrowedAmount.add(
                Amount.calculatePrincipal(
                    borrowToLiquidate,
                    borrowIndex,
                    true
                )
            )
        );

        // Decrease the user's collateral amount by adding the collateral delta (which is negative)
        position = setCollateralAmount(
            positionId,
            position.collateralAmount.add(liquidationCollateralDelta)
        );

        require(
            IERC20(collateralAsset).balanceOf(msg.sender) >= borrowToLiquidate,
            "liquidatePosition(): msg.sender not enough of borrowed asset to liquidate"
        );

        _settleLiquidation(
            borrowToLiquidate,
            liquidationCollateralDelta,
            liquidatorCollateralCost
        );

        return position;
    }

    function _settleLiquidation(
        uint256 borrowToLiquidate,
        Amount.Principal memory liquidationCollateralDelta,
        Amount.Principal memory liquidatorCollateralCost
    )
        private
    {
        ISyntheticToken synthetic = ISyntheticToken(syntheticAsset);
        IERC20 collateralAsset = IERC20(collateralAsset);

        synthetic.burn(
            msg.sender,
            borrowToLiquidate
        );

        // This is the actual profit collected from the liquidation
        // Since the liquidationCollateralDelta is negative and liquidationCollateralCost
        // is a positive value, by adding them the result gives us the profit
        Amount.Principal memory collateralProfit = liquidationCollateralDelta.add(
            liquidatorCollateralCost
        );

        // ARC's profit is simple a percentage of the profit, not net total
        uint256 arcProfit = Decimal.mul(
            collateralProfit.value,
            liquidationArcRatio
        );

        // Transfer them the collateral assets they acquired at a discount
        bool userTransferResult = synthetic.transferCollateral(
            address(collateralAsset),
            msg.sender,
            uint256(liquidationCollateralDelta.value).sub(arcProfit).div(precisionScalar)
        );

        require(
            userTransferResult == true,
            "liquidate(): collateral failed to transfer to user"
        );

        // Transfer ARC the collateral asset acquired at a discount
        bool arcTransferResult = synthetic.transferCollateral(
            address(collateralAsset),
            address(this),
            arcProfit.div(precisionScalar)
        );

        require(
            arcTransferResult == true,
            "liquidate(): collateral failed to transfer to arc"
        );
    }

    /**
     * @dev Update a position's collateral amount. This function is used to ensure
     *      consistency in the total supplied amount as a user's collateral balance changes.
     *
     * @param positionId The id of the position to update the collateral amount for
     * @param newSupplyAmount How much to set their new supply values to
     */
    function setCollateralAmount(
        uint256 positionId,
        Amount.Principal memory newSupplyAmount
    )
        private
        returns (MozartTypes.Position storage)
    {
        MozartTypes.Position storage position = positions[positionId];

        if (position.collateralAmount.equals(newSupplyAmount)) {
            return position;
        }

        uint256 newTotalSupplied = totalSupplied;

        // Roll back the old amount
        newTotalSupplied = newTotalSupplied.sub(position.collateralAmount.value);

        // Roll forward the new amount
        newTotalSupplied = newTotalSupplied.add(newSupplyAmount.value);

        // Update the total borrowed storage value to the final result
        totalSupplied = newTotalSupplied;

        // Update the actual position's supplied amount
        position.collateralAmount = newSupplyAmount;

        // Prevent having collateral represented by negative values
        if (position.collateralAmount.value == 0) {
            position.collateralAmount.sign = true;
        }

        return position;
    }

    /**
     * @dev Update a position's borrow amount. This function is used to ensure consistency in the
     *      total borrowed amount as the user's borrowed amount changes.
     *
     * @param positionId The id of the position to update the borrow amount for
     * @param newBorrowAmount The new borrow amount for the position
     */
    function setBorrowAmount(
        uint256 positionId,
        Amount.Principal memory newBorrowAmount
    )
        private
        returns (MozartTypes.Position storage)
    {
        MozartTypes.Position storage position = positions[positionId];
        Amount.Principal memory existingAmount = position.borrowedAmount;

        if (position.borrowedAmount.equals(newBorrowAmount)) {
            return position;
        }

        uint256 newTotalBorrowed = totalBorrowed;

        // Roll back the old amount
        newTotalBorrowed = newTotalBorrowed.sub(existingAmount.value);

        // Roll forward the new amount
        newTotalBorrowed = newTotalBorrowed.add(newBorrowAmount.value);

        // Update the total borrowed storage value to the final result
        totalBorrowed = newTotalBorrowed;

        // Update the actual position's borrowed amount
        position.borrowedAmount = newBorrowAmount;

        // Prevent having debt represented by positive values
        if (position.borrowedAmount.value == 0) {
            position.borrowedAmount.sign = false;
        }

        return position;
    }

    /**
     * @dev This should allow a user to transfer ownership of a position to a
     *      a different address to operate their position.
     *
     * @param positionId ID of the position to transfer ownership to
     * @param newOwner New owner of the position to set
     */
    function transferOwnership(
        uint256 positionId,
        address newOwner
    )
        private
        returns (MozartTypes.Position storage)
    {
        MozartTypes.Position storage position = positions[positionId];

        require(
            msg.sender == position.owner,
            "transferOwnership(): must be the owner of the position"
        );

        position.owner = newOwner;

        return position;
    }

    /* ========== Public Getters ========== */

    function getPosition(
        uint256 id
    )
        external
        view
        returns (MozartTypes.Position memory)
    {
        return positions[id];
    }

    function getCurrentPrice()
        external
        view
        returns (Decimal.D256 memory)
    {
        return oracle.fetchCurrentPrice();
    }

    function getSyntheticAsset()
        external
        view
        returns (address)
    {
        return address(syntheticAsset);
    }

    function getCollateralAsset()
        external
        view
        returns (address)
    {
        return address(collateralAsset);
    }

    function getCurrentOracle()
        external
        view
        returns (address)
    {
        return address(oracle);
    }

    function getInterestSetter()
        external
        view
        returns (address)
    {
        return interestSetter;
    }

    function currentBorrowIndex()
        public
        view
        returns (uint256)
    {
        // First we multiply the interest rate (expressed in rate/sec) by the time since
        // the last update. This result represents the proportional amount of interest to
        // apply to the system at a whole
        uint256 interestAccumulated = interestRate.mul(currentTimestamp().sub(indexLastUpdate));

        // Then we multiply the existing index by the newly generated rate so that we can
        // get a compounded interest rate.
        // ie. interestAccumulated = 0.1, borrowIndex = 1.1, new borrowIndex = 0.1 + 1.1 = 1.2
        return borrowIndex.add(interestAccumulated);
    }

    function getBorrowIndex()
        external
        view
        returns (uint256, uint256)
    {
        return (borrowIndex, indexLastUpdate);
    }

    function getCollateralRatio()
        external
        view
        returns (Decimal.D256 memory)
    {
        return collateralRatio;
    }

    function getTotals()
        external
        view
        returns (
            uint256,
            uint256
        )
    {
        return (
            totalSupplied,
            totalBorrowed
        );
    }

    function getLimits()
        external
        view
        returns (uint256, uint256)
    {
        return (collateralLimit, positionCollateralMinimum);
    }

    function getInterestRate()
        external
        view
        returns (uint256)
    {
        return interestRate;
    }

    function getFees()
        external
        view
        returns (
            Decimal.D256 memory _liquidationUserFee,
            Decimal.D256 memory _liquidationArcRatio
        )
    {
        return (
            liquidationUserFee,
            liquidationArcRatio
        );
    }

    function isPositionOperator(
        uint256 _positionId,
        address _operator
    )
        public
        view
        returns (bool)
    {
        return positionOperators[_positionId][_operator];
    }

    function isGlobalOperator(
        address _operator
    )
        public
        view
        returns (bool)
    {
        return globalOperators[_operator];
    }

    /* ========== Developer Functions ========== */

    function currentTimestamp()
        public
        view
        returns (uint256)
    {
        return block.timestamp;
    }

    /**
     * @dev Check if a position is collateralised or not
     *
     * @param position The struct of a position to validate if it's underwater or not
     * @param currentPrice The current price of the collateral
     */
    function isCollateralized(
        MozartTypes.Position memory position,
        Decimal.D256 memory currentPrice
    )
        public
        view
        returns (bool)
    {
        if (position.borrowedAmount.value == 0) {
            return true;
        }

        (Amount.Principal memory collateralDelta) = calculateCollateralDelta(
            position.collateralAmount,
            position.borrowedAmount.calculateAdjusted(borrowIndex),
            currentPrice
        );

        if (collateralDelta.value == 0) {
            collateralDelta.sign = true;
        }

        return collateralDelta.sign;
    }

    /**
     * @dev Calculate how much collateral you need given a certain borrow amount
     *
     * @param borrowedAmount The borrowed amount expressed as a uint256 (NOT principal)
     * @param price What price do you want to calculate the inverse at
     */
    function calculateCollateralRequired(
        uint256 borrowedAmount,
        Decimal.D256 memory price
    )
        public
        view
        returns (Amount.Principal memory)
    {

        uint256 inverseRequired = Decimal.div(
            borrowedAmount,
            price
        );

        inverseRequired = Decimal.mul(
            inverseRequired,
            collateralRatio
        );

        return Amount.Principal({
            sign: true,
            value: inverseRequired
        });
    }

    /**
     * @dev Given an asset being borrowed, figure out how much collateral can this still borrow or
     *      is in the red by. This function is used to check if a position is undercolalteralised and
     *      also to calculate how much can a position be liquidated by.
     *
     * @param parSupply The amount being supplied
     * @param borrowedAmount The non-par amount being borrowed
     * @param price The price to calculate this difference by
     */
    function calculateCollateralDelta(
        Amount.Principal memory parSupply,
        uint256 borrowedAmount,
        Decimal.D256 memory price
    )
        public
        view
        returns (Amount.Principal memory)
    {
        Amount.Principal memory collateralDelta;
        Amount.Principal memory collateralRequired;

        collateralRequired = calculateCollateralRequired(
            borrowedAmount,
            price
        );

        // If the amount of collateral needed exceeds the par supply amount
        // then the result will be negative indicating the position is undercollateralised.
        collateralDelta = parSupply.sub(collateralRequired);

        return collateralDelta;
    }

    /**
     * @dev When executing a liqudation, the price of the asset has to be calculated
     *      at a discount in order for it to be profitable for the liquidator. This function
     *      will get the current oracle price for the asset and find the discounted price.
     *
     * @param currentPrice The current price of the collateral
     */
    function calculateLiquidationPrice(
        Decimal.D256 memory currentPrice
    )
        public
        view
        returns (Decimal.D256 memory)
    {
        Decimal.D256 memory result;

        result = Decimal.sub(
            Decimal.one(),
            liquidationUserFee.value
        );

        result = Decimal.mul(
            currentPrice,
            result
        );

        return result;
    }
}
