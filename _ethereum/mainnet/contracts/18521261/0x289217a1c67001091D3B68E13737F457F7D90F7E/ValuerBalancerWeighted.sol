// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./RewardsBoosterErrors.sol";
import "./IERC20.sol";
import "./IVault.sol";
import "./IPool.sol";
import "./ERC20.sol";
import "./Address.sol";
import "./IValuer.sol";
import "./IOracle.sol";
import "./Pow.sol";

/**
 * @title Asymetrix Protocol V2 ValuerBalancerWeighted
 * @author Asymetrix Protocol Inc Team
 * @notice A valuer for Balancer Weighted Pool LPs.
 */
contract ValuerBalancerWeighted is IValuer {
    using Address for address;

    IVault private vault;
    IPool private pool;
    IOracle[] private oracles;

    /**
     * @notice Deploy the ValuerBalancerWeighted contract.
     * @param _vault Balancer Vault contract address.
     * @param _pool Balancer Pool contract address.
     * @param _oracles Oracles' addresses that will be used in time of BPT valuing.
     * @dev Oracles' addresses should be provided in the same order as tokens registered in the Balancer pool.
     *      Eg.: ASX/WETH pool -> [ASX oracle, WETH oracle]
     *      Eg.: WETH/ASX pool -> [WETH oracle, ASX oracle]
     */
    constructor(address _vault, address _pool, address[] memory _oracles) {
        onlyContract(_vault);
        onlyContract(_pool);

        vault = IVault(_vault);
        pool = IPool(_pool);

        (IERC20[] memory _tokens, , ) = vault.getPoolTokens(pool.getPoolId());

        if (_oracles.length != _tokens.length) revert RewardsBoosterErrors.LengthsMismatch();

        for (uint256 _i; _i < _oracles.length; ++_i) {
            onlyContract(_oracles[_i]);
            oracles.push(IOracle(_oracles[_i]));
        }
    }

    /// @inheritdoc IValuer
    function value(uint256 _amount) external view returns (uint256 _value) {
        IPool _pool = pool;
        (IERC20[] memory _tokens, uint256[] memory _balances, ) = vault.getPoolTokens(_pool.getPoolId());
        uint256[] memory _weights = _pool.getNormalizedWeights();
        uint256 _tmp = 1e18;
        uint256 _invariant = 1e18;

        for (uint256 _i; _i < _tokens.length; ++_i) {
            IOracle _oracle = oracles[_i];
            uint256 _price = (uint256(_oracle.latestAnswer()) * 1e18) / 10 ** _oracle.decimals();

            _tmp = (_tmp * Pow.pow(((_price * 1e18) / _weights[_i]), _weights[_i])) / 1e18;
            _invariant =
                (_invariant *
                    Pow.pow((_balances[_i] * 1e18) / (10 ** ERC20(address(_tokens[_i])).decimals()), _weights[_i])) /
                1e18;
        }

        uint256 _bptValue = (_invariant * _tmp) / _pool.totalSupply();

        return (_amount * _bptValue) / 1e18;
    }

    /**
     * @notice Returns token amounts inside the position.
     * @param _bptBalance BPT balance of the user.
     * @return _amount0 The first token amount.
     * @return _amount1 The second token amount.
     */
    function getTokenAmounts(uint256 _bptBalance) external view returns (uint256 _amount0, uint256 _amount1) {
        IPool _pool = pool;
        (, uint256[] memory _balances, ) = vault.getPoolTokens(_pool.getPoolId());
        uint256 _poolShare = (_bptBalance * 1e18) / _pool.totalSupply();
        uint256[] memory _underlyingBalances = new uint256[](_balances.length);

        for (uint256 _i; _i < _balances.length; ++_i) {
            _underlyingBalances[_i] = (_balances[_i] * _poolShare) / 1e18;
        }

        return (_underlyingBalances[0], _underlyingBalances[1]);
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
     * @notice Returns oracles' addresses that are used in time of BPT valuing.
     * @return Oracles' addresses.
     */
    function getOracles() external view returns (IOracle[] memory) {
        return oracles;
    }

    /// @inheritdoc IValuer
    function getTokenAmountsInUSD(uint256) external pure returns (uint256, uint256) {
        revert RewardsBoosterErrors.StubMethod();
    }

    /**
     * @notice Checks if an address is a contract.
     * @param _contract An address to check.
     */
    function onlyContract(address _contract) private view {
        if (!_contract.isContract()) revert RewardsBoosterErrors.NotContract();
    }
}
