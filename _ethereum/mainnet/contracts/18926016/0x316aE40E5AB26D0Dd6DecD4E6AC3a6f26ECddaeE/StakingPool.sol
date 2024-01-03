// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Context.sol";
import "./IUniswapV2Router02.sol";
import "./ITokenStakingPoolExtension.sol";

interface IUniswapV2Pair {
    function getReserves() external view returns (uint reserve0, uint reserve1, uint32 blockTimestampLast);
}

contract StakingPool is Context, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IUniswapV2Router02 immutable _router;
    uint256 constant MULTIPLIER = 10 ** 36;
    address public token;
    uint256 public lockupPeriod; //in seconds
    uint256 public totalStakers;
    uint256 public totalStakedShares;
    uint256 public targetFeeUSD;
    address public uniswapUsdEthPair;
    address public teamWallet;

    ITokenStakingPoolExtension public tokenStakingPool;

    struct Stake {
        uint256 amount;
        uint256 lastStakeTime;
    }
    struct Reward {
        uint256 excluded;
        uint256 realised;
    }
    mapping(address => Stake) public stakerShares;
    mapping(address => Reward) public stakerRewards;

    uint256 public rewardsRatePerShare;
    uint256 public totalRewardDistributed;
    uint256 public totalRewards;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event StakingRewardClaimed(address user);
    event PoolHasBeenFunded(address indexed user, uint256 amountTokens);
    event rewardDistributed(
        address indexed user,
        uint256 amount,
        bool _wasCompounded
    );

    constructor(address _token, uint256 _lockupPeriod, address __router, address _uniswapUsdEthPair, address _teamWallet) {
        token = _token;
        lockupPeriod = _lockupPeriod;
        _router = IUniswapV2Router02(__router);
        uniswapUsdEthPair = _uniswapUsdEthPair;
        targetFeeUSD = 15 * 10**6;
        teamWallet = _teamWallet;
    }

    function stake(uint256 _amount) external payable nonReentrant {
        uint256 currentFee = getCurrentFeeInETH();
        require(msg.value >= currentFee * 95/100, 'Not enough fees has been sent');

        // Determine the fee to be charged
        uint256 feeToCharge = msg.value >= currentFee ? currentFee : msg.value;

        // Transfer the fee to the team wallet
        (bool sent, ) = teamWallet.call{ value: feeToCharge }('');
        require(sent, "Failed to send ETH to team wallet");

        // Refund any excess ETH
        if (msg.value > feeToCharge) {
            (bool refunded, ) = msg.sender.call{ value: msg.value - feeToCharge }('');
            require(refunded, "Failed to refund excess ETH");
        }
        IERC20(token).safeTransferFrom(_msgSender(), address(this), _amount);
        _setShare(_msgSender(), _amount, false);
    }

    function stakeForWallets(
        address[] memory _wallets,
        uint256[] memory _amounts
    ) external nonReentrant {
        require(_wallets.length == _amounts.length, 'INSYNC');
        uint256 _totalAmount;
        for (uint256 _i; _i < _wallets.length; _i++) {
            _totalAmount += _amounts[_i];
            _setShare(_wallets[_i], _amounts[_i], false);
        }
        IERC20(token).safeTransferFrom(_msgSender(), address(this), _totalAmount);
    }

    function unstake(uint256 _amount) external payable nonReentrant {
        uint256 currentFee = getCurrentFeeInETH();
        require(msg.value >= currentFee * 95/100, 'Not enough fees has been sent');

        // Determine the fee to be charged
        uint256 feeToCharge = msg.value >= currentFee ? currentFee : msg.value;

        // Transfer the fee to the team wallet
        (bool sent, ) = teamWallet.call{ value: feeToCharge }('');
        require(sent, "Failed to send ETH to team wallet");

        // Refund any excess ETH
        if (msg.value > feeToCharge) {
            (bool refunded, ) = msg.sender.call{ value: msg.value - feeToCharge }('');
            require(refunded, "Failed to refund excess ETH");
        }
        IERC20(token).safeTransfer(_msgSender(), _amount);
        _setShare(_msgSender(), _amount, true);
    }

    function _setShare(
        address wallet,
        uint256 balanceUpdate,
        bool isRemoving
    ) internal {
        if (address(tokenStakingPool) != address(0)) {

            try tokenStakingPool.setShare(wallet, balanceUpdate, isRemoving) {

            } catch {

            }
        }
        if (isRemoving) {
            _removeShares(wallet, balanceUpdate);
            emit Unstaked(wallet, balanceUpdate);
        } else {
            _addShares(wallet, balanceUpdate);
            emit Staked(wallet, balanceUpdate);
        }
    }

    function _addShares(address wallet, uint256 amount) private {
        if (stakerShares[wallet].amount > 0) {
            _distributeReward(wallet, false, 0);
        }
        uint256 sharesBefore = stakerShares[wallet].amount;
        totalStakedShares += amount;
        stakerShares[wallet].amount += amount;
        stakerShares[wallet].lastStakeTime = block.timestamp;
        if (sharesBefore == 0 && stakerShares[wallet].amount > 0) {
            totalStakers++;
        }
        stakerRewards[wallet].excluded = _cumulativeRewards(stakerShares[wallet].amount);
    }

    function _removeShares(address wallet, uint256 amount) private {
        require(
            stakerShares[wallet].amount > 0 && amount <= stakerShares[wallet].amount,
            'amount cannot be greater than staked'
        );
        require(
            block.timestamp > stakerShares[wallet].lastStakeTime + lockupPeriod,
            'lockup period did not ended'
        );
        uint256 _unclaimed = getUnpaid(wallet);
        bool _otherStakersPresent = totalStakedShares - amount > 0;
        if (!_otherStakersPresent) {
            _distributeReward(wallet, false, 0);
        }
        totalStakedShares -= amount;
        stakerShares[wallet].amount -= amount;
        if (stakerShares[wallet].amount == 0) {
            totalStakers--;
        }
        stakerRewards[wallet].excluded = _cumulativeRewards(stakerShares[wallet].amount);
        // if there are other stakers and unclaimed rewards,
        // deposit them back into the pool for other stakers to claim
        if (_otherStakersPresent && _unclaimed > 0) {
            _fundPoolWithRewards(wallet, _unclaimed);
        }
    }

    function fundPoolWithRewards() external payable {
        _fundPoolWithRewards(_msgSender(), msg.value);
    }

    function _fundPoolWithRewards(address _wallet, uint256 _amountETH) internal {
        require(_amountETH > 0, 'ETH');
        require(totalStakedShares > 0, 'SHARES');
        totalRewards += _amountETH;
        rewardsRatePerShare += (MULTIPLIER * _amountETH) / totalStakedShares;
        emit PoolHasBeenFunded(_wallet, _amountETH);
    }

    function _distributeReward(
        address _wallet,
        bool _compound,
        uint256 _compoundMinTokensToReceive
    ) internal {
        if (stakerShares[_wallet].amount == 0) {
            return;
        }
        stakerShares[_wallet].lastStakeTime = block.timestamp; // reset every claim
        uint256 _amountWei = getUnpaid(_wallet);
        stakerRewards[_wallet].realised += _amountWei;
        stakerRewards[_wallet].excluded = _cumulativeRewards(stakerShares[_wallet].amount);
        if (_amountWei > 0) {
            totalRewardDistributed += _amountWei;
            if (_compound) {
                _compoundRewards(_wallet, _amountWei, _compoundMinTokensToReceive);
            } else {
                uint256 _balBefore = address(this).balance;
                (bool success, ) = payable(_wallet).call{ value: _amountWei }('');
                require(success, 'DIST0');
                require(address(this).balance >= _balBefore - _amountWei, 'DIST1');
            }
            emit rewardDistributed(_wallet, _amountWei, _compound);
        }
    }

    function _compoundRewards(
        address _wallet,
        uint256 _wei,
        uint256 _minTokensToReceive
    ) internal {
        address[] memory path = new address[](2);
        path[0] = _router.WETH();
        path[1] = token;

        IERC20 _token = IERC20(token);
        uint256 _tokenBalBefore = _token.balanceOf(address(this));
        _router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: _wei }(
            _minTokensToReceive,
            path,
            address(this),
            block.timestamp
        );
        uint256 _compoundAmount = _token.balanceOf(address(this)) - _tokenBalBefore;
        _setShare(_wallet, _compoundAmount, false);
    }

    function claimReward(
        bool _compound,
        uint256 _compMinTokensToReceive
    ) external nonReentrant {
        _distributeReward(_msgSender(), _compound, _compMinTokensToReceive);
        emit StakingRewardClaimed(_msgSender());
    }

    function claimRewardAdmin(
        address _wallet,
        bool _compound,
        uint256 _compMinTokensToReceive
    ) external nonReentrant onlyOwner {
        _distributeReward(_wallet, _compound, _compMinTokensToReceive);
        emit StakingRewardClaimed(_wallet);
    }

    function getUnpaid(address wallet) public view returns (uint256) {
        if (stakerShares[wallet].amount == 0) {
            return 0;
        }
        uint256 earnedRewards = _cumulativeRewards(stakerShares[wallet].amount);
        uint256 rewardsExcluded = stakerRewards[wallet].excluded;
        if (earnedRewards <= rewardsExcluded) {
            return 0;
        }
        return earnedRewards - rewardsExcluded;
    }

    function _cumulativeRewards(uint256 share) internal view returns (uint256) {
        return (share * rewardsRatePerShare) / MULTIPLIER;
    }

    function setPoolExtension(ITokenStakingPoolExtension _tokenStakingPool) external onlyOwner {
        tokenStakingPool = _tokenStakingPool;
    }

    function setLockupPeriod(uint256 _seconds) external onlyOwner {
        require(_seconds < 365 days, 'lte 1 year');
        lockupPeriod = _seconds;
    }

    function withdrawTokens(uint256 _amount) external onlyOwner {
        IERC20 _token = IERC20(token);
        _token.safeTransfer(
            _msgSender(),
            _amount == 0 ? _token.balanceOf(address(this)) : _amount
        );
    }

    function getETHPrice() public view returns (uint) {
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(uniswapUsdEthPair).getReserves();
        // Assume reserve0 is USDC and reserve1 is WETH. Adjust as per actual pool.
        return reserve0 * 1e12 / reserve1; // Returns the price of 1 ETH in terms of USDC (with 6 decimal places)
    }

    function getCurrentFeeInETH() public view returns (uint) {
        if (targetFeeUSD == 0) {
            return 0;
        }
        uint ethPrice = getETHPrice();
        if (ethPrice <= 0) {
            return 0;
        }
        return (targetFeeUSD * 1e12) / ethPrice;
    }

    function setTargetFeeUSD(uint256 _newFeeUSD) external onlyOwner {
        targetFeeUSD = _newFeeUSD * 10**6;
    }

    function setAddresses(address _uniswapUsdEthPair, address _teamWallet) external onlyOwner {
        uniswapUsdEthPair = _uniswapUsdEthPair;
        teamWallet = _teamWallet;
    }

}