// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract YieldMagnetFlexiStaking is Ownable {
    using SafeERC20 for IERC20;
    address public immutable magnetTokenAddress;

    mapping(address => uint256) public shareHoldings;
    uint256 public totalShares = 0;

    uint256 private constant base = 10 ** 18;
    uint256 public minimumDepositAmount = 20_000 * base;

    uint256 public amountOfStakers = 0;

    // openToDeposits allows/disallows new deposits. Withdrawals are always allowed.
    bool public openToDeposits = true;


    event Deposit(address staker, uint256 amount);
    event Withdraw(address staker, uint256 amount);

    event DepositsPaused();
    event DepositsUnpaused();

    constructor(address _magnetTokenAddress) Ownable(msg.sender) {
        magnetTokenAddress = _magnetTokenAddress;
    }

    /// @notice  Sets the minimum amount of tokens required to stake.
    /// @param minimumDepositAmount_ provide in without adding the decimals for the token.
    function setMinimumDeposit(uint256 minimumDepositAmount_) external onlyOwner {
        minimumDepositAmount = minimumDepositAmount_ * base;
    }

    /// @notice pauseNewDeposits pauses deposits - not allowing new deposits.
    function pauseNewDeposits() external onlyOwner {
        openToDeposits = false;
    }

    /// @notice unpauseNewDeposits unpauses deposits - allowing new deposits.
    function unpauseNewDeposits() external onlyOwner {
        openToDeposits = true;
    }

    /// @notice Deposits and stakes the specified token. Staking contract must be approved for magnet token.
    /// @dev Calculates shares based on tvl and staked amount. Adds shares to user. TVL must be increased after share calculation.
    /// @param stakeAmount_ amount of tokens to stake. Must be above minimumDepositAmount.
    function stakeTokens(uint256 stakeAmount_) external {
        require(
            openToDeposits == true,
            "YieldMagnetFlexiStaking: This contract is no longer accepting new stakes. Users can still withdraw."
        );
        require(
            stakeAmount_ >= minimumDepositAmount,
            "YieldMagnetFlexiStaking: Please stake above Minimum Deposit Amount!"
        );
        uint256 tvl = IERC20(magnetTokenAddress).balanceOf(address(this));
        uint256 tShares = totalShares;

        uint256 shares;
        if(tShares == 0) {
            // Staking from empty. If there's any tokens, assign them to the staker.
            shares = stakeAmount_+tvl;
        } else {
            shares = (stakeAmount_ * tShares) / tvl;
        }

        IERC20(magnetTokenAddress).transferFrom(
            msg.sender,
            address(this),
            stakeAmount_
        );

        uint256 currentShares = shareHoldings[msg.sender];
        shareHoldings[msg.sender] = currentShares + shares;
        totalShares += shares;
        if(currentShares == 0) {
            amountOfStakers++;
        }

        emit Deposit(msg.sender, stakeAmount_);
    }

    /// @notice Unstakes all tokens and withdraws them to the user's wallet.
    /// @return value of tokens unstaked.
    function unstakeAll() external returns (uint256) {
        uint256 tShares = totalShares;
        
        uint256 shares = shareHoldings[msg.sender];
        require(shares > 0, "YieldMagnetFlexiStaking: No shares to unstake!");
        uint256 tvl = IERC20(magnetTokenAddress).balanceOf(address(this));
        
        uint256 value = (tvl * shares) / tShares;

        shareHoldings[msg.sender] = 0;
        totalShares = tShares - shares;
        amountOfStakers--;

        IERC20(magnetTokenAddress).safeTransfer(msg.sender, value);

        return value;
    }

    /// @notice Unstake specified amount of tokens and withdraw them to the user's wallet. Will round up to balance if difference is < 1 token.
    function unstakeTokens(uint256 unstakeAmount_) public {
        uint256 stakerHoldings = getStakedValue(msg.sender);
        require(
            unstakeAmount_ <= stakerHoldings,
            "YieldMagnetFlexiStaking: Not enough staked!"
        );

        // If the amount left would be less than < 1 token, round the withdrawal to everything.
        if(stakerHoldings - unstakeAmount_ < base) {
            unstakeAmount_ = stakerHoldings;
        }

        uint256 tvl = IERC20(magnetTokenAddress).balanceOf(address(this));
        // uint256 sharesRemoved = (unstakeAmount_ / tvl) * totalShares;
        uint256 sharesRemoved = (unstakeAmount_ * totalShares) / tvl;

        uint256 currentShares = shareHoldings[msg.sender];
        shareHoldings[msg.sender] = currentShares - sharesRemoved;
        totalShares -= sharesRemoved;
        
        if(currentShares == sharesRemoved) {
            amountOfStakers--;
        }

        IERC20(magnetTokenAddress).safeTransfer(msg.sender, unstakeAmount_);

        emit Withdraw(msg.sender, unstakeAmount_);
    }

    /// @notice Retrieves the user's current staked value.
    /// @dev it calculates the user stake value using their shares and tvl.
    /// @param staker_ Address of the user to check staked value for.
    function getStakedValue(address staker_) public view returns (uint256) {
        uint256 stakerShares = shareHoldings[staker_];
        uint256 tvl = IERC20(magnetTokenAddress).balanceOf(address(this));
        uint256 value = (tvl * stakerShares) / totalShares;

        return value;
    }
}