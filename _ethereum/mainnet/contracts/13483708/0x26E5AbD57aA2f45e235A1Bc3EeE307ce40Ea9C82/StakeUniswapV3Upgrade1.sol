// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IUniswapV3Pool.sol";
import "./INonfungiblePositionManager.sol";
import "./TransferHelper.sol";
import "./PoolAddress.sol";

//import "./IStakeRegistry.sol";
//import "./IStakeUniswapV3.sol";
import "./IAutoRefactorCoinageWithTokenId.sol";
import "./IIStake2Vault.sol";
import "./DSMath.sol";
import "./AccessibleCommon.sol";
import "./StakeUniswapV3Storage.sol";
import "./SafeMath.sol";
import "./SafeMath32.sol";

import "./IERC20.sol";

//import "./console.sol";

/// @title StakeUniswapV3
/// @notice Uniswap V3 Contract for staking LP and mining TOS
contract StakeUniswapV3Upgrade1 is
    StakeUniswapV3Storage,
    AccessibleCommon,
    DSMath
{
    using SafeMath for uint256;
    using SafeMath32 for uint32;

    event MinedCoinage(
        uint256 curTime,
        uint256 miningInterval,
        uint256 miningAmount,
        uint256 prevTotalSupply,
        uint256 afterTotalSupply,
        uint256 factor
    );

    event IncreasedLiquidity(
        address indexed sender,
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    event Collected(
        address indexed sender,
        uint256 indexed tokenId,
        uint256 amount0,
        uint256 amount1
    );

    event DecreasedLiquidity(
        address indexed sender,
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    event WithdrawalToken(
        address indexed sender,
        uint256 indexed tokenId,
        uint256 miningAmount,
        uint256 nonMiningAmount
    );

    event Claimed(
        address indexed sender,
        uint256 indexed tokenId,
        address poolAddress,
        uint256 miningAmount,
        uint256 nonMiningAmount
    );

    /// @dev constructor of StakeCoinage
    constructor() {
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);

    }

    /// @dev receive ether - revert
    receive() external payable {
        revert();
    }

    /// @dev mining on coinage, Mining conditions :  the sale start time must pass,
    /// the stake start time must pass, the vault mining start time (sale start time) passes,
    /// the mining interval passes, and the current total amount is not zero,
    function miningCoinage() public lock {
        if (saleStartTime == 0 || saleStartTime > block.timestamp) return;
        if (stakeStartTime == 0 || stakeStartTime > block.timestamp) return;

        uint256 _miningEndTime = IIStake2Vault(vault).miningEndTime();

        uint256 curBlocktimestamp = block.timestamp;
        if (curBlocktimestamp > _miningEndTime)
            curBlocktimestamp = _miningEndTime;

        if (
            IIStake2Vault(vault).miningStartTime() > block.timestamp ||
            (coinageLastMintBlockTimetamp > 0 &&
                IIStake2Vault(vault).miningEndTime() <=
                coinageLastMintBlockTimetamp)
        ) return;

        if (coinageLastMintBlockTimetamp == 0)
            coinageLastMintBlockTimetamp = stakeStartTime;

        if (
            curBlocktimestamp >
            (coinageLastMintBlockTimetamp.add(miningIntervalSeconds))
        ) {
            uint256 miningInterval =
                curBlocktimestamp.sub(coinageLastMintBlockTimetamp);
            uint256 miningAmount =
                miningInterval.mul(IIStake2Vault(vault).miningPerSecond());
            uint256 prevTotalSupply =
                IAutoRefactorCoinageWithTokenId(coinage).totalSupply();

            if (miningAmount > 0 && prevTotalSupply > 0) {
                uint256 afterTotalSupply =
                    prevTotalSupply.add(miningAmount.mul(10**9));
                uint256 factor =
                    IAutoRefactorCoinageWithTokenId(coinage).setFactor(
                        _calcNewFactor(
                            prevTotalSupply,
                            afterTotalSupply,
                            IAutoRefactorCoinageWithTokenId(coinage).factor()
                        )
                    );
                coinageLastMintBlockTimetamp = curBlocktimestamp;

                emit MinedCoinage(
                    block.timestamp,
                    miningInterval,
                    miningAmount,
                    prevTotalSupply,
                    afterTotalSupply,
                    factor
                );
            }
        }
    }

    function _calcNewFactor(
        uint256 source,
        uint256 target,
        uint256 oldFactor
    ) internal pure returns (uint256) {
        return rdiv(rmul(target, oldFactor), source);
    }

    function checkCurrentPosition(int24 tickLower, int24 tickUpper)
        internal
        view
        returns (bool)
    {
        (, int24 tick, , , , , ) = IUniswapV3Pool(poolAddress).slot0();
        if (tickLower < tick && tick < tickUpper) return true;
        else return false;
    }

    function safeApproveAll(address[] calldata tokens, uint256[] calldata totals) external returns (bool) {
        require(tokens.length == totals.length, "StakeUniswapV3Upgrade1: diff length");

        for(uint256 i=0; i < tokens.length; i++){
            if(tokens[i] != address(0) && totals[i] > 0 ){
                TransferHelper.safeApprove(
                    tokens[i],
                    address(nonfungiblePositionManager),
                    totals[i]
                );
            }
        }
        return true;
    }

    function increaseLiquidity(uint256 tokenId,
            uint256 amount0Desired,
            uint256 amount1Desired,
            uint256 amount0Min,
            uint256 amount1Min,
            uint256 deadline)
        external
        payable
        returns (bool)
    {

        LibUniswapV3Stake.StakeLiquidity storage _depositTokens =
            depositTokens[tokenId];
        require(
            msg.sender == _depositTokens.owner,
            "StakeUniswapV3Upgrade1: not owner"
        );
        require(
            !_depositTokens.claimLock && !_depositTokens.withdraw,
            "StakeUniswapV3Upgrade1: in process"
        );
        require(
            poolToken0 != address(0) && poolToken1 != address(0),
            "StakeUniswapV3Upgrade1: zeroAddress token"
        );
        require(
            checkCurrentPosition(
                _depositTokens.tickLower,
                _depositTokens.tickUpper
            ),
            "StakeUniswapV3Upgrade1: out of range"
        );

        _depositTokens.claimLock = true;

        miningCoinage();

        TransferHelper.safeTransferFrom(
            poolToken0,
            msg.sender,
            address(this),
            amount0Desired
        );
        TransferHelper.safeTransferFrom(
            poolToken1,
            msg.sender,
            address(this),
            amount1Desired
        );

        (uint128 liquidity, uint256 amount0, uint256 amount1) =
            nonfungiblePositionManager.increaseLiquidity(
                INonfungiblePositionManager.IncreaseLiquidityParams({
                    tokenId: tokenId,
                    amount0Desired: amount0Desired,
                    amount1Desired: amount1Desired,
                    amount0Min: amount0Min,
                    amount1Min: amount1Min,
                    deadline: deadline
                })
            );
        (, , , , , int24 tickLower, int24 tickUpper, , , , , ) =
            nonfungiblePositionManager.positions(tokenId);
        _depositTokens.liquidity += liquidity;
        _depositTokens.tickLower = tickLower;
        _depositTokens.tickUpper = tickUpper;

        totalStakedAmount = totalStakedAmount.add(uint256(liquidity));

        uint256 tokenId_ = tokenId;

        LibUniswapV3Stake.StakedTotalTokenAmount storage _userTotalStaked =
            userTotalStaked[msg.sender];
        _userTotalStaked.totalDepositAmount = _userTotalStaked
            .totalDepositAmount
            .add(uint256(liquidity));
        LibUniswapV3Stake.StakedTokenAmount storage _stakedCoinageTokens =
            stakedCoinageTokens[tokenId_];
        _stakedCoinageTokens.amount = _stakedCoinageTokens.amount.add(
            uint256(liquidity)
        );

        //mint coinage of user amount
        IAutoRefactorCoinageWithTokenId(coinage).mint(
            msg.sender,
            tokenId_,
            uint256(liquidity).mul(10**9)
        );

        _depositTokens.claimLock = false;

        emit IncreasedLiquidity(
            msg.sender,
            tokenId_,
            liquidity,
            amount0,
            amount1
        );
        return true;
    }

    function collect(uint256 tokenId, uint128 amount0Max, uint128 amount1Max) public returns (bool) {

        LibUniswapV3Stake.StakeLiquidity storage _depositTokens =
            depositTokens[tokenId];
        require(
            msg.sender == _depositTokens.owner,
            "StakeUniswapV3Upgrade1: not owner"
        );
        require(
            !_depositTokens.claimLock && !_depositTokens.withdraw,
            "StakeUniswapV3Upgrade1: in process"
        );
        require(
            poolToken0 != address(0) && poolToken1 != address(0),
            "StakeUniswapV3Upgrade1: zeroAddress token"
        );
        (, , , , , , , , , , uint128 tokensOwed0, uint128 tokensOwed1) =
            nonfungiblePositionManager.positions(tokenId);

        require(
            amount0Max <= tokensOwed0 && amount1Max <= tokensOwed1,
            "StakeUniswapV3Upgrade1: tokensOwed is insufficient"
        );

        require(
            amount0Max > 0 || amount1Max > 0,
            "StakeUniswapV3Upgrade1: zero amount"
        );

        _depositTokens.claimLock = true;

        (uint256 amount0, uint256 amount1) =
            nonfungiblePositionManager.collect(
                INonfungiblePositionManager.CollectParams({
                    tokenId: tokenId,
                    recipient: _depositTokens.owner,
                    amount0Max: amount0Max,
                    amount1Max: amount1Max
                })
            );

        _depositTokens.claimLock = false;
        emit Collected(msg.sender, tokenId, amount0, amount1);
        return true;
    }

    function decreaseLiquidity(uint256 tokenId,
            uint128 paramliquidity,
            uint256 amount0Min,
            uint256 amount1Min,
            uint256 deadline)
        external
        payable
        returns (bool ret)
    {

        LibUniswapV3Stake.StakeLiquidity storage _depositTokens =
            depositTokens[tokenId];
        require(
            msg.sender == _depositTokens.owner,
            "StakeUniswapV3Upgrade1: not owner"
        );
        require(
            _depositTokens.liquidity > paramliquidity,
            "StakeUniswapV3Upgrade1: insufficient liquidity"
        );
        require(
            !_depositTokens.claimLock && !_depositTokens.withdraw,
            "StakeUniswapV3Upgrade1: in process"
        );
        require(
            checkCurrentPosition(
                _depositTokens.tickLower,
                _depositTokens.tickUpper
            ),
            "StakeUniswapV3Upgrade1: out of range"
        );

        _depositTokens.claimLock = true;
        ret = true;

        //uint128 positionLiquidity = liquidity;
        miningCoinage();
        (uint256 amount0, uint256 amount1) =
            nonfungiblePositionManager.decreaseLiquidity(
                INonfungiblePositionManager.DecreaseLiquidityParams({
                    tokenId: tokenId,
                    liquidity: paramliquidity,
                    amount0Min: amount0Min,
                    amount1Min: amount1Min,
                    deadline: deadline
                })
            );
        (
            ,
            ,
            ,
            ,
            ,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(tokenId);
        _depositTokens.tickLower = tickLower;
        _depositTokens.tickUpper = tickUpper;

        uint256 tokenId_ = tokenId;
        //_depositTokens.liquidity -= positionLiquidity;
        uint128 diffLiquidity = _depositTokens.liquidity - liquidity;
        _depositTokens.liquidity = liquidity;

        totalStakedAmount = totalStakedAmount.sub(uint256(diffLiquidity));

        LibUniswapV3Stake.StakedTotalTokenAmount storage _userTotalStaked =
            userTotalStaked[msg.sender];
        _userTotalStaked.totalDepositAmount = _userTotalStaked
            .totalDepositAmount
            .sub(uint256(diffLiquidity));
        LibUniswapV3Stake.StakedTokenAmount storage _stakedCoinageTokens =
            stakedCoinageTokens[tokenId_];
        _stakedCoinageTokens.amount = _stakedCoinageTokens.amount.sub(
            uint256(diffLiquidity)
        );

        uint256 amount0_ = amount0;
        uint256 amount1_ = amount1;

        //mint coinage of user amount
        IAutoRefactorCoinageWithTokenId(coinage).burn(
            msg.sender,
            tokenId_,
            uint256(diffLiquidity).mul(10**9)
        );

        _depositTokens.claimLock = false;
        emit DecreasedLiquidity(
            msg.sender,
            tokenId_,
            diffLiquidity,
            amount0_,
            amount1_
        );
    }

    function withdraw(uint256 tokenId) external returns (bool) {

        LibUniswapV3Stake.StakeLiquidity storage _depositTokens =
            depositTokens[tokenId];
        require(
            _depositTokens.owner == msg.sender,
            "StakeUniswapV3Upgrade1: not staker"
        );

        require(
            _depositTokens.withdraw == false,
            "StakeUniswapV3Upgrade1: withdrawing"
        );
        _depositTokens.withdraw = true;

        miningCoinage();

        if (totalStakedAmount >= _depositTokens.liquidity)
            totalStakedAmount = totalStakedAmount.sub(_depositTokens.liquidity);

        if (totalTokens > 0) totalTokens = totalTokens.sub(1);

        (
            uint256 miningAmount,
            uint256 nonMiningAmount,
            uint256 minableAmount,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = getMiningTokenId(tokenId);

        IAutoRefactorCoinageWithTokenId(coinage).burnTokenId(
            msg.sender,
            tokenId
        );

        // storage  StakedTotalTokenAmount
        LibUniswapV3Stake.StakedTotalTokenAmount storage _userTotalStaked =
            userTotalStaked[msg.sender];
        _userTotalStaked.totalDepositAmount = _userTotalStaked
            .totalDepositAmount
            .sub(_depositTokens.liquidity);
        _userTotalStaked.totalMiningAmount = _userTotalStaked
            .totalMiningAmount
            .add(miningAmount);
        _userTotalStaked.totalNonMiningAmount = _userTotalStaked
            .totalNonMiningAmount
            .add(nonMiningAmount);

        // total
        miningAmountTotal = miningAmountTotal.add(miningAmount);
        nonMiningAmountTotal = nonMiningAmountTotal.add(nonMiningAmount);

        deleteUserToken(_depositTokens.owner, tokenId, _depositTokens.idIndex);

        delete depositTokens[tokenId];
        delete stakedCoinageTokens[tokenId];

        if (_userTotalStaked.totalDepositAmount == 0) {
            totalStakers = totalStakers.sub(1);
            delete userTotalStaked[msg.sender];
        }

        if (minableAmount > 0) {
            require(
                IIStake2Vault(vault).claimMining(
                    msg.sender,
                    minableAmount,
                    miningAmount,
                    nonMiningAmount
                ),
                "fail claimMining"
            );
        }

        nonfungiblePositionManager.safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        emit WithdrawalToken(
            msg.sender,
            tokenId,
            miningAmount,
            nonMiningAmount
        );
        return true;
    }

    /// @dev delete user's token storage of index place
    /// @param _owner tokenId's owner
    /// @param tokenId tokenId
    /// @param _index owner's tokenId's index
    function deleteUserToken(
        address _owner,
        uint256 tokenId,
        uint256 _index
    ) internal {
        uint256 _tokenid = userStakedTokenIds[_owner][_index];
        require(_tokenid == tokenId, "StakeUniswapV3Upgrade1: mismatch token");
        uint256 lastIndex = (userStakedTokenIds[_owner].length).sub(1);
        if (tokenId > 0 && _tokenid == tokenId) {
            if (_index < lastIndex) {
                uint256 tokenId_lastIndex =
                    userStakedTokenIds[_owner][lastIndex];
                userStakedTokenIds[_owner][_index] = tokenId_lastIndex;
                depositTokens[tokenId_lastIndex].idIndex = _index;
            }
            userStakedTokenIds[_owner].pop();
        }
    }

    /// @dev view mining information of tokenId
    /// @param tokenId  tokenId
    function getMiningTokenId(uint256 tokenId)
        public
        view
        returns (
            uint256 miningAmount,
            uint256 nonMiningAmount,
            uint256 minableAmount,
            uint160 secondsInside,
            uint256 secondsInsideDiff256,
            uint256 liquidity,
            uint256 balanceOfTokenIdRay,
            uint256 minableAmountRay,
            uint256 secondsInside256,
            uint256 secondsAbsolute256
        )
    {
        if (
            stakeStartTime < block.timestamp && stakeStartTime < block.timestamp
        ) {
            LibUniswapV3Stake.StakeLiquidity storage _depositTokens =
                depositTokens[tokenId];
            liquidity = _depositTokens.liquidity;

            uint32 secondsAbsolute = 0;
            balanceOfTokenIdRay = IAutoRefactorCoinageWithTokenId(coinage)
                .balanceOf(tokenId);

            uint256 curBlockTimestamp = block.timestamp;
            uint256 _miningEndTime = IIStake2Vault(vault).miningEndTime();
            if (curBlockTimestamp > _miningEndTime)
                curBlockTimestamp = _miningEndTime;

            if (_depositTokens.liquidity > 0 && balanceOfTokenIdRay > 0) {
                if (balanceOfTokenIdRay > liquidity.mul(10**9)) {
                    minableAmountRay = balanceOfTokenIdRay.sub(
                        liquidity.mul(10**9)
                    );
                    minableAmount = minableAmountRay.div(10**9);
                }
                if (minableAmount > 0) {
                    (, , secondsInside) = IUniswapV3Pool(poolAddress)
                        .snapshotCumulativesInside(
                        _depositTokens.tickLower,
                        _depositTokens.tickUpper
                    );
                    secondsInside256 = uint256(secondsInside);

                    if (_depositTokens.claimedTime > 0)
                        secondsAbsolute = uint32(curBlockTimestamp).sub(
                            _depositTokens.claimedTime
                        );
                    else
                        secondsAbsolute = uint32(curBlockTimestamp).sub(
                            _depositTokens.startTime
                        );
                    secondsAbsolute256 = uint256(secondsAbsolute);

                    if (secondsAbsolute > 0) {
                        if (_depositTokens.secondsInsideLast > 0) {
                            // unit32 문제로 더 작은 수가 나올수있다.
                            if(secondsInside < _depositTokens.secondsInsideLast){
                               secondsInsideDiff256 = secondsInside256.add(
                                   uint256(type(uint32).max).sub(uint256(_depositTokens.secondsInsideLast))
                                   );
                            } else {
                                secondsInsideDiff256 = secondsInside256.sub(
                                    uint256(_depositTokens.secondsInsideLast)
                                );
                            }
                        } else {
                            // unit32 문제로 더 작은 수가 나올수있다.
                            if(secondsInside < _depositTokens.secondsInsideInitial){
                                secondsInsideDiff256 = secondsInside256.add(
                                    uint256(type(uint32).max).sub(uint256(_depositTokens.secondsInsideInitial))
                                    );
                            } else {
                                secondsInsideDiff256 = secondsInside256.sub(
                                    uint256(_depositTokens.secondsInsideInitial)
                                );
                            }
                        }

                        if (
                            secondsInsideDiff256 < secondsAbsolute256 &&
                            secondsInsideDiff256 > 0
                        ) {
                            miningAmount = minableAmount
                                .mul(secondsInsideDiff256)
                                .div(secondsAbsolute256);
                            nonMiningAmount = minableAmount.sub(miningAmount);
                        } else if (secondsInsideDiff256 > 0) {
                            miningAmount = minableAmount;
                            nonMiningAmount = 0;
                        } else {
                            nonMiningAmount = minableAmount;
                            miningAmount = 0;
                        }

                    }
                }
            }
        }
    }

    function claim(uint256 tokenId) public returns (bool) {

        LibUniswapV3Stake.StakeLiquidity storage _depositTokens =
            depositTokens[tokenId];

        require(
            _depositTokens.owner == msg.sender,
            "StakeUniswapV3Upgrade1: not staker"
        );

        require(
            _depositTokens.claimedTime <
                uint32(block.timestamp.sub(miningIntervalSeconds)),
            "StakeUniswapV3Upgrade1: already claimed"
        );

        require(
            _depositTokens.claimLock == false,
            "StakeUniswapV3Upgrade1: claiming"
        );
        _depositTokens.claimLock = true;

        miningCoinage();

        (
            uint256 miningAmount,
            uint256 nonMiningAmount,
            uint256 minableAmount,
            uint160 secondsInside,
            ,
            ,
            ,
            uint256 minableAmountRay,
            ,

        ) = getMiningTokenId(tokenId);

        require(miningAmount > 0, "StakeUniswapV3Upgrade1: zero miningAmount");

        _depositTokens.claimedTime = uint32(block.timestamp);
        _depositTokens.secondsInsideLast = secondsInside;

        IAutoRefactorCoinageWithTokenId(coinage).burn(
            msg.sender,
            tokenId,
            minableAmountRay
        );

        // storage  stakedCoinageTokens
        LibUniswapV3Stake.StakedTokenAmount storage _stakedCoinageTokens =
            stakedCoinageTokens[tokenId];
        _stakedCoinageTokens.claimedTime = uint32(block.timestamp);
        _stakedCoinageTokens.claimedAmount = _stakedCoinageTokens
            .claimedAmount
            .add(miningAmount);
        _stakedCoinageTokens.nonMiningAmount = _stakedCoinageTokens
            .nonMiningAmount
            .add(nonMiningAmount);

        // storage  StakedTotalTokenAmount
        LibUniswapV3Stake.StakedTotalTokenAmount storage _userTotalStaked =
            userTotalStaked[msg.sender];
        _userTotalStaked.totalMiningAmount = _userTotalStaked
            .totalMiningAmount
            .add(miningAmount);
        _userTotalStaked.totalNonMiningAmount = _userTotalStaked
            .totalNonMiningAmount
            .add(nonMiningAmount);

        // total
        miningAmountTotal = miningAmountTotal.add(miningAmount);
        nonMiningAmountTotal = nonMiningAmountTotal.add(nonMiningAmount);

        require(
            IIStake2Vault(vault).claimMining(
                msg.sender,
                minableAmount,
                miningAmount,
                nonMiningAmount
            )
        );

        _depositTokens.claimLock = false;

        emit Claimed(
            msg.sender,
            tokenId,
            poolAddress,
            miningAmount,
            nonMiningAmount
        );
        return true;
    }

    function claimAndCollect(uint256 tokenId, uint128 amount0Max, uint128 amount1Max) external returns (bool) {

        require(
            claim(tokenId),
            "StakeUniswapV3Upgrade1: fail claim"
        );
        require(collect(tokenId, amount0Max, amount1Max), "StakeUniswapV3Upgrade1: fail collect");
        return true;
    }
}
