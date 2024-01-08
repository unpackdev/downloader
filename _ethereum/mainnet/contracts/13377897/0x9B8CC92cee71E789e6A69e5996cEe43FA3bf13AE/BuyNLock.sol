//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeCast.sol";
import "./IUniswapV2Router02.sol";

contract BuyNLock is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    uint256 constant MAX_LOCK_TIME = 60 * 60 * 24 * 30; // 30 days
    uint256 constant MAX_UNLOCKS_PER_TX = 500;

    IERC20 public immutable buyingToken;
    uint24 public lockTime;
    IUniswapV2Router02 public immutable uniswapRouter;

    struct Lock {
        uint128 amount;
        uint48 lockedAt;
    }

    struct User {
        uint128 lockedAmountTotal;
        uint128 indexToUnlock;
        Lock[] locks;
    }

    mapping(address => User) public users;

    event LockTimeChange(uint24 oldLockTime, uint24 newLockTime);
    event BuyAndLock(address indexed user, IERC20 indexed sellingToken, uint amountSold, uint amountBought, uint lockedAt);
    event Unlock(address indexed user, uint amountUnlocked, uint numberOfUnlocks);

    constructor(IERC20 _buyingToken, uint24 _lockTime, IUniswapV2Router02 _uniswapRouter) {
        require(address(_buyingToken) != address(0), "Invalid buying token address");
        require(address(_uniswapRouter) != address(0), "Invalid uniswap router address");
        require(_lockTime <= MAX_LOCK_TIME, "Lock time > MAX lock time");

        buyingToken = _buyingToken;
        lockTime = _lockTime;
        uniswapRouter = _uniswapRouter;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setLockTime(uint24 _lockTime) external onlyOwner {
        require(_lockTime <= MAX_LOCK_TIME, "Lock time > MAX lock time");

        emit LockTimeChange(lockTime, _lockTime);
        lockTime = _lockTime;
    }

    function buyForERC20(uint256 amountToSell, uint256 minimumAmountToBuy, address[] calldata swapPath, uint256 swapDeadline) external whenNotPaused {
        require(swapPath.length > 1, "Invalid path length");
        require(swapPath[swapPath.length - 1] == address(buyingToken), "Invalid token out");
        IERC20 sellingToken = IERC20(swapPath[0]);
        require(sellingToken != buyingToken, "selling token == buying token");

        if (sellingToken.allowance(address(this), address(uniswapRouter)) < amountToSell) {
            sellingToken.safeApprove(address(uniswapRouter), 2 ** 256 - 1);
        }

        sellingToken.safeTransferFrom(msg.sender, address(this), amountToSell);

        uint256 buyingTokenBalanceBefore = buyingToken.balanceOf(address(this));
        IUniswapV2Router02(uniswapRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountToSell, 
            minimumAmountToBuy, 
            swapPath, 
            address(this), 
            swapDeadline
        );
        uint128 amountBought = (buyingToken.balanceOf(address(this)) - buyingTokenBalanceBefore).toUint128();
        _lockBoughtTokens(amountBought);

        emit BuyAndLock(msg.sender, sellingToken, amountToSell, amountBought, block.timestamp);
    }

    function buyForETH(uint256 minimumAmountToBuy, address[] calldata swapPath, uint256 swapDeadline) external payable whenNotPaused {
        require(swapPath.length > 1, "Invalid path length");
        require(swapPath[swapPath.length - 1] == address(buyingToken), "Invalid token out");
        IERC20 sellingToken = IERC20(swapPath[0]);
        require(sellingToken != buyingToken, "selling token == buying token");

        uint256 buyingTokenBalanceBefore = buyingToken.balanceOf(address(this));
        IUniswapV2Router02(uniswapRouter).swapExactETHForTokensSupportingFeeOnTransferTokens{ value: msg.value }(
            minimumAmountToBuy, 
            swapPath, 
            address(this), 
            swapDeadline
        );
        uint128 amountBought = (buyingToken.balanceOf(address(this)) - buyingTokenBalanceBefore).toUint128();
        _lockBoughtTokens(amountBought);

        emit BuyAndLock(msg.sender, sellingToken, msg.value, amountBought, block.timestamp);
    }

    function unlockBoughtTokens(address userAddress) external {
        (uint128 unlockableAmount, uint128 unlocksCount) = getUnlockableAmount(userAddress);
        require(unlockableAmount > 0, "No unlockable amount");

        _unlockBoughtTokens(userAddress, unlockableAmount, unlocksCount);
    }

    function multiUnlockBoughtTokens(address[] calldata userAddresses) external {
        for (uint256 i = 0; i < userAddresses.length; i++) {
            address userAddress = userAddresses[i];
            (uint128 unlockableAmount, uint128 unlocksCount) = getUnlockableAmount(userAddress);

            if (unlockableAmount > 0) {
                _unlockBoughtTokens(userAddress, unlockableAmount, unlocksCount);
            }
        }
    }

    // INTERNAL 

    function _lockBoughtTokens(uint128 amountBought) internal {
        User storage user = users[msg.sender];
        user.lockedAmountTotal += amountBought;
        user.locks.push(Lock(amountBought, uint48(block.timestamp)));
    }

    function _unlockBoughtTokens(address userAddress, uint128 unlockableAmount, uint128 unlocksCount) internal {
        User storage user = users[userAddress];
        user.indexToUnlock += unlocksCount;
        user.lockedAmountTotal -= unlockableAmount;
        buyingToken.safeTransfer(userAddress, unlockableAmount);
        emit Unlock(userAddress, unlockableAmount, unlocksCount);
    }

    // VIEW

    function getUnlockableAmount(address userAddress) public view returns (uint128, uint128) {
        User storage user = users[userAddress];
        uint128 indexToUnlock = user.indexToUnlock;
        uint128 locksLength = uint128(user.locks.length);
        uint128 unlocksCount = 0;
        uint128 unlockableAmount = 0;
        uint24 _lockTime = lockTime;

        if (_lockTime != 0) {
            while (indexToUnlock + unlocksCount < locksLength && unlocksCount < MAX_UNLOCKS_PER_TX) {
                Lock storage lock = user.locks[indexToUnlock + unlocksCount];
                if (block.timestamp < lock.lockedAt + _lockTime) break;

                unlockableAmount += lock.amount;
                unlocksCount++;
            }
        } else {
            unlockableAmount = user.lockedAmountTotal;
            unlocksCount = locksLength - indexToUnlock;
        }

        return (unlockableAmount, unlocksCount);
    }

    function getLockedAmount(address userAddress) external view returns (uint128) {
        return users[userAddress].lockedAmountTotal;
    }
}
