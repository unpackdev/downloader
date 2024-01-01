// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./IERC20.sol";
import "./IVault.sol";
import "./IPool.sol";
import "./Address.sol";
import "./ESASXErrors.sol";
import "./IOracle.sol";

/**
 * @title Asymetrix Protocol V2 OracleEthBalancerWeighted contract.
 * @author Asymetrix Protocol Inc Team
 * @notice An oracle for a token that uses Balancer weighted pool to price it. nly pools with 2 tokens are supported by
 *         this oracle. One of them must be WETH.
 */
contract OracleEthBalancerWeighted is IOracle {
    using Address for address;

    IVault private vault;
    IPool private pool;
    uint256 private tokenIndex;
    uint256 private wethIndex;

    /**
     * @notice Deploy the OracleEthBalancerWeighted contract.
     * @param _vault Balancer Vault contract address.
     * @param _pool Balancer Pool contract address.
     */
    constructor(address _vault, address _pool, address _weth) {
        onlyContract(_vault);
        onlyContract(_pool);
        onlyContract(_weth);

        vault = IVault(_vault);
        pool = IPool(_pool);

        (IERC20[] memory _tokens, , ) = vault.getPoolTokens(pool.getPoolId());

        if (_tokens.length > 2) revert ESASXErrors.WrongBalancerPoolTokensNumber();

        address(_tokens[0]) == _weth ? tokenIndex = 1 : wethIndex = 1;
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
        IPool _pool = pool;
        (, uint256[] memory _balances, ) = vault.getPoolTokens(_pool.getPoolId());
        uint256[] memory _weights = _pool.getNormalizedWeights();
        uint256 _tokenIndex = tokenIndex;
        uint256 _wethIndex = wethIndex;

        return
            int256(
                (((_balances[_wethIndex] * 1e18) / _weights[_wethIndex]) * 1e18) /
                    ((_balances[_tokenIndex] * 1e18) / _weights[_tokenIndex])
            );
    }
}
