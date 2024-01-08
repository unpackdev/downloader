// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IARTH.sol";
import "./IARTHPool.sol";
import "./IERC20.sol";
import "./IARTHX.sol";
import "./IOracle.sol";
import "./SafeMath.sol";
import "./ArthPoolLibrary.sol";
import "./IARTHController.sol";
import "./IERC20Burnable.sol";
import "./AccessControl.sol";

/**
 * @title  ARTHPool.
 * @author MahaDAO.
 *
 *  Original code written by:
 *  - Travis Moore, Jason Huan, Same Kazemian, Sam Sun.
 */
contract ArthPool is AccessControl, IARTHPool {
    using SafeMath for uint256;

    /**
     * @dev Contract instances.
     */

    IARTH public _ARTH;
    IARTHX public _ARTHX;
    IERC20 public _COLLATERAL;
    IERC20Burnable public _MAHA;
    IARTHController public _arthController;
    IOracle public _collateralGMUOracle;
    //ICurve public _recollateralizeDiscountCruve;

    uint256 public buybackCollateralBuffer = 20; // In %.
    uint256 public poolCeiling = 0; // Total units of collateral that a pool contract can hold
    uint256 public redemptionDelay = 1; // Number of blocks to wait before being able to collect redemption.

    uint256 public unclaimedPoolARTHX;
    uint256 public unclaimedPoolCollateral;

    address public override collateralGMUOracleAddress;

    mapping(address => uint256) public lastRedeemed;
    mapping(address => uint256) public borrowedCollateral;
    mapping(address => uint256) public redeemARTHXBalances;
    mapping(address => uint256) public redeemCollateralBalances;

    bytes32 public constant _AMO_ROLE = keccak256('AMO_ROLE');

    uint256 private immutable _missingDeciamls;
    uint256 private constant _PRICE_PRECISION = 1e6;
    uint256 private constant _COLLATERAL_RATIO_MAX = 2e6; // Placeholder, need to replace this with apt. val.
    uint256 private constant _COLLATERAL_RATIO_MIN = 1e6 + 1; // 100.0001 in 1e6 precision.
    uint256 private constant _COLLATERAL_RATIO_PRECISION = 1e6;

    address private _wethAddress;
    address private _ownerAddress;
    address private _timelockAddress;
    address private _collateralAddress;
    address private _arthContractAddress;
    address private _arthxContractAddress;

    /**
     * Events.
     */
    event Repay(address indexed from, uint256 amount);
    event Borrow(address indexed from, uint256 amount);
    event StabilityFeesCharged(address indexed from, uint256 fee);

    /**
     * Modifiers.
     */
    modifier onlyByOwnerOrGovernance() {
        require(
            msg.sender == _timelockAddress || msg.sender == _ownerAddress,
            'ArthPool: You are not the owner or the governance timelock'
        );
        _;
    }

    modifier onlyAdminOrOwnerOrGovernance() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
                msg.sender == _timelockAddress ||
                msg.sender == _ownerAddress,
            'ArthPool: forbidden'
        );
        _;
    }

    modifier onlyAMOS {
        require(hasRole(_AMO_ROLE, _msgSender()), 'ArthPool: forbidden');
        _;
    }

    modifier notRedeemPaused() {
        require(
            !_arthController.isRedeemPaused(),
            'ArthPool: Redeeming is paused'
        );
        _;
    }

    modifier notMintPaused() {
        require(!_arthController.isMintPaused(), 'ArthPool: Minting is paused');
        _;
    }

    /**
     * Constructor.
     */

    constructor(
        address __arthContractAddress,
        address __arthxContractAddress,
        address __collateralAddress,
        address _creatorAddress,
        address __timelockAddress,
        address __MAHA,
        address __arthController,
        uint256 _poolCeiling
    ) {
        _MAHA = IERC20Burnable(__MAHA);
        _ARTH = IARTH(__arthContractAddress);
        _COLLATERAL = IERC20(__collateralAddress);
        _ARTHX = IARTHX(__arthxContractAddress);
        _arthController = IARTHController(__arthController);

        _ownerAddress = _creatorAddress;
        _timelockAddress = __timelockAddress;
        _collateralAddress = __collateralAddress;
        _arthContractAddress = __arthContractAddress;
        _arthxContractAddress = __arthxContractAddress;

        poolCeiling = _poolCeiling;
        _missingDeciamls = uint256(18).sub(_COLLATERAL.decimals());

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * External.
     */
    function setBuyBackCollateralBuffer(uint256 percent)
        external
        override
        onlyAdminOrOwnerOrGovernance
    {
        require(percent <= 100, 'ArthPool: percent > 100');
        buybackCollateralBuffer = percent;
    }

    function setARTHController(IARTHController controller)
        external
        onlyAdminOrOwnerOrGovernance
    {
        _arthController = controller;
    }

    function setCollatGMUOracle(address _collateralGMUOracleAddress)
        external
        override
        onlyByOwnerOrGovernance
    {
        collateralGMUOracleAddress = _collateralGMUOracleAddress;
        _collateralGMUOracle = IOracle(_collateralGMUOracleAddress);
    }

    // Combined into one function due to 24KiB contract memory limit
    function setPoolParameters(uint256 newCeiling, uint256 newRedemptionDelay)
        external
        override
        onlyByOwnerOrGovernance
    {
        poolCeiling = newCeiling;
        redemptionDelay = newRedemptionDelay;
    }

    function setTimelock(address new_timelock)
        external
        override
        onlyByOwnerOrGovernance
    {
        _timelockAddress = new_timelock;
    }

    function setOwner(address __ownerAddress)
        external
        override
        onlyByOwnerOrGovernance
    {
        _ownerAddress = __ownerAddress;
    }

    function borrow(uint256 _amount) external override onlyAMOS {
        require(
            _COLLATERAL.balanceOf(address(this)) > _amount,
            'ArthPool: Insufficent funds in the pool'
        );

        borrowedCollateral[msg.sender] += _amount;
        require(
            _COLLATERAL.transfer(msg.sender, _amount),
            'ArthPool: transfer failed'
        );

        emit Borrow(msg.sender, _amount);
    }

    function repay(uint256 amount) external override onlyAMOS {
        require(
            borrowedCollateral[msg.sender] > 0,
            "ArthPool: Repayer doesn't not have any debt"
        );

        require(
            _COLLATERAL.balanceOf(msg.sender) >= amount,
            'ArthPool: balance < required'
        );

        borrowedCollateral[msg.sender] -= amount;
        require(
            _COLLATERAL.transferFrom(msg.sender, address(this), amount),
            'ARTHPool: transfer from failed'
        );

        emit Repay(msg.sender, amount);
    }

    function mint(
        uint256 collateralAmount,
        uint256 arthOutMin,
        uint256 arthxOutMin
    ) external override notMintPaused returns (uint256, uint256) {
        uint256 collateralAmountD18 = collateralAmount * (10**_missingDeciamls);
        uint256 cr = _arthController.getGlobalCollateralRatio();

        require(
            cr <= _COLLATERAL_RATIO_MAX,
            'ARHTPool: Collateral ratio > MAX'
        );
        require(
            cr >= _COLLATERAL_RATIO_MIN,
            'ARHTPool: Collateral ratio < MIN'
        );
        require(
            (_COLLATERAL.balanceOf(address(this)))
                .sub(unclaimedPoolCollateral)
                .add(collateralAmount) <= poolCeiling,
            'ARTHPool: ceiling reached'
        );

        uint256 algorithmicRatio = uint256(cr).sub(1e6);
        uint256 collateralRatio = uint256(1e6).sub(algorithmicRatio);

        // 1 ARTH for each $1 worth of collateral.
        (uint256 arthAmountD18, uint256 arthxAmountD18) =
            ArthPoolLibrary.calcOverCollateralizedMintAmounts(
                collateralRatio,
                algorithmicRatio,
                getCollateralPrice(),
                _arthController.getARTHXPrice(),
                collateralAmountD18
            );

        // Remove precision at the end.
        arthAmountD18 = (
            arthAmountD18.mul(uint256(1e6).sub(_arthController.getMintingFee()))
        )
            .div(1e6);

        require(
            arthOutMin <= arthAmountD18,
            'ARTHPool: ARTH Slippage limit reached'
        );
        require(
            arthxOutMin <= arthxAmountD18,
            'ARTHPool: ARTHX Slippage limit reached'
        );

        require(
            _COLLATERAL.balanceOf(msg.sender) >= collateralAmount,
            'ArthPool: balance < required'
        );
        require(
            _COLLATERAL.transferFrom(
                msg.sender,
                address(this),
                collateralAmount
            ),
            'ARTHPool: transfer from failed'
        );

        _ARTH.poolMint(msg.sender, arthAmountD18);
        _ARTHX.poolMint(msg.sender, arthxAmountD18);

        return (arthAmountD18, arthxAmountD18);
    }

    // Redeem collateral. 100% collateral-backed
    function redeem(
        uint256 arthAmount,
        uint256 arthxAmount,
        uint256 collateralOutMin
    ) external override notRedeemPaused {
        uint256 cr = _arthController.getGlobalCollateralRatio();

        require(cr <= _COLLATERAL_RATIO_MAX, 'Collateral ratio > MAX');
        require(cr >= _COLLATERAL_RATIO_MIN, 'Collateral ratio < MIN');

        // Need to adjust for decimals of collateral
        uint256 arthAmountPrecision = arthAmount.div(10**_missingDeciamls);
        // uint256 arthxAmountPrecision = arthxAmount.div(10**_missingDeciamls);

        uint256 algorithmicRatio = uint256(cr).sub(1e6);
        uint256 collateralRatio = uint256(1e6).sub(algorithmicRatio);

        (uint256 collateralNeeded, uint256 arthxInputNeeded) =
            ArthPoolLibrary.calcOverCollateralizedRedeemAmounts(
                collateralRatio,
                // algorithmicRatio,
                _arthController.getARTHXPrice(),
                getCollateralPrice(),
                arthAmountPrecision
                //, arthxAmountPrecision
            );

        collateralNeeded = (
            collateralNeeded.mul(
                uint256(1e6).sub(_arthController.getRedemptionFee())
            )
        )
            .div(1e6);

        uint256 arthxInputNeededD18 =
            arthxInputNeeded.mul(10**_missingDeciamls);
        require(
            _ARTHX.balanceOf(msg.sender) >= arthxInputNeededD18,
            'ARTHPool: balance not enough'
        );
        require(
            collateralNeeded <=
                _COLLATERAL.balanceOf(address(this)).sub(
                    unclaimedPoolCollateral
                ),
            'ARTHPool: Not enough collateral in pool'
        );
        require(
            collateralOutMin <= collateralNeeded,
            'ARTHPool: Collateral Slippage limit reached'
        );
        require(
            arthxAmount >= arthxInputNeededD18,
            'ArthPool: Not enought arthx input provided'
        );

        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[
            msg.sender
        ]
            .add(collateralNeeded);
        unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateralNeeded);
        lastRedeemed[msg.sender] = block.number;

        _chargeStabilityFee(arthAmount);

        _ARTH.poolBurnFrom(msg.sender, arthAmount);
        _ARTHX.poolBurnFrom(msg.sender, arthxInputNeededD18);
    }

    // After a redemption happens, transfer the newly minted ARTHX and owed collateral from this pool
    // contract to the user. Redemption is split into two functions to prevent flash loans from being able
    // to take out ARTH/collateral from the system, use an AMM to trade the new price, and then mint back into the system.
    function collectRedemption() external override {
        require(
            (lastRedeemed[msg.sender].add(redemptionDelay)) <= block.number,
            'Must wait for redemptionDelay blocks before collecting redemption'
        );

        uint256 ARTHXAmount;
        uint256 CollateralAmount;
        bool sendARTHX = false;
        bool sendCollateral = false;

        // Use Checks-Effects-Interactions pattern
        if (redeemARTHXBalances[msg.sender] > 0) {
            ARTHXAmount = redeemARTHXBalances[msg.sender];
            redeemARTHXBalances[msg.sender] = 0;
            unclaimedPoolARTHX = unclaimedPoolARTHX.sub(ARTHXAmount);

            sendARTHX = true;
        }

        if (redeemCollateralBalances[msg.sender] > 0) {
            CollateralAmount = redeemCollateralBalances[msg.sender];
            redeemCollateralBalances[msg.sender] = 0;
            unclaimedPoolCollateral = unclaimedPoolCollateral.sub(
                CollateralAmount
            );

            sendCollateral = true;
        }

        if (sendARTHX)
            require(
                _ARTHX.transfer(msg.sender, ARTHXAmount),
                'ARTHPool: transfer failed'
            );

        if (sendCollateral)
            require(
                _COLLATERAL.transfer(msg.sender, CollateralAmount),
                'ARTHPool: transfer failed'
            );
    }

    // When the protocol is recollateralizing, we need to give a discount of ARTHX to hit the new CR target
    // Thus, if the target collateral ratio is higher than the actual value of collateral, minters get ARTHX for adding collateral
    // This function simply rewards anyone that sends collateral to a pool with the same amount of ARTHX + the bonus rate
    // Anyone can call this function to recollateralize the protocol and take the extra ARTHX value from the bonus rate as an arb opportunity
    function recollateralizeARTH(uint256 collateralAmount, uint256 arthxOutMin)
        external
        override
        returns (uint256)
    {
        require(
            !_arthController.isRecollaterlizePaused(),
            'Recollateralize is paused'
        );

        uint256 arthxPrice = _arthController.getARTHXPrice();

        (uint256 collateralUnits, uint256 amountToRecollateralize, ) =
            estimateAmountToRecollateralize(collateralAmount);

        uint256 collateralUnitsPrecision =
            collateralUnits.div(10**_missingDeciamls);

        // NEED to make sure that recollatFee is less than 1e6.
        uint256 arthxPaidBack =
            amountToRecollateralize
                .mul(_arthController.getRecollateralizationDiscount().add(1e6))
                .div(arthxPrice);

        require(arthxOutMin <= arthxPaidBack, 'Slippage limit reached');
        require(
            _COLLATERAL.balanceOf(msg.sender) >= collateralUnitsPrecision,
            'ArthPool: balance < required'
        );
        require(
            _COLLATERAL.transferFrom(
                msg.sender,
                address(this),
                collateralUnitsPrecision
            ),
            'ARTHPool: transfer from failed'
        );

        _ARTHX.poolMint(msg.sender, arthxPaidBack);

        return arthxPaidBack;
    }

    function estimateAmountToRecollateralize(uint256 collateralAmount)
        public
        view
        returns (
            uint256 collateralUnits,
            uint256 amountToRecollateralize,
            uint256 recollateralizePossible
        )
    {
        uint256 collateralAmountD18 = collateralAmount * (10**_missingDeciamls);
        uint256 arthTotalSupply = _arthController.getARTHSupply();
        uint256 collateralRatioForRecollateralize =
            _arthController.getGlobalCollateralRatio();
        uint256 globalCollatValue = _arthController.getGlobalCollateralValue();

        return
            ArthPoolLibrary.calcRecollateralizeARTHInner(
                collateralAmountD18,
                getCollateralPrice(),
                globalCollatValue,
                arthTotalSupply,
                collateralRatioForRecollateralize
            );
    }

    // Function can be called by an ARTHX holder to have the protocol buy back ARTHX with excess collateral value from a desired collateral pool
    // This can also happen if the collateral ratio > 1
    function buyBackARTHX(uint256 arthxAmount, uint256 collateralOutMin)
        external
        override
    {
        require(!_arthController.isBuybackPaused(), 'Buyback is paused');

        uint256 arthxPrice = _arthController.getARTHXPrice();

        ArthPoolLibrary.BuybackARTHXParams memory inputParams =
            ArthPoolLibrary.BuybackARTHXParams(
                getAvailableExcessCollateralDV(),
                arthxPrice,
                getCollateralPrice(),
                arthxAmount
            );

        uint256 collateralEquivalentD18 =
            (ArthPoolLibrary.calcBuyBackARTHX(inputParams))
                .mul(uint256(1e6).sub(_arthController.getBuybackFee()))
                .div(1e6);
        uint256 collateralPrecision =
            collateralEquivalentD18.div(10**_missingDeciamls);

        require(
            collateralOutMin <= collateralPrecision,
            'Slippage limit reached'
        );

        // Give the sender their desired collateral and burn the ARTHX
        _ARTHX.poolBurnFrom(msg.sender, arthxAmount);
        require(
            _COLLATERAL.transfer(msg.sender, collateralPrecision),
            'ARTHPool: transfer failed'
        );
    }

    function getGlobalCR() public view override returns (uint256) {
        return _arthController.getGlobalCollateralRatio();
    }

    function getCollateralGMUBalance()
        external
        view
        override
        returns (uint256)
    {
        uint256 collateralPrice = getCollateralPrice();

        return (
            (_COLLATERAL.balanceOf(address(this)).sub(unclaimedPoolCollateral))
                .mul(10**_missingDeciamls)
                .mul(collateralPrice)
                .div(_PRICE_PRECISION)
            // .div(10**_missingDeciamls)
        );
    }

    // Returns the value of excess collateral held in this Arth pool, compared to what is
    // needed to maintain the global collateral ratio
    function getAvailableExcessCollateralDV()
        public
        view
        override
        returns (uint256)
    {
        uint256 totalSupply = _arthController.getARTHSupply();
        uint256 globalCollateralRatio = getGlobalCR();
        uint256 globalCollatValue = _arthController.getGlobalCollateralValue();

        // Check if overcollateralized contract with CR > 1.
        if (globalCollateralRatio > _COLLATERAL_RATIO_PRECISION)
            globalCollateralRatio = _COLLATERAL_RATIO_PRECISION;

        // Calculates collateral needed to back each 1 ARTH with $1 of collateral at current CR.
        uint256 reqCollateralGMUValue =
            (totalSupply.mul(globalCollateralRatio)).div(
                _COLLATERAL_RATIO_PRECISION
            );

        // TODO: add a 10-20% buffer for volatile collaterals.
        if (globalCollatValue > reqCollateralGMUValue) {
            uint256 excessCollateral =
                globalCollatValue.sub(reqCollateralGMUValue);
            uint256 bufferValue =
                excessCollateral.mul(buybackCollateralBuffer).div(100);

            return excessCollateral.sub(bufferValue);
        }

        return 0;
    }

    function getTargetCollateralValue() public view returns (uint256) {
        return
            _arthController
                .getARTHSupply()
                .mul(_arthController.getGlobalCollateralRatio())
                .div(1e6);
    }

    function getCollateralPrice() public view override returns (uint256) {
        return _collateralGMUOracle.getPrice();
    }

    function estimateStabilityFeeInMAHA(uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 stabilityFeeInARTH =
            amount.mul(_arthController.getStabilityFee()).div(1e6);

        // ARTH is redeemed at 1$.
        return (
            stabilityFeeInARTH.mul(1e6).div(_arthController.getMAHAPrice())
        );
    }

    function _chargeStabilityFee(uint256 amount) internal {
        uint256 stabilityFeeInMAHA = estimateStabilityFeeInMAHA(amount);

        if (stabilityFeeInMAHA > 0) {
            _MAHA.burnFrom(msg.sender, stabilityFeeInMAHA);
            emit StabilityFeesCharged(msg.sender, stabilityFeeInMAHA);
        }
    }
}
