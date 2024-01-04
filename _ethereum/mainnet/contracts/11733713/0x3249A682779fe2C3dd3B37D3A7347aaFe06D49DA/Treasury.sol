pragma solidity ^0.6.0;

import "./Math.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./IOracle.sol";
import "./IBoardroom.sol";
import "./IKlondikeAsset.sol";
import "./ISimpleERCFund.sol";
import "./Babylonian.sol";
import "./FixedPoint.sol";
import "./Safe112.sol";
import "./Operator.sol";
import "./Epoch.sol";
import "./ContractGuard.sol";

/**
 * @title KBTC Treasury contract
 * @notice Monetary policy logic to adjust supplies of KBTC assets
 * @author Summer Smith & Rick Sanchez
 */
contract Treasury is ContractGuard, Epoch {
    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using Safe112 for uint112;

    /* ========== STATE VARIABLES ========== */

    // ========== FLAGS
    bool public migrated = false;
    bool public initialized = false;

    // ========== CORE
    address public devfund;
    address public stablefund;
    address public kbtc;
    address public kbond;
    address public klon;
    address public boardroom;

    address public kbondOracle;
    address public seigniorageOracle;

    // ========== PARAMS
    uint256 public constant kbtcOneUnit = 1e18;
    uint256 public constant wbtcOneUnit = 1e8;
    uint256 public kbtcPriceCeiling; // sat / eth
    uint256 private accumulatedSeigniorage = 0;
    uint256 public devfundAllocationRate = 2; // %
    uint256 public stablefundAllocationRate = 50; // %

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _kbtc,
        address _kbond,
        address _klon,
        address _kbondOracle,
        address _seigniorageOracle,
        address _boardroom,
        address _devfund,
        address _stablefund,
        uint256 _startTime,
        uint256 _period
    ) public Epoch(_period, _startTime, 0) {
        kbtc = _kbtc;
        kbond = _kbond;
        klon = _klon;
        kbondOracle = _kbondOracle;
        seigniorageOracle = _seigniorageOracle;

        boardroom = _boardroom;
        devfund = _devfund;
        stablefund = _stablefund;

        kbtcPriceCeiling = uint256(105).mul(wbtcOneUnit).div(10**2);
    }

    /* =================== Modifier =================== */

    modifier checkMigration {
        require(!migrated, 'Treasury: migrated');

        _;
    }

    modifier checkOperator {
        require(
            IKlondikeAsset(kbtc).operator() == address(this) &&
                IKlondikeAsset(kbond).operator() == address(this) &&
                IKlondikeAsset(klon).operator() == address(this) &&
                Operator(boardroom).operator() == address(this),
            'Treasury: need more permission'
        );

        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    // budget
    function getReserve() public view returns (uint256) {
        return accumulatedSeigniorage;
    }

    // sat / eth
    function getKbondOraclePrice() public view returns (uint256) {
        return _getKBTCPrice(kbondOracle);
    }

    // sat / eth
    function getSeigniorageOraclePrice() public view returns (uint256) {
        return _getKBTCPrice(seigniorageOracle);
    }

    // sat / eth
    function _getKBTCPrice(address oracle) internal view returns (uint256) {
        try IOracle(oracle).consult(kbtc, kbtcOneUnit) returns (uint256 price) {
            return price;
        } catch {
            revert('Treasury: failed to consult kbtc price from the oracle');
        }
    }

    /* ========== GOVERNANCE ========== */

    function initialize() public checkOperator {
        require(!initialized, 'Treasury: initialized');

        // burn all of it's balance
        IKlondikeAsset(kbtc).burn(IERC20(kbtc).balanceOf(address(this)));

        // set accumulatedSeigniorage to it's balance
        accumulatedSeigniorage = IERC20(kbtc).balanceOf(address(this));

        initialized = true;
        emit Initialized(msg.sender, block.number);
    }

    function migrate(address target) public onlyOperator checkOperator {
        require(!migrated, 'Treasury: migrated');

        // kbtc
        Operator(kbtc).transferOperator(target);
        Operator(kbtc).transferOwnership(target);
        IERC20(kbtc).transfer(target, IERC20(kbtc).balanceOf(address(this)));

        // kbond
        Operator(kbond).transferOperator(target);
        Operator(kbond).transferOwnership(target);
        IERC20(kbond).transfer(target, IERC20(kbond).balanceOf(address(this)));

        // klon
        Operator(klon).transferOperator(target);
        Operator(klon).transferOwnership(target);
        IERC20(klon).transfer(target, IERC20(klon).balanceOf(address(this)));

        migrated = true;
        emit Migration(target);
    }

    function setDevFund(address newFund) public onlyOperator {
        devfund = newFund;
        emit DevFundChanged(msg.sender, newFund);
    }

    function setDevFundAllocationRate(uint256 rate) public onlyOperator {
        devfundAllocationRate = rate;
        emit DevFundRateChanged(msg.sender, rate);
    }

    function setStableFund(address newFund) public onlyOperator {
        stablefund = newFund;
        emit StableFundChanged(msg.sender, newFund);
    }

    function setStableFundAllocationRate(uint256 rate) public onlyOperator {
        stablefundAllocationRate = rate;
        emit StableFundRateChanged(msg.sender, rate);
    }

    function setKBTCPriceCeiling(uint256 percentage) public onlyOperator {
        kbtcPriceCeiling = percentage.mul(wbtcOneUnit).div(10**2);
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    function _updateKBTCPrice() internal {
        try IOracle(kbondOracle).update() {} catch {}
        try IOracle(seigniorageOracle).update() {} catch {}
    }

    function buyKbonds(uint256 amount, uint256 targetPrice)
        external
        onlyOneBlock
        checkMigration
        checkStartTime
        checkOperator
    {
        require(
            amount > 0,
            'Treasury: cannot purchase kbonds with zero amount'
        );

        uint256 kbondPrice = getKbondOraclePrice(); // sat / eth
        require(kbondPrice == targetPrice, 'Treasury: kbtc price moved');
        require(
            kbondPrice < wbtcOneUnit,
            'Treasury: kbtcPrice not eligible for kbond purchase'
        );

        IKlondikeAsset(kbtc).burnFrom(msg.sender, amount);
        IKlondikeAsset(kbond).mint(
            msg.sender,
            amount.mul(wbtcOneUnit).div(kbondPrice)
        );
        _updateKBTCPrice();

        emit BoughtKbonds(msg.sender, amount);
    }

    function redeemKbonds(uint256 amount, uint256 targetPrice)
        external
        onlyOneBlock
        checkMigration
        checkStartTime
        checkOperator
    {
        require(amount > 0, 'Treasury: cannot redeem kbonds with zero amount');

        uint256 kbtcPrice = _getKBTCPrice(kbondOracle);
        require(kbtcPrice == targetPrice, 'Treasury: kbtc price moved');
        require(
            kbtcPrice > kbtcPriceCeiling,
            'Treasury: kbtcPrice not eligible for kbond purchase'
        );
        require(
            IERC20(kbtc).balanceOf(address(this)) >= amount,
            'Treasury: treasury has no more budget'
        );

        accumulatedSeigniorage = accumulatedSeigniorage.sub(
            Math.min(accumulatedSeigniorage, amount)
        );

        IKlondikeAsset(kbond).burnFrom(msg.sender, amount);
        IERC20(kbtc).safeTransfer(msg.sender, amount);
        _updateKBTCPrice();

        emit RedeemedKbonds(msg.sender, amount);
    }

    function allocateSeigniorage()
        external
        onlyOneBlock
        checkMigration
        checkStartTime
        checkEpoch
        checkOperator
    {
        _updateKBTCPrice();
        uint256 kbtcPrice = getSeigniorageOraclePrice();
        if (kbtcPrice <= kbtcPriceCeiling) {
            return;
        }

        uint256 kbtcSupply =
            IERC20(kbtc).totalSupply().sub(accumulatedSeigniorage); //wei
        uint256 percentage = kbtcPrice.sub(wbtcOneUnit); // sat
        uint256 seigniorage = kbtcSupply.mul(percentage).div(wbtcOneUnit); // wei
        IKlondikeAsset(kbtc).mint(address(this), seigniorage);

        uint256 devfundReserve =
            seigniorage.mul(devfundAllocationRate).div(100);
        if (devfundReserve > 0) {
            IERC20(kbtc).safeApprove(devfund, devfundReserve);
            ISimpleERCFund(devfund).deposit(
                kbtc,
                devfundReserve,
                'Treasury: Seigniorage Allocation'
            );
            emit DevFundFunded(now, devfundReserve);
        }

        seigniorage = seigniorage.sub(devfundReserve);

        // fixed reserve for Bond
        uint256 treasuryReserve =
            Math.min(
                seigniorage,
                IERC20(kbond).totalSupply().sub(accumulatedSeigniorage)
            );
        if (treasuryReserve > 0) {
            accumulatedSeigniorage = accumulatedSeigniorage.add(
                treasuryReserve
            );
            emit TreasuryFunded(now, treasuryReserve);
        }

        seigniorage = seigniorage.sub(treasuryReserve);

        uint256 stablefundReserve =
            seigniorage.mul(stablefundAllocationRate).div(100);
        if (stablefundReserve > 0) {
            IERC20(kbtc).safeTransfer(stablefund, stablefundReserve);
            emit StableFundFunded(now, stablefundReserve);
        }
        seigniorage = seigniorage.sub(stablefundReserve);

        // boardroom
        uint256 boardroomReserve = seigniorage;
        if (boardroomReserve > 0) {
            IERC20(kbtc).safeApprove(boardroom, boardroomReserve);
            IBoardroom(boardroom).allocateSeigniorage(boardroomReserve);
            emit BoardroomFunded(now, boardroomReserve);
        }
    }

    // GOV
    event Initialized(address indexed executor, uint256 at);
    event Migration(address indexed target);
    event DevFundChanged(address indexed operator, address newFund);
    event DevFundRateChanged(address indexed operator, uint256 newRate);
    event StableFundChanged(address indexed operator, address newFund);
    event StableFundRateChanged(address indexed operator, uint256 newRate);

    // CORE
    event RedeemedKbonds(address indexed from, uint256 amount);
    event BoughtKbonds(address indexed from, uint256 amount);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event BoardroomFunded(uint256 timestamp, uint256 seigniorage);
    event DevFundFunded(uint256 timestamp, uint256 seigniorage);
    event StableFundFunded(uint256 timestamp, uint256 seigniorage);
}
