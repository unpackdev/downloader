// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./FijaStrategy.sol";
import "./CurveConvexStrategyProtocol.sol";
import "./errors.sol";
import "./ICurve.sol";
import "./ICurveConvexPeriphery.sol";

struct CoinRating {
    // token address used in liquidity pools
    address coinAddr;
    // rating of token used in liquidity pools
    uint8 rating;
}

struct Pool {
    // pool address
    address addr;
    // deposit zap for the pool
    address deposit;
    // pool category to reference correct interface
    uint8[4] category;
}

struct EmergencyPool {
    // pool address
    address addr;
    // deposit zap for pool
    address deposit;
    // exchange category to reference correct interface
    uint8[2] exchangeCategory;
}

struct RewardPoolInput {
    // address of pool used in reward route
    address addr;
    // deposit zap for the pool
    address deposit;
    // "from" address in exchange pair
    address from;
    // "to" address in exchange pair
    address to;
    // exchange category to reference correct interface
    uint8[2] exchangeCategory;
}

struct RewardPool {
    // address of pool used in reward route
    address addr;
    // "from" address in exchange pair
    address from;
    // "to" address in exchange pair
    address to;
}

struct ConstructorData {
    // flag for checking depeg
    bool dePegCheck;
    // flag for disabling emergency pool
    bool isEmePoolDisabled;
    // emergency token address
    address emergencyCurrency;
    //address used for linking contracts
    address linkAddr;
    // harvest time frequency
    uint256 harvestTime;
    // rebalance time param
    uint256 rebalanceTimeLower;
    // rebalance time param
    uint256 rebalanceTimeUpper;
    // depeg deviation in bps
    uint256 depegDev;
    // swap slippage in bps
    uint256 slippageSwap;
    // slippage during emergency mode in bps
    uint256 slippageEmergency;
    // threshold used in rebalance procedure
    uint256 rebalanceThreshold1;
    // threshold used in rebalance procedure
    uint256 rebalanceThreshold2;
    // liquidity threshold in bps
    uint256 liquidityThresholdBps;
    // list of liquidity pools used in strategy
    Pool[] curvePools;
    // list of token ratings used in strategy
    CoinRating[] coinRating;
    // emergency pool data
    EmergencyPool emergencyPool;
    // list of pools used in CRV reward route
    RewardPoolInput[] crvRewardRoute;
    // list of pools used in CVX reward route
    RewardPoolInput[] cvxRewardRoute;
}

