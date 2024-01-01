// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./RewardsBoosterErrors.sol";
import "./IERC20.sol";
import "./IVault.sol";
import "./IPool.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IOracle.sol";

/**
 * @title Asymetrix Protocol V2 OracleBalancerWeighted
 * @author Asymetrix Protocol Inc Team
 * @notice An oracle for a token that uses Balancer weighted pool to price it. Only pools with 2 tokens are supported by
 *         this oracle. One of them must be WETH.
 */
contract OracleBalancerWeighted is Ownable, IOracle {
    using Address for address;

    IVault private vault;
    IPool private pool;
    IOracle private ethOracle;
    uint256 private tokenIndex;
    uint256 private wethIndex;
    uint32 private validityDuration;

    /**
     * @notice Deploy the OracleBalancerWeighted contract.
     * @param _vault Balancer Vault contract address.
     * @param _pool Balancer Pool contract address.
     * @param _ethOracle ETH Oracle contract address.
     * @param _validityDuration A duration (in seconds) during which the latest answer from the Chainlink oracle is
     *                          valid.
     */
    constructor(address _vault, address _pool, address _ethOracle, address _weth, uint32 _validityDuration) {
        onlyContract(_vault);
        onlyContract(_pool);
        onlyContract(_ethOracle);
        onlyContract(_weth);

        vault = IVault(_vault);
        pool = IPool(_pool);
        ethOracle = IOracle(_ethOracle);

        setNewValidityDuration(_validityDuration);

        (IERC20[] memory _tokens, , ) = vault.getPoolTokens(pool.getPoolId());

        if (_tokens.length > 2) revert RewardsBoosterErrors.WrongBalancerPoolTokensNumber();

        address(_tokens[0]) == _weth ? tokenIndex = 1 : wethIndex = 1;
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
     * @notice Returns Balancer Vault address.
     * @return Balancer Vault address.
     */
    function getVault() external view returns (IVault) {
        return vault;
    }

    /**
     * @notice Returns Balancer Pool address.
     * @return Balancer Pool address.
     */
    function getPool() external view returns (IPool) {
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
     * @return The latest answer.
     */
    function getLatestAnswer() private view returns (int256) {
        IOracle _ethOracle = ethOracle;
        (, int256 _answer, , uint256 _updatedAt, ) = _ethOracle.latestRoundData();

        if (block.timestamp - _updatedAt > validityDuration) revert RewardsBoosterErrors.StalePrice();

        uint256 _ethPrice = (uint256(_answer) * 1e18) / 10 ** _ethOracle.decimals();
        IPool _pool = pool;
        (, uint256[] memory _balances, ) = vault.getPoolTokens(_pool.getPoolId());
        uint256[] memory _weights = _pool.getNormalizedWeights();
        uint256 _tokenIndex = tokenIndex;
        uint256 _wethIndex = wethIndex;
        uint256 _tokenPrice = (((_balances[_tokenIndex] * 1e18) / _weights[_tokenIndex]) * 1e18) /
            ((_balances[_wethIndex] * 1e18) / _weights[_wethIndex]);

        return int256((_ethPrice * 1e18) / _tokenPrice);
    }
}
