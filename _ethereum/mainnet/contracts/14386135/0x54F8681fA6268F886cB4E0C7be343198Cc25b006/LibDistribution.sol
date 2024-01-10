// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./FixedPoint96.sol";
import "./IUniswapV3Factory.sol";
import "./IUniswapV3Pool.sol";

import "./LibAppStorage.sol";
import "./LibGetters.sol";
import "./Math.sol";
import "./FullMath.sol";

import "./console.sol";

library LibDistribution {
    /// @notice The Earn Pair Reward Event.
    ///
    /// @param  _metaNftId  The Meta NFT ID.
    /// @param  _amount     The amount earned.
    ///
    event EarnPairReward(uint256 _metaNftId, uint128 _amount);

    /// @notice The Earn User Reward Event.
    ///
    /// @param  _metaNftId      The Meta NFT ID.
    /// @param  _userAddress    The user address.
    /// @param  _amount         The amount earned.
    ///
    event EarnUserReward(uint256 _metaNftId, address _userAddress, uint128 _amount);

    function _addPairReward(uint256 _metaNftId, uint128 _amount) private {
        LibAppStorage._diamondStorage().pairRewards[_metaNftId] += _amount;
        emit EarnPairReward(_metaNftId, _amount);
    }

    function _addUserReward(uint256 _metaNftId, address _userAddress, uint128 _amount) private {
        LibAppStorage._diamondStorage().userRewards[_userAddress] += _amount;
        emit EarnUserReward(_metaNftId, _userAddress, _amount);
    }

    function _getPriceX96FromSqrtPriceX96(uint160 _sqrtPriceX96) public pure returns(uint256 _priceX96) {
        return FullMath.mulDiv(_sqrtPriceX96, _sqrtPriceX96, FixedPoint96.Q96);
    }

    function _convertToken(address _from, address _to, uint128 _amount) private returns (uint128 _result) {
        address pool = IUniswapV3Factory(LibAppStorage._diamondStorage().uniV3Factory).getPool(_from, _to, 500);
        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3PoolState(pool).slot0();
        uint256 priceX96 = _getPriceX96FromSqrtPriceX96(sqrtPriceX96);

        if (IUniswapV3PoolImmutables(pool).token0() == _from) {
            _result = uint128(FullMath.mulDiv(_amount, priceX96, FixedPoint96.Q96));
        }
        else {
            _result = uint128(FullMath.mulDiv(_amount, FixedPoint96.Q96, priceX96));
        }
    }

    function _convertToPil(address _token, uint128 _amount) private returns (uint128 _pilAmount) {
        address pil = LibAppStorage._diamondStorage().pil;
        if (_token == pil) {
            return _amount;
        }
        address weth = LibAppStorage._diamondStorage().weth;
        if (_token == weth) {
            return _convertToken(_token, pil, _amount);
        }
        return _convertToken(weth, pil, _convertToken(_token, weth, _amount));
    }

    function _updateReserve(uint128 _baseDelta, uint128 _roundDelta, bool _roundMinted, uint256 _metaNftId, address _userAddress) internal {
        PairInfo storage pairInfo = LibGetters._getPairInfo(_metaNftId);
        DistPoolInfo storage distPoolInfo = LibAppStorage._diamondStorage().distPools[pairInfo.baseToken];
        DistUserInfo storage distUserInfo = pairInfo.distUsers[_userAddress];
        uint128 userRoundReserve = pairInfo.roundBalanceOf[_userAddress];
        uint32 rewardEpoch = LibAppStorage._diamondStorage().rewardEpoch;
        uint128 actualBaseReserveInPil = _convertToPil(pairInfo.baseToken, pairInfo.actualBaseReserve);

        if (block.number > pairInfo.lastBlockNumber + rewardEpoch) {
            if (pairInfo.tradingVolume > 0) {
                uint128 lastBlockRoundTotalSupply = pairInfo.roundTotalSupply;
                if (_roundMinted) {
                    lastBlockRoundTotalSupply -= _roundDelta;
                }
                else {
                    lastBlockRoundTotalSupply += _roundDelta;
                }
                uint256 deltaRewardPerRound = Math.sqrt(uint256(pairInfo.minBaseReserve) * 1 ether) * pairInfo.tradingVolume * pairInfo.extraRewardParameter
                    / (distPoolInfo.rewardParameter * lastBlockRoundTotalSupply);
                pairInfo.cumulativeRewardPerRound += uint128(deltaRewardPerRound);
                _addPairReward(_metaNftId, uint128(deltaRewardPerRound * INITIAL_ROUNDS / 1 ether));
                _addUserReward(_metaNftId, _userAddress, distPoolInfo.gasReward);
            }
            pairInfo.tradingVolume = 0;
            pairInfo.minBaseReserve = actualBaseReserveInPil;
            pairInfo.lastBlockNumber = uint32(block.number);
        }

        if (pairInfo.cumulativeRewardPerRound > distUserInfo.lastCumulativeRewardPerRound) {
            _addUserReward(
                _metaNftId,
                _userAddress,
                uint128(uint256(distUserInfo.minRoundReserve) * (pairInfo.cumulativeRewardPerRound - distUserInfo.lastCumulativeRewardPerRound) / 1 ether)
            );
            distUserInfo.lastCumulativeRewardPerRound = pairInfo.cumulativeRewardPerRound;
            distUserInfo.minRoundReserve = userRoundReserve;
        }

        pairInfo.tradingVolume += _convertToPil(pairInfo.baseToken, _baseDelta);
        if (actualBaseReserveInPil < pairInfo.minBaseReserve) {
            pairInfo.minBaseReserve = actualBaseReserveInPil;
        }

        if (userRoundReserve < distUserInfo.minRoundReserve || distUserInfo.minRoundReserve == 0) {
            distUserInfo.minRoundReserve = userRoundReserve;
        }
    }

    function _setUniExtraRewardParam(address _tokenA, address _tokenB, uint32 _value) internal {
        require(_tokenA != _tokenB, "Pilgrim: Must be different tokens");
        (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
        LibAppStorage._diamondStorage().uniV3ExtraRewardParams[token0][token1] = _value;
    }
}