///
/// @title Curve Convex Base contrat
/// @author Fija
/// @notice Used to initalize main and periphery contract variables
/// @dev Enables spliting contracts to main and periphery with access to same data
/// NOTE: Parent contract to CurveConvexPeriphery and CurveConvexStrategy
///
abstract contract CurveConvexBase is FijaStrategy, CurveConvexStrategyProtocol {
    ///
    /// @dev number of liquidity pools used in strategy
    ///
    uint8 internal immutable POOL_NUM;

    ///
    /// @dev deposit token used in strategy
    ///
    address internal immutable DEPOSIT_CCY;

    ///
    /// @dev flag is depeg checked in the strategy
    ///
    bool internal DE_PEG_CHECK;

    ///
    /// @dev flag is emergency pool disabled
    ///
    bool internal EME_POOL_DISABLED;

    ///
    /// @dev harvest time frequency
    ///
    uint256 internal HARVEST_TIME;

    ///
    /// @dev rebalance time parameter
    ///
    uint256 internal REBALANCE_TIME_UPPER;

    ///
    /// @dev rebalance time parameter
    ///
    uint256 internal REBALANCE_TIME_LOWER;

    ///
    /// @dev depeg deviation in bps
    ///
    uint256 internal DEPEG_DEVIATION;

    ///
    /// @dev slippage swap in bps
    ///
    uint256 internal SLIPPAGE_SWAP;

    ///
    /// @dev rebalance threshold used when calling needRebalance()
    ///
    uint256 internal REBALANCE_THR1;

    ///
    /// @dev rebalance threshold used when calling needRebalance()
    ///
    uint256 internal REBALANCE_THR2;

    ///
    /// @dev slippage when in emergency mode
    ///
    uint256 internal SLIPPAGE_EMERGENCY;

    ///
    /// @dev liquidity threshold for low-liquidity pool checks
    ///
    uint256 internal LIQUIDITY_THR_BPS;

    ///
    /// @dev timestamp for last harvest time in seconds
    ///
    uint256 internal _lastHarvestTime;

    ///
    /// @dev timestamp for last rebalance time in seconds
    ///
    uint256 internal _lastRebalanceTime;

    ///
    /// @dev emergency token address
    ///
    address internal EMERGENCY_CCY;

    ///
    /// @dev pool used to transfer assets to emergency token when emergency mode is triggered
    ///
    address internal _emergencyPool;

    ///
    /// @dev list of Curve pools used for providing liquidity
    ///
    address[] internal _curvePools;

    ///
    /// @dev list of pools data for CRV reward route
    ///
    RewardPool[] internal _crvRewardRoute;

    ///
    /// @dev list of pools data for CVX reward route
    ///
    RewardPool[] internal _cvxRewardRoute;

    ///
    /// @dev maps address of reward pool to token address index indicating
    /// token position in pool, used in reward route swaps
    ///
    mapping(address => mapping(address => uint256))
        internal _rewardPoolCoinIndex;

    ///
    /// @dev maps pool to deposit contract, needed when
    /// providing liquidity and swaps requires use of seperate deposit contracts
    ///
    mapping(address => address) internal _poolDepositCtr;

    ///
    /// @dev maps Curve liquidity pool to corresponding reward contract on Convex
    ///
    mapping(address => address) internal _poolRewardContract;

    ///
    /// @dev maps Curve liquidity pool to it's LP token
    ///
    mapping(address => address) internal _poolLpToken;

    ///
    /// @dev maps Curve liquidity pool to it's rating
    /// 2 decimals precision
    ///
    mapping(address => uint256) internal _poolRating;

    ///
    /// @dev maps Curve liquidity pool deposit token index,
    /// this indicates deposit token position in the pool, used for swaps
    ///
    mapping(address => int128) internal _poolDepositCcyIndex;

    ///
    /// @dev maps Curve liquidity pool to corresponding Convex pool id
    ///
    mapping(address => uint16) internal _poolConvexPoolId;

    ///
    /// @dev maps Curve liquidity pool to list of categories,
    /// used to invoke correct interface method when working with liquidity
    ///
    mapping(address => uint8[4]) internal _poolCategory;

    ///
    /// @dev maps emergency or reward route pool to list of exchange categories,
    /// used to invoke correct interface method when performing swaps
    ///
    mapping(address => uint8[2]) internal _poolExchangeCategory;

    constructor(
        address depositCurrency_,
        address governance_,
        string memory tokenName_,
        string memory tokenSymbol_,
        uint256 maxTicketSize_,
        uint256 maxVaultValue_,
        ConstructorData memory data_
    )
        FijaStrategy(
            IERC20(depositCurrency_),
            governance_,
            tokenName_,
            tokenSymbol_,
            maxTicketSize_,
            maxVaultValue_
        )
    {
        _lastHarvestTime = block.timestamp;
        _lastRebalanceTime = block.timestamp;

        DEPEG_DEVIATION = data_.depegDev;
        REBALANCE_TIME_LOWER = data_.rebalanceTimeLower;
        REBALANCE_TIME_UPPER = data_.rebalanceTimeUpper;
        HARVEST_TIME = data_.harvestTime;

        REBALANCE_THR1 = data_.rebalanceThreshold1;
        REBALANCE_THR2 = data_.rebalanceThreshold2;

        SLIPPAGE_EMERGENCY = data_.slippageEmergency;
        SLIPPAGE_SWAP = data_.slippageSwap;

        LIQUIDITY_THR_BPS = data_.liquidityThresholdBps;
        DE_PEG_CHECK = data_.dePegCheck;
        EME_POOL_DISABLED = data_.isEmePoolDisabled;

        DEPOSIT_CCY = depositCurrency_;
        EMERGENCY_CCY = data_.emergencyCurrency;
        POOL_NUM = uint8(data_.curvePools.length);

        // #### build CRV route storage var #####
        RewardPoolInput[] memory crvRewardRoute = data_.crvRewardRoute;
        for (uint8 i = 0; i < crvRewardRoute.length; i++) {
            _crvRewardRoute.push(
                RewardPool(
                    crvRewardRoute[i].addr,
                    crvRewardRoute[i].from,
                    crvRewardRoute[i].to
                )
            );

            _poolDepositCtr[crvRewardRoute[i].addr] = crvRewardRoute[i].deposit;
            _poolExchangeCategory[crvRewardRoute[i].addr] = crvRewardRoute[i]
                .exchangeCategory;

            // no exchange support, build rewardRoute coin indexes for swaps
            if (crvRewardRoute[i].exchangeCategory[0] != 0) {
                address rewardRoutePool = crvRewardRoute[i].addr;
                address[8] memory poolCoins = _underlyingCoins(rewardRoutePool);

                for (uint8 j = 0; j < poolCoins.length; j++) {
                    if (poolCoins[j] == address(0)) {
                        break;
                    }
                    _rewardPoolCoinIndex[rewardRoutePool][poolCoins[j]] = j;
                }
            }
        }
        // #### build CVX route storage var #####
        RewardPoolInput[] memory cvxRewardRoute = data_.cvxRewardRoute;
        for (uint8 i = 0; i < cvxRewardRoute.length; i++) {
            _cvxRewardRoute.push(
                RewardPool(
                    cvxRewardRoute[i].addr,
                    cvxRewardRoute[i].from,
                    cvxRewardRoute[i].to
                )
            );
            _poolDepositCtr[cvxRewardRoute[i].addr] = cvxRewardRoute[i].deposit;
            _poolExchangeCategory[cvxRewardRoute[i].addr] = cvxRewardRoute[i]
                .exchangeCategory;

            // no exchange support, build rewardRoute coin indexes
            if (cvxRewardRoute[i].exchangeCategory[0] != 0) {
                address rewardRoutePool = cvxRewardRoute[i].addr;
                address[8] memory poolCoins = _underlyingCoins(rewardRoutePool);

                for (uint8 j = 0; j < poolCoins.length; j++) {
                    if (poolCoins[j] == address(0)) {
                        break;
                    }
                    _rewardPoolCoinIndex[rewardRoutePool][poolCoins[j]] = j;
                }
            }
        }
        // #### build curve pool storage variables #####
        Pool[] memory curvePools = data_.curvePools;
        CoinRating[] memory coinRating = data_.coinRating;
        for (uint8 i = 0; i < curvePools.length; i++) {
            address curveAddr = curvePools[i].addr;
            _curvePools.push(curveAddr);
            _poolDepositCtr[curveAddr] = curvePools[i].deposit;
            _poolCategory[curveAddr] = curvePools[i].category;
            _poolLpToken[curveAddr] = Curve_ICurveMetaRegistry.get_lp_token(
                curveAddr
            );

            address[8] memory poolCoins = _underlyingCoins(curveAddr);

            _poolDepositCcyIndex[curveAddr] = _findCoinIndex(
                poolCoins,
                depositCurrency_
            );

            // create pool ratings
            bool isFound;
            uint16 ratingSum = 0;
            for (uint8 j = 0; j < poolCoins.length; j++) {
                if (poolCoins[j] == address(0)) {
                    break;
                }
                isFound = false;
                for (uint8 k = 0; k < coinRating.length; k++) {
                    if (poolCoins[j] == coinRating[k].coinAddr) {
                        isFound = true;
                        ratingSum += coinRating[k].rating;
                        break;
                    }
                }
                if (!isFound) {
                    revert FijaPoolRatingInvalid();
                }
            }

            _poolRating[curveAddr] = (ratingSum * 100) / poolCoins.length;

            // associate convex pool with curve pool through curve LP token
            uint256 convexPoolLength = Convex_IBooster.poolLength();
            isFound = false;
            for (uint16 j = 0; j < convexPoolLength; j++) {
                // gets curveLP token from convex pool
                (
                    address clpToken,
                    ,
                    ,
                    address rewardContract,
                    ,
                    bool isShutdown
                ) = Convex_IBooster.poolInfo(j);
                // check if convex curveLP tokens matches with curve pool lp token
                if (!isShutdown && clpToken == _poolLpToken[curveAddr]) {
                    isFound = true;
                    _poolConvexPoolId[curveAddr] = j;
                    _poolRewardContract[curveAddr] = rewardContract;

                    break;
                }
            }
            if (!isFound) {
                revert FijaConvexPoolUnknown();
            }
        }

        // #### initalize emergency pool #####
        _emergencyPool = data_.emergencyPool.addr;
        _poolExchangeCategory[_emergencyPool] = data_
            .emergencyPool
            .exchangeCategory;
        _poolDepositCtr[_emergencyPool] = data_.emergencyPool.deposit;

        // no exchange support, build emergency coin indexes
        if (data_.emergencyPool.exchangeCategory[0] != 0) {
            address[8] memory emeCoins = _underlyingCoins(_emergencyPool);

            for (uint8 j = 0; j < emeCoins.length; j++) {
                if (emeCoins[j] == address(0)) {
                    break;
                }
                _rewardPoolCoinIndex[_emergencyPool][emeCoins[j]] = j;
            }
        }
    }

    ///
    /// @dev Helper method querying which tokens pool supports. Only non-wrapped.
    /// @param pool address for which addresses of pool tokens are fetched
    /// @return array with token addresses inside pool
    ///
    function _underlyingCoins(
        address pool
    ) internal view returns (address[8] memory) {
        bool isMeta = Curve_ICurveMetaRegistry.is_meta(pool);

        address[8] memory underCoins = Curve_ICurveMetaRegistry
            .get_underlying_coins(pool);

        if (!isMeta) {
            address[8] memory coins = Curve_ICurveMetaRegistry.get_coins(pool);
            if (_isEqualAddr(coins, underCoins)) {
                if (!_isTokenAddrIn(coins, WETH)) {
                    // plain or plain eth pool
                    return coins;
                } else {
                    // pool which takes eth and wrapped eth
                    // but replaces WETH with ETH address as it's underlying
                    address[8] memory replacedCoins = _findAddrReplace(
                        coins,
                        WETH,
                        ETH
                    );
                    return replacedCoins;
                }
            } else {
                if (
                    _isTokenAddrIn(coins, ETH) &&
                    _isTokenAddrIn(underCoins, ETH)
                ) {
                    // plain eth pool
                    return coins;
                } else {
                    // normal lending pool
                    if (_isAllDiffAddr(coins, underCoins)) {
                        return underCoins;
                    } else {
                        revert FijaUnknownPoolForCoins();
                    }
                }
            }
        } else {
            return underCoins;
        }
    }

    ///
    /// @dev Helper method finding correct index in array of coins
    /// @param coins array of token addresses
    /// @param coin address of token for queried index
    /// @return token index in coins array
    /// NOTE: throws if index is not found
    ///
    function _findCoinIndex(
        address[8] memory coins,
        address coin
    ) internal pure returns (int128) {
        for (uint256 i = 0; i < coins.length; i++) {
            if (coins[i] == coin && coins[i] != address(0)) {
                return int128(int256(i));
            }
        }
        revert FijaCoinIndexNotFound();
    }

    ///
    /// @dev Helper method to build array which is provided to liquidity methods
    /// There is always 1 non-zero value in array, as there is only 1 token to
    /// use as deposit token in strategy
    /// @param amount array of token addresses
    /// @param index indicating token position in the pool
    /// @return array of values with 1 non-zero value on index which indicates
    /// deposit token index inside pool
    ///
    function _buildInputAmount(
        uint256 amount,
        int128 index
    ) internal pure returns (uint256[4] memory) {
        uint256[4] memory inputs = [
            uint256(0),
            uint256(0),
            uint256(0),
            uint256(0)
        ];
        inputs[uint256(uint128(index))] = amount;
        return inputs;
    }

    ///
    /// @dev Helper method which finds address in array and replaces it with different address
    /// @param inputAddrs array of token address on which to perform find and replace
    /// @param find address of token to replace
    /// @param replaceWith address of token to replace with
    /// @return array of addresses modified with replaceWith if flag is true
    ///
    function _findAddrReplace(
        address[8] memory inputAddrs,
        address find,
        address replaceWith
    ) private pure returns (address[8] memory) {
        for (uint8 i = 0; i < inputAddrs.length; i++) {
            if (inputAddrs[i] == find) {
                inputAddrs[i] = replaceWith;
                break;
            }
        }
        return inputAddrs;
    }

    ///
    /// @dev Helper method which checks if token address exists in array
    /// @param inputAddrs array of token address on which to perform find
    /// @param token address of token to find
    /// @return flag indicating if token is found in the inputAddrs
    ///
    function _isTokenAddrIn(
        address[8] memory inputAddrs,
        address token
    ) private pure returns (bool) {
        for (uint8 i = 0; i < inputAddrs.length; i++) {
            if (inputAddrs[i] == token) {
                return true;
            }
        }
        return false;
    }

    ///
    /// @dev Helper method to verify if 2 array are equal
    /// @param A array of token addresses to compare
    /// @param B array of token addresses to compare
    /// @return flag indicting if arrays are equal
    ///
    function _isEqualAddr(
        address[8] memory A,
        address[8] memory B
    ) private pure returns (bool) {
        for (uint8 i = 0; i < A.length; i++) {
            if (A[i] != B[i]) {
                return false;
            }
        }
        return true;
    }

    ///
    /// @dev Helper method to verify if 2 array are different on all positions
    /// @param A array of token addresses to compare
    /// @param B array of token addresses to compare
    /// @return flag indicting if arrays are not equal
    ///
    function _isAllDiffAddr(
        address[8] memory A,
        address[8] memory B
    ) private pure returns (bool) {
        for (uint8 i = 0; i < A.length; i++) {
            if (A[i] == B[i] && A[i] != address(0)) {
                return false;
            }
        }
        return true;
    }
}
