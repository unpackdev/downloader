// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./IUniswapV3Pool.sol";
import "./OracleLibrary.sol";
import "./RewardsBoosterErrors.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IOracle.sol";

/**
 * @title Asymetrix Protocol V2 OracleUniswapV3
 * @author Asymetrix Protocol Inc Team
 * @notice An oracle for a token that uses Uniswap V3 pool's TWAP to price it. One of the tokens in the pool must be
 *         WETH.
 */
contract OracleUniswapV3 is Ownable, IOracle {
    using Address for address;

    IUniswapV3Pool private pool;
    IOracle private ethOracle;
    address private weth;
    uint32 private twapPeriod;
    uint32 private validityDuration;

    /**
     * @notice Deploy the OracleUniswapV3 contract.
     * @param _pool Uniswap V3 Pool contract address.
     * @param _ethOracle ETH Oracle contract address.
     * @param _weth WETH contract address.
     * @param _twapPeriod TWAP period (in seconds) that will be used to price the token.
     * @param _validityDuration A duration (in seconds) during which the latest answer from the Chainlink oracle is
     *                          valid.
     */
    constructor(address _pool, address _ethOracle, address _weth, uint32 _twapPeriod, uint32 _validityDuration) {
        onlyContract(_pool);
        onlyContract(_ethOracle);
        onlyContract(_weth);

        pool = IUniswapV3Pool(_pool);
        ethOracle = IOracle(_ethOracle);
        weth = _weth;
        twapPeriod = _twapPeriod;

        setNewValidityDuration(_validityDuration);
    }

    /**
     * @notice Sets a new TWAP period (in seconds) by an owner.
     * @param _newTwapPeriod New TWAP period (in seconds) that will be used to price the token.
     */
    function setTwapPeriod(uint32 _newTwapPeriod) external onlyOwner {
        twapPeriod = _newTwapPeriod;
    }

    /**
     * @notice Sets a new validity duration (in seconds) by an owner.
     * @param _newValidityDuration A new duration (in seconds) during which the latest answer from the Chainlink oracle
     *                             is valid.
     */
    function setValidityDuration(uint32 _newValidityDuration) external onlyOwner {
        setNewValidityDuration(_newValidityDuration);
    }

    /// @inheritdoc IOracle
    function latestAnswer() external view returns (int256) {
        return getLatestAnswer(twapPeriod);
    }

    /**
     * @notice Returns the latest answer.
     * @param _twapPeriod TWAP period that will be used to calculate latest answer.
     * @return The latest answer.
     */
    function latestAnswer(uint32 _twapPeriod) external view returns (int256) {
        return getLatestAnswer(_twapPeriod);
    }

    /// @inheritdoc IOracle
    function latestRoundData()
        external
        view
        returns (uint80 _roundId, int256 _answer, uint256 _startedAt, uint256 _updatedAt, uint80 _answeredInRound)
    {
        return (0, getLatestAnswer(twapPeriod), block.timestamp, block.timestamp, 0);
    }

    /**
     * @notice Returns Uniswap V3 Pool address.
     * @return Uniswap V3 Pool address.
     */
    function getPool() external view returns (IUniswapV3Pool) {
        return pool;
    }

    /**
     * @notice Returns ETH Oracle address.
     * @return ETH Oracle address.
     */
    function getEthOracle() external view returns (IOracle) {
        return ethOracle;
    }

    /**
     * @notice Returns WETH token address.
     * @return WETH token address.
     */
    function getWeth() external view returns (address) {
        return weth;
    }

    /**
     * @notice Returns TWAP period in seconds.
     * @return TWAP period in seconds.
     */
    function getTwapPeriod() external view returns (uint32) {
        return twapPeriod;
    }

    /**
     * @notice Returns validity duration in seconds.
     * @return Validity duration in seconds.
     */
    function getValidityDuration() external view returns (uint32) {
        return validityDuration;
    }

    /// @inheritdoc IOracle
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /**
     * @notice Sets a new validity duration (in seconds).
     * @param _newValidityDuration A new duration (in seconds) during which the latest answer from the Chainlink oracle
     *                             is valid.
     */
    function setNewValidityDuration(uint32 _newValidityDuration) private {
        if (_newValidityDuration == 0) revert RewardsBoosterErrors.WrongValidityDuration();

        validityDuration = _newValidityDuration;
    }

    /**
     * @notice Checks if an address is a contract.
     * @param _contract An address to check.
     */
    function onlyContract(address _contract) private view {
        if (!_contract.isContract()) revert RewardsBoosterErrors.NotContract();
    }

    /**
     * @notice Returns the latest answer.
     * @param _twapPeriod TWAP period that will be used to calculate latest answer.
     * @return The latest answer.
     */
    function getLatestAnswer(uint32 _twapPeriod) private view returns (int256) {
        IOracle _ethOracle = ethOracle;
        (, int256 _answer, , uint256 _updatedAt, ) = _ethOracle.latestRoundData();

        if (block.timestamp - _updatedAt > validityDuration) revert RewardsBoosterErrors.StalePrice();

        IUniswapV3Pool _pool = pool;
        address _weth = weth;
        address _token0 = _pool.token0();
        address _token = _token0 == _weth ? _pool.token1() : _token0;
        (int24 _amount, ) = OracleLibrary.consult(address(_pool), _twapPeriod);
        uint256 _price = OracleLibrary.getQuoteAtTick(_amount, uint128(10) ** ERC20(_token).decimals(), _token, _weth);

        return (int256(_price) * _answer) / int256(10 ** _ethOracle.decimals());
    }
}
