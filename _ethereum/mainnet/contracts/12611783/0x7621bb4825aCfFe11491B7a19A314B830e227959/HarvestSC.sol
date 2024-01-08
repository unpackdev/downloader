// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./ReentrancyGuardUpgradeable.sol";

import "./HarvestSCBase.sol";
import "./StrategyBase.sol";

/*
  |Strategy Flow| 
      - User shows up with Token and we deposit it in Havest's Vault. 
      - After this we have fToken that we add in Harvest's Reward Pool which gives FARM as rewards

    - Withdrawal flow does same thing, but backwards
        - User can obtain extra Token when withdrawing. 50% of them goes to the user, 50% goes to the treasury in ETH
        - User can obtain FARM tokens when withdrawing. 50% of them goes to the user in Token, 50% goes to the treasury in ETH 
*/
contract HarvestSC is StrategyBase, HarvestSCBase, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @notice Create a new HarvestDAI contract
     * @param _harvestRewardVault VaultDAI  address
     * @param _harvestRewardPool NoMintRewardPool address
     * @param _sushiswapRouter Sushiswap Router address
     * @param _harvestfToken Pool's underlying token address
     * @param _farmToken Farm address
     * @param _token Token address
     * @param _weth WETH address
     * @param _treasuryAddress treasury address
     * @param _feeAddress fee address
     */
    function initialize(
        address _harvestRewardVault,
        address _harvestRewardPool,
        address _sushiswapRouter,
        address _harvestfToken,
        address _farmToken,
        address _token,
        address _weth,
        address payable _treasuryAddress,
        address payable _feeAddress
    ) external initializer {
        __ReentrancyGuard_init();
        __HarvestBase_init(
            _harvestRewardVault,
            _harvestRewardPool,
            _sushiswapRouter,
            _harvestfToken,
            _farmToken,
            _token,
            _weth,
            _treasuryAddress,
            _feeAddress,
            5000000 * (10**18)
        );
    }

    /**
     * @notice Deposit to this strategy for rewards
     * @param tokenAmount Amount of Token investment
     * @param deadline Number of blocks until transaction expires
     * @return Amount of fToken
     */
    function deposit(
        uint256 tokenAmount,
        uint256 deadline,
        uint256 slippage
    ) public nonReentrant returns (uint256) {
        // -----
        // validate
        // -----
        _validateDeposit(deadline, tokenAmount, totalToken, slippage);

        _updateRewards(msg.sender);

        IERC20(token).safeTransferFrom(msg.sender, address(this), tokenAmount);

        DepositData memory results;
        UserInfo storage user = userInfo[msg.sender];

        user.timestamp = block.timestamp;

        totalToken = totalToken.add(tokenAmount);
        user.amountToken = user.amountToken.add(tokenAmount);
        results.obtainedToken = tokenAmount;

        // -----
        // deposit Token into harvest and get fToken
        // -----
        results.obtainedfToken = _depositTokenToHarvestVault(
            results.obtainedToken
        );

        // -----
        // stake fToken into the NoMintRewardPool
        // -----
        _stakefTokenToHarvestPool(results.obtainedfToken);
        user.amountfToken = user.amountfToken.add(results.obtainedfToken);

        // -----
        // mint parachain tokens
        // -----
        _mintParachainAuctionTokens(results.obtainedfToken);

        emit Deposit(
            msg.sender,
            tx.origin,
            results.obtainedToken,
            results.obtainedfToken
        );

        user.underlyingRatio = _getRatio(
            user.amountfToken,
            user.amountToken,
            18
        );

        return results.obtainedfToken;
    }

    /**
     * @notice Withdraw tokens and claim rewards
     * @param deadline Number of blocks until transaction expires
     * @return Amount of ETH obtained
     */
    function withdraw(
        uint256 amount,
        uint256 deadline,
        uint256 slippage,
        uint256 ethPerToken,
        uint256 ethPerFarm,
        uint256 tokensPerEth //no of tokens per 1 eth
    ) public nonReentrant returns (uint256) {
        // -----
        // validation
        // -----
        UserInfo storage user = userInfo[msg.sender];
        uint256 receiptBalance = receiptToken.balanceOf(msg.sender);

        _validateWithdraw(
            deadline,
            amount,
            user.amountfToken,
            receiptBalance,
            user.timestamp,
            slippage
        );

        _updateRewards(msg.sender);

        WithdrawData memory results;
        results.initialAmountfToken = user.amountfToken;
        results.prevDustEthBalance = address(this).balance;

        // -----
        // withdraw from HarvestRewardPool (get fToken back)
        // -----
        results.obtainedfToken = _unstakefTokenFromHarvestPool(amount);

        // -----
        // get rewards
        // -----
        harvestRewardPool.getReward(); //transfers FARM to this contract

        // -----
        // calculate rewards and do the accounting for fTokens
        // -----
        uint256 transferableRewards =
            _calculateRewards(msg.sender, amount, results.initialAmountfToken);

        (user.amountfToken, results.burnAmount) = _calculatefTokenRemainings(
            amount,
            results.initialAmountfToken
        );
        _burnParachainAuctionTokens(results.burnAmount);

        // -----
        // withdraw from HarvestRewardVault (return fToken and get Token back)
        // -----
        results.obtainedToken = _withdrawTokenFromHarvestVault(
            results.obtainedfToken
        );
        emit ObtainedInfo(
            msg.sender,
            results.obtainedToken,
            results.obtainedfToken
        );

        // -----
        // calculate feeable tokens (extra Token obtained by returning fToken)
        //              - feeableToken/2 (goes to the treasury in ETH)
        //              - results.totalToken = obtainedToken + 1/2*feeableToken (goes to the user)
        // -----
        results.auctionedToken = 0;
        (results.feeableToken, results.earnedTokens) = _calculateFeeableTokens(
            results.initialAmountfToken,
            results.obtainedToken,
            user.amountToken,
            results.obtainedfToken,
            user.underlyingRatio
        );
        user.earnedTokens = user.earnedTokens.add(results.earnedTokens);

        results.calculatedTokenAmount = (amount.mul(10**18)).div(
            user.underlyingRatio
        );
        if (user.amountfToken == 0) {
            user.amountToken = 0;
        } else {
            if (results.calculatedTokenAmount <= user.amountToken) {
                user.amountToken = user.amountToken.sub(
                    results.calculatedTokenAmount
                );
            } else {
                user.amountToken = 0;
            }
        }
        results.obtainedToken = results.obtainedToken.sub(results.feeableToken);

        if (results.feeableToken > 10**ERC20(token).decimals()) {
            //min
            results.auctionedToken = results.feeableToken.div(2);
            results.feeableToken = results.feeableToken.sub(
                results.auctionedToken
            );
        }
        results.totalToken = results.obtainedToken.add(results.feeableToken);
        // -----
        // swap auctioned Token to ETH
        // -----
        address[] memory swapPath = new address[](2);
        swapPath[0] = token;
        swapPath[1] = weth;

        if (results.auctionedToken > 0) {
            uint256 swapAuctionedTokenResult =
                _swapTokenToEth(
                    swapPath,
                    results.auctionedToken,
                    deadline,
                    slippage,
                    ethPerToken
                );
            results.auctionedEth = results.auctionedEth.add(
                swapAuctionedTokenResult
            );

            emit ExtraTokensExchanged(
                msg.sender,
                results.auctionedToken,
                swapAuctionedTokenResult
            );
        }

        // -----
        // check & swap FARM rewards with ETH (50% for treasury) and with Token by going through ETH first (the other 50% for user)
        // -----

        if (transferableRewards > 0) {
            emit RewardsEarned(msg.sender, transferableRewards);
            user.earnedRewards = user.earnedRewards.add(transferableRewards);

            swapPath[0] = farmToken;

            results.rewardsInEth = _swapTokenToEth(
                swapPath,
                transferableRewards,
                deadline,
                slippage,
                ethPerFarm
            );
            results.auctionedRewardsInEth = results.rewardsInEth.div(2);
            //50% goes to treasury in ETH
            results.userRewardsInEth = results.rewardsInEth.sub(
                results.auctionedRewardsInEth
            );
            //50% goes to user in Token (swapped below)

            results.auctionedEth = results.auctionedEth.add(
                results.auctionedRewardsInEth
            );
            emit RewardsExchanged(
                msg.sender,
                "ETH",
                transferableRewards,
                results.rewardsInEth
            );
        }
        if (results.userRewardsInEth > 0) {
            swapPath[0] = weth;
            swapPath[1] = token;

            uint256 userRewardsEthToTokenResult =
                _swapEthToToken(
                    swapPath,
                    results.userRewardsInEth,
                    deadline,
                    slippage,
                    tokensPerEth
                );
            results.totalToken = results.totalToken.add(
                userRewardsEthToTokenResult
            );

            emit RewardsExchanged(
                msg.sender,
                "Token",
                transferableRewards.div(2),
                userRewardsEthToTokenResult
            );
        }
        user.rewards = user.rewards.sub(transferableRewards);

        // -----
        // final accounting
        // -----
        if (results.calculatedTokenAmount <= totalToken) {
            totalToken = totalToken.sub(results.calculatedTokenAmount);
        } else {
            totalToken = 0;
        }

        user.underlyingRatio = _getRatio(
            user.amountfToken,
            user.amountToken,
            18
        );

        // -----
        // transfer Token to user, ETH to fee address and ETH to the treasury address
        // -----
        if (fee > 0) {
            uint256 feeToken = _calculateFee(results.totalToken);
            results.totalToken = results.totalToken.sub(feeToken);

            swapPath[0] = token;
            swapPath[1] = weth;

            uint256 feeTokenInEth =
                _swapTokenToEth(
                    swapPath,
                    feeToken,
                    deadline,
                    slippage,
                    ethPerToken
                );

            safeTransferETH(feeAddress, feeTokenInEth);
            user.userCollectedFees = user.userCollectedFees.add(feeTokenInEth);
        }

        IERC20(token).safeTransfer(msg.sender, results.totalToken);

        safeTransferETH(treasuryAddress, results.auctionedEth);
        user.userTreasuryEth = user.userTreasuryEth.add(results.auctionedEth);

        emit Withdraw(
            msg.sender,
            tx.origin,
            results.obtainedToken,
            results.obtainedfToken,
            results.auctionedEth
        );

        // -----
        // dust check
        // -----
        if (address(this).balance > results.prevDustEthBalance) {
            ethDust = ethDust.add(
                address(this).balance.sub(results.prevDustEthBalance)
            );
        }

        return results.totalToken;
    }
}
