// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./IUniswapV3Pool.sol";
import "./OracleLibrary.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ESASXErrors.sol";
import "./IOracle.sol";

/**
 * @title Asymetrix Protocol V2 OracleEthUniswapV3 contract.
 * @author Asymetrix Protocol Inc Team
 * @notice An oracle for a token that uses Uniswap V3 pool's TWAP to price it. On of the tokens in the pool must be
 *         WETH.
 */
contract OracleEthUniswapV3 is Ownable, IOracle {
    using Address for address;

    IUniswapV3Pool private pool;
    address private weth;
    uint32 private twapPeriod;

    /**
     * @notice Deploy the OracleEthUniswapV3 contract.
     * @param _pool Uniswap V3 Pool contract address.
     * @param _weth WETH contract address.
     * @param _twapPeriod TWAP period (in seconds) that will be used to price the token.
     */
    constructor(address _pool, address _weth, uint32 _twapPeriod) {
        onlyContract(_pool);
        onlyContract(_weth);

        pool = IUniswapV3Pool(_pool);
        weth = _weth;
        twapPeriod = _twapPeriod;
    }

    /**
     * @notice Sets a new TWAP period (in seconds) by an owner.
     * @param _newTwapPeriod New TWAP period (in seconds) that will be used to price the token.
     */
    function setTwapPeriod(uint32 _newTwapPeriod) external onlyOwner {
        twapPeriod = _newTwapPeriod;
    }

    /// @inheritdoc IOracle
    function latestAnswer() external view returns (int256) {
        return getLatestAnswer();
    }

    /// @inheritdoc IOracle
    function latestRoundData()
        external
        view
        returns (uint80 _roundId, int256 _answer, uint256 _startedAt, uint256 _updatedAt, uint80 _answeredInRound)
    {
        return (0, getLatestAnswer(), block.timestamp, block.timestamp, 0);
    }

    /**
     * @notice Returns Uniswap V3 Pool address.
     * @return Uniswap V3 Pool address.
     */
    function getPool() external view returns (IUniswapV3Pool) {
        return pool;
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

    /// @inheritdoc IOracle
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /**
     * @notice Checks if an address is a contract.
     * @param _contract An address to check.
     */
    function onlyContract(address _contract) private view {
        if (!_contract.isContract()) revert ESASXErrors.NotContract();
    }

    /**
     * @notice Returns the latest answer.
     * @return The latest answer.
     */
    function getLatestAnswer() private view returns (int256) {
        IUniswapV3Pool _pool = pool;
        address _weth = weth;
        address _token0 = _pool.token0();
        address _token = _token0 == _weth ? _pool.token1() : _token0;
        (int24 _amount, ) = OracleLibrary.consult(address(_pool), twapPeriod);
        uint256 _price = OracleLibrary.getQuoteAtTick(_amount, uint128(10) ** ERC20(_token).decimals(), _token, _weth);

        return int256(_price);
    }
}
