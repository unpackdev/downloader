pragma solidity ^0.6.0;

import "./Math.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./Babylonian.sol";
import "./FixedPoint.sol";
import "./Safe112.sol";
import "./Operator.sol";
import "./ContractGuard.sol";
import "./IStandAsset.sol";
import "./IOracle.sol";
import "./IBoardroom.sol";
import "./IUniswapV2Router02.sol";

/**
 * @title Stand Cash Treasury contract
 * @notice Monetary policy logic to adjust supplies of stand cash assets
 * @author Summer Smith & Rick Sanchez
 */
contract Treasury is ContractGuard, Operator {
    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using Safe112 for uint112;

    /* ========= CONSTANT VARIABLES ======== */

    uint256 public constant PERIOD = 1 days;
    // address public constant UIN_ROUTER = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    // address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /* ========== STATE VARIABLES ========== */

    // flags
    bool private migrated = false;
    bool private initialized = false;

    // epoch
    uint256 public startTime;
    uint256 public epoch = 0;

    // core components
    address public cash;
    address public bond;
    address public share;
    address public boardroom;
    address public cashOracle;

    // swap
    IUniswapV2Router02 public unirouter;
    address[] public path;

    // price
    uint256 public cashPriceOne;
    uint256 public cashPriceCeiling;
    uint256 public bondDepletionFloor;
    uint256 public seigniorageSaved = 0;
    uint256 public treasuryavailable = 0;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _cash,
        address _bond,
        address _share,
        address _cashOracle,
        address _boardroom,
        address _unirouter,
        uint256 _startTime
    ) public {
        cash = _cash;
        bond = _bond;
        share = _share;
        cashOracle = _cashOracle;
        boardroom = _boardroom;

        unirouter = IUniswapV2Router02(_unirouter);
        address weth = unirouter.WETH();
        path = [cash, weth];

        startTime = _startTime;

        cashPriceOne = 10**6;
        cashPriceCeiling = uint256(105).mul(cashPriceOne).div(10**2);

        bondDepletionFloor = uint256(1000).mul(cashPriceOne);
    }

    /* =================== Modifier =================== */

    modifier checkCondition {
        require(!migrated, 'Treasury: migrated');
        require(now >= startTime, 'Treasury: not started yet');

        _;
    }

    modifier checkEpoch {
        require(now >= nextEpochPoint(), 'Treasury: not opened yet');

        _;

        epoch = epoch.add(1);
    }

    modifier checkOperator {
        require(
            IStandAsset(cash).operator() == address(this) &&
                IStandAsset(bond).operator() == address(this) &&
                IStandAsset(share).operator() == address(this) &&
                Operator(boardroom).operator() == address(this),
            'Treasury: need more permission'
        );

        _;
    }

    modifier notInitialized {
        require(!initialized, 'Treasury: already initialized');

        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    // flags
    function isMigrated() public view returns (bool) {
        return migrated;
    }

    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // epoch
    function nextEpochPoint() public view returns (uint256) {
        return startTime.add(epoch.mul(PERIOD));
    }

    // oracle
    function getCashPrice() public view returns (uint256 cashPrice) {
        try IOracle(cashOracle).consult(cash, 1e18) returns (uint256 price) {
            return price;
        } catch {
            revert('Treasury: failed to consult cash price from the oracle');
        }
    }

    // budget
    function getReserve() public view returns (uint256) {
        return seigniorageSaved;
    }

    /* ========== GOVERNANCE ========== */

    function initialize() public notInitialized checkOperator {
        // burn all of it's balance
        IStandAsset(cash).burn(IERC20(cash).balanceOf(address(this)));

        // mint only 1001 cash to itself
        IStandAsset(cash).mint(address(this), 1001 ether);

        // set seigniorageSaved to it's balance
        seigniorageSaved = IERC20(cash).balanceOf(address(this));

        initialized = true;
        emit Initialized(msg.sender, block.number);
    }

    function migrate(address target) public onlyOperator checkOperator {
        require(!migrated, 'Treasury: migrated');

        // cash
        Operator(cash).transferOperator(target);
        Operator(cash).transferOwnership(target);
        IERC20(cash).transfer(target, IERC20(cash).balanceOf(address(this)));

        // bond
        Operator(bond).transferOperator(target);
        Operator(bond).transferOwnership(target);
        IERC20(bond).transfer(target, IERC20(bond).balanceOf(address(this)));

        // share
        Operator(share).transferOperator(target);
        Operator(share).transferOwnership(target);
        IERC20(share).transfer(target, IERC20(share).balanceOf(address(this)));

        migrated = true;
        emit Migration(target);
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    function _updateCashPrice() internal {
        try IOracle(cashOracle).update()  {} catch {}
    }

    function buyBonds(uint256 amount, uint256 targetPrice)
        external
        onlyOneBlock
        checkCondition
        checkOperator
    {
        require(amount > 0, 'Treasury: cannot purchase bonds with zero amount');

        uint256 cashPrice = getCashPrice();
        require(cashPrice == targetPrice, 'Treasury: cash price moved');
        require(
            cashPrice < cashPriceOne, // price < $1
            'Treasury: cashPrice not eligible for bond purchase'
        );

        uint256 bondPrice = cashPrice;

        IStandAsset(cash).burnFrom(msg.sender, amount);
        IStandAsset(bond).mint(msg.sender, amount.mul(1e6).div(bondPrice));
        _updateCashPrice();

        emit BoughtBonds(msg.sender, amount);
    }

    function redeemBonds(uint256 amount, uint256 targetPrice)
        external
        onlyOneBlock
        checkCondition
        checkOperator
    {
        require(amount > 0, 'Treasury: cannot redeem bonds with zero amount');

        uint256 cashPrice = getCashPrice();
        require(cashPrice == targetPrice, 'Treasury: cash price moved');
        require(
            cashPrice > cashPriceCeiling, // price > $1.05
            'Treasury: cashPrice not eligible for bond purchase'
        );
        require(
            IERC20(cash).balanceOf(address(this)) >= amount,
            'Treasury: treasury has no more budget'
        );

        seigniorageSaved = seigniorageSaved.sub(
            Math.min(seigniorageSaved, amount)
        );

        IStandAsset(bond).burnFrom(msg.sender, amount);
        IERC20(cash).safeTransfer(msg.sender, amount);
        _updateCashPrice();

        emit RedeemedBonds(msg.sender, amount);
    }

    function allocateSeigniorage()
        external
        onlyOneBlock
        checkCondition
        checkEpoch
        checkOperator
    {
        _updateCashPrice();
        uint256 cashPrice = getCashPrice();
        require(
            cashPrice > cashPriceCeiling,
            'Treasury: there is no seigniorage to be allocated'
        );

        uint256 cashSupply = IERC20(cash).totalSupply().sub(seigniorageSaved);
        uint256 percentage = cashPrice.sub(cashPriceOne);
        uint256 seigniorage = cashSupply.mul(percentage).div(1e6);

        if (seigniorageSaved.div(1e18) > bondDepletionFloor.div(1e6)) {
            IStandAsset(cash).mint(address(this), seigniorage);
            uint112 reserveInLp = IOracle(cashOracle).getReserves(cash);

            uint reserve = seigniorage.div(10);
            uint forTrade = Math.min(reserve, uint(reserveInLp).div(2));
            IERC20(cash).safeApprove(address(unirouter), forTrade);
            try unirouter.swapExactTokensForETH(forTrade, 0, path, address(this), now.add(1800)) {
            } catch {
                IStandAsset(cash).burn(forTrade);
            }

            uint leftover = reserve.sub(forTrade);
            treasuryavailable = treasuryavailable.add(leftover);

            uint remain = seigniorage.mul(90).div(100);
            IERC20(cash).safeApprove(boardroom, remain);
            IBoardroom(boardroom).allocateSeigniorage(remain);
            emit BoardroomFunded(now, remain);
        } else {
            seigniorageSaved = seigniorageSaved.add(seigniorage);
            IStandAsset(cash).mint(address(this), seigniorage);
            emit TreasuryFunded(now, seigniorage);
        }
    }

    function handleReserve(address payable account, uint256 amount)
        external
        onlyOperator
    {
        require(
            address(this).balance >= amount,
            "Treasury: balance not enough"
        );
        account.transfer(amount);
    }

    function withdrawTreasuryKeeped(address _to, uint _amount)
        external
        onlyOperator
    {
        uint max = IERC20(cash).balanceOf(address(this));
        require(_amount <= max, "Treasury: !exceeds total balance");
        require(_amount <= treasuryavailable, "Treasury: !exceeds avaiable");
        treasuryavailable = treasuryavailable.sub(_amount);
        IERC20(cash).safeTransfer(_to, _amount);
    }

    function setPath(address[] calldata _path)
        external
        onlyOperator
    {
        path = _path;
    }

    receive() external payable {}

    event Initialized(address indexed executor, uint256 at);
    event Migration(address indexed target);
    event RedeemedBonds(address indexed from, uint256 amount);
    event BoughtBonds(address indexed from, uint256 amount);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event BoardroomFunded(uint256 timestamp, uint256 seigniorage);
}
