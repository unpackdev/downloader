pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



import "./IERC20.sol";
import "./ITwapDelay.sol";
import "./ITwapFactory.sol";
import "./ITwapFactoryGovernor.sol";
import "./ITwapPair.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./ITwapFactoryGovernorInitializable.sol";

contract TwapFactoryGovernor is ITwapFactoryGovernor, ITwapFactoryGovernorInitializable {
    using SafeMath for uint256;

    uint256 private constant PROTOCOL_FEE_RATIO_PRECISION = 1e10;
    uint256 private constant DEFAULT_PROTOCOL_FEE_RATIO = PROTOCOL_FEE_RATIO_PRECISION; // 100%

    /*
     * DO NOT CHANGE THE BELOW STATE VARIABLES.
     * REMOVING, REORDERING OR INSERTING STATE VARIABLES WILL CAUSE STORAGE COLLISION.
     * NEW VARIABLES SHOULD BE ADDED BELOW THESE VARIABLES TO AVOID STORAGE COLLISION.
     */
    uint8 public initialized;
    address public override owner;
    address public override factory;
    address public override delay;
    uint256 public override protocolFeeRatio;
    uint256 public override ethTransferCost;

    // This contract implements a proxy pattern.
    // The constructor is to set to prevent abuse of this implementation contract.
    constructor() {
        owner = msg.sender;
        initialized = 1;
    }

    // This function should be called through the proxy contract to initialize the proxy contract's storage.
    function initialize(address _factory) external override {
        require(initialized == 0, 'FG5B');
        initialized = 1;

        _setOwner(msg.sender);
        _setFactory(_factory);
        _setProtocolFeeRatio(DEFAULT_PROTOCOL_FEE_RATIO);
        _setEthTransferCost(Orders.ETHER_TRANSFER_COST);

        emit Initialized(_factory);
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner, 'FG00');

        _setOwner(_owner);
    }

    function _setOwner(address _owner) internal {
        require(_owner != owner, 'FG01');
        require(_owner != address(0), 'FG02');

        owner = _owner;

        emit OwnerSet(_owner);
    }

    function setFactoryOwner(address _factoryOwner) external override {
        require(msg.sender == owner, 'FG00');

        ITwapFactory(factory).setOwner(_factoryOwner);
    }

    function setFactory(address _factory) external override {
        require(msg.sender == owner, 'FG00');

        _setFactory(_factory);
    }

    function _setFactory(address _factory) internal {
        require(_factory != factory, 'FG01');
        require(_factory != address(0), 'FG02');

        factory = _factory;

        emit FactorySet(_factory);
    }

    function setDelay(address _delay) external override {
        require(msg.sender == owner, 'FG00');
        require(_delay != delay, 'FG01');
        require(_delay != address(0), 'FG02');

        delay = _delay;

        emit DelaySet(_delay);
    }

    function setProtocolFeeRatio(uint256 _protocolFeeRatio) external override {
        require(msg.sender == owner, 'FG00');

        _setProtocolFeeRatio(_protocolFeeRatio);
    }

    function _setProtocolFeeRatio(uint256 _protocolFeeRatio) internal {
        require(_protocolFeeRatio != protocolFeeRatio, 'FG01');
        require(_protocolFeeRatio <= PROTOCOL_FEE_RATIO_PRECISION, 'FG54');

        protocolFeeRatio = _protocolFeeRatio;

        emit ProtocolFeeRatioSet(_protocolFeeRatio);
    }

    function setEthTransferCost(uint256 _ethTransferCost) external override {
        require(msg.sender == owner, 'FG00');

        _setEthTransferCost(_ethTransferCost);
    }

    function _setEthTransferCost(uint256 _ethTransferCost) internal {
        require(_ethTransferCost != ethTransferCost, 'FG01');

        ethTransferCost = _ethTransferCost;

        emit EthTransferCostSet(_ethTransferCost);
    }

    function createPair(
        address tokenA,
        address tokenB,
        address oracle,
        address trader
    ) external override returns (address) {
        require(msg.sender == owner, 'FG00');

        return ITwapFactory(factory).createPair(tokenA, tokenB, oracle, trader);
    }

    function getPair(address token0, address token1) external view override returns (address) {
        return ITwapFactory(factory).getPair(token0, token1);
    }

    function allPairs(uint256 pairId) external view override returns (address) {
        return ITwapFactory(factory).allPairs(pairId);
    }

    function allPairsLength() external view override returns (uint256) {
        return ITwapFactory(factory).allPairsLength();
    }

    function setMintFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external override {
        require(msg.sender == owner, 'FG00');

        return ITwapFactory(factory).setMintFee(tokenA, tokenB, fee);
    }

    function setBurnFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external override {
        require(msg.sender == owner, 'FG00');

        return ITwapFactory(factory).setBurnFee(tokenA, tokenB, fee);
    }

    function setSwapFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external override {
        require(msg.sender == owner, 'FG00');

        return ITwapFactory(factory).setSwapFee(tokenA, tokenB, fee);
    }

    function setOracle(
        address tokenA,
        address tokenB,
        address oracle
    ) external override {
        require(msg.sender == owner, 'FG00');

        return ITwapFactory(factory).setOracle(tokenA, tokenB, oracle);
    }

    function setTrader(
        address tokenA,
        address tokenB,
        address trader
    ) external override {
        require(msg.sender == owner, 'FG00');

        return ITwapFactory(factory).setTrader(tokenA, tokenB, trader);
    }

    function collectFees(
        address tokenA,
        address tokenB,
        address to
    ) external override {
        require(msg.sender == owner, 'FG00');

        ITwapDelay(delay).syncPair(tokenA, tokenB);

        return ITwapFactory(factory).collect(tokenA, tokenB, to);
    }

    function withdrawToken(
        address token,
        uint256 amount,
        address to
    ) external override {
        require(msg.sender == owner, 'FG00');
        require(to != address(0), 'FG02');

        if (token == Orders.NATIVE_CURRENCY_SENTINEL) {
            TransferHelper.safeTransferETH(to, amount, ethTransferCost);
        } else {
            TransferHelper.safeTransfer(token, to, amount);
        }

        emit WithdrawToken(token, to, amount);
    }

    function distributeFees(address tokenA, address tokenB) external override {
        require(msg.sender == owner, 'FG00');

        address pairAddress = ITwapDelay(delay).syncPair(tokenA, tokenB);
        _distributeFees(tokenA, tokenB, pairAddress);
    }

    function distributeFees(
        address tokenA,
        address tokenB,
        address pairAddress
    ) external override {
        require(msg.sender == delay, 'FG00');

        _distributeFees(tokenA, tokenB, pairAddress);
    }

    /// @dev The caller should update the reserves and fees on the pair (by using `ITwapPair.sync`) before calling this function.
    function _distributeFees(
        address tokenA,
        address tokenB,
        address pairAddress
    ) private {
        uint256 tokenABalance = IERC20(tokenA).balanceOf(address(this));
        uint256 tokenBBalance = IERC20(tokenB).balanceOf(address(this));
        ITwapFactory(factory).collect(tokenA, tokenB, address(this));
        uint256 tokenACollectedFee = IERC20(tokenA).balanceOf(address(this)).sub(tokenABalance);
        uint256 tokenBCollectedFee = IERC20(tokenB).balanceOf(address(this)).sub(tokenBBalance);

        if (tokenACollectedFee > 0) {
            _distributeFee(tokenA, pairAddress, tokenACollectedFee);
        }
        if (tokenBCollectedFee > 0) {
            _distributeFee(tokenB, pairAddress, tokenBCollectedFee);
        }
    }

    function _distributeFee(
        address token,
        address pairAddress,
        uint256 amount
    ) private {
        uint256 protocolAmount = amount.mul(protocolFeeRatio).div(PROTOCOL_FEE_RATIO_PRECISION);
        uint256 lpAmount = amount.sub(protocolAmount);

        if (lpAmount > 0) {
            TransferHelper.safeTransfer(token, pairAddress, lpAmount);
        }

        emit FeeDistributed(token, pairAddress, lpAmount, protocolAmount);
    }

    function feesToDistribute(address tokenA, address tokenB)
        external
        view
        override
        returns (uint256 fee0ToDistribute, uint256 fee1ToDistribute)
    {
        address pairAddress = ITwapFactory(factory).getPair(tokenA, tokenB);
        require(pairAddress != address(0), 'FG17');
        (uint256 fee0, uint256 fee1) = ITwapPair(pairAddress).getFees();

        uint256 protocolFee0 = fee0.mul(protocolFeeRatio).div(PROTOCOL_FEE_RATIO_PRECISION);
        fee0ToDistribute = fee0.sub(protocolFee0);
        uint256 protocolFee1 = fee1.mul(protocolFeeRatio).div(PROTOCOL_FEE_RATIO_PRECISION);
        fee1ToDistribute = fee1.sub(protocolFee1);
    }

    function withdrawLiquidity(
        address tokenA,
        address tokenB,
        uint256 amount,
        address to
    ) external override {
        require(msg.sender == owner, 'FG00');

        ITwapDelay(delay).syncPair(tokenA, tokenB);

        return ITwapFactory(factory).withdraw(tokenA, tokenB, amount, to);
    }
}
