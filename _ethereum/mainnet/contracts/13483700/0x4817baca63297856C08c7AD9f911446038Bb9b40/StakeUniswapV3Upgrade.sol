// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IUniswapV3Pool.sol";
import "./PoolAddress.sol";
import "./INonfungiblePositionManager.sol";
import "./TransferHelper.sol";
//import "./IStakeRegistry.sol";
import "./IIStakeUniswapV3.sol";
import "./IAutoRefactorCoinageWithTokenId.sol";
import "./IIStake2Vault.sol";
import "./DSMath.sol";
import "./AccessibleCommon.sol";
import "./StakeUniswapV3Storage.sol";
import "./SafeMath.sol";
import "./SafeMath32.sol";


/// @title StakeUniswapV3Upgrade
/// @notice Uniswap V3 Contract for staking LP and mining TOS
contract StakeUniswapV3Upgrade is
    StakeUniswapV3Storage,
    AccessibleCommon,
    IIStakeUniswapV3,
    DSMath
{
    using SafeMath for uint256;
    using SafeMath32 for uint32;

    /// @dev event on staking
    /// @param to the sender
    /// @param poolAddress the pool address of uniswapV3
    /// @param tokenId the uniswapV3 Lp token
    /// @param amount the amount of staking
    event Staked(
        address indexed to,
        address indexed poolAddress,
        uint256 tokenId,
        uint256 amount
    );

    /// @dev event on mining in coinage
    /// @param curTime the current time
    /// @param miningInterval mining period (sec)
    /// @param miningAmount the mining amount
    /// @param prevTotalSupply Total amount of coinage before mining
    /// @param afterTotalSupply Total amount of coinage after being mined
    /// @param factor coinage's Factor
    event MinedCoinage(
        uint256 curTime,
        uint256 miningInterval,
        uint256 miningAmount,
        uint256 prevTotalSupply,
        uint256 afterTotalSupply,
        uint256 factor
    );

    event MintAndStaked(
        address indexed to,
        address indexed poolAddress,
        uint256 tokenId,
        uint256 liquidity,
        uint256 amount0,
        uint256 amount1
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


    /// @dev calculate the factor of coinage
    /// @param source tsource
    /// @param target target
    /// @param oldFactor oldFactor
    function _calcNewFactor(
        uint256 source,
        uint256 target,
        uint256 oldFactor
    ) internal pure returns (uint256) {
        return rdiv(rmul(target, oldFactor), source);
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
        require(_tokenid == tokenId, "StakeUniswapV3Upgrade: mismatch token");
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

    /// @dev view mining information of tokenId
    /// @param tokenId  tokenId
    function getMiningTokenId(uint256 tokenId)
        public
        view
        override
        nonZeroAddress(poolAddress)
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
            //uint256 _miningEndTime = IIStake2Vault(vault).miningEndTime();
            if (curBlockTimestamp > IIStake2Vault(vault).miningEndTime())
                curBlockTimestamp = IIStake2Vault(vault).miningEndTime();

            if (_depositTokens.liquidity > 0 && balanceOfTokenIdRay > 0) {
                uint256 _minableAmount = 0;
                if (balanceOfTokenIdRay > liquidity.mul(10**9)) {
                    minableAmountRay = balanceOfTokenIdRay.sub(
                        liquidity.mul(10**9)
                    );
                    _minableAmount = minableAmountRay.div(10**9);
                }
                if (_minableAmount > 0) {
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

                        minableAmount = _minableAmount;
                        if (
                            secondsInsideDiff256 < secondsAbsolute256 &&
                            secondsInsideDiff256 > 0
                        ) {
                            miningAmount = _minableAmount
                                .mul(secondsInsideDiff256)
                                .div(secondsAbsolute256);
                        } else if (secondsInsideDiff256 > 0) {
                            miningAmount = _minableAmount;
                        }

                        nonMiningAmount = minableAmount.sub(miningAmount);
                    }
                }
            }
        }
    }

    /// @dev stake tokenId of UniswapV3
    /// @param tokenId  tokenId
    /// @param deadline the deadline that valid the owner's signature
    /// @param v the owner's signature - v
    /// @param r the owner's signature - r
    /// @param s the owner's signature - s
    function stakePermit(
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        override
        nonZeroAddress(token)
        nonZeroAddress(vault)
        nonZeroAddress(stakeRegistry)
        nonZeroAddress(poolToken0)
        nonZeroAddress(poolToken1)
        nonZeroAddress(address(nonfungiblePositionManager))
        nonZeroAddress(uniswapV3FactoryAddress)
    {
        require(
            saleStartTime < block.timestamp,
            "StakeUniswapV3Upgrade: before start"
        );

        require(
            block.timestamp < IIStake2Vault(vault).miningEndTime(),
            "StakeUniswapV3Upgrade: end mining"
        );

        require(
            nonfungiblePositionManager.ownerOf(tokenId) == msg.sender,
            "StakeUniswapV3Upgrade: not owner"
        );

        nonfungiblePositionManager.permit(
            address(this),
            tokenId,
            deadline,
            v,
            r,
            s
        );

        _stake(tokenId);
    }

    /// @dev stake tokenId of UniswapV3
    /// @param tokenId  tokenId
    function stake(uint256 tokenId)
        external
        override
        nonZeroAddress(token)
        nonZeroAddress(vault)
        nonZeroAddress(stakeRegistry)
        nonZeroAddress(poolToken0)
        nonZeroAddress(poolToken1)
        nonZeroAddress(address(nonfungiblePositionManager))
        nonZeroAddress(uniswapV3FactoryAddress)
        nonZeroAddress(poolAddress)
    {
        require(
            saleStartTime < block.timestamp,
            "StakeUniswapV3Upgrade: before start"
        );
        require(
            block.timestamp < IIStake2Vault(vault).miningEndTime(),
            "StakeUniswapV3Upgrade: end mining"
        );
        require(
            nonfungiblePositionManager.ownerOf(tokenId) == msg.sender,
            "StakeUniswapV3Upgrade: not owner"
        );

        _stake(tokenId);
    }

    /// @dev stake tokenId of UniswapV3
    /// @param tokenId  tokenId
    function _stake(uint256 tokenId) internal {
        LibUniswapV3Stake.StakeLiquidity storage _depositTokens =
            depositTokens[tokenId];

        require(
            _depositTokens.owner == address(0),
            "StakeUniswapV3Upgrade: Already staked"
        );

        uint256 _tokenId = tokenId;
        (
            ,
            ,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(_tokenId);

        require(
            (token0 == poolToken0 && token1 == poolToken1) ||
                (token0 == poolToken1 && token1 == poolToken0),
            "StakeUniswapV3Upgrade: different token"
        );

        require(liquidity > 0, "StakeUniswapV3Upgrade: zero liquidity");

        if (poolAddress == address(0)) {
            poolAddress = PoolAddress.computeAddress(
                uniswapV3FactoryAddress,
                PoolAddress.PoolKey({token0: token0, token1: token1, fee: fee})
            );
        }

        require(poolAddress != address(0), "StakeUniswapV3Upgrade: zero poolAddress");

        require(
            checkCurrentPosition(tickLower, tickUpper),
            "StakeUniswapV3Upgrade: locked or out of range"
        );

        (, , uint32 secondsInside) =
            IUniswapV3Pool(poolAddress).snapshotCumulativesInside(
                tickLower,
                tickUpper
            );

        uint256 tokenId_ = _tokenId;

        // initial start time
        if (stakeStartTime == 0) stakeStartTime = block.timestamp;

        _depositTokens.owner = msg.sender;
        _depositTokens.idIndex = userStakedTokenIds[msg.sender].length;
        _depositTokens.liquidity = liquidity;
        _depositTokens.tickLower = tickLower;
        _depositTokens.tickUpper = tickUpper;
        _depositTokens.startTime = uint32(block.timestamp);
        _depositTokens.claimedTime = 0;
        _depositTokens.secondsInsideInitial = secondsInside;
        _depositTokens.secondsInsideLast = 0;

        nonfungiblePositionManager.transferFrom(
            msg.sender,
            address(this),
            tokenId_
        );

        // save tokenid
        userStakedTokenIds[msg.sender].push(tokenId_);

        totalStakedAmount = totalStakedAmount.add(liquidity);
        totalTokens = totalTokens.add(1);

        LibUniswapV3Stake.StakedTotalTokenAmount storage _userTotalStaked =
            userTotalStaked[msg.sender];
        if (!_userTotalStaked.staked) totalStakers = totalStakers.add(1);
        _userTotalStaked.staked = true;
        _userTotalStaked.totalDepositAmount = _userTotalStaked
            .totalDepositAmount
            .add(liquidity);

        LibUniswapV3Stake.StakedTokenAmount storage _stakedCoinageTokens =
            stakedCoinageTokens[tokenId_];
        _stakedCoinageTokens.amount = liquidity;
        _stakedCoinageTokens.startTime = uint32(block.timestamp);

        //mint coinage of user amount
        IAutoRefactorCoinageWithTokenId(coinage).mint(
            msg.sender,
            tokenId_,
            uint256(liquidity).mul(10**9)
        );

        miningCoinage();

        emit Staked(msg.sender, poolAddress, tokenId_, liquidity);
    }

    function checkCurrentPosition(int24 tickLower, int24 tickUpper)
        internal
        view
        returns (bool)
    {
        (, int24 tick, , , , , bool unlocked) =
            IUniswapV3Pool(poolAddress).slot0();
        if (unlocked && tickLower < tick && tick < tickUpper) return true;
        else return false;
    }

    function mint(int24 tickLower, int24 tickUpper,
        uint256 amount0Desired, uint256 amount1Desired, uint256 amount0Min, uint256 amount1Min,
        uint256 deadline)
        external
    {
        require(
            saleStartTime < block.timestamp,
            "StakeUniswapV3Upgrade: before start"
        );

        require(
            block.timestamp < IIStake2Vault(vault).miningEndTime(),
            "StakeUniswapV3Upgrade: end mining"
        );

        require(
            poolToken0 != address(0) && poolToken1 != address(0),
            "StakeUniswapV3Upgrade: zeroAddress token"
        );
        require(
            checkCurrentPosition(tickLower, tickUpper),
            "StakeUniswapV3Upgrade: out of range"
        );

        require(
            amount0Desired > 0 ||  amount1Desired > 0,
            "StakeUniswapV3Upgrade: liquidity zero"
        );

        if(amount0Desired > 0 ){
             TransferHelper.safeTransferFrom(
                poolToken0,
                msg.sender,
                address(this),
                amount0Desired
            );
        }
        if(amount1Desired > 0 ){
            TransferHelper.safeTransferFrom(
                poolToken1,
                msg.sender,
                address(this),
                amount1Desired
            );
        }

        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) =
            nonfungiblePositionManager.mint(
                INonfungiblePositionManager.MintParams({
                    token0: poolToken0,
                    token1: poolToken1,
                    fee: uint24(poolFee),
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    amount0Desired: amount0Desired,
                    amount1Desired: amount1Desired,
                    amount0Min: amount0Min,
                    amount1Min: amount1Min,
                    recipient: address(this),
                    deadline: deadline
                })
            );

        require(nonfungiblePositionManager.ownerOf(tokenId) == address(this), "StakeUniswapV3Upgrade: owner wrong");

        if(amount0 < amount0Desired) {
            TransferHelper.safeTransfer(
                poolToken0,
                msg.sender,
                amount0Desired.sub(amount0)
            );
        }
        if(amount1 < amount1Desired) {
            TransferHelper.safeTransfer(
                poolToken1,
                msg.sender,
                amount1Desired.sub(amount1)
            );
        }

        require(
            tokenId > 0 && liquidity > 0,
            "StakeUniswapV3Upgrade: zero tokenId or liquidity"
        );

        LibUniswapV3Stake.StakeLiquidity storage _depositTokens =
            depositTokens[tokenId];
        require(
            _depositTokens.owner == address(0),
            "StakeUniswapV3Upgrade: already staked"
        );
        _depositTokens.owner = msg.sender;

        (, , uint32 secondsInside) =
            IUniswapV3Pool(poolAddress).snapshotCumulativesInside(
                tickLower,
                tickUpper
            );

        _depositTokens.idIndex = userStakedTokenIds[msg.sender].length;
        _depositTokens.liquidity = liquidity;
        _depositTokens.tickLower = tickLower;
        _depositTokens.tickUpper = tickUpper;
        _depositTokens.startTime = uint32(block.timestamp);
        _depositTokens.claimedTime = 0;
        _depositTokens.secondsInsideInitial = secondsInside;
        _depositTokens.secondsInsideLast = 0;

        userStakedTokenIds[msg.sender].push(tokenId);

        totalStakedAmount = totalStakedAmount.add(liquidity);
        totalTokens = totalTokens.add(1);

        LibUniswapV3Stake.StakedTotalTokenAmount storage _userTotalStaked =
            userTotalStaked[msg.sender];

        if (!_userTotalStaked.staked) {
            totalStakers = totalStakers.add(1);
            _userTotalStaked.staked = true;
        }

        _userTotalStaked.totalDepositAmount = _userTotalStaked
            .totalDepositAmount
            .add(liquidity);

        LibUniswapV3Stake.StakedTokenAmount storage _stakedCoinageTokens =
            stakedCoinageTokens[tokenId];
        _stakedCoinageTokens.amount = liquidity;
        _stakedCoinageTokens.startTime = uint32(block.timestamp);

        //mint coinage of user amount
        IAutoRefactorCoinageWithTokenId(coinage).mint(
            msg.sender,
            tokenId,
            uint256(liquidity).mul(10**9)
        );

        miningCoinage();

        emit MintAndStaked(msg.sender, poolAddress, tokenId, liquidity, amount0, amount1);
    }

}
