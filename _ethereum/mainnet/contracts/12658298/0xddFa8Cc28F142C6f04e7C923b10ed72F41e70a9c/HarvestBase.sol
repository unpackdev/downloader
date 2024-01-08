// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./OwnableUpgradeable.sol";
import "./SafeMath.sol";

import "./IUniswapRouter.sol";
import "./IHarvestVault.sol";
import "./IMintNoRewardPool.sol";

import "./IHarvest.sol";
import "./IStrategy.sol";

import "./StrategyBase.sol";
import "./HarvestStorage.sol";

contract HarvestBase is
    HarvestStorage,
    OwnableUpgradeable,
    StrategyBase,
    IHarvest,
    IStrategy
{
    using SafeMath for uint256;

    struct UserDeposits {
        uint256 timestamp;
        uint256 amountfToken;
    }
    /// @notice Used internally for avoiding "stack-too-deep" error when depositing
    struct DepositData {
        address[] swapPath;
        uint256[] swapAmounts;
        uint256 obtainedToken;
        uint256 obtainedfToken;
        uint256 prevfTokenBalance;
    }

    /// @notice Used internally for avoiding "stack-too-deep" error when withdrawing
    struct WithdrawData {
        uint256 prevDustEthBalance;
        uint256 prevfTokenBalance;
        uint256 prevTokenBalance;
        uint256 obtainedfToken;
        uint256 obtainedToken;
        uint256 feeableToken;
        uint256 feeableEth;
        uint256 totalEth;
        uint256 totalToken;
        uint256 auctionedEth;
        uint256 auctionedToken;
        uint256 rewards;
        uint256 farmBalance;
        uint256 burnAmount;
        uint256 earnedTokens;
        uint256 rewardsInEth;
        uint256 auctionedRewardsInEth;
        uint256 userRewardsInEth;
        uint256 initialAmountfToken;
        uint256 calculatedTokenAmount;
    }

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Events -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    event ExtraTokensExchanged(
        address indexed user,
        uint256 tokensAmount,
        uint256 obtainedEth
    );
    event ObtainedInfo(
        address indexed user,
        uint256 underlying,
        uint256 underlyingReceipt
    );

    event RewardsEarned(address indexed user, uint256 amount);
    event ExtraTokens(address indexed user, uint256 amount);

    /// @notice Event emitted when owner makes a rescue dust request
    event RescuedDust(string indexed dustType, uint256 amount);

    /// @notice Event emitted when owner changes any contract address
    event ChangedAddress(
        string indexed addressType,
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice Event emitted when owner changes any contract address
    event ChangedValue(
        string indexed valueType,
        uint256 indexed oldValue,
        uint256 indexed newValue
    );

    /**
     * @notice Create a new HarvestDAI contract
     * @param _harvestRewardVault VaultToken  address
     * @param _harvestRewardPool NoMintRewardPool address
     * @param _sushiswapRouter Sushiswap Router address
     * @param _harvestfToken Pool's underlying token address
     * @param _farmToken Farm address
     * @param _token Token address
     * @param _weth WETH address
     * @param _treasuryAddress treasury address
     * @param _feeAddress fee address
     */
    function __HarvestBase_init(
        address _harvestRewardVault,
        address _harvestRewardPool,
        address _sushiswapRouter,
        address _harvestfToken,
        address _farmToken,
        address _token,
        address _weth,
        address payable _treasuryAddress,
        address payable _feeAddress,
        uint256 _cap
    ) internal initializer {
        require(_harvestRewardVault != address(0), "VAULT_0x0");
        require(_harvestRewardPool != address(0), "POOL_0x0");
        require(_harvestfToken != address(0), "fTOKEN_0x0");
        require(_farmToken != address(0), "FARM_0x0");

        __Ownable_init();

        __StrategyBase_init(
            _sushiswapRouter,
            _token,
            _weth,
            _treasuryAddress,
            _feeAddress,
            _cap
        );
        harvestRewardVault = IHarvestVault(_harvestRewardVault);
        harvestRewardPool = IMintNoRewardPool(_harvestRewardPool);
        harvestfToken = _harvestfToken;
        farmToken = _farmToken;
        receiptToken = new ReceiptToken(token, address(this));
    }

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Setters -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    /**
     * @notice Update the address of VaultDAI
     * @dev Can only be called by the owner
     * @param _harvestRewardVault Address of VaultDAI
     */
    function setHarvestRewardVault(address _harvestRewardVault)
        external
        override
        onlyOwner
    {
        require(_harvestRewardVault != address(0), "VAULT_0x0");
        emit ChangedAddress(
            "VAULT",
            address(harvestRewardVault),
            _harvestRewardVault
        );
        harvestRewardVault = IHarvestVault(_harvestRewardVault);
    }

    /**
     * @notice Update the address of NoMintRewardPool
     * @dev Can only be called by the owner
     * @param _harvestRewardPool Address of NoMintRewardPool
     */
    function setHarvestRewardPool(address _harvestRewardPool)
        external
        override
        onlyOwner
    {
        require(_harvestRewardPool != address(0), "POOL_0x0");
        emit ChangedAddress(
            "POOL",
            address(harvestRewardPool),
            _harvestRewardPool
        );
        harvestRewardPool = IMintNoRewardPool(_harvestRewardPool);
    }

    /**
     * @notice Update the address of Sushiswap Router
     * @dev Can only be called by the owner
     * @param _sushiswapRouter Address of Sushiswap Router
     */
    function setSushiswapRouter(address _sushiswapRouter)
        external
        override
        onlyOwner
    {
        require(_sushiswapRouter != address(0), "0x0");
        emit ChangedAddress(
            "SUSHISWAP_ROUTER",
            address(sushiswapRouter),
            _sushiswapRouter
        );
        sushiswapRouter = IUniswapRouter(_sushiswapRouter);
    }

    /**
     * @notice Update the address of Pool's underlying token
     * @dev Can only be called by the owner
     * @param _harvestfToken Address of Pool's underlying token
     */
    function setHarvestPoolToken(address _harvestfToken)
        external
        override
        onlyOwner
    {
        require(_harvestfToken != address(0), "TOKEN_0x0");
        emit ChangedAddress("TOKEN", harvestfToken, _harvestfToken);
        harvestfToken = _harvestfToken;
    }

    /**
     * @notice Update the address of FARM
     * @dev Can only be called by the owner
     * @param _farmToken Address of FARM
     */
    function setFarmToken(address _farmToken) external override onlyOwner {
        require(_farmToken != address(0), "FARM_0x0");
        emit ChangedAddress("FARM", farmToken, _farmToken);
        farmToken = _farmToken;
    }

    /**
     * @notice Update the address for fees
     * @dev Can only be called by the owner
     * @param _feeAddress Fee's address
     */
    function setTreasury(address payable _feeAddress)
        external
        override
        onlyOwner
    {
        require(_feeAddress != address(0), "0x0");
        emit ChangedAddress(
            "TREASURY",
            address(treasuryAddress),
            address(_feeAddress)
        );
        treasuryAddress = _feeAddress;
    }

    /**
     * @notice Set max ETH cap for this strategy
     * @dev Can only be called by the owner
     * @param _cap ETH amount
     */
    function setCap(uint256 _cap) external override onlyOwner {
        emit ChangedValue("CAP", cap, _cap);
        cap = _cap;
    }

    /**
     * @notice Set lock time
     * @dev Can only be called by the owner
     * @param _lockTime lock time in seconds
     */
    function setLockTime(uint256 _lockTime) external override onlyOwner {
        require(_lockTime > 0, "TIME_0");
        emit ChangedValue("LOCKTIME", lockTime, _lockTime);
        lockTime = _lockTime;
    }

    function setFeeAddress(address payable _feeAddress)
        external
        override
        onlyOwner
    {
        emit ChangedAddress("FEE", address(feeAddress), address(_feeAddress));
        feeAddress = _feeAddress;
    }

    function setFee(uint256 _fee) external override onlyOwner {
        require(_fee <= uint256(9000), "FEE_TOO_HIGH");
        emit ChangedValue("FEE", fee, _fee);
    }

    /**
     * @notice Rescue dust resulted from swaps/liquidity
     * @dev Can only be called by the owner
     */
    function rescueDust() external override onlyOwner {
        if (ethDust > 0) {
            safeTransferETH(treasuryAddress, ethDust);
            treasueryEthDust = treasueryEthDust.add(ethDust);
            emit RescuedDust("ETH", ethDust);
            ethDust = 0;
        }
    }

    /**
     * @notice Rescue any non-reward token that was airdropped to this contract
     * @dev Can only be called by the owner
     */
    function rescueAirdroppedTokens(address _token, address to)
        external
        override
        onlyOwner
    {
        require(_token != farmToken, "rescue_reward_error");

        uint256 balanceOfToken = IERC20(_token).balanceOf(address(this));
        require(balanceOfToken > 0, "balance_0");

        require(IERC20(_token).transfer(to, balanceOfToken), "rescue_failed");
    }

    /// @notice Transfer rewards to this strategy
    function updateReward() external override onlyOwner {
        harvestRewardPool.getReward();
    }

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ View methods -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    /**
     * @notice Check if user can withdraw based on current lock time
     * @param user Address of the user
     * @return true or false
     */
    function isWithdrawalAvailable(address user) public view returns (bool) {
        if (lockTime > 0) {
            return userInfo[user].timestamp.add(lockTime) <= block.timestamp;
        }
        return true;
    }

    /**
     * @notice View function to see pending rewards for account.
     * @param account user account to check
     * @return pending rewards
     */
    function getPendingRewards(address account) public view returns (uint256) {
        if (account != address(0)) {
            if (userInfo[account].amountfToken == 0) {
                return 0;
            }
            return
                _earned(
                    userInfo[account].amountfToken,
                    userInfo[account].userRewardPerTokenPaid,
                    userInfo[account].rewards
                );
        }
        return 0;
    }

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Internal methods -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    function _calculateRewards(
        address account,
        uint256 amount,
        uint256 amountfToken
    ) internal view returns (uint256) {
        uint256 rewards = userInfo[account].rewards;
        uint256 farmBalance = IERC20(farmToken).balanceOf(address(this));

        if (amount == 0) {
            if (rewards < farmBalance) {
                return rewards;
            }
            return farmBalance;
        }

        return (amount.mul(rewards)).div(amountfToken);
    }

    function _updateRewards(address account) internal {
        if (account != address(0)) {
            UserInfo storage user = userInfo[account];

            uint256 _stored = harvestRewardPool.rewardPerToken();

            user.rewards = _earned(
                user.amountfToken,
                user.userRewardPerTokenPaid,
                user.rewards
            );
            user.userRewardPerTokenPaid = _stored;
        }
    }

    function _earned(
        uint256 _amountfToken,
        uint256 _userRewardPerTokenPaid,
        uint256 _rewards
    ) internal view returns (uint256) {
        return
            _amountfToken
                .mul(
                harvestRewardPool.rewardPerToken().sub(_userRewardPerTokenPaid)
            )
                .div(1e18)
                .add(_rewards);
    }

    function _validateWithdraw(
        uint256 deadline,
        uint256 amount,
        uint256 amountfToken,
        uint256 receiptBalance,
        uint256 timestamp,
        uint256 slippage
    ) internal view {
        _validateCommon(deadline, amount, slippage);

        require(amountfToken >= amount, "AMOUNT_GREATER_THAN_BALANCE");

        require(receiptBalance >= amountfToken, "RECEIPT_AMOUNT");

        if (lockTime > 0) {
            require(timestamp.add(lockTime) <= block.timestamp, "LOCK_TIME");
        }
    }

    function _depositTokenToHarvestVault(uint256 amount)
        internal
        returns (uint256)
    {
        _increaseAllowance(token, address(harvestRewardVault), amount);

        uint256 prevfTokenBalance = _getBalance(harvestfToken);
        harvestRewardVault.deposit(amount);
        uint256 currentfTokenBalance = _getBalance(harvestfToken);

        require(
            currentfTokenBalance > prevfTokenBalance,
            "DEPOSIT_VAULT_ERROR"
        );

        return currentfTokenBalance.sub(prevfTokenBalance);
    }

    function _withdrawTokenFromHarvestVault(uint256 amount)
        internal
        returns (uint256)
    {
        _increaseAllowance(harvestfToken, address(harvestRewardVault), amount);

        uint256 prevTokenBalance = _getBalance(token);
        harvestRewardVault.withdraw(amount);
        uint256 currentTokenBalance = _getBalance(token);

        require(currentTokenBalance > prevTokenBalance, "WITHDRAW_VAULT_ERROR");

        return currentTokenBalance.sub(prevTokenBalance);
    }

    function _stakefTokenToHarvestPool(uint256 amount) internal {
        _increaseAllowance(harvestfToken, address(harvestRewardPool), amount);
        harvestRewardPool.stake(amount);
    }

    function _unstakefTokenFromHarvestPool(uint256 amount)
        internal
        returns (uint256)
    {
        _increaseAllowance(harvestfToken, address(harvestRewardPool), amount);

        uint256 prevfTokenBalance = _getBalance(harvestfToken);
        harvestRewardPool.withdraw(amount);
        uint256 currentfTokenBalance = _getBalance(harvestfToken);

        require(
            currentfTokenBalance > prevfTokenBalance,
            "WITHDRAW_POOL_ERROR"
        );

        return currentfTokenBalance.sub(prevfTokenBalance);
    }

    function _calculatefTokenRemainings(uint256 amount, uint256 amountfToken)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 burnAmount = amount;
        if (amount < amountfToken) {
            amountfToken = amountfToken.sub(amount);
        } else {
            burnAmount = amountfToken;
            amountfToken = 0;
        }

        return (amountfToken, burnAmount);
    }

    function _calculateFeeableTokens(
        uint256 amountfToken,
        uint256 obtainedToken,
        uint256 amountToken,
        uint256 obtainedfToken,
        uint256 underlyingRatio
    ) internal returns (uint256 feeableToken, uint256 earnedTokens) {
        if (obtainedfToken == amountfToken) {
            //there is no point to do the ratio math as we can just get the difference between current obtained tokens and initial obtained tokens
            if (obtainedToken > amountToken) {
                feeableToken = obtainedToken.sub(amountToken);
            }
        } else {
            uint256 currentRatio = _getRatio(obtainedfToken, obtainedToken, 18);

            if (currentRatio < underlyingRatio) {
                uint256 noOfOriginalTokensForCurrentAmount =
                    (obtainedfToken.mul(10**18)).div(underlyingRatio);
                if (noOfOriginalTokensForCurrentAmount < obtainedToken) {
                    feeableToken = obtainedToken.sub(
                        noOfOriginalTokensForCurrentAmount
                    );
                }
            }
        }

        if (feeableToken > 0) {
            uint256 extraTokensFee = _calculateFee(feeableToken);
            emit ExtraTokens(msg.sender, feeableToken.sub(extraTokensFee));
            earnedTokens = feeableToken.sub(extraTokensFee);
        }
    }

    receive() external payable {}
}
