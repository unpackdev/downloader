// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IUniswapV3Pool.sol";
//import "./INonfungiblePositionManager.sol";
//import "./TransferHelper.sol";
import "./PoolAddress.sol";

//import "./IStakeRegistry.sol";
import "./IStakeUniswapV3.sol";
import "./IAutoRefactorCoinageWithTokenId.sol";
import "./IIStake2Vault.sol";
import "./DSMath.sol";
import "./AccessibleCommon.sol";
import "./StakeUniswapV3Storage.sol";
import "./SafeMath.sol";
import "./SafeMath32.sol";

/// @title StakeUniswapV3
/// @notice Uniswap V3 Contract for staking LP and mining TOS
contract StakeUniswapV3 is
    StakeUniswapV3Storage,
    AccessibleCommon,
    IStakeUniswapV3,
    DSMath
{
    using SafeMath for uint256;
    using SafeMath32 for uint32;

    struct PositionInfo {
        // the amount of liquidity owned by this position
        uint128 liquidity;
        // fee growth per unit of liquidity as of the last update to liquidity or fees owed
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        // the fees owed to the position owner in token0/token1
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    struct Slot0 {
        // the current price
        uint160 sqrtPriceX96;
        // the current tick
        int24 tick;
        // the most-recently updated index of the observations array
        uint16 observationIndex;
        // the current maximum number of observations that are being stored
        uint16 observationCardinality;
        // the next maximum number of observations to store, triggered in observations.write
        uint16 observationCardinalityNext;
        // the current protocol fee as a percentage of the swap fee taken on withdrawal
        // represented as an integer denominator (1/x)%
        uint8 feeProtocol;
        // whether the pool is locked
        bool unlocked;
    }

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

    /// @dev event on claim
    /// @param to the sender
    /// @param poolAddress the pool address of uniswapV3
    /// @param tokenId the uniswapV3 Lp token
    /// @param miningAmount the amount of mining
    /// @param nonMiningAmount the amount of non-mining
    event Claimed(
        address indexed to,
        address poolAddress,
        uint256 tokenId,
        uint256 miningAmount,
        uint256 nonMiningAmount
    );

    /// @dev event on withdrawal
    /// @param to the sender
    /// @param tokenId the uniswapV3 Lp token
    /// @param miningAmount the amount of mining
    /// @param nonMiningAmount the amount of non-mining
    event WithdrawalToken(
        address indexed to,
        uint256 tokenId,
        uint256 miningAmount,
        uint256 nonMiningAmount
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

    /// @dev event on burning in coinage
    /// @param curTime the current time
    /// @param tokenId the token id
    /// @param burningAmount the buring amount
    /// @param prevTotalSupply Total amount of coinage before mining
    /// @param afterTotalSupply Total amount of coinage after being mined
    event BurnedCoinage(
        uint256 curTime,
        uint256 tokenId,
        uint256 burningAmount,
        uint256 prevTotalSupply,
        uint256 afterTotalSupply
    );

    /// @dev constructor of StakeCoinage
    constructor() {
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);

        miningIntervalSeconds = 15;
    }

    /// @dev receive ether - revert
    receive() external payable {
        revert();
    }

    /// @dev Mining interval setting (seconds)
    /// @param _intervalSeconds the mining interval (sec)
    function setMiningIntervalSeconds(uint256 _intervalSeconds)
        external
        onlyOwner
    {
        miningIntervalSeconds = _intervalSeconds;
    }

    /// @dev reset coinage's last mining time variable for tes
    function resetCoinageTime() external onlyOwner {
        coinageLastMintBlockTimetamp = 0;
    }

    /// @dev set sale start time
    /// @param _saleStartTime sale start time
    function setSaleStartTime(uint256 _saleStartTime) external onlyOwner {
        require(
            _saleStartTime > 0 && saleStartTime != _saleStartTime,
            "StakeUniswapV3: zero or same _saleStartTime"
        );
        saleStartTime = _saleStartTime;
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
        require(_tokenid == tokenId, "StakeUniswapV3: mismatch token");
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
        if (
            IIStake2Vault(vault).miningStartTime() > block.timestamp ||
            IIStake2Vault(vault).miningEndTime() < block.timestamp
        ) return;

        if (coinageLastMintBlockTimetamp == 0)
            coinageLastMintBlockTimetamp = stakeStartTime;

        if (
            block.timestamp >
            (coinageLastMintBlockTimetamp.add(miningIntervalSeconds))
        ) {
            uint256 miningInterval =
                block.timestamp.sub(coinageLastMintBlockTimetamp);
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
                coinageLastMintBlockTimetamp = block.timestamp;

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
                        secondsAbsolute = uint32(block.timestamp).sub(
                            _depositTokens.claimedTime
                        );
                    else
                        secondsAbsolute = uint32(block.timestamp).sub(
                            _depositTokens.startTime
                        );
                    secondsAbsolute256 = uint256(secondsAbsolute);

                    if (secondsAbsolute > 0) {
                        if (_depositTokens.secondsInsideLast > 0) {
                            secondsInsideDiff256 = secondsInside256.sub(
                                uint256(_depositTokens.secondsInsideLast)
                            );
                        } else {
                            secondsInsideDiff256 = secondsInside256.sub(
                                uint256(_depositTokens.secondsInsideInitial)
                            );
                        }

                        if (
                            secondsInsideDiff256 < secondsAbsolute256 &&
                            secondsInsideDiff256 > 0
                        ) {
                            miningAmount = minableAmount
                                .mul(secondsInsideDiff256)
                                .div(secondsAbsolute256);
                            nonMiningAmount = minableAmount.sub(miningAmount);
                        } else if(secondsInsideDiff256 > 0){
                            miningAmount = minableAmount;
                        } else {
                            nonMiningAmount = minableAmount;
                        }
                    }
                }
            }
        }
    }

    /// @dev With the given tokenId, information is retrieved from nonfungiblePositionManager,
    ///      and the pool address is calculated and set.
    /// @param tokenId  tokenId
    function setPoolAddress(uint256 tokenId)
        external
        onlyOwner
        nonZeroAddress(token)
        nonZeroAddress(vault)
        nonZeroAddress(stakeRegistry)
        nonZeroAddress(poolToken0)
        nonZeroAddress(poolToken1)
        nonZeroAddress(address(nonfungiblePositionManager))
        nonZeroAddress(uniswapV3FactoryAddress)
    {
        require(poolAddress == address(0), "StakeUniswapV3: already set");
        (, , address token0, address token1, uint24 fee, , , , , , , ) =
            nonfungiblePositionManager.positions(tokenId);

        require(
            (token0 == poolToken0 && token1 == poolToken1) ||
                (token0 == poolToken1 && token1 == poolToken0),
            "StakeUniswapV3: different token"
        );
        poolToken0 = token0;
        poolToken1 = token1;

        poolAddress = PoolAddress.computeAddress(
            uniswapV3FactoryAddress,
            PoolAddress.PoolKey({token0: token0, token1: token1, fee: fee})
        );
        poolFee = fee;
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
            "StakeUniswapV3: before start"
        );

        require(
            block.timestamp < IIStake2Vault(vault).miningEndTime(),
            "StakeUniswapV3: end mining"
        );

        require(
            nonfungiblePositionManager.ownerOf(tokenId) == msg.sender,
            "StakeUniswapV3: not owner"
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
    {
        require(
            saleStartTime < block.timestamp,
            "StakeUniswapV3: before start"
        );
        require(
            block.timestamp < IIStake2Vault(vault).miningEndTime(),
            "StakeUniswapV3: end mining"
        );
        require(
            nonfungiblePositionManager.ownerOf(tokenId) == msg.sender,
            "StakeUniswapV3: not owner"
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
            "StakeUniswapV3: Already staked"
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
            "StakeUniswapV3: different token"
        );

        require(liquidity > 0, "StakeUniswapV3: zero liquidity");

        if (poolAddress == address(0)) {
            poolAddress = PoolAddress.computeAddress(
                uniswapV3FactoryAddress,
                PoolAddress.PoolKey({token0: token0, token1: token1, fee: fee})
            );
        }

        require(poolAddress != address(0), "StakeUniswapV3: zero poolAddress");

        (, int24 tick, , , , , bool unlocked) =
            IUniswapV3Pool(poolAddress).slot0();
        require(unlocked, "StakeUniswapV3: unlocked pool");
        require(
            tickLower < tick && tick < tickUpper,
            "StakeUniswapV3: out of tick range"
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

    /// @dev The amount mined with the deposited liquidity is claimed and taken.
    ///      The amount of mining taken is changed in proportion to the amount of time liquidity
    ///       has been provided since recent mining
    /// @param tokenId  tokenId
    function claim(uint256 tokenId) external override {
        LibUniswapV3Stake.StakeLiquidity storage _depositTokens =
            depositTokens[tokenId];

        require(
            _depositTokens.owner == msg.sender,
            "StakeUniswapV3: not staker"
        );

        require(
            _depositTokens.claimedTime <
                uint32(block.timestamp.sub(miningIntervalSeconds)),
            "StakeUniswapV3: already claimed"
        );

        require(_depositTokens.claimLock == false, "StakeUniswapV3: claiming");
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

        require(miningAmount > 0, "StakeUniswapV3: zero miningAmount");

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
            poolAddress,
            tokenId,
            miningAmount,
            nonMiningAmount
        );
    }

    /// @dev withdraw the deposited token.
    ///      The amount mined with the deposited liquidity is claimed and taken.
    ///      The amount of mining taken is changed in proportion to the amount of time liquidity
    ///      has been provided since recent mining
    /// @param tokenId  tokenId
    function withdraw(uint256 tokenId) external override {
        LibUniswapV3Stake.StakeLiquidity storage _depositTokens =
            depositTokens[tokenId];
        require(
            _depositTokens.owner == msg.sender,
            "StakeUniswapV3: not staker"
        );

        require(
            _depositTokens.withdraw == false,
            "StakeUniswapV3: withdrawing"
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

        if (minableAmount > 0)
            require(
                IIStake2Vault(vault).claimMining(
                    msg.sender,
                    minableAmount,
                    miningAmount,
                    nonMiningAmount
                )
            );

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
    }

    /// @dev Get the list of staked tokens of the user
    /// @param user  user address
    function getUserStakedTokenIds(address user)
        external
        view
        override
        returns (uint256[] memory ids)
    {
        return userStakedTokenIds[user];
    }

    /// @dev tokenId's deposited information
    /// @param tokenId   tokenId
    /// @return _poolAddress   poolAddress
    /// @return tick tick,
    /// @return liquidity liquidity,
    /// @return args liquidity,  startTime, claimedTime, startBlock, claimedBlock, claimedAmount
    /// @return secondsPL secondsPerLiquidityInsideInitialX128, secondsPerLiquidityInsideX128Las
    function getDepositToken(uint256 tokenId)
        external
        view
        override
        returns (
            address _poolAddress,
            int24[2] memory tick,
            uint128 liquidity,
            uint256[5] memory args,
            uint160[2] memory secondsPL
        )
    {
        LibUniswapV3Stake.StakeLiquidity memory _depositTokens =
            depositTokens[tokenId];
        LibUniswapV3Stake.StakedTokenAmount memory _stakedCoinageTokens =
            stakedCoinageTokens[tokenId];

        return (
            poolAddress,
            [_depositTokens.tickLower, _depositTokens.tickUpper],
            _depositTokens.liquidity,
            [
                _depositTokens.startTime,
                _depositTokens.claimedTime,
                _stakedCoinageTokens.startTime,
                _stakedCoinageTokens.claimedTime,
                _stakedCoinageTokens.claimedAmount
            ],
            [
                _depositTokens.secondsInsideInitial,
                _depositTokens.secondsInsideLast
            ]
        );
    }

    /// @dev user's staked total infos
    /// @param user  user address
    /// @return totalDepositAmount  total deposited amount
    /// @return totalMiningAmount total mining amount ,
    /// @return totalNonMiningAmount total non-mining amount,
    function getUserStakedTotal(address user)
        external
        view
        override
        returns (
            uint256 totalDepositAmount,
            uint256 totalMiningAmount,
            uint256 totalNonMiningAmount
        )
    {
        return (
            userTotalStaked[user].totalDepositAmount,
            userTotalStaked[user].totalMiningAmount,
            userTotalStaked[user].totalNonMiningAmount
        );
    }

    /// @dev totalSupply of coinage
    function totalSupplyCoinage() external view returns (uint256) {
        return IAutoRefactorCoinageWithTokenId(coinage).totalSupply();
    }

    /// @dev balanceOf of tokenId's coinage
    function balanceOfCoinage(uint256 tokenId) external view returns (uint256) {
        return IAutoRefactorCoinageWithTokenId(coinage).balanceOf(tokenId);
    }

    /// @dev Give the infomation of this stakeContracts
    /// @return return1  [token, vault, stakeRegistry, coinage]
    /// @return return2  [poolToken0, poolToken1, nonfungiblePositionManager, uniswapV3FactoryAddress]
    /// @return return3  [totalStakers, totalStakedAmount, miningAmountTotal,nonMiningAmountTotal]
    function infos()
        external
        view
        override
        returns (
            address[4] memory,
            address[4] memory,
            uint256[4] memory
        )
    {
        return (
            [token, vault, stakeRegistry, coinage],
            [
                poolToken0,
                poolToken1,
                address(nonfungiblePositionManager),
                uniswapV3FactoryAddress
            ],
            [
                totalStakers,
                totalStakedAmount,
                miningAmountTotal,
                nonMiningAmountTotal
            ]
        );
    }

    /*
    /// @dev pool's infos
    /// @return factory  pool's factory address
    /// @return token0  token0 address
    /// @return token1  token1 address
    /// @return fee  fee
    /// @return tickSpacing  tickSpacing
    /// @return maxLiquidityPerTick  maxLiquidityPerTick
    /// @return liquidity  pool's liquidity
    function poolInfos()
        external
        view
        override
        nonZeroAddress(poolAddress)
        returns (
            address factory,
            address token0,
            address token1,
            uint24 fee,
            int24 tickSpacing,
            uint128 maxLiquidityPerTick,
            uint128 liquidity
        )
    {
        liquidity = IUniswapV3Pool(poolAddress).liquidity();
        factory = IUniswapV3Pool(poolAddress).factory();
        token0 = IUniswapV3Pool(poolAddress).token0();
        token1 = IUniswapV3Pool(poolAddress).token1();
        fee = IUniswapV3Pool(poolAddress).fee();
        tickSpacing = IUniswapV3Pool(poolAddress).tickSpacing();
        maxLiquidityPerTick = IUniswapV3Pool(poolAddress).maxLiquidityPerTick();
    }
    */
    /*
    /// @dev key's info
    /// @param key hash(owner, tickLower, tickUpper)
    /// @return _liquidity  key's liquidity
    /// @return feeGrowthInside0LastX128  key's feeGrowthInside0LastX128
    /// @return feeGrowthInside1LastX128  key's feeGrowthInside1LastX128
    /// @return tokensOwed0  key's tokensOwed0
    /// @return tokensOwed1  key's tokensOwed1
    function poolPositions(bytes32 key)
        external
        view
        override
        nonZeroAddress(poolAddress)
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        (
            _liquidity,
            feeGrowthInside0LastX128,
            feeGrowthInside1LastX128,
            tokensOwed0,
            tokensOwed1
        ) = IUniswapV3Pool(poolAddress).positions(key);
    }
    */

    /// @dev pool's slot0 (current position)
    /// @return sqrtPriceX96  The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick  The current tick of the pool
    /// @return observationIndex  The index of the last oracle observation that was written,
    /// @return observationCardinality  The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext  The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol  The protocol fee for both tokens of the pool
    /// @return unlocked  Whether the pool is currently locked to reentrancy
    function poolSlot0()
        external
        view
        override
        nonZeroAddress(poolAddress)
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        )
    {
        (
            sqrtPriceX96,
            tick,
            observationIndex,
            observationCardinality,
            observationCardinalityNext,
            feeProtocol,
            unlocked
        ) = IUniswapV3Pool(poolAddress).slot0();
    }

    /*
    /// @dev _tokenId's position
    /// @param _tokenId  tokenId
    /// @return nonce  the nonce for permits
    /// @return operator  the address that is approved for spending this token
    /// @return token0  The address of the token0 for pool
    /// @return token1  The address of the token1 for pool
    /// @return fee  The fee associated with the pool
    /// @return tickLower  The lower end of the tick range for the position
    /// @return tickUpper  The higher end of the tick range for the position
    /// @return liquidity  The liquidity of the position
    /// @return feeGrowthInside0LastX128  The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128  The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0  The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1  The uncollected amount of token1 owed to the position as of the last computation
    function npmPositions(uint256 _tokenId)
        external
        view
        override
        nonZeroAddress(address(nonfungiblePositionManager))
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        return nonfungiblePositionManager.positions(_tokenId);
    }
    */
    /*
    /// @dev snapshotCumulativesInside
    /// @param tickLower  The lower tick of the range
    /// @param tickUpper  The upper tick of the range
    /// @return tickCumulativeInside  The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128  The snapshot of seconds per liquidity for the range
    /// @return secondsInside  The snapshot of seconds per liquidity for the range
    /// @return curTimestamps  current Timestamps
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        override
        nonZeroAddress(poolAddress)
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside,
            uint32 curTimestamps
        )
    {
        tickCumulativeInside;
        secondsPerLiquidityInsideX128;
        secondsInside;
        curTimestamps = uint32(block.timestamp);

        (
            tickCumulativeInside,
            secondsPerLiquidityInsideX128,
            secondsInside
        ) = IUniswapV3Pool(poolAddress).snapshotCumulativesInside(
            tickLower,
            tickUpper
        );
    }
    */
    /// @dev mining end time
    /// @return endTime mining end time
    function miningEndTime()
        external
        view
        override
        nonZeroAddress(vault)
        returns (uint256)
    {
        return IIStake2Vault(vault).miningEndTime();
    }

    /// @dev get price
    /// @param decimals pool's token1's decimals (ex. 1e18)
    /// @return price price
    function getPrice(uint256 decimals)
        external
        view
        override
        nonZeroAddress(poolAddress)
        returns (uint256 price)
    {
        (uint160 sqrtPriceX96, , , , , , ) =
            IUniswapV3Pool(poolAddress).slot0();

        return
            uint256(sqrtPriceX96).mul(uint256(sqrtPriceX96)).mul(decimals) >>
            (96 * 2);
    }

    /// @dev Liquidity provision time (seconds) at a specific point in time since the token was recently mined
    /// @param tokenId token id
    /// @param expectBlocktimestamp The specific time you want to know (It must be greater than the last mining time.) set it to the current time.
    /// @return secondsAbsolute Absolute duration (in seconds) from the latest mining to the time of expectTime
    /// @return secondsInsideDiff256 The time (in seconds) that the token ID provided liquidity from the last claim (or staking time) to the present time.
    /// @return expectTime time used in the calculation
    function currentliquidityTokenId(
        uint256 tokenId,
        uint256 expectBlocktimestamp
    )
        public
        view
        override
        nonZeroAddress(poolAddress)
        returns (
            uint256 secondsAbsolute,
            uint256 secondsInsideDiff256,
            uint256 expectTime
        )
    {
        secondsAbsolute = 0;
        secondsInsideDiff256 = 0;
        expectTime = 0;

        if (
            stakeStartTime > 0 &&
            expectBlocktimestamp > coinageLastMintBlockTimetamp
        ) {
            expectTime = expectBlocktimestamp;

            LibUniswapV3Stake.StakeLiquidity storage _depositTokens =
                depositTokens[tokenId];
            (, , uint160 secondsInside) =
                IUniswapV3Pool(poolAddress).snapshotCumulativesInside(
                    _depositTokens.tickLower,
                    _depositTokens.tickUpper
                );

            if (
                expectTime > _depositTokens.claimedTime &&
                expectTime > _depositTokens.startTime
            ) {
                if (_depositTokens.claimedTime > 0) {
                    secondsAbsolute = expectTime.sub(
                        (uint256)(_depositTokens.claimedTime)
                    );
                } else {
                    secondsAbsolute = expectTime.sub(
                        (uint256)(_depositTokens.startTime)
                    );
                }

                if (secondsAbsolute > 0) {
                    if (_depositTokens.secondsInsideLast > 0) {
                        secondsInsideDiff256 = uint256(secondsInside).sub(
                            uint256(_depositTokens.secondsInsideLast)
                        );
                    } else {
                        secondsInsideDiff256 = uint256(secondsInside).sub(
                            uint256(_depositTokens.secondsInsideInitial)
                        );
                    }
                }
            }
        }
    }

    /// @dev Coinage balance information that tokens can receive in the future
    /// @param tokenId token id
    /// @param expectBlocktimestamp The specific time you want to know (It must be greater than the last mining time.)
    /// @return currentTotalCoinage Current Coinage Total Balance
    /// @return afterTotalCoinage Total balance of Coinage at a future point in time
    /// @return afterBalanceTokenId The total balance of the coin age of the token at a future time
    /// @return expectTime future time
    /// @return addIntervalTime Duration (in seconds) between the future time and the recent mining time
    function currentCoinageBalanceTokenId(
        uint256 tokenId,
        uint256 expectBlocktimestamp
    )
        public
        view
        override
        nonZeroAddress(poolAddress)
        returns (
            uint256 currentTotalCoinage,
            uint256 afterTotalCoinage,
            uint256 afterBalanceTokenId,
            uint256 expectTime,
            uint256 addIntervalTime
        )
    {
        currentTotalCoinage = 0;
        afterTotalCoinage = 0;
        afterBalanceTokenId = 0;
        expectTime = 0;
        addIntervalTime = 0;

        if (
            stakeStartTime > 0 &&
            expectBlocktimestamp > coinageLastMintBlockTimetamp
        ) {
            expectTime = expectBlocktimestamp;

            uint256 miningEndTime_ = IIStake2Vault(vault).miningEndTime();
            if (expectTime > miningEndTime_) expectTime = miningEndTime_;

            currentTotalCoinage = IAutoRefactorCoinageWithTokenId(coinage)
                .totalSupply();
            (uint256 balance, uint256 refactoredCount, uint256 remain) =
                IAutoRefactorCoinageWithTokenId(coinage).balancesTokenId(
                    tokenId
                );

            uint256 coinageLastMintTime = coinageLastMintBlockTimetamp;
            if (coinageLastMintTime == 0) coinageLastMintTime = stakeStartTime;

            addIntervalTime = expectTime.sub(coinageLastMintTime);
            if (
                miningIntervalSeconds > 0 &&
                addIntervalTime > miningIntervalSeconds
            ) addIntervalTime = addIntervalTime.sub(miningIntervalSeconds);

            if (addIntervalTime > 0) {
                uint256 miningPerSecond_ =
                    IIStake2Vault(vault).miningPerSecond();
                uint256 addAmountCoinage =
                    addIntervalTime.mul(miningPerSecond_);
                afterTotalCoinage = currentTotalCoinage.add(
                    addAmountCoinage.mul(10**9)
                );
                uint256 factor_ =
                    IAutoRefactorCoinageWithTokenId(coinage).factor();
                uint256 infactor =
                    _calcNewFactor(
                        currentTotalCoinage,
                        afterTotalCoinage,
                        factor_
                    );

                uint256 count = 0;
                uint256 f = infactor;
                for (; f >= 10**28; f = f.div(2)) {
                    count = count.add(1);
                }
                uint256 afterBalanceTokenId_ =
                    applyCoinageFactor(balance, refactoredCount, f, count);

                afterBalanceTokenId = afterBalanceTokenId_.add(remain);
            }
        }
    }

    /// @dev Estimated additional claimable amount on a specific time
    /// @param tokenId token id
    /// @param expectBlocktimestamp The specific time you want to know (It must be greater than the last mining time.)
    /// @return miningAmount Amount you can claim
    /// @return nonMiningAmount The amount that burn without receiving a claim
    /// @return minableAmount Total amount of mining allocated at the time of claim
    /// @return minableAmountRay Total amount of mining allocated at the time of claim (ray unit)
    /// @return expectTime time used in the calculation
    function expectedPlusClaimableAmount(
        uint256 tokenId,
        uint256 expectBlocktimestamp
    )
        external
        view
        override
        nonZeroAddress(poolAddress)
        returns (
            uint256 miningAmount,
            uint256 nonMiningAmount,
            uint256 minableAmount,
            uint256 minableAmountRay,
            uint256 expectTime
        )
    {
        miningAmount = 0;
        nonMiningAmount = 0;
        minableAmount = 0;
        minableAmountRay = 0;
        expectTime = 0;

        if (
            stakeStartTime > 0 &&
            expectBlocktimestamp > coinageLastMintBlockTimetamp
        ) {
            expectTime = expectBlocktimestamp;
            uint256 afterBalanceTokenId = 0;
            uint256 secondsAbsolute = 0;
            uint256 secondsInsideDiff256 = 0;

            uint256 currentBalanceOfTokenId =
                IAutoRefactorCoinageWithTokenId(coinage).balanceOf(tokenId);

            (secondsAbsolute, secondsInsideDiff256, ) = currentliquidityTokenId(
                tokenId,
                expectTime
            );

            (, , afterBalanceTokenId, , ) = currentCoinageBalanceTokenId(
                tokenId,
                expectTime
            );

            if (
                currentBalanceOfTokenId > 0 &&
                afterBalanceTokenId > currentBalanceOfTokenId
            ) {
                minableAmountRay = afterBalanceTokenId.sub(
                    currentBalanceOfTokenId
                );
                minableAmount = minableAmountRay.div(10**9);
            }
            if (minableAmount > 0 && secondsAbsolute > 0 && secondsInsideDiff256 > 0 ) {
                if (
                    secondsInsideDiff256 < secondsAbsolute &&
                    secondsInsideDiff256 > 0
                ) {
                    miningAmount = minableAmount.mul(secondsInsideDiff256).div(
                        secondsAbsolute
                    );
                    nonMiningAmount = minableAmount.sub(miningAmount);
                } else {
                    miningAmount = minableAmount;
                }
            } else if(secondsInsideDiff256 == 0){
                nonMiningAmount = minableAmount;
            }
        }
    }

    function applyCoinageFactor(
        uint256 v,
        uint256 refactoredCount,
        uint256 _factor,
        uint256 refactorCount
    ) internal pure returns (uint256) {
        if (v == 0) {
            return 0;
        }

        v = rmul2(v, _factor);

        for (uint256 i = refactoredCount; i < refactorCount; i++) {
            v = v * (2);
        }

        return v;
    }
}
