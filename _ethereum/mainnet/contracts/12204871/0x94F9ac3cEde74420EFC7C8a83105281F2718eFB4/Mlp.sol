// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.6;

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";
import "./Math.sol";
import "./SafeERC20.sol";
import "./IMlp.sol";
import "./IFeesController.sol";
import "./IRewardManager.sol";

contract MLP is IMlp {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public endDate;
    address public submitter;
    uint256 public exceedingLiquidity;
    uint256 public bonusToken0;
    uint256 public reward0Rate;
    uint256 public reward0PerTokenStored;
    uint256 public bonusToken1;
    uint256 public reward1Rate;
    uint256 public reward1PerTokenStored;
    uint256 public lastUpdateTime;
    uint256 public pendingOfferCount;
    uint256 public activeOfferCount;

    IRewardManager public rewardManager;
    IUniswapV2Pair public uniswapPair;
    IFeesController public feesController;
    IUniswapV2Router02 public uniswapRouter;

    mapping(address => uint256) public userReward0PerTokenPaid;
    mapping(address => uint256) public userRewards0;
    mapping(address => uint256) public userReward1PerTokenPaid;
    mapping(address => uint256) public userRewards1;
    mapping(address => uint256) public directStakeBalances;
    mapping(uint256 => PendingOffer) public getPendingOffer;
    mapping(uint256 => ActiveOffer) public getActiveOffer;

    enum OfferStatus {PENDING, TAKEN, CANCELED}

    event OfferMade(uint256 id);
    event OfferTaken(uint256 pendingOfferId, uint256 activeOfferId);
    event OfferCanceled(uint256 id);
    event OfferReleased(uint256 offerId);

    struct PendingOffer {
        address owner;
        address token;
        uint256 amount;
        uint256 unlockDate;
        uint256 endDate;
        OfferStatus status;
        uint256 slippageTolerancePpm;
        uint256 maxPriceVariationPpm;
    }

    struct ActiveOffer {
        address user0;
        uint256 originalAmount0;
        address user1;
        uint256 originalAmount1;
        uint256 unlockDate;
        uint256 liquidity;
        bool released;
        uint256 maxPriceVariationPpm;
    }

    constructor(
        address _uniswapPair,
        address _submitter,
        uint256 _endDate,
        address _uniswapRouter,
        address _feesController,
        IRewardManager _rewardManager,
        uint256 _bonusToken0,
        uint256 _bonusToken1
    ) public {
        feesController = IFeesController(_feesController);
        uniswapPair = IUniswapV2Pair(_uniswapPair);
        endDate = _endDate;
        submitter = _submitter;
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        rewardManager = _rewardManager;

        uint256 remainingTime = _endDate.sub(block.timestamp);
        bonusToken0 = _bonusToken0;
        reward0Rate = _bonusToken0 / remainingTime;
        bonusToken1 = _bonusToken1;
        reward1Rate = _bonusToken1 / remainingTime;
        lastUpdateTime = block.timestamp;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, endDate);
    }

    function reward0PerToken() public view returns (uint256) {
        uint256 totalSupply = rewardManager.getPoolSupply(address(this));
        if (totalSupply == 0) {
            return reward0PerTokenStored;
        }
        return
            reward0PerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(reward0Rate)
                    .mul(1e18) / totalSupply
            );
    }

    function reward1PerToken() public view returns (uint256) {
        uint256 totalSupply = rewardManager.getPoolSupply(address(this));
        if (totalSupply == 0) {
            return reward1PerTokenStored;
        }
        return
            reward1PerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(reward1Rate)
                    .mul(1e18) / totalSupply
            );
    }

    function rewardEarned(address account)
        public
        view
        returns (uint256 reward0Earned, uint256 reward1Earned)
    {
        uint256 balance = rewardManager.getUserAmount(address(this), account);
        reward0Earned = (balance.mul(
            reward0PerToken().sub(userReward0PerTokenPaid[account])
        ) / 1e18)
            .add(userRewards0[account]);
        reward1Earned = (balance.mul(
            reward1PerToken().sub(userReward1PerTokenPaid[account])
        ) / 1e18)
            .add(userRewards1[account]);
    }

    function updateRewards(address account) internal {
        reward0PerTokenStored = reward0PerToken();
        reward1PerTokenStored = reward1PerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            (uint256 earned0, uint256 earned1) = rewardEarned(account);
            userRewards0[account] = earned0;
            userRewards1[account] = earned1;
            userReward0PerTokenPaid[account] = reward0PerTokenStored;
            userReward1PerTokenPaid[account] = reward1PerTokenStored;
        }
    }

    function payRewards(address account) public {
        updateRewards(account);
        (uint256 reward0, uint256 reward1) = rewardEarned(account);
        if (reward0 > 0) {
            userRewards0[account] = 0;
            IERC20(uniswapPair.token0()).safeTransfer(account, reward0);
        }
        if (reward1 > 0) {
            userRewards1[account] = 0;
            IERC20(uniswapPair.token1()).safeTransfer(account, reward1);
        }
    }

    function _notifyDeposit(address account, uint256 amount) internal {
        updateRewards(account);
        rewardManager.notifyDeposit(account, amount);
    }

    function _notifyWithdraw(address account, uint256 amount) internal {
        updateRewards(account);
        rewardManager.notifyWithdraw(account, amount);
    }

    function makeOffer(
        address _token,
        uint256 _amount,
        uint256 _unlockDate,
        uint256 _endDate,
        uint256 _slippageTolerancePpm,
        uint256 _maxPriceVariationPpm
    ) external override returns (uint256 offerId) {
        require(_amount > 0);
        require(_endDate > now);
        require(_endDate <= _unlockDate);
        offerId = pendingOfferCount;
        pendingOfferCount++;
        getPendingOffer[offerId] = PendingOffer(
            msg.sender,
            _token,
            _amount,
            _unlockDate,
            _endDate,
            OfferStatus.PENDING,
            _slippageTolerancePpm,
            _maxPriceVariationPpm
        );
        IERC20 token;
        if (_token == address(uniswapPair.token0())) {
            token = IERC20(uniswapPair.token0());
        } else if (_token == address(uniswapPair.token1())) {
            token = IERC20(uniswapPair.token1());
        } else {
            require(false, "unknown token");
        }

        token.safeTransferFrom(msg.sender, address(this), _amount);
        emit OfferMade(offerId);
    }

    struct ProviderInfo {
        address user;
        uint256 amount;
        IERC20 token;
    }

    struct OfferInfo {
        uint256 deadline;
        uint256 slippageTolerancePpm;
    }

    function takeOffer(
        uint256 _pendingOfferId,
        uint256 _amount,
        uint256 _deadline
    ) external override returns (uint256 activeOfferId) {
        PendingOffer storage pendingOffer = getPendingOffer[_pendingOfferId];
        require(pendingOffer.status == OfferStatus.PENDING);
        require(pendingOffer.endDate > now);
        pendingOffer.status = OfferStatus.TAKEN;

        // Sort the users, tokens, and amount
        ProviderInfo memory provider0;
        ProviderInfo memory provider1;

        if (pendingOffer.token == uniswapPair.token0()) {
            provider0 = ProviderInfo(
                pendingOffer.owner,
                pendingOffer.amount,
                IERC20(uniswapPair.token0())
            );
            provider1 = ProviderInfo(
                msg.sender,
                _amount,
                IERC20(uniswapPair.token1())
            );

            provider1.token.safeTransferFrom(
                provider1.user,
                address(this),
                provider1.amount
            );
        } else {
            provider0 = ProviderInfo(
                msg.sender,
                _amount,
                IERC20(uniswapPair.token0())
            );
            provider1 = ProviderInfo(
                pendingOffer.owner,
                pendingOffer.amount,
                IERC20(uniswapPair.token1())
            );

            provider0.token.safeTransferFrom(
                provider0.user,
                address(this),
                provider0.amount
            );
        }

        // calculate fees
        uint256 feesAmount0 =
            provider0.amount.mul(feesController.feesPpm()) / 1000;
        uint256 feesAmount1 =
            provider1.amount.mul(feesController.feesPpm()) / 1000;

        // take fees
        provider0.amount = provider0.amount.sub(feesAmount0);
        provider1.amount = provider1.amount.sub(feesAmount1);

        // send fees
        provider0.token.safeTransfer(feesController.feesTo(), feesAmount0);
        provider1.token.safeTransfer(feesController.feesTo(), feesAmount1);

        // send tokens to uniswap
        uint256 liquidity =
            _provideLiquidity(
                provider0,
                provider1,
                OfferInfo(_deadline, pendingOffer.slippageTolerancePpm)
            );

        // stake liquidity
        _notifyDeposit(provider0.user, liquidity / 2);
        _notifyDeposit(provider1.user, liquidity / 2);

        if (liquidity % 2 != 0) {
            exceedingLiquidity = exceedingLiquidity.add(1);
        }

        // Record the active offer
        activeOfferId = activeOfferCount;
        activeOfferCount++;

        getActiveOffer[activeOfferId] = ActiveOffer(
            provider0.user,
            provider0.amount,
            provider1.user,
            provider1.amount,
            pendingOffer.unlockDate,
            liquidity,
            false,
            pendingOffer.maxPriceVariationPpm
        );

        emit OfferTaken(_pendingOfferId, activeOfferId);

        return activeOfferId;
    }

    function _provideLiquidity(
        ProviderInfo memory _provider0,
        ProviderInfo memory _provider1,
        OfferInfo memory _info
    ) internal returns (uint256) {
        _provider0.token.safeApprove(address(uniswapRouter), _provider0.amount);
        _provider1.token.safeApprove(address(uniswapRouter), _provider1.amount);

        uint256 amountMin0 =
            _provider0.amount.sub(
                _provider0.amount.mul(_info.slippageTolerancePpm) / 1000
            );
        uint256 amountMin1 =
            _provider1.amount.sub(
                _provider1.amount.mul(_info.slippageTolerancePpm) / 1000
            );

        // Add the liquidity to Uniswap
        (uint256 spentAmount0, uint256 spentAmount1, uint256 liquidity) =
            uniswapRouter.addLiquidity(
                address(_provider0.token),
                address(_provider1.token),
                _provider0.amount,
                _provider1.amount,
                amountMin0,
                amountMin1,
                address(this),
                _info.deadline
            );

        // Give back the exceeding tokens
        if (spentAmount0 < _provider0.amount) {
            _provider0.token.safeTransfer(
                _provider0.user,
                _provider0.amount - spentAmount0
            );
        }
        if (spentAmount1 < _provider1.amount) {
            _provider1.token.safeTransfer(
                _provider1.user,
                _provider1.amount - spentAmount1
            );
        }

        return liquidity;
    }

    function cancelOffer(uint256 _offerId) external override {
        PendingOffer storage pendingOffer = getPendingOffer[_offerId];
        require(pendingOffer.status == OfferStatus.PENDING);
        pendingOffer.status = OfferStatus.CANCELED;
        IERC20(pendingOffer.token).safeTransfer(
            pendingOffer.owner,
            pendingOffer.amount
        );
        emit OfferCanceled(_offerId);
    }

    function release(uint256 _offerId, uint256 _deadline) external override {
        ActiveOffer storage offer = getActiveOffer[_offerId];

        require(
            msg.sender == offer.user0 || msg.sender == offer.user1,
            "unauthorized"
        );
        require(now > offer.unlockDate, "locked");
        require(!offer.released, "already released");

        IERC20 token0 = IERC20(uniswapPair.token0());
        IERC20 token1 = IERC20(uniswapPair.token1());

        IERC20(address(uniswapPair)).safeApprove(
            address(uniswapRouter),
            offer.liquidity
        );
        (uint256 amount0, uint256 amount1) =
            uniswapRouter.removeLiquidity(
                address(token0),
                address(token1),
                offer.liquidity,
                0,
                0,
                address(this),
                _deadline
            );

        _notifyWithdraw(offer.user0, offer.liquidity / 2);
        _notifyWithdraw(offer.user1, offer.liquidity / 2);

        if (
            _getPriceVariation(offer.originalAmount0, amount0) >
            offer.maxPriceVariationPpm
        ) {
            if (amount0 > offer.originalAmount0) {
                uint256 toSwap = amount0.sub(offer.originalAmount0);
                address[] memory path = new address[](2);
                path[0] = uniswapPair.token0();
                path[1] = uniswapPair.token1();
                token0.safeApprove(address(uniswapRouter), toSwap);
                uint256[] memory newAmounts =
                    uniswapRouter.swapExactTokensForTokens(
                        toSwap,
                        0,
                        path,
                        address(this),
                        _deadline
                    );
                amount0 = amount0.sub(toSwap);
                amount1 = amount1.add(newAmounts[1]);
            }
        }
        if (
            _getPriceVariation(offer.originalAmount1, amount1) >
            offer.maxPriceVariationPpm
        ) {
            if (amount1 > offer.originalAmount1) {
                uint256 toSwap = amount1.sub(offer.originalAmount1);
                address[] memory path = new address[](2);
                path[0] = uniswapPair.token1();
                path[1] = uniswapPair.token0();
                token1.safeApprove(address(uniswapRouter), toSwap);
                uint256[] memory newAmounts =
                    uniswapRouter.swapExactTokensForTokens(
                        toSwap,
                        0,
                        path,
                        address(this),
                        _deadline
                    );
                amount1 = amount1.sub(toSwap);
                amount0 = amount0.add(newAmounts[1]);
            }
        }

        token0.safeTransfer(offer.user0, amount0);
        payRewards(offer.user0);
        token1.safeTransfer(offer.user1, amount1);
        payRewards(offer.user1);

        offer.released = true;
        emit OfferReleased(_offerId);
    }

    function _getPriceVariation(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 sub;
        if (a > b) {
            sub = a.sub(b);
            return sub.mul(1000) / a;
        } else {
            sub = b.sub(a);
            return sub.mul(1000) / b;
        }
    }

    function directStake(uint256 _amount) external {
        require(_amount > 0, "cannot stake 0");
        _notifyDeposit(msg.sender, _amount);
        directStakeBalances[msg.sender] = directStakeBalances[msg.sender].add(
            _amount
        );
        IERC20(address(uniswapPair)).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    function directWithdraw(uint256 _amount) external {
        require(_amount > 0, "cannot withdraw 0");
        _notifyWithdraw(msg.sender, _amount);
        directStakeBalances[msg.sender] = directStakeBalances[msg.sender].sub(
            _amount
        );
        IERC20(address(uniswapPair)).safeTransfer(msg.sender, _amount);
    }

    function transferExceedingLiquidity() external {
        require(exceedingLiquidity != 0);
        exceedingLiquidity = 0;
        IERC20(address(uniswapPair)).safeTransfer(
            feesController.feesTo(),
            exceedingLiquidity
        );
    }
}
