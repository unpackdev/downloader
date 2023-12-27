// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./LibAtomic.sol";
import "./SafeTransferHelper.sol";
import "./IExchangeWithAtomic.sol";
import "./IOrionPoolV2Pair.sol";
import "./IWETH9.sol";

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

contract OrionMigratorToAtomic is Ownable {
    using SafeERC20 for IERC20;

    IExchangeWithAtomic public exchange;
    IWETH9 public WETH9;
    bool initialized;

    mapping (address => bool) public exchangeAllowances;

    /**
     * @notice Can only be called once
     * @dev Initalizes parameters of the migrator contract
     * @param _exchange address of the exchange
     * @param _WETH9 address of the native token
     */
    function initialize (address _exchange, address _WETH9) external onlyOwner {
        require(!initialized, "Already initialized");
        exchange = IExchangeWithAtomic(_exchange);
        WETH9 = IWETH9(_WETH9);
        initialized = true;
    }

    receive() external payable {
        require(msg.sender == address(WETH9));
    }

    /**
     * @dev Migrates token/tokens from the token-token pair pool to the exchange and locks token/tokens atomically
     * @param pairAddress address of the token-token pair pool
     * @param tokensToMigrate number of LP tokens of the token-token pair pool to migrate
     * @param secretHash0 atomic secret hash for the token0
     * @param secretHash1 atomic secret hash for the token0
     * @param expiration expiration of lock atomic
     * @param targetChainId id of target blockchain network
     */
    function migrate(address pairAddress, uint tokensToMigrate, bytes32 secretHash0, bytes32 secretHash1,
            uint64 expiration, uint24 targetChainId) external {
        SafeERC20.safeTransferFrom(IERC20(pairAddress), msg.sender, pairAddress, tokensToMigrate);

        IOrionPoolV2Pair pair = IOrionPoolV2Pair(pairAddress);
        (uint amount0, uint amount1) = pair.burn(address(this));

        address token0 = pair.token0();
        address token1 = pair.token1();

        uint value0;
        uint value1;

        if (address(token0) == address(WETH9)) {
            WETH9.withdraw(amount0);
            value0 = amount0;
            token0 = address(0);
        }

        if (address(token1) == address(WETH9)) {
            WETH9.withdraw(amount1);
            value1 = amount1;
            token1 = address(0);
        }

        _safeIncreaseAllowance(token0);
        _safeIncreaseAllowance(token1);

        amount0 = LibUnitConverter.baseUnitToDecimal(token0, amount0);
        require(amount0 < type(uint64).max, "Token0 amount overflow");
        amount1 = LibUnitConverter.baseUnitToDecimal(token1, amount1);
        require(amount1 < type(uint64).max, "Token1 amount overflow");

        exchange.lockAtomic{value: value0}(LibAtomic.LockOrder(msg.sender, expiration, token0, uint64(amount0), targetChainId, secretHash0));
        exchange.lockAtomic{value: value1}(LibAtomic.LockOrder(msg.sender, expiration, token1, uint64(amount1), targetChainId, secretHash1));
    }

    function _safeIncreaseAllowance(address token) internal {
        if (token != address(0) && !exchangeAllowances[token]) {
            IERC20(token).safeIncreaseAllowance(address(exchange), type(uint).max);
            exchangeAllowances[token] = true;
        }
    }
}
