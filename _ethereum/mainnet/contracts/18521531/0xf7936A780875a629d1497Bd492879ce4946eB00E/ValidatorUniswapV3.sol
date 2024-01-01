// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./INonfungiblePositionManager.sol";
import "./IUniswapV3Factory.sol";
import "./TickMath.sol";
import "./RewardsBoosterErrors.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IRewardsBooster.sol";
import "./IValidator.sol";
import "./IValuer.sol";

/**
 * @title Asymetrix Protocol V2 ValidatorUniswapV3
 * @author Asymetrix Protocol Inc Team
 * @notice A validator that validates staking parameters in time of staking in the Uniswap V3 staking pool on the
 *         RewardsBooster contract.
 */
contract ValidatorUniswapV3 is Ownable, IValidator {
    using Address for address;

    INonfungiblePositionManager private positionManager;
    IUniswapV3Factory private factory;
    IRewardsBooster private rewardsBooster;
    IValuer private valuerUniV3;

    uint256 private maxTokenDominance;

    int24 private minTick;
    int24 private maxTick;

    uint256 public constant ONE_HUNDRED_PERCENT = 10000;

    /**
     * @notice Deploy the ValidatorUniswapV3 contract.
     * @param _positionManager Uniswap V3 NonfungiblePositionManager contract address.
     * @param _factory Uniswap V3 Factory contract address.
     * @param _rewardsBooster RewardsBooster contract address.
     * @param _valuerUniV3 an address of the Uniswap V3 valuer.
     * @param _maxTick max tick allowed for the position.
     * @param _minTick min tick allowed for the position.
     * @param _maxTokenDominance max token dominance.
     */
    constructor(
        address _positionManager,
        address _factory,
        address _rewardsBooster,
        address _valuerUniV3,
        int24 _maxTick,
        int24 _minTick,
        uint256 _maxTokenDominance
    ) {
        onlyContract(_positionManager);
        onlyContract(_factory);
        onlyContract(_rewardsBooster);

        _setMaxTick(_maxTick);
        _setMinTick(_minTick);
        _setValuerUniV3(_valuerUniV3);
        _setMaxTokenDominance(_maxTokenDominance);

        positionManager = INonfungiblePositionManager(_positionManager);
        factory = IUniswapV3Factory(_factory);
        rewardsBooster = IRewardsBooster(_rewardsBooster);
    }

    /**
     * @notice Sets new max token dominance.
     * @param _maxTokenDominance new max token dominance.
     */
    function setMaxTokenDominance(uint256 _maxTokenDominance) external onlyOwner {
        _setMaxTokenDominance(_maxTokenDominance);
    }

    /**
     * @notice Sets new max tick.
     * @param _maxTick new max tick.
     */
    function setMaxTick(int24 _maxTick) external onlyOwner {
        _setMaxTick(_maxTick);
    }

    /**
     * @notice Sets new min tick.
     * @param _minTick new min tick.
     */
    function setMinTick(int24 _minTick) external onlyOwner {
        _setMinTick(_minTick);
    }

    /**
     * @notice Sets a Uniswap V3 valuer address.
     * @param _valuerUniV3 new address of the Uniswap V3 valuer.
     */
    function setValuerUniV3(address _valuerUniV3) external onlyOwner {
        _setValuerUniV3(_valuerUniV3);
    }

    /// @inheritdoc IValidator
    function validateStake(uint8 _pid, uint256 _tokenId) external view {
        INonfungiblePositionManager.Position memory _position = positionManager.positions(_tokenId);

        address _liquidityPool = factory.getPool(_position.token0, _position.token1, _position.fee);
        IRewardsBooster.Pool memory _stakingPool = rewardsBooster.getPoolInfo(_pid);

        if (_liquidityPool != _stakingPool.liquidityPool) revert RewardsBoosterErrors.InvalidStakeArguments();
        if (_position.tickLower != minTick || _position.tickUpper != maxTick) revert RewardsBoosterErrors.WrongTick();

        (uint256 _value0, uint256 _value1) = valuerUniV3.getTokenAmountsInUSD(_tokenId);

        uint256 _maxTokenDominance = maxTokenDominance;
        uint256 _totalInUSD = _value0 + _value1;
        uint256 _tokenDominance = (_value0 * ONE_HUNDRED_PERCENT) / _totalInUSD;

        if (
            _tokenDominance < (ONE_HUNDRED_PERCENT - _maxTokenDominance) ||
            _tokenDominance / _totalInUSD > _maxTokenDominance
        ) revert RewardsBoosterErrors.WrongTokensRatio();
    }

    /**
     * @notice Returns maxTick.
     * @return maxTick.
     */
    function getMaxTick() external view returns (int24) {
        return maxTick;
    }

    /**
     * @notice Returns minTick.
     * @return minTick.
     */
    function getMinTick() external view returns (int24) {
        return minTick;
    }

    /**
     * @notice Returns NonfungiblePositionManager contract address.
     * @return NonfungiblePositionManager contract address.
     */
    function getPositionManager() external view returns (INonfungiblePositionManager) {
        return positionManager;
    }

    /**
     * @notice Returns UniswapV3Factory contract address.
     * @return UniswapV3Factory contract address.
     */
    function getFactory() external view returns (IUniswapV3Factory) {
        return factory;
    }

    /**
     * @notice Returns RewardsBooster contract address.
     * @return RewardsBooster contract address.
     */
    function getRewardsBooster() external view returns (IRewardsBooster) {
        return rewardsBooster;
    }

    /**
     * @notice Private function which sets new max token dominance.
     * @param _maxTokenDominance new max token dominance.
     */
    function _setMaxTokenDominance(uint256 _maxTokenDominance) private {
        if (_maxTokenDominance > ONE_HUNDRED_PERCENT) revert RewardsBoosterErrors.WrongMaxTokenDominance();

        maxTokenDominance = _maxTokenDominance;
    }

    /**
     * @notice Private function which sets new max tick.
     * @param _maxTick new max tick.
     */
    function _setMaxTick(int24 _maxTick) private {
        if (_maxTick > TickMath.MAX_TICK || _maxTick < TickMath.MIN_TICK) revert RewardsBoosterErrors.WrongTick();

        maxTick = _maxTick;
    }

    /**
     * @notice Private function which sets new min tick.
     * @param _minTick new min tick.
     */
    function _setMinTick(int24 _minTick) private {
        if (_minTick < TickMath.MIN_TICK || _minTick > TickMath.MAX_TICK) revert RewardsBoosterErrors.WrongTick();

        minTick = _minTick;
    }

    /**
     * @notice Private function which sets a Uniswap V3 valuer address.
     * @param _valuerUniV3 new address of the Uniswap V3 valuer.
     */
    function _setValuerUniV3(address _valuerUniV3) private {
        onlyContract(_valuerUniV3);

        valuerUniV3 = IValuer(_valuerUniV3);
    }

    /**
     * @notice Checks if an address is a contract.
     * @param _contract An address to check.
     */
    function onlyContract(address _contract) private view {
        if (!_contract.isContract()) revert RewardsBoosterErrors.NotContract();
    }
}
