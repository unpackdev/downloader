// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./Math.sol";
import "./BMonTwapable.sol";
import "./IBMon.sol";
import "./IUniswapV2Helper.sol";

contract BMon is ERC20, AccessControl, BMonTwapable, IBMon {
    using SafeMath for uint256;

    // Uniswap
    address public uniswapPair;
    address public uniswapRouter;
    address public immutable uniswapV2HelperAddress;
    IUniswapV2Helper private immutable uniswapV2Helper;

    // $BMON
    bytes32 public constant BURNING_ROLE = keccak256("BURNING_ROLE");
    address public presaleAddress;
    mapping(address => uint256) public presaleParticipants;
    mapping(address => uint256) public burnedParticipants;
    bool public isInIDOPeriod = false;
    bool public isBurningActive = true;

    uint256 private constant BURN_PERCENT_SCALE = 1e9;

    // Events
    event PresaleParticipated(address indexed buyer, uint256 indexed timestamp, uint256 amount);
    event BurnAmountCalculated(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint256 burnAmount
    );


    constructor(address _uniswapV2HelperAddress) public ERC20("Battle Monster Token", "$BMON") {
        // Setup Uniswap
        uniswapV2HelperAddress = _uniswapV2HelperAddress;
        uniswapV2Helper = IUniswapV2Helper(_uniswapV2HelperAddress);

        // Setup $BMON
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BURNING_ROLE, _msgSender());
        _mint(_msgSender(), 18000 * 10 ** 18);
    }

    modifier hasAdminRole() {
        require(hasRole(DEFAULT_ADMIN_ROLE, tx.origin), "Not Authorized.");
        _;
    }

    modifier hasBurningRole() {
        require(hasRole(BURNING_ROLE, _msgSender()), "Not Authorized.");
        _;
    }

    modifier notInitialized() {
        require(!isInitialized(), "Contract Already Initialized.");
        _;
    }

    function setIdoPeriod(bool _isInIdoPeriod) external hasAdminRole {
        isInIDOPeriod = _isInIdoPeriod;
    }

    function setActiveBurning(bool _isBurningActive) external hasAdminRole {
        isBurningActive = _isBurningActive;
    }

    function isInitialized() public view returns (bool) {
        bool isPresaleAddressSet = presaleAddress != address(0);
        bool isUniswapPairSet = uniswapPair != address(0);
        bool isUniswapRouterSet = uniswapRouter != address(0);

        return isPresaleAddressSet &&
        isUniswapPairSet &&
        isUniswapRouterSet;
    }

    function initialize(
        address _presaleAddress,
        address _wethAddress
    ) external notInitialized hasAdminRole {
        // Initialize $BMON
        presaleAddress = _presaleAddress;
        _setupRole(BURNING_ROLE, presaleAddress);

        // Initialize Uniswap Twap
        (address token0, address token1) = uniswapV2Helper.sortTokens(address(this), _wethAddress);

        uniswapPair = uniswapV2Helper.pairFor(token0, token1);
        uniswapRouter = uniswapV2Helper.getRouterAddress();

        bool isBmonAddress0 = token0 == address(this);
        address oracle = uniswapV2Helper.getUniswapV2OracleAddress();

        _initializeTwap(isBmonAddress0, uniswapPair, oracle);
    }

    function initializeTwap() external hasAdminRole {
        _setListingTwap();
    }

    function logPresaleParticipants(address _recipient, uint256 _amount) external override hasBurningRole {
        presaleParticipants[_recipient] = presaleParticipants[_recipient] + _amount;

        emit PresaleParticipated(_recipient, block.timestamp, _amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        // Burning mechanism
        if (isBurningActive) {
            uint256 burningAmounts = _getBurningAmounts(sender, recipient, amount);

            if (burningAmounts > 0) {
                _burn(sender, burningAmounts);

                amount = amount.sub(burningAmounts);
            }
        }

        // Normal transfer
        super._transfer(sender, recipient, amount);
    }

    function _isUniswapTrade(
        address _sender,
        address _recipient
    ) internal view virtual returns (bool isUniswapTrade) {
        if (_sender == uniswapRouter) {
            return false;
        }

        if (_sender == uniswapPair) {
            return false;
        }

        isUniswapTrade = _recipient == uniswapPair;

        return isUniswapTrade;
    }

    function _getPresalePriceForBurningCalculation() internal view virtual returns (uint256 presalePrice) {
        return _getPresalePrice();
    }

    function _getTwapPriceForBurnCalculation() internal virtual returns (uint256 twapPrice) {
        _updateTwap();
        return currentTwap;
    }

    function _getBurningAmounts(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal returns (uint256) {
        if (_amount == 0) {
            return 0;
        }

        // Check the txn is Uniswap Trade?
        if (_isUniswapTrade(_sender, _recipient)) {
            if (presaleParticipants[_sender] > burnedParticipants[_sender]) {
                uint256 presaleShouldBurnAmount = presaleParticipants[_sender].sub(burnedParticipants[_sender]);

                uint256 _calculateAmount = Math.min(presaleShouldBurnAmount, _amount);

                burnedParticipants[_sender] = burnedParticipants[_sender].add(_calculateAmount);

                emit BurnAmountCalculated(_sender, _recipient, _amount, _calculateAmount);

                return _calculateSlashAmount(_calculateAmount);
            }
        }

        return 0;
    }

    function _calculateSlashAmount(
        uint256 _calculateAmount
    ) internal returns (uint256) {
        // Rule 1: in the IDO period - Slash 95%
        if (isInIDOPeriod) {
            return _calculateAmount.mul(95).div(100);
        }

        // Rule 2: burn by twap - Presale Token Slashing Mechanism
        uint256 presalePrice = _getPresalePriceForBurningCalculation();
        uint256 marketPrice = _getTwapPriceForBurnCalculation();

        uint256 ratio = marketPrice.mul(BURN_PERCENT_SCALE).div(presalePrice);

        if (ratio < uint256(2).mul(BURN_PERCENT_SCALE)) {
            // Slash 55%
            return _calculateAmount.mul(55).div(100);
        } else if (ratio >= uint256(2).mul(BURN_PERCENT_SCALE) && ratio <= uint256(10).mul(BURN_PERCENT_SCALE)) {
            // Slash by algorithm
            uint256 maxPercent = 61250; // 61.25
            uint256 minPercent = 5625; // 5.625

            uint256 maxPercentScaled = maxPercent.mul(BURN_PERCENT_SCALE);
            uint256 minPercentScaled = minPercent.mul(BURN_PERCENT_SCALE);

            uint256 slashPercent = maxPercentScaled.sub(
                minPercentScaled.mul(ratio)
            ).div(1000);

            return _calculateAmount.mul(slashPercent).div(100);
        }

        return 0;
    }
}