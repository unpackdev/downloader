pragma solidity 0.6.6;

import "./ReentrancyGuard.sol";
import "./ITetherswapFactory.sol";
import "./ITetherswapPriceOracle.sol";
import "./SafeMathTetherswap.sol";
import "./TransferHelper.sol";
import "./TetherswapPair.sol";

contract TetherswapFactory is ITetherswapFactory, ReentrancyGuard {
    using SafeMathTetherswap for uint256;

    address public immutable override USDT;
    address public immutable override WETH;
    address public immutable override YFTE;

    address public override governance;
    address public override treasury;
    address public override priceOracle;
    uint256 public override usdtListingFeeInUsd;
    uint256 public override wethListingFeeInUsd;
    uint256 public override yfteListingFeeInUsd;
    uint256 public override treasuryListingFeeShare = 1000000;
    uint256 public override minListingLockupAmountInUsd;
    uint256 public override targetListingLockupAmountInUsd;
    uint256 public override minListingLockupPeriod;
    uint256 public override targetListingLockupPeriod;
    uint256 public override lockupAmountListingFeeDiscountShare;
    uint256 public override defaultUsdtTradingFeePercent = 2500; // 0.2500%
    uint256 public override defaultNonUsdtTradingFeePercent = 3000; // 0.3000%
    uint256 public override treasuryProtocolFeeShare = 1000000; // 100%
    uint256 public override protocolFeeFractionInverse; // protocol fee off initially
    uint256 public override maxSlippagePercent;
    uint256 public override maxSlippageBlocks = 1;

    mapping(address => mapping(address => address)) public override getPair;
    mapping(address => mapping(address => bool)) public override approvedPair;
    address[] public override allPairs;

    modifier onlyGovernance() {
        require(msg.sender == governance);
        _;
    }

    constructor(
        address _governance,
        address _treasury,
        address _priceOracle,
        uint256 _usdtListingFeeInUsd,
        uint256 _wethListingFeeInUsd,
        uint256 _yfteListingFeeInUsd,
        uint256 _treasuryListingFeeShare,
        uint256 _minListingLockupAmountInUsd,
        uint256 _targetListingLockupAmountInUsd,
        uint256 _minListingLockupPeriod,
        uint256 _targetListingLockupPeriod,
        uint256 _lockupAmountListingFeeDiscountShare,
        address _usdtToken,
        address _WETH,
        address _yfteToken
    ) public {
        governance = _governance;
        treasury = _treasury;
        priceOracle = _priceOracle;
        usdtListingFeeInUsd = _usdtListingFeeInUsd;
        wethListingFeeInUsd = _wethListingFeeInUsd;
        yfteListingFeeInUsd = _yfteListingFeeInUsd;
        treasuryListingFeeShare = _treasuryListingFeeShare;
        _setTargetListingLockupAmountInUsd(_targetListingLockupAmountInUsd);
        _setMinListingLockupAmountInUsd(_minListingLockupAmountInUsd);
        _setTargetListingLockupPeriod(_targetListingLockupPeriod);
        _setMinListingLockupPeriod(_minListingLockupPeriod);
        lockupAmountListingFeeDiscountShare = _lockupAmountListingFeeDiscountShare;
        USDT = _usdtToken;
        WETH = _WETH;
        YFTE = _yfteToken;
    }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    function _validatePair(address tokenA, address tokenB)
        private
        view
        returns (address token0, address token1)
    {
        require(tokenA != tokenB);
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0));
        require(getPair[token0][token1] == address(0)); // single check is sufficient
    }

    function _createPair(address token0, address token1)
        private
        returns (address pair)
    {
        {
            bytes memory bytecode = type(TetherswapPair).creationCode;
            bytes32 salt = keccak256(abi.encodePacked(token0, token1));
            assembly {
                pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
            }
        }
        TetherswapPair(pair).initialize(
            token0,
            token1,
            token0 == address(USDT) || token1 == address(USDT)
                ? defaultUsdtTradingFeePercent
                : defaultNonUsdtTradingFeePercent
        );
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function approvePairViaGovernance(address tokenA, address tokenB)
        external
        override
        onlyGovernance
        nonReentrant
    {
        (address token0, address token1) = _validatePair(tokenA, tokenB);
        approvedPair[token0][token1] = true;
    }

    function _payListingFee(
        address listingFeeToken,
        uint256 lockupAmountInUsd,
        uint256 lockupPeriod
    ) private {
        require(
            listingFeeToken == USDT ||
                listingFeeToken == WETH ||
                listingFeeToken == YFTE
        );
        uint256 listingFeeTokenAmount;
        if (listingFeeToken == USDT) {
            listingFeeTokenAmount = ITetherswapPriceOracle(priceOracle)
                .calculateTokenAmountFromUsdAmount(USDT, usdtListingFeeInUsd);
        } else if (listingFeeToken == WETH) {
            listingFeeTokenAmount = ITetherswapPriceOracle(priceOracle)
                .calculateTokenAmountFromUsdAmount(WETH, wethListingFeeInUsd);
        } else if (listingFeeToken == YFTE) {
            ITetherswapPriceOracle(priceOracle).update();
            listingFeeTokenAmount = ITetherswapPriceOracle(priceOracle)
                .calculateTokenAmountFromUsdAmount(YFTE, yfteListingFeeInUsd);
        }
        uint256 discount;
        if (targetListingLockupAmountInUsd > minListingLockupAmountInUsd) {
            discount =
                lockupAmountListingFeeDiscountShare.mul(
                    lockupAmountInUsd.sub(minListingLockupAmountInUsd)
                ) /
                (
                    targetListingLockupAmountInUsd.sub(
                        minListingLockupAmountInUsd
                    )
                );
        }
        if (targetListingLockupPeriod > minListingLockupPeriod) {
            discount = discount.add(
                (uint256(1000000).sub(lockupAmountListingFeeDiscountShare)).mul(
                    lockupPeriod.sub(minListingLockupPeriod)
                ) / (targetListingLockupPeriod.sub(minListingLockupPeriod))
            );
        }
        uint256 discountedListingFeeTokenAmount =
            listingFeeTokenAmount.mul(uint256(1000000).sub(discount)) / 1000000;
        TransferHelper.safeTransferFrom(
            listingFeeToken,
            msg.sender,
            treasury,
            discountedListingFeeTokenAmount.mul(treasuryListingFeeShare) /
                1000000
        );
        TransferHelper.safeTransferFrom(
            listingFeeToken,
            msg.sender,
            governance,
            discountedListingFeeTokenAmount.mul(
                uint256(1000000).sub(treasuryListingFeeShare)
            ) / 1000000
        );
    }

    function createPair(
        address newToken,
        uint256 newTokenAmount,
        address lockupToken, // USDT or WETH, or part of a governance-approved pair
        uint256 lockupTokenAmount,
        uint256 lockupPeriod,
        address listingFeeToken // can be zero address if governance-approved pair
    ) external override nonReentrant returns (address pair) {
        require(msg.sender != governance);
        require(newToken != address(0) && lockupToken != address(0));
        (address token0, address token1) = _validatePair(newToken, lockupToken);
        if (!approvedPair[token0][token1]) {
            require(
                lockupToken == USDT || lockupToken == WETH,
                "TetherswapFactory: Pair Not Approved."
            );
            require(lockupPeriod >= minListingLockupPeriod);
            uint256 lockupAmountInUsd =
                ITetherswapPriceOracle(priceOracle)
                    .calculateUsdAmountFromTokenAmount(
                    lockupToken,
                    lockupTokenAmount
                );
            require(lockupAmountInUsd >= minListingLockupAmountInUsd);
            _payListingFee(listingFeeToken, lockupAmountInUsd, lockupPeriod);
        }
        pair = _createPair(token0, token1);
        uint256 liquidity;
        if (newTokenAmount > 0 && lockupTokenAmount > 0) {
            TransferHelper.safeTransferFrom(
                newToken,
                msg.sender,
                pair,
                newTokenAmount
            );
            TransferHelper.safeTransferFrom(
                lockupToken,
                msg.sender,
                pair,
                lockupTokenAmount
            );
            liquidity = TetherswapPair(pair).mint(msg.sender);
        }
        if (
            !approvedPair[token0][token1] &&
            lockupTokenAmount > 0 &&
            lockupPeriod > 0
        ) {
            TetherswapPair(pair).listingLock(
                msg.sender,
                lockupPeriod,
                liquidity
            );
        }
    }

    function setPriceOracle(address _priceOracle)
        external
        override
        onlyGovernance
    {
        priceOracle = _priceOracle;
    }

    function setTreasury(address _treasury) external override onlyGovernance {
        treasury = _treasury;
    }

    function setGovernance(address _governance)
        external
        override
        onlyGovernance
    {
        require(_governance != address(0));
        governance = _governance;
    }

    function setTreasuryProtocolFeeShare(uint256 _treasuryProtocolFeeShare)
        external
        override
        onlyGovernance
    {
        require(_treasuryProtocolFeeShare <= 1000000);
        treasuryProtocolFeeShare = _treasuryProtocolFeeShare;
    }

    function setProtocolFeeFractionInverse(uint256 _protocolFeeFractionInverse)
        external
        override
        onlyGovernance
    {
        // max 50% of trading fee (2/1 * 1000)
        require(
            _protocolFeeFractionInverse >= 2000 ||
                _protocolFeeFractionInverse == 0
        );
        protocolFeeFractionInverse = _protocolFeeFractionInverse;
    }

    function setUsdtListingFeeInUsd(uint256 _usdtListingFeeInUsd)
        external
        override
        onlyGovernance
    {
        usdtListingFeeInUsd = _usdtListingFeeInUsd;
    }

    function setWethListingFeeInUsd(uint256 _wethListingFeeInUsd)
        external
        override
        onlyGovernance
    {
        wethListingFeeInUsd = _wethListingFeeInUsd;
    }

    function setYfteListingFeeInUsd(uint256 _yfteListingFeeInUsd)
        external
        override
        onlyGovernance
    {
        yfteListingFeeInUsd = _yfteListingFeeInUsd;
    }

    function setTreasuryListingFeeShare(uint256 _treasuryListingFeeShare)
        external
        override
        onlyGovernance
    {
        require(_treasuryListingFeeShare <= 1000000);
        treasuryListingFeeShare = _treasuryListingFeeShare;
    }

    function _setMinListingLockupAmountInUsd(
        uint256 _minListingLockupAmountInUsd
    ) private {
        require(_minListingLockupAmountInUsd <= targetListingLockupAmountInUsd);
        if (_minListingLockupAmountInUsd > 0) {
            // needs to be at least 1000 due to TetherswapPair MINIMUM_LIQUIDITY subtraction
            require(_minListingLockupAmountInUsd >= 1000);
        }
        minListingLockupAmountInUsd = _minListingLockupAmountInUsd;
    }

    function setMinListingLockupAmountInUsd(
        uint256 _minListingLockupAmountInUsd
    ) external override onlyGovernance {
        _setMinListingLockupAmountInUsd(_minListingLockupAmountInUsd);
    }

    function _setTargetListingLockupAmountInUsd(
        uint256 _targetListingLockupAmountInUsd
    ) private {
        require(_targetListingLockupAmountInUsd >= minListingLockupAmountInUsd);
        targetListingLockupAmountInUsd = _targetListingLockupAmountInUsd;
    }

    function setTargetListingLockupAmountInUsd(
        uint256 _targetListingLockupAmountInUsd
    ) external override onlyGovernance {
        _setTargetListingLockupAmountInUsd(_targetListingLockupAmountInUsd);
    }

    function _setMinListingLockupPeriod(uint256 _minListingLockupPeriod)
        private
    {
        require(_minListingLockupPeriod <= targetListingLockupPeriod);
        minListingLockupPeriod = _minListingLockupPeriod;
    }

    function setMinListingLockupPeriod(uint256 _minListingLockupPeriod)
        external
        override
        onlyGovernance
    {
        _setMinListingLockupPeriod(_minListingLockupPeriod);
    }

    function _setTargetListingLockupPeriod(uint256 _targetListingLockupPeriod)
        private
    {
        require(_targetListingLockupPeriod >= minListingLockupPeriod);
        targetListingLockupPeriod = _targetListingLockupPeriod;
    }

    function setTargetListingLockupPeriod(uint256 _targetListingLockupPeriod)
        external
        override
        onlyGovernance
    {
        _setTargetListingLockupPeriod(_targetListingLockupPeriod);
    }

    function setLockupAmountListingFeeDiscountShare(
        uint256 _lockupAmountListingFeeDiscountShare
    ) external override onlyGovernance {
        require(_lockupAmountListingFeeDiscountShare <= 1000000);
        lockupAmountListingFeeDiscountShare = _lockupAmountListingFeeDiscountShare;
    }

    function setDefaultUsdtTradingFeePercent(
        uint256 _defaultUsdtTradingFeePercent
    ) external override onlyGovernance {
        // max 1%
        require(_defaultUsdtTradingFeePercent <= 10000);
        defaultUsdtTradingFeePercent = _defaultUsdtTradingFeePercent;
    }

    function setDefaultNonUsdtTradingFeePercent(
        uint256 _defaultNonUsdtTradingFeePercent
    ) external override onlyGovernance {
        // max 1%
        require(_defaultNonUsdtTradingFeePercent <= 10000);
        defaultNonUsdtTradingFeePercent = _defaultNonUsdtTradingFeePercent;
    }

    function setMaxSlippagePercent(uint256 _maxSlippagePercent)
        external
        override
        onlyGovernance
    {
        // max 100%
        require(_maxSlippagePercent <= 100);
        maxSlippagePercent = _maxSlippagePercent;
    }

    function setMaxSlippageBlocks(uint256 _maxSlippageBlocks)
        external
        override
        onlyGovernance
    {
        // min 1 block, max 7 days (15s/block)
        require(_maxSlippageBlocks >= 1 && _maxSlippageBlocks <= 40320);
        maxSlippageBlocks = _maxSlippageBlocks;
    }
}
