// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./ICollectionswap.sol";
import "./RewardPoolETH.sol";
import "./RewardPoolETHDraw.sol";
import "./Ownable.sol";
import "./RNGChainlinkV2Interface.sol";
import "./Clones.sol";

contract Collectionstaker is Ownable {
    using SafeERC20 for IERC20;

    ICollectionswap immutable lpToken;
    RewardPoolETH immutable rewardPoolETHLogic;
    RewardPoolETHDraw immutable rewardPoolETHDrawLogic;
    uint256 public constant MAX_REWARD_TOKENS = 5;
    RNGChainlinkV2Interface public rngChainlink;

    /// @notice Event emitted when a liquidity mining incentive has been created
    /// @param poolAddress The Reward pool address
    /// @param rewardTokens The tokens being distributed as a reward
    /// @param rewards The amount of reward tokens to be distributed
    /// @param startTime The time when the incentive program begins
    /// @param endTime The time when rewards stop accruing
    event IncentiveETHCreated(
        address poolAddress,
        IERC20[] rewardTokens,
        uint256[] rewards,
        uint256 startTime,
        uint256 endTime
    );

    event IncentiveETHDrawCreated(
        address poolAddress,
        IERC20[] rewardTokens,
        uint256[] rewards,
        uint256 startTime,
        uint256 endTime
    );

    constructor(ICollectionswap _lpToken) {
        lpToken = _lpToken;
        rewardPoolETHLogic = new RewardPoolETH();
        rewardPoolETHDrawLogic = new RewardPoolETHDraw();
    }

    function setRNG(RNGChainlinkV2Interface _rngChainlink) external onlyOwner {
        rngChainlink = _rngChainlink;
    }

    function createIncentiveETH(
        IERC721 nft,
        address bondingCurve,
        uint128 delta,
        uint96 fee,
        IERC20[] calldata rewardTokens,
        uint256[] calldata rewards,
        uint256 startTime,
        uint256 endTime
    ) external {
        require(startTime > block.timestamp, "cannot backdate");
        uint256 rewardTokensLength = rewardTokens.length;
        require(
            rewardTokensLength <= MAX_REWARD_TOKENS,
            "too many reward tokens"
        );
        require(rewardTokensLength == rewards.length, "unequal lengths");
        uint256[] memory rewardRates = new uint256[](rewardTokensLength);
        for (uint256 i; i < rewardTokensLength; ) {
            rewardRates[i] = rewards[i] / (endTime - startTime); // guaranteed endTime > startTime
            require(rewardRates[i] != 0, "0 reward rate");
            unchecked {
                ++i;
            }
        }
        RewardPoolETH rewardPool = RewardPoolETH(
            Clones.clone(address(rewardPoolETHLogic))
        );

        lpToken.setCanSpecifySender(address(rewardPool), true);
        
        rewardPool.initialize(
            owner(),
            msg.sender,
            lpToken,
            nft,
            bondingCurve,
            delta,
            fee,
            rewardTokens,
            rewardRates,
            startTime,
            endTime
        );

        // transfer reward tokens to RewardPool
        for (uint256 i; i < rewardTokensLength; ) {
            rewardTokens[i].safeTransferFrom(
                msg.sender,
                address(rewardPool),
                rewards[i]
            );

            unchecked {
                ++i;
            }
        }

        emit IncentiveETHCreated(
            address(rewardPool),
            rewardTokens,
            rewards,
            startTime,
            endTime
        );
    }

    modifier randomnessIsSet() {
        require(address(rngChainlink) != address(0), "randomness not set");
        _;
    }

    function createIncentiveETHDraw(
        IERC721 nft,
        address bondingCurve,
        uint128 delta,
        uint96 fee,
        IERC20[] calldata rewardTokens,
        uint256[] calldata rewards,
        uint256 rewardStartTime,
        uint256 rewardEndTime,
        IERC20[] calldata _additionalERC20DrawPrize,
        uint256[] calldata _additionalERC20DrawAmounts,
        IERC721[] calldata _nftCollectionsPrize,
        uint256[] calldata _nftIdsPrize,
        uint256 _prizesPerWinner,
        uint256 drawStartTime,
        uint256 drawPeriodFinish
    ) public randomnessIsSet {
        uint256 rewardTokensLength = rewardTokens.length;
        if (rewardStartTime != 0) {
            // deployer intends to use normal reward distribution functionality
            // same checks apply as per createIncentiveETH()
            require(rewardStartTime > block.timestamp, "cannot backdate");
            require(rewardTokensLength <= MAX_REWARD_TOKENS, "too many reward tokens");
            require(rewardTokensLength == rewards.length, "unequal lengths");
        } else {
            // rewardStartTime == 0 => deployer intends to initially utilise draw functionality only
            require(rewardTokensLength == 0, "bad config");
        }

        uint256[] memory rewardRates = new uint256[](rewardTokensLength);
        for (uint256 i; i < rewardTokensLength; ) {
            rewardRates[i] = rewards[i] / (rewardEndTime - rewardStartTime); // guaranteed endTime > startTime
            require(rewardRates[i] != 0, "0 reward rate");
            unchecked {
                ++i;
            }
        }

        RewardPoolETHDraw rewardPool = RewardPoolETHDraw(
            Clones.clone(address(rewardPoolETHDrawLogic))
        );

        lpToken.setCanSpecifySender(address(rewardPool), true);

        rewardPool.initialize(
            owner(),
            address(this),
            msg.sender,
            lpToken,
            nft,
            bondingCurve,
            delta,
            fee,
            rewardTokens,
            rewardRates,
            rewardStartTime,
            rewardEndTime,
            rngChainlink,
            _additionalERC20DrawPrize,
            _additionalERC20DrawAmounts,
            _nftCollectionsPrize,
            _nftIdsPrize,
            _prizesPerWinner,
            drawStartTime,
            drawPeriodFinish
        );

        rngChainlink.setAllowedCaller(address(rewardPool));

        // transfer erc20 drawTokens to RewardPool
        for (uint256 i; i < _additionalERC20DrawPrize.length; ) {
            _additionalERC20DrawPrize[i].safeTransferFrom(
                msg.sender,
                address(rewardPool),
                _additionalERC20DrawAmounts[i]
            );

            unchecked {
                ++i;
            }
        }

        // transfer erc721 drawTokens to RewardPool
        for (uint256 i; i < _nftCollectionsPrize.length; ) {
            _nftCollectionsPrize[i].safeTransferFrom(
                msg.sender,
                address(rewardPool),
                _nftIdsPrize[i]
            );

            unchecked {
                ++i;
            }
        }

        // transfer reward tokens to RewardPool
        for (uint256 i; i < rewardTokensLength; ) {
            rewardTokens[i].safeTransferFrom(
                msg.sender,
                address(rewardPool),
                rewards[i]
            );

            unchecked {
                ++i;
            }
        }

        emit IncentiveETHDrawCreated(address(rewardPool), rewardTokens, rewards, rewardStartTime, rewardEndTime);
    }
}
