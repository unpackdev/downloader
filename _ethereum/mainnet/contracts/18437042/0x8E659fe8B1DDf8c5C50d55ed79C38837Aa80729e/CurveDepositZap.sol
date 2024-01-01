// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "Ownable.sol";
import "SafeERC20.sol";
import "IVault.sol";

interface ICurveToken {
    function minter() external view returns (address);
}

interface ICurvePool {
    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);

    function coins(uint256 arg0) external view returns (address);

    function balances(uint256 i) external view returns (uint256);
}

interface ICurvePoolV2 {
    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        uint256 i,
        uint256 _min_received
    ) external returns (uint256);

    function gamma() external view returns (uint256);

    // changed interface only appears to be used in 2-coin v2 pools
    function calc_token_amount(uint256[2] calldata amounts) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, uint256 i) external view returns (uint256);
}

interface ICurvePool2 is ICurvePool {
    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount) external returns (uint256);

    function remove_liquidity(uint256 _burn_amount, uint256[2] calldata _min_amounts) external;

    function calc_token_amount(uint256[2] calldata _amounts, bool _is_deposit) external view returns (uint256);
}

interface ICurvePool3 is ICurvePool {
    function add_liquidity(uint256[3] calldata _amounts, uint256 _min_mint_amount) external returns (uint256);

    function remove_liquidity(uint256 _burn_amount, uint256[3] calldata _min_amounts) external;

    function calc_token_amount(uint256[3] calldata _amounts, bool _is_deposit) external view returns (uint256);
}

interface ICurvePool4 is ICurvePool {
    function add_liquidity(uint256[4] calldata _amounts, uint256 _min_mint_amount) external returns (uint256);

    function remove_liquidity(uint256 _burn_amount, uint256[4] calldata _min_amounts) external;

    function calc_token_amount(uint256[4] calldata _amounts, bool _is_deposit) external view returns (uint256);
}

interface IDepositToken {
    function emissionId() external view returns (uint256);

    function lpToken() external view returns (address);

    function deposit(address receiver, uint256 amount) external returns (bool);

    function withdraw(address receiver, uint256 amount) external returns (bool);
}

/**
    @title PRISMA Curve Deposit Zap
    @notice Deposits tokens into Curve and stakes LP tokens into Curve/Convex via Prisma
 */
