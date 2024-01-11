// Be name Khoda
// Bime Abolfazl
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;
pragma abicoder v2;

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ============================= DEIPool =============================
// ===================================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Vahid: https://github.com/vahid-dev

import "./AccessControl.sol";
import "./TransferHelper.sol";
import "./IPoolLibrary.sol";
import "./IPoolV2.sol";
import "./IERC20.sol";
import "./IDEUS.sol";
import "./IDEI.sol";

/// @title Minter Pool Contract V2
/// @author DEUS Finance
/// @notice Minter pool of DEI stablecoin
/// @dev Uses twap and vwap for DEUS price in DEI redemption by using muon oracles
///      Usable for stablecoins as collateral
contract DEIPool is IDEIPool, AccessControl {
    /* ========== STATE VARIABLES ========== */
    address public collateral;
    address private dei;
    address private deus;

    uint256 public mintingFee;
    uint256 public redemptionFee = 10000;
    uint256 public buybackFee = 5000;
    uint256 public recollatFee = 5000;

    mapping(address => uint256) public redeemCollateralBalances;
    uint256 public unclaimedPoolCollateral;
    mapping(address => uint256) public lastCollateralRedeemed;

    // position data
    mapping(address => IDEIPool.RedeemPosition[]) public redeemPositions;
    mapping(address => uint256) public nextRedeemId;

    uint256 public collateralRedemptionDelay;
    uint256 public deusRedemptionDelay;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    uint256 private constant COLLATERAL_RATIO_PRECISION = 1e6;
    uint256 private constant COLLATERAL_RATIO_MAX = 1e6;
    uint256 private constant COLLATERAL_PRICE = 1e6;
    uint256 private constant SCALE = 1e6;

    // Number of decimals needed to get to 18
    uint256 private immutable missingDecimals;

    // Pool_ceiling is the total units of collateral that a pool contract can hold
    uint256 public poolCeiling;

    // Bonus rate on DEUS minted during RecollateralizeDei(); 6 decimals of precision, set to 0.75% on genesis
    uint256 public bonusRate = 7500;

    uint256 public daoShare = 0; // fees goes to daoWallet

    address public poolLibrary; // Pool library contract

    address public muon;
    uint32 public appId;
    uint256 minimumRequiredSignatures;

    // AccessControl Roles
    bytes32 public constant PARAMETER_SETTER_ROLE =
        keccak256("PARAMETER_SETTER_ROLE");
    bytes32 public constant DAO_SHARE_COLLECTOR =
        keccak256("DAO_SHARE_COLLECTOR");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant TRUSTY_ROLE = keccak256("TRUSTY_ROLE");

    // AccessControl state variables
    bool public mintPaused = false;
    bool public redeemPaused = false;
    bool public recollateralizePaused = false;
    bool public buyBackPaused = false;

    /* ========== MODIFIERS ========== */
    modifier notRedeemPaused() {
        require(redeemPaused == false, "DEIPool: REDEEM_PAUSED");
        _;
    }

    modifier notMintPaused() {
        require(mintPaused == false, "DEIPool: MINTING_PAUSED");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address dei_,
        address deus_,
        address collateral_,
        address muon_,
        address library_,
        address admin,
        uint256 minimumRequiredSignatures_,
        uint256 collateralRedemptionDelay_,
        uint256 deusRedemptionDelay_,
        uint256 poolCeiling_,
        uint32 appId_
    ) {
        require(
            (dei_ != address(0)) &&
                (deus_ != address(0)) &&
                (collateral_ != address(0)) &&
                (library_ != address(0)) &&
                (admin != address(0)),
            "DEIPool: ZERO_ADDRESS_DETECTED"
        );
        dei = dei_;
        deus = deus_;
        collateral = collateral_;
        muon = muon_;
        appId = appId_;
        minimumRequiredSignatures = minimumRequiredSignatures_;
        collateralRedemptionDelay = collateralRedemptionDelay_;
        deusRedemptionDelay = deusRedemptionDelay_;
        poolCeiling = poolCeiling_;
        poolLibrary = library_;
        missingDecimals = uint256(18) - IERC20(collateral).decimals();

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /* ========== VIEWS ========== */

    // Returns dollar value of collateral held in this DEI pool
    function collatDollarBalance(uint256 collateralPrice)
        public
        view
        returns (uint256 balance)
    {
        balance =
            ((IERC20(collateral).balanceOf(address(this)) -
                unclaimedPoolCollateral) *
                (10**missingDecimals) *
                collateralPrice) /
            (PRICE_PRECISION);
    }

    // Returns the value of excess collateral held in this DEI pool, compared to what is needed to maintain the global collateral ratio
    function availableExcessCollatDV(uint256[] memory collateralPrice)
        public
        view
        returns (uint256)
    {
        uint256 totalSupply = IDEI(dei).totalSupply();
        uint256 globalCollateralRatio = IDEI(dei).global_collateral_ratio();
        uint256 globalCollateralValue = IDEI(dei).globalCollateralValue(
            collateralPrice
        );

        if (globalCollateralRatio > COLLATERAL_RATIO_PRECISION)
            globalCollateralRatio = COLLATERAL_RATIO_PRECISION; // Handles an overcollateralized contract with CR > 1
        uint256 requiredCollateralDollarValued18 = (totalSupply *
            globalCollateralRatio) / (COLLATERAL_RATIO_PRECISION); // Calculates collateral needed to back each 1 DEI with $1 of collateral at current collat ratio
        if (globalCollateralValue > requiredCollateralDollarValued18)
            return globalCollateralValue - requiredCollateralDollarValued18;
        else return 0;
    }

    function positionsLength(address user)
        external
        view
        returns (uint256 length)
    {
        length = redeemPositions[user].length;
    }

    function getAllPositions(address user)
        external
        view
        returns (RedeemPosition[] memory positions)
    {
        positions = redeemPositions[user];
    }

    function getUnRedeemedPositions(address user)
        external
        view
        returns (RedeemPosition[] memory)
    {
        uint256 totalRedeemPositions = redeemPositions[user].length;
        uint256 redeemId = nextRedeemId[user];

        RedeemPosition[] memory positions = new RedeemPosition[](
            totalRedeemPositions - redeemId + 1
        );
        uint256 index = 0;
        for (uint256 i = redeemId; i < totalRedeemPositions; i++) {
            positions[index] = redeemPositions[user][i];
            index++;
        }

        return positions;
    }

    function _getChainId() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // We separate out the 1t1, fractional and algorithmic minting functions for gas efficiency
    function mint1t1DEI(uint256 collateralAmount)
        external
        notMintPaused
        returns (uint256 deiAmount)
    {
        require(
            IDEI(dei).global_collateral_ratio() >= COLLATERAL_RATIO_MAX,
            "DEIPool: INVALID_COLLATERAL_RATIO"
        );
        require(
            IERC20(collateral).balanceOf(address(this)) -
                unclaimedPoolCollateral +
                collateralAmount <=
                poolCeiling,
            "DEIPool: CEILING_REACHED"
        );

        uint256 collateralAmountD18 = collateralAmount * (10**missingDecimals);
        deiAmount = IPoolLibrary(poolLibrary).calcMint1t1DEI(
            COLLATERAL_PRICE,
            collateralAmountD18
        ); //1 DEI for each $1 worth of collateral

        deiAmount = (deiAmount * (SCALE - mintingFee)) / SCALE; //remove precision at the end

        TransferHelper.safeTransferFrom(
            collateral,
            msg.sender,
            address(this),
            collateralAmount
        );

        daoShare += (deiAmount * mintingFee) / SCALE;
        IDEI(dei).pool_mint(msg.sender, deiAmount);
    }

    // 0% collateral-backed
    function mintAlgorithmicDEI(
        uint256 deusAmount,
        uint256 deusPrice,
        uint256 expireBlock,
        bytes[] calldata sigs
    ) external notMintPaused returns (uint256 deiAmount) {
        require(
            IDEI(dei).global_collateral_ratio() == 0,
            "DEIPool: INVALID_COLLATERAL_RATIO"
        );
        require(expireBlock >= block.number, "DEIPool: EXPIRED_SIGNATURE");
        bytes32 sighash = keccak256(
            abi.encodePacked(deus, deusPrice, expireBlock, _getChainId())
        );
        require(
            IDEI(dei).verify_price(sighash, sigs),
            "DEIPool: UNVERIFIED_SIGNATURE"
        );

        deiAmount = IPoolLibrary(poolLibrary).calcMintAlgorithmicDEI(
            deusPrice, // X DEUS / 1 USD
            deusAmount
        );

        deiAmount = (deiAmount * (SCALE - (mintingFee))) / SCALE;
        daoShare += (deiAmount * mintingFee) / SCALE;

        IDEUS(deus).pool_burn_from(msg.sender, deusAmount);
        IDEI(dei).pool_mint(msg.sender, deiAmount);
    }

    // Will fail if fully collateralized or fully algorithmic
    // > 0% and < 100% collateral-backed
    function mintFractionalDEI(
        uint256 collateralAmount,
        uint256 deusAmount,
        uint256 deusPrice,
        uint256 expireBlock,
        bytes[] calldata sigs
    ) external notMintPaused returns (uint256 mintAmount) {
        uint256 globalCollateralRatio = IDEI(dei).global_collateral_ratio();
        require(
            globalCollateralRatio < COLLATERAL_RATIO_MAX &&
                globalCollateralRatio > 0,
            "DEIPool: INVALID_COLLATERAL_RATIO"
        );
        require(
            IERC20(collateral).balanceOf(address(this)) -
                unclaimedPoolCollateral +
                collateralAmount <=
                poolCeiling,
            "DEIPool: CEILING_REACHED"
        );

        require(expireBlock >= block.number, "DEIPool: EXPIRED_SIGNATURE");
        bytes32 sighash = keccak256(
            abi.encodePacked(deus, deusPrice, expireBlock, _getChainId())
        );
        require(
            IDEI(dei).verify_price(sighash, sigs),
            "DEIPool: UNVERIFIED_SIGNATURE"
        );

        IPoolLibrary.MintFractionalDeiParams memory inputParams;

        // Blocking is just for solving stack depth problem
        {
            uint256 collateralAmountD18 = collateralAmount *
                (10**missingDecimals);
            inputParams = IPoolLibrary.MintFractionalDeiParams(
                deusPrice,
                COLLATERAL_PRICE,
                collateralAmountD18,
                globalCollateralRatio
            );
        }

        uint256 deusNeeded;
        (mintAmount, deusNeeded) = IPoolLibrary(poolLibrary)
            .calcMintFractionalDEI(inputParams);
        require(deusNeeded <= deusAmount, "INSUFFICIENT_DEUS_INPUTTED");

        mintAmount = (mintAmount * (SCALE - mintingFee)) / SCALE;

        IDEUS(deus).pool_burn_from(msg.sender, deusNeeded);

        TransferHelper.safeTransferFrom(
            collateral,
            msg.sender,
            address(this),
            collateralAmount
        );

        daoShare += (mintAmount * mintingFee) / SCALE;
        IDEI(dei).pool_mint(msg.sender, mintAmount);
    }

    // Redeem collateral. 100% collateral-backed
    function redeem1t1DEI(uint256 deiAmount) external notRedeemPaused {
        require(
            IDEI(dei).global_collateral_ratio() == COLLATERAL_RATIO_MAX,
            "DEIPool: INVALID_COLLATERAL_RATIO"
        );

        // Need to adjust for decimals of collateral
        uint256 deiAmountPrecision = deiAmount / (10**missingDecimals);
        uint256 collateralNeeded = IPoolLibrary(poolLibrary).calcRedeem1t1DEI(
            COLLATERAL_PRICE,
            deiAmountPrecision
        );

        collateralNeeded = (collateralNeeded * (SCALE - redemptionFee)) / SCALE;
        require(
            collateralNeeded <=
                IERC20(collateral).balanceOf(address(this)) -
                    unclaimedPoolCollateral,
            "DEIPool: INSUFFICIENT_COLLATERAL_BALANCE"
        );

        redeemCollateralBalances[msg.sender] =
            redeemCollateralBalances[msg.sender] +
            collateralNeeded;
        unclaimedPoolCollateral = unclaimedPoolCollateral + collateralNeeded;
        lastCollateralRedeemed[msg.sender] = block.number;

        daoShare += (deiAmount * redemptionFee) / SCALE;
        // Move all external functions to the end
        IDEI(dei).pool_burn_from(msg.sender, deiAmount);
    }

    // Will fail if fully collateralized or algorithmic
    // Redeem DEI for collateral and DEUS. > 0% and < 100% collateral-backed
    function redeemFractionalDEI(uint256 deiAmount) external notRedeemPaused {
        uint256 globalCollateralRatio = IDEI(dei).global_collateral_ratio();
        require(
            globalCollateralRatio < COLLATERAL_RATIO_MAX &&
                globalCollateralRatio > 0,
            "DEIPool: INVALID_COLLATERAL_RATIO"
        );

        // Blocking is just for solving stack depth problem
        uint256 collateralAmount;
        {
            uint256 deiAmountPostFee = (deiAmount * (SCALE - redemptionFee)) /
                (PRICE_PRECISION);
            uint256 deiAmountPrecision = deiAmountPostFee /
                (10**missingDecimals);
            collateralAmount =
                (deiAmountPrecision * globalCollateralRatio) /
                PRICE_PRECISION;
        }
        require(
            collateralAmount <=
                IERC20(collateral).balanceOf(address(this)) -
                    unclaimedPoolCollateral,
            "DEIPool: NOT_ENOUGH_COLLATERAL"
        );

        redeemCollateralBalances[msg.sender] += collateralAmount;
        lastCollateralRedeemed[msg.sender] = block.timestamp;
        unclaimedPoolCollateral = unclaimedPoolCollateral + collateralAmount;

        {
            uint256 deiAmountPostFee = (deiAmount * (SCALE - redemptionFee)) /
                SCALE;
            uint256 deusDollarAmount = (deiAmountPostFee *
                (SCALE - globalCollateralRatio)) / SCALE;

            redeemPositions[msg.sender].push(
                RedeemPosition({
                    amount: deusDollarAmount,
                    timestamp: block.timestamp
                })
            );
        }

        daoShare += (deiAmount * redemptionFee) / SCALE;

        IDEI(dei).pool_burn_from(msg.sender, deiAmount);
    }

    // Redeem DEI for DEUS. 0% collateral-backed
    function redeemAlgorithmicDEI(uint256 deiAmount) external notRedeemPaused {
        require(
            IDEI(dei).global_collateral_ratio() == 0,
            "DEIPool: INVALID_COLLATERAL_RATIO"
        );

        uint256 deusDollarAmount = (deiAmount * (SCALE - redemptionFee)) /
            (PRICE_PRECISION);
        redeemPositions[msg.sender].push(
            RedeemPosition({
                amount: deusDollarAmount,
                timestamp: block.timestamp
            })
        );
        daoShare += (deiAmount * redemptionFee) / SCALE;
        IDEI(dei).pool_burn_from(msg.sender, deiAmount);
    }

    function collectCollateral() external {
        require(
            (lastCollateralRedeemed[msg.sender] + collateralRedemptionDelay) <=
                block.timestamp,
            "DEIPool: COLLATERAL_REDEMPTION_DELAY"
        );

        if (redeemCollateralBalances[msg.sender] > 0) {
            uint256 collateralAmount = redeemCollateralBalances[msg.sender];
            redeemCollateralBalances[msg.sender] = 0;
            TransferHelper.safeTransfer(
                collateral,
                msg.sender,
                collateralAmount
            );
            unclaimedPoolCollateral =
                unclaimedPoolCollateral -
                collateralAmount;
        }
    }

    function collectDeus(
        uint256 price,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    ) external {
        require(
            sigs.length >= minimumRequiredSignatures,
            "DEIPool: INSUFFICIENT_SIGNATURES"
        );

        uint256 redeemId = nextRedeemId[msg.sender]++;

        require(
            redeemPositions[msg.sender][redeemId].timestamp +
                deusRedemptionDelay <=
                block.timestamp,
            "DEIPool: DEUS_REDEMPTION_DELAY"
        );

        {
            bytes32 hash = keccak256(
                abi.encodePacked(
                    appId,
                    msg.sender,
                    redeemId,
                    price,
                    _getChainId()
                )
            );
            require(
                IMuonV02(muon).verify(_reqId, uint256(hash), sigs),
                "DEIPool: UNVERIFIED_SIGNATURES"
            );
        }

        uint256 deusAmount = (redeemPositions[msg.sender][redeemId].amount *
            1e18) / price;

        IDEUS(deus).pool_mint(msg.sender, deusAmount);
    }

    // When the protocol is recollateralizing, we need to give a discount of DEUS to hit the new CR target
    // Thus, if the target collateral ratio is higher than the actual value of collateral, minters get DEUS for adding collateral
    // This function simply rewards anyone that sends collateral to a pool with the same amount of DEUS + the bonus rate
    // Anyone can call this function to recollateralize the protocol and take the extra DEUS value from the bonus rate as an arb opportunity
    function RecollateralizeDei(RecollateralizeDeiParams memory inputs)
        external
    {
        require(
            recollateralizePaused == false,
            "DEIPool: RECOLLATERALIZE_PAUSED"
        );

        require(
            inputs.expireBlock >= block.number,
            "DEIPool: EXPIRE_SIGNATURE"
        );
        bytes32 sighash = keccak256(
            abi.encodePacked(
                deus,
                inputs.deusPrice,
                inputs.expireBlock,
                _getChainId()
            )
        );
        require(
            IDEI(dei).verify_price(sighash, inputs.sigs),
            "DEIPool: UNVERIFIED_SIGNATURES"
        );

        uint256 collateralAmountD18 = inputs.collateralAmount *
            (10**missingDecimals);

        uint256 deiTotalSupply = IDEI(dei).totalSupply();
        uint256 globalCollateralRatio = IDEI(dei).global_collateral_ratio();
        uint256 globalCollateralValue = IDEI(dei).globalCollateralValue(
            inputs.collateralPrice
        );

        (uint256 collateralUnits, uint256 amountToRecollat) = IPoolLibrary(
            poolLibrary
        ).calcRecollateralizeDEIInner(
                collateralAmountD18,
                inputs.collateralPrice[inputs.collateralPrice.length - 1], // pool collateral price exist in last index
                globalCollateralValue,
                deiTotalSupply,
                globalCollateralRatio
            );

        uint256 collateralUnitsPrecision = collateralUnits /
            (10**missingDecimals);

        uint256 deusPaidBack = (amountToRecollat *
            (SCALE + bonusRate - recollatFee)) / inputs.deusPrice;

        TransferHelper.safeTransferFrom(
            collateral,
            msg.sender,
            address(this),
            collateralUnitsPrecision
        );
        IDEUS(deus).pool_mint(msg.sender, deusPaidBack);
    }

    // Function can be called by an DEUS holder to have the protocol buy back DEUS with excess collateral value from a desired collateral pool
    // This can also happen if the collateral ratio > 1
    function buyBackDeus(
        uint256 deusAmount,
        uint256[] memory collateralPrice,
        uint256 deusPrice,
        uint256 expireBlock,
        bytes[] calldata sigs
    ) external {
        require(buyBackPaused == false, "DEIPool: BUYBACK_PAUSED");
        require(expireBlock >= block.number, "DEIPool: EXPIRED_SIGNATURE");
        bytes32 sighash = keccak256(
            abi.encodePacked(
                collateral,
                collateralPrice,
                deus,
                deusPrice,
                expireBlock,
                _getChainId()
            )
        );
        require(
            IDEI(dei).verify_price(sighash, sigs),
            "DEIPool: UNVERIFIED_SIGNATURE"
        );

        IPoolLibrary.BuybackDeusParams memory inputParams = IPoolLibrary
            .BuybackDeusParams(
                availableExcessCollatDV(collateralPrice),
                deusPrice,
                collateralPrice[collateralPrice.length - 1], // pool collateral price exist in last index
                deusAmount
            );

        uint256 collateralEquivalentD18 = (IPoolLibrary(poolLibrary)
            .calcBuyBackDEUS(inputParams) * (SCALE - buybackFee)) / SCALE;
        uint256 collateralPrecision = collateralEquivalentD18 /
            (10**missingDecimals);

        // Give the sender their desired collateral and burn the DEUS
        IDEUS(deus).pool_burn_from(msg.sender, deusAmount);
        TransferHelper.safeTransfer(
            collateral,
            msg.sender,
            collateralPrecision
        );
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function collectDaoShare(uint256 amount, address to)
        external
        onlyRole(DAO_SHARE_COLLECTOR)
    {
        require(amount <= daoShare, "DEIPool: INVALID_AMOUNT");

        IDEI(dei).pool_mint(to, amount);
        daoShare -= amount;

        emit daoShareCollected(amount, to);
    }

    function emergencyWithdrawERC20(
        address token,
        uint256 amount,
        address to
    ) external onlyRole(TRUSTY_ROLE) {
        IERC20(token).transfer(to, amount);
    }

    function toggleMinting() external onlyRole(PAUSER_ROLE) {
        mintPaused = !mintPaused;
        emit MintingToggled(mintPaused);
    }

    function toggleRedeeming() external onlyRole(PAUSER_ROLE) {
        redeemPaused = !redeemPaused;
        emit RedeemingToggled(redeemPaused);
    }

    function toggleRecollateralize() external onlyRole(PAUSER_ROLE) {
        recollateralizePaused = !recollateralizePaused;
        emit RecollateralizeToggled(recollateralizePaused);
    }

    function toggleBuyBack() external onlyRole(PAUSER_ROLE) {
        buyBackPaused = !buyBackPaused;
        emit BuybackToggled(buyBackPaused);
    }

    // Combined into one function due to 24KiB contract memory limit
    function setPoolParameters(
        uint256 poolCeiling_,
        uint256 bonusRate_,
        uint256 collateralRedemptionDelay_,
        uint256 deusRedemptionDelay_,
        uint256 mintingFee_,
        uint256 redemptionFee_,
        uint256 buybackFee_,
        uint256 recollatFee_,
        address muon_,
        uint32 appId_,
        uint256 minimumRequiredSignatures_
    ) external onlyRole(PARAMETER_SETTER_ROLE) {
        poolCeiling = poolCeiling_;
        bonusRate = bonusRate_;
        collateralRedemptionDelay = collateralRedemptionDelay_;
        deusRedemptionDelay = deusRedemptionDelay_;
        mintingFee = mintingFee_;
        redemptionFee = redemptionFee_;
        buybackFee = buybackFee_;
        recollatFee = recollatFee_;
        muon = muon_;
        appId = appId_;
        minimumRequiredSignatures = minimumRequiredSignatures_;

        emit PoolParametersSet(
            poolCeiling_,
            bonusRate_,
            collateralRedemptionDelay_,
            deusRedemptionDelay_,
            mintingFee_,
            redemptionFee_,
            buybackFee_,
            recollatFee_,
            muon_,
            appId_,
            minimumRequiredSignatures_
        );
    }
}

//Dar panah khoda