contract CurveDepositZap is Ownable {
    using SafeERC20 for IERC20;

    struct CurvePool {
        address pool;
        bool isMetapool;
        bool isCryptoswap;
        address[] coins;
    }

    IPrismaVault public immutable vault;

    mapping(address lpToken => CurvePool) poolData;
    mapping(address depositToken => address lpToken) depositTokenToLpToken;

    constructor(IPrismaVault _vault, address[2][] memory _basePools) {
        vault = _vault;
        for (uint i = 0; i < _basePools.length; i++) {
            addCurvePool(_basePools[i][0], _basePools[i][1]);
        }
    }

    /**
        @notice Get an array of coins used in `depositToken`
        @dev Arrays for `amounts` or `minReceived` correspond to the returned coins
     */
    function getCoins(address depositToken) public view returns (address[] memory coins) {
        address lpToken = IDepositToken(depositToken).lpToken();
        CurvePool memory pool = poolData[lpToken];
        require(pool.pool != address(0), "depositToken not registered");

        if (!pool.isMetapool) {
            return pool.coins;
        }
        CurvePool memory basePool = poolData[pool.coins[1]];
        coins = new address[](basePool.coins.length + 1);
        coins[0] = pool.coins[0];
        for (uint i = 1; i < coins.length; i++) {
            coins[i] = basePool.coins[i - 1];
        }
        return coins;
    }

    /**
        @notice Get the expected amount of LP tokens returned when adding
                liquidity to `depositToken`
        @dev Used to calculate `minReceived` when calling `addLiquidity`
     */
    function getAddLiquidityReceived(address depositToken, uint256[] memory amounts) external view returns (uint256) {
        address lpToken = depositTokenToLpToken[depositToken];
        CurvePool memory pool = poolData[lpToken];
        require(pool.pool != address(0), "depositToken not registered");

        if (pool.isMetapool) {
            CurvePool memory basePool = poolData[pool.coins[1]];
            require(amounts.length == basePool.coins.length + 1, "Incorrect amounts.length");
            bool isBaseDeposit;
            for (uint i = 1; i < amounts.length; i++) {
                if (amounts[i] > 0) {
                    isBaseDeposit = true;
                    break;
                }
            }
            if (isBaseDeposit) {
                amounts[1] = _calcTokenAmount(basePool, 1, amounts);
            } else {
                amounts[1] = 0;
            }
        } else {
            require(amounts.length == pool.coins.length, "Incorrect amounts.length");
        }
        return _calcTokenAmount(pool, 0, amounts);
    }

    function _calcTokenAmount(
        CurvePool memory pool,
        uint256 i,
        uint256[] memory amounts
    ) internal view returns (uint256) {
        uint256 numCoins = pool.coins.length;

        if (numCoins == 2) {
            if (pool.isCryptoswap) {
                return ICurvePoolV2(pool.pool).calc_token_amount([amounts[i], amounts[i + 1]]);
            } else {
                return ICurvePool2(pool.pool).calc_token_amount([amounts[i], amounts[i + 1]], true);
            }
        }
        if (numCoins == 3) {
            return ICurvePool3(pool.pool).calc_token_amount([amounts[i], amounts[i + 1], amounts[i + 2]], true);
        }
        if (numCoins == 4) {
            return
                ICurvePool4(pool.pool).calc_token_amount(
                    [amounts[i], amounts[i + 1], amounts[i + 2], amounts[i + 3]],
                    true
                );
        }
    }

    /**
        @notice Get the expected amount of coins returned when removing
                liquidity from `depositToken`
        @dev Used to calculate `minReceived` when calling `removeLiquidity`
     */
    function getRemoveLiquidityReceived(
        address depositToken,
        uint256 burnAmount
    ) external view returns (uint256[] memory received) {
        address lpToken = depositTokenToLpToken[depositToken];
        CurvePool memory pool = poolData[lpToken];
        require(pool.pool != address(0), "depositToken not registered");

        if (pool.isMetapool) {
            CurvePool memory basePool = poolData[pool.coins[1]];
            uint256 length = basePool.coins.length;
            received = new uint256[](length + 1);
            uint256 supply = IERC20(lpToken).totalSupply();
            received[0] = (ICurvePool(pool.pool).balances(0) * burnAmount) / supply;

            burnAmount = (ICurvePool(pool.pool).balances(1) * burnAmount) / supply;
            supply = IERC20(pool.coins[1]).totalSupply();
            for (uint i = 0; i < length; i++) {
                received[i + 1] = (ICurvePool(basePool.pool).balances(i) * burnAmount) / supply;
            }
            return received;
        } else {
            uint256 length = pool.coins.length;
            received = new uint256[](length);
            uint256 supply = IERC20(lpToken).totalSupply();
            for (uint i = 0; i < length; i++) {
                received[i] = (ICurvePool(pool.pool).balances(i) * burnAmount) / supply;
            }
            return received;
        }
    }

    /**
        @notice Get the expected amount of coins returned when removing
                liquidity one-sided from `depositToken`
        @dev Used to calculate `minReceived` when calling `removeLiquidityOneCoin`
     */
    function getRemoveLiquidityOneCoinReceived(
        address depositToken,
        uint256 burnAmount,
        uint256 index
    ) external view returns (uint256) {
        address lpToken = depositTokenToLpToken[depositToken];
        CurvePool memory pool = poolData[lpToken];
        require(pool.pool != address(0), "depositToken not registered");

        if (index != 0 && pool.isMetapool) {
            if (pool.isCryptoswap) {
                burnAmount = ICurvePoolV2(pool.pool).calc_withdraw_one_coin(burnAmount, 1);
            } else {
                burnAmount = ICurvePool(pool.pool).calc_withdraw_one_coin(burnAmount, 1);
            }
            pool = poolData[pool.coins[1]];
            index -= 1;
        }
        if (pool.isCryptoswap) {
            return ICurvePoolV2(pool.pool).calc_withdraw_one_coin(burnAmount, index);
        } else {
            return ICurvePool(pool.pool).calc_withdraw_one_coin(burnAmount, int128(int256(index)));
        }
    }

    /**
        @notice For emergencies if someone accidentally sent some ERC20 tokens here
     */
    function recoverERC20(IERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(msg.sender, amount);
    }

    /**
        @notice Owner-only method to add data about a curve pool
        @dev Pools used as bases for metapools must be added this way prior to
             the metapool being added, otherwise things could break strangely.
     */
    function addCurvePool(address pool, address lpToken) public onlyOwner {
        _addPoolData(pool, lpToken);
    }

    /**
        @notice Register a deposit token
        @dev Also called the first time liquidity is added or removed via the zap,
             this method is only needed to ensure the view methods work prior.
     */
    function registerDepositToken(address depositToken) external {
        require(depositTokenToLpToken[depositToken] == address(0), "Already registered");
        _registerDepositToken(depositToken);
    }

    function _addPoolData(address pool, address lpToken) internal {
        poolData[lpToken].pool = pool;
        address[] memory coins = new address[](4);
        uint256 i;
        for (; i < 4; i++) {
            try ICurvePool(pool).coins(i) returns (address _coin) {
                coins[i] = _coin;
                IERC20(_coin).safeApprove(pool, type(uint256).max);
            } catch {
                assembly {
                    mstore(coins, i)
                }
                break;
            }
        }
        poolData[lpToken].coins = coins;
        address lastCoin = coins[i - 1];
        address basePool = poolData[lastCoin].pool;
        if (basePool != address(0)) poolData[lpToken].isMetapool = true;
        try ICurvePoolV2(pool).gamma() returns (uint256) {
            poolData[lpToken].isCryptoswap = true;
        } catch {
            poolData[lpToken].isCryptoswap = false;
        }
    }

    function _registerDepositToken(address depositToken) internal returns (address lpToken) {
        lpToken = IDepositToken(depositToken).lpToken();
        depositTokenToLpToken[depositToken] = lpToken;

        address pool = poolData[lpToken].pool;
        if (pool == address(0)) {
            uint256 id = IDepositToken(depositToken).emissionId();
            (address receiver, ) = vault.idToReceiver(id);
            require(receiver == depositToken, "receiver != depositToken");

            try ICurveToken(lpToken).minter() returns (address _pool) {
                pool = _pool;
            } catch {
                pool = lpToken;
            }
            _addPoolData(pool, lpToken);
        }
        IERC20(lpToken).safeApprove(depositToken, type(uint256).max);
        return lpToken;
    }

    /**
        @notice Add liquidity to Curve and stake LP tokens via `depositToken`
        @param depositToken Address of Prisma `CurveDepositToken` or `ConvexDepositToken` deployment
        @param amounts Array of coin amounts to deposit into Curve
        @param minReceived Minimum amount of Curve LP tokens received when adding liquidity
        @param receiver Address to deposit into Prisma on behalf of
        @return lpTokenAmount Amount of LP tokens deposited into `depositToken`
     */
    function addLiquidity(
        address depositToken,
        uint256[] memory amounts,
        uint256 minReceived,
        address receiver
    ) external returns (uint256 lpTokenAmount) {
        address lpToken = depositTokenToLpToken[depositToken];
        if (lpToken == address(0)) lpToken = _registerDepositToken(depositToken);

        CurvePool memory pool = poolData[lpToken];
        if (amounts[0] > 0) IERC20(pool.coins[0]).safeTransferFrom(msg.sender, address(this), amounts[0]);

        if (pool.isMetapool) {
            CurvePool memory basePool = poolData[pool.coins[1]];
            uint256 length = basePool.coins.length + 1;
            require(amounts.length == length, "Incorrect amounts.length");
            bool isBaseDeposit;
            for (uint i = 1; i < length; i++) {
                if (amounts[i] > 0) {
                    isBaseDeposit = true;
                    IERC20(basePool.coins[i - 1]).safeTransferFrom(msg.sender, address(this), amounts[i]);
                }
            }
            if (isBaseDeposit) {
                amounts[1] = _addLiquidity(basePool.pool, length - 1, 1, amounts, 0);
            } else {
                amounts[1] = 0;
            }
        } else {
            uint256 length = pool.coins.length;
            require(amounts.length == length, "Incorrect amounts.length");
            for (uint i = 1; i < length; i++) {
                if (amounts[i] > 0) {
                    IERC20(pool.coins[i]).safeTransferFrom(msg.sender, address(this), amounts[i]);
                }
            }
        }
        lpTokenAmount = _addLiquidity(pool.pool, pool.coins.length, 0, amounts, minReceived);

        IDepositToken(depositToken).deposit(receiver, lpTokenAmount);

        return lpTokenAmount;
    }

    function _addLiquidity(
        address pool,
        uint256 numCoins,
        uint256 i,
        uint256[] memory amounts,
        uint256 minReceived
    ) internal returns (uint256) {
        if (numCoins == 2) {
            return ICurvePool2(pool).add_liquidity([amounts[i], amounts[i + 1]], minReceived);
        }
        if (numCoins == 3) {
            return ICurvePool3(pool).add_liquidity([amounts[i], amounts[i + 1], amounts[i + 2]], minReceived);
        }
        if (numCoins == 4) {
            return
                ICurvePool4(pool).add_liquidity(
                    [amounts[i], amounts[i + 1], amounts[i + 2], amounts[i + 3]],
                    minReceived
                );
        }
    }

    /**
        @notice Withdraw LP tokens from `depositToken` and remove liquidity from Curve
        @param depositToken Address of Prisma `CurveDepositToken` or `ConvexDepositToken` deployment
        @param burnAmount Amount of Curve LP tokens to withdraw
        @param minReceived Minimum coin amounts received when removing liquidity
        @param receiver Address to send withdrawn coins to
        @return received Array of withdrawn coin amounts
     */
    function removeLiquidity(
        address depositToken,
        uint256 burnAmount,
        uint256[] calldata minReceived,
        address receiver
    ) external returns (uint256[] memory received) {
        address lpToken = depositTokenToLpToken[depositToken];
        if (lpToken == address(0)) lpToken = _registerDepositToken(depositToken);

        IERC20(depositToken).transferFrom(msg.sender, address(this), burnAmount);
        IDepositToken(depositToken).withdraw(address(this), burnAmount);

        CurvePool memory pool = poolData[lpToken];
        if (pool.isMetapool) return _removeLiquidityMeta(pool, burnAmount, minReceived, receiver);
        else return _removeLiquidityPlain(pool, burnAmount, minReceived, receiver);
    }

    function _removeLiquidityMeta(
        CurvePool memory pool,
        uint256 burnAmount,
        uint256[] calldata minReceived,
        address receiver
    ) internal returns (uint256[] memory) {
        CurvePool memory basePool = poolData[pool.coins[1]];
        uint256 length = basePool.coins.length;
        require(minReceived.length == length + 1, "Incorrect minReceived.length");
        uint256[] memory received = new uint256[](length + 1);

        _removeLiquidity(pool.pool, 2, burnAmount);

        IERC20 coin = IERC20(pool.coins[0]);
        uint256 amount = coin.balanceOf(address(this));
        require(amount >= minReceived[0], "Slippage");
        coin.safeTransfer(receiver, amount);
        received[0] = amount;

        burnAmount = IERC20(pool.coins[1]).balanceOf(address(this));
        _removeLiquidity(basePool.pool, length, burnAmount);

        for (uint i = 0; i < length; i++) {
            coin = IERC20(basePool.coins[i]);
            amount = coin.balanceOf(address(this));
            require(amount >= minReceived[i + 1], "Slippage");
            coin.safeTransfer(receiver, amount);
            received[i + 1] = amount;
        }
        return received;
    }

    function _removeLiquidityPlain(
        CurvePool memory pool,
        uint256 burnAmount,
        uint256[] calldata minReceived,
        address receiver
    ) internal returns (uint256[] memory) {
        uint length = pool.coins.length;
        require(minReceived.length == length, "Incorrect minReceived.length");
        uint256[] memory received = new uint256[](length);

        _removeLiquidity(pool.pool, length, burnAmount);

        for (uint i = 0; i < length; i++) {
            IERC20 coin = IERC20(pool.coins[i]);
            uint256 amount = coin.balanceOf(address(this));
            require(amount >= minReceived[i], "Slippage");
            coin.safeTransfer(receiver, amount);
            received[i] = amount;
        }
        return received;
    }

    function _removeLiquidity(address pool, uint256 numCoins, uint256 burnAmount) internal {
        if (numCoins == 2) {
            ICurvePool2(pool).remove_liquidity(burnAmount, [uint256(0), uint256(0)]);
        } else if (numCoins == 3) {
            ICurvePool3(pool).remove_liquidity(burnAmount, [uint256(0), uint256(0), uint256(0)]);
        } else if (numCoins == 4) {
            ICurvePool4(pool).remove_liquidity(burnAmount, [uint256(0), uint256(0), uint256(0), uint256(0)]);
        }
    }

    /**
        @notice Withdraw LP tokens from `depositToken` and remove liquidity from Curve single-sided
        @param depositToken Address of Prisma `CurveDepositToken` or `ConvexDepositToken` deployment
        @param burnAmount Amount of Curve LP tokens to withdraw
        @param index Index of coin to withdraw (from `getCoins`)
        @param minReceived Minimum amount received when removing liquidity
        @param receiver Address to send withdrawn coins to
        @return received Amount of coin received in withdrawal
     */
    function removeLiquidityOneCoin(
        address depositToken,
        uint256 burnAmount,
        uint256 index,
        uint256 minReceived,
        address receiver
    ) external returns (uint256) {
        address lpToken = depositTokenToLpToken[depositToken];
        if (lpToken == address(0)) lpToken = _registerDepositToken(depositToken);

        IERC20(depositToken).transferFrom(msg.sender, address(this), burnAmount);
        IDepositToken(depositToken).withdraw(address(this), burnAmount);

        CurvePool memory pool = poolData[lpToken];
        if (index != 0 && pool.isMetapool) {
            if (pool.isCryptoswap) {
                burnAmount = ICurvePoolV2(pool.pool).remove_liquidity_one_coin(burnAmount, 1, 0);
            } else {
                burnAmount = ICurvePool(pool.pool).remove_liquidity_one_coin(burnAmount, 1, 0);
            }
            pool = poolData[pool.coins[1]];
            index -= 1;
        }

        uint256 amount;
        if (pool.isCryptoswap) {
            amount = ICurvePoolV2(pool.pool).remove_liquidity_one_coin(burnAmount, index, minReceived);
        } else {
            amount = ICurvePool(pool.pool).remove_liquidity_one_coin(burnAmount, int128(int256(index)), minReceived);
        }
        IERC20(pool.coins[index]).safeTransfer(receiver, amount);

        return amount;
    }
}
