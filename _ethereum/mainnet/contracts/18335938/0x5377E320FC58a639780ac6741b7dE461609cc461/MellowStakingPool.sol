// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./ERC20.sol";

import "./IWithdrawalQueue.sol";
import "./IWETH9.sol";
import "./ILido.sol";
import "./ICurvePool.sol";

import "./FullMath.sol";
import "./CommonLibrary.sol";

import "./DefaultAccessControl.sol";

contract MellowStakingPool is DefaultAccessControl, ERC20 {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    error LimitUnderflow(uint256 value, uint256 minValue);
    error LimitOverflow(uint256 value, uint256 maxValue);
    error InvalidToken();
    error InvalidIndex();
    error InvalidState();
    error InvalidInitialDepositAmount();
    error NonEmptyData();
    error DeadlineExceeded();

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint24 fee;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    uint256 public constant D6 = 1e6;
    uint256 public constant D9 = 1e9;
    uint256 public constant Q96 = 2 ** 96;
    uint256 public constant UNSTAKING_DELAY = 24 * 3600; // 1 day
    uint24 public constant MAX_FEE = 10000; // 1%
    uint256 public constant MAX_PROTOCOL_FEE = 5e8; // 50% of fees
    uint256 public constant MIN_PERMISSIONSLESS_UNSTAKING_AMOUNT = 10 ether;
    int128 public constant CURVE_ETH_INDEX = 0;
    int128 public constant CURVE_STETH_INDEX = 1;

    address public immutable weth;
    address public immutable steth;
    IWithdrawalQueue public immutable withdrawalQueue;
    uint256 public immutable minUnstakingAmount;
    uint256 public immutable maxUnstakingAmount;
    address public immutable protocolTreasury;
    address public immutable curvePool;

    uint24 public fee = 250;
    uint256 public protocolFee = 0;
    uint256 public pendingWithdrawalLpTokens;
    uint256 public lastUnstakeRequestTimestamp;
    mapping(address => uint256) public userRequestedLpTokens;

    EnumerableSet.UintSet private _lidoNfts;

    uint256 public totalSupplyCap;

    constructor(
        address weth_,
        address steth_,
        address admin_,
        string memory name_,
        string memory symbol_,
        IWithdrawalQueue withdrawalQueue_,
        address protocolTreasury_,
        address curvePool_
    ) DefaultAccessControl(admin_) ERC20(name_, symbol_) {
        weth = weth_;
        steth = steth_;
        withdrawalQueue = withdrawalQueue_;
        IERC20(steth_).safeApprove(address(withdrawalQueue_), type(uint256).max);
        minUnstakingAmount = withdrawalQueue_.MIN_STETH_WITHDRAWAL_AMOUNT();
        maxUnstakingAmount = withdrawalQueue_.MAX_STETH_WITHDRAWAL_AMOUNT();
        protocolTreasury = protocolTreasury_;
        curvePool = curvePool_;
    }

    function nfts() public view returns (uint256[] memory) {
        return _lidoNfts.values();
    }

    function evaluateNfts() public view returns (uint256 amount) {
        IWithdrawalQueue.WithdrawalRequestStatus[] memory statuses = withdrawalQueue.getWithdrawalStatus(nfts());
        for (uint256 i = 0; i < statuses.length; i++) {
            if (statuses[i].isClaimed) continue;
            amount += statuses[i].amountOfStETH;
        }
    }

    function tvl() public view returns (uint256) {
        uint256 tokenAmounts = IERC20(weth).balanceOf(address(this)) +
            IERC20(steth).balanceOf(address(this)) +
            evaluateNfts();
        uint256 totalSupply_ = totalSupply();
        return FullMath.mulDiv(tokenAmounts, totalSupply_, totalSupply_ + pendingWithdrawalLpTokens);
    }

    function updateFees(uint24 newFee, uint256 newProtocolFee) external {
        _requireAdmin();
        if (newFee > MAX_FEE) revert LimitOverflow(newFee, MAX_FEE);
        if (newProtocolFee > MAX_PROTOCOL_FEE) revert LimitOverflow(newProtocolFee, MAX_PROTOCOL_FEE);
        fee = newFee;
        protocolFee = newProtocolFee;
    }

    function updateTotalSupplyCap(uint256 newTotalSupplyCap) external {
        _requireAdmin();
        uint256 totalSupply_ = totalSupply();
        if (totalSupply_ > newTotalSupplyCap) revert LimitUnderflow(newTotalSupplyCap, totalSupply_);
        totalSupplyCap = newTotalSupplyCap;
    }

    function deposit(uint256 amount, uint256 minLpAmount) external returns (uint256 lpAmount) {
        uint256 totalSupply_ = totalSupply();

        if (totalSupply_ == 0) {
            IERC20(weth).safeTransferFrom(msg.sender, address(this), amount);
            if (amount != minLpAmount || amount < 1e9) revert InvalidInitialDepositAmount();
            _mint(address(this), amount);
            return minLpAmount;
        }

        uint256 tvl_ = tvl();
        lpAmount = FullMath.mulDiv(totalSupply_, amount, tvl_);
        if (lpAmount < minLpAmount) revert LimitUnderflow(lpAmount, minLpAmount);
        if (lpAmount + totalSupply_ > totalSupplyCap) {
            revert LimitOverflow(lpAmount + totalSupply_, totalSupplyCap);
        }
        amount = FullMath.mulDiv(lpAmount, tvl_, totalSupply_);

        IERC20(weth).safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, lpAmount);
    }

    function registerWithdrawalRequest(uint256 lpAmount, uint256 minAmountOut, bool isInstantWithdrawal) external {
        uint256 userBalance = balanceOf(msg.sender);
        if (userBalance < lpAmount) lpAmount = userBalance;
        _burn(msg.sender, lpAmount);
        pendingWithdrawalLpTokens += lpAmount;
        userRequestedLpTokens[msg.sender] += lpAmount;
        withdraw(minAmountOut, isInstantWithdrawal);
    }

    function _swapOnCurve(uint256 amountIn, uint256 minAmountOut) private returns (uint256 amountOut) {
        if (amountIn == 0) {
            if (minAmountOut != 0) revert LimitUnderflow(0, minAmountOut);
            return 0;
        }
        uint256 tokenInBalance = IERC20(steth).balanceOf(address(this));
        if (tokenInBalance < amountIn) revert LimitUnderflow(tokenInBalance, amountIn);
        IERC20(steth).safeIncreaseAllowance(curvePool, amountIn);
        amountOut = ICurvePool(curvePool).exchange(CURVE_STETH_INDEX, CURVE_ETH_INDEX, amountIn, minAmountOut);
        IWETH9(weth).deposit{value: address(this).balance}();
        IERC20(steth).safeApprove(curvePool, 0);
    }

    function _processRegularWithdrawal(
        uint256 expectedWithdrawalAmount,
        uint256 minAmountOut,
        uint256 lpAmount
    ) private returns (uint256 amountOut) {
        if (expectedWithdrawalAmount < minAmountOut) revert LimitUnderflow(expectedWithdrawalAmount, minAmountOut);
        if (expectedWithdrawalAmount > 0) {
            IERC20(weth).safeTransfer(msg.sender, expectedWithdrawalAmount);
            pendingWithdrawalLpTokens -= lpAmount;
            userRequestedLpTokens[msg.sender] -= lpAmount;
        }
        return expectedWithdrawalAmount;
    }

    function _processInstantCurveWithdrawal(
        uint256 expectedWithdrawalAmount,
        uint256 minAmountOut,
        uint256 lpAmount,
        uint256 wethBalance
    ) private returns (uint256 amountOut) {
        uint256 stethBalance = IERC20(steth).balanceOf(address(this));
        uint256 stethForSwap = expectedWithdrawalAmount - wethBalance;
        if (stethBalance < stethForSwap) revert LimitUnderflow(stethBalance, stethForSwap);
        uint256 minSwapAmountOut = minAmountOut > wethBalance ? minAmountOut - wethBalance : 0;
        amountOut = wethBalance + _swapOnCurve(stethForSwap, minSwapAmountOut);
        if (amountOut < minAmountOut) revert LimitUnderflow(amountOut, minAmountOut);
        if (amountOut > 0) {
            IERC20(weth).safeTransfer(msg.sender, amountOut);
            pendingWithdrawalLpTokens -= lpAmount;
            userRequestedLpTokens[msg.sender] -= lpAmount;
        }
    }

    function _processDelayedWithdrawal(
        uint256 totalSupply_,
        uint256 wethBalance,
        uint256 tvl_,
        uint256 lpAmount,
        uint256 minAmountOut
    ) private returns (uint256 amountOut, uint256 withdrawnLpAmount) {
        withdrawnLpAmount = lpAmount;
        uint256 lpAmountAvaliableForWithdraw = FullMath.mulDiv(totalSupply_, wethBalance, tvl_);
        if (withdrawnLpAmount > lpAmountAvaliableForWithdraw) withdrawnLpAmount = lpAmountAvaliableForWithdraw;

        amountOut = FullMath.mulDiv(withdrawnLpAmount, tvl_, totalSupply_);
        if (amountOut > wethBalance) amountOut = wethBalance;
        if (amountOut < minAmountOut) revert LimitUnderflow(amountOut, minAmountOut);

        if (amountOut > 0) {
            IERC20(weth).safeTransfer(msg.sender, amountOut);
            pendingWithdrawalLpTokens -= withdrawnLpAmount;
            userRequestedLpTokens[msg.sender] -= withdrawnLpAmount;
        }
    }

    function withdraw(
        uint256 minAmountOut,
        bool isInstantWithdrawal
    ) public returns (uint256 amountOut, uint256 lpAmount) {
        lpAmount = userRequestedLpTokens[msg.sender];
        if (lpAmount == 0) {
            if (minAmountOut != 0) revert LimitUnderflow(0, minAmountOut);
            return (0, 0);
        }

        uint256 tvl_ = tvl();
        uint256 totalSupply_ = totalSupply();
        uint256 expectedWithdrawalAmount = FullMath.mulDiv(tvl_, lpAmount, totalSupply_);

        uint256 wethBalance = IERC20(weth).balanceOf(address(this));

        if (expectedWithdrawalAmount <= wethBalance) {
            amountOut = _processRegularWithdrawal(expectedWithdrawalAmount, minAmountOut, lpAmount);
            return (amountOut, lpAmount);
        }

        if (isInstantWithdrawal) {
            amountOut = _processInstantCurveWithdrawal(expectedWithdrawalAmount, minAmountOut, lpAmount, wethBalance);
            return (amountOut, lpAmount);
        }

        (lpAmount, amountOut) = _processDelayedWithdrawal(totalSupply_, wethBalance, tvl_, lpAmount, minAmountOut);
    }

    function requestLidoWithdrawals(uint256[] calldata requestIds) external {
        claimLidoWithdrawals(requestIds);
        uint256 balance = IERC20(steth).balanceOf(address(this));
        uint256 batchCount = balance / maxUnstakingAmount + 1;
        if ((balance % maxUnstakingAmount) < minUnstakingAmount) {
            --batchCount;
        }
        if (batchCount == 0) return;

        uint256[] memory unstakingAmount = new uint256[](batchCount);
        for (uint i = 0; i < batchCount; i++) {
            if (balance > maxUnstakingAmount) {
                unstakingAmount[i] = maxUnstakingAmount;
                balance -= maxUnstakingAmount;
            } else {
                unstakingAmount[i] = balance;
                balance = 0;
            }
        }

        if (unstakingAmount.length == 1) {
            if (lastUnstakeRequestTimestamp + UNSTAKING_DELAY > block.timestamp) {
                if (unstakingAmount[0] < MIN_PERMISSIONSLESS_UNSTAKING_AMOUNT) {
                    _requireAdmin();
                }
            }
        }

        lastUnstakeRequestTimestamp = block.timestamp;
        uint256[] memory mintedNfts = withdrawalQueue.requestWithdrawals(unstakingAmount, address(this));
        for (uint256 i = 0; i < mintedNfts.length; i++) {
            _lidoNfts.add(mintedNfts[i]);
        }
    }

    function claimLidoWithdrawals(uint256[] calldata requestIds) public returns (uint256 claimedAmount) {
        uint256[] memory nfts_ = nfts();
        IWithdrawalQueue.WithdrawalRequestStatus[] memory statuses = withdrawalQueue.getWithdrawalStatus(nfts_);
        uint256 numberToBeClaimed = 0;
        for (uint256 i = 0; i < statuses.length; i++) {
            if (statuses[i].isClaimed) revert InvalidState();
            if (!statuses[i].isFinalized) continue;
            numberToBeClaimed++;
        }
        if (numberToBeClaimed == 0) return 0;
        uint256[] memory requests = new uint256[](numberToBeClaimed);
        {
            uint256 index = 0;
            for (uint256 i = 0; i < statuses.length; i++) {
                if (!statuses[i].isFinalized) continue;
                requests[index] = nfts_[i];
                _lidoNfts.remove(nfts_[i]);
                index++;
            }
            requests = CommonLibrary.sort(requests);
        }

        uint256 balanceBefore = IERC20(weth).balanceOf(address(this));
        withdrawalQueue.claimWithdrawals(
            requests,
            requestIds.length > 0
                ? requestIds
                : withdrawalQueue.findCheckpointHints(requests, 1, withdrawalQueue.getLastCheckpointIndex())
        );
        IWETH9(weth).deposit{value: address(this).balance}();

        uint256 balanceAfter = IERC20(weth).balanceOf(address(this));
        claimedAmount = balanceAfter - balanceBefore;
    }

    function _chargeProtocolFees(uint24 fee_, uint256 protocolFee_, uint256 swapAmount, address token) private {
        uint256 claimAmount = FullMath.mulDiv(swapAmount, fee_, D6);
        claimAmount = FullMath.mulDiv(claimAmount, protocolFee_, D9);
        if (claimAmount > 0) {
            IERC20(token).safeTransfer(protocolTreasury, claimAmount);
        }
    }

    function _getRequiredAmountOutMinimum(
        ExactInputSingleParams memory params
    ) private pure returns (uint256 amountOutMinimum) {
        amountOutMinimum = params.amountOutMinimum;
        if (params.sqrtPriceLimitX96 != 0) {
            uint256 priceX96 = FullMath.mulDiv(params.sqrtPriceLimitX96, params.sqrtPriceLimitX96, Q96);
            uint256 amountOutMinimumByPrice = FullMath.mulDiv(params.amountIn, priceX96, Q96);
            if (amountOutMinimum < amountOutMinimumByPrice) {
                amountOutMinimum = amountOutMinimumByPrice;
            }
        }
    }

    function exactInputSingle(ExactInputSingleParams memory params) public returns (uint256 amountOut) {
        if (params.deadline < block.timestamp) revert DeadlineExceeded();
        if (params.amountIn == 0) return 0;
        if (
            !(params.tokenIn == weth && params.tokenOut == steth) &&
            !(params.tokenIn == steth && params.tokenOut == weth)
        ) revert InvalidToken();

        if (params.tokenIn == weth) {
            amountOut = params.amountIn;
        } else {
            amountOut = FullMath.mulDiv(params.amountIn, D6 - fee, D6);
        }

        uint256 amountOutMinimum = _getRequiredAmountOutMinimum(params);
        if (amountOut < amountOutMinimum) {
            revert LimitUnderflow(amountOut, amountOutMinimum);
        }

        IERC20(params.tokenIn).safeTransferFrom(msg.sender, address(this), params.amountIn);
        if (params.tokenIn == weth) {
            uint256 availableBalance = IERC20(params.tokenOut).balanceOf(address(this));
            if (availableBalance < amountOut) {
                uint256 curveAmountIn = amountOut - availableBalance;
                IWETH9(weth).withdraw(curveAmountIn);
                ILido(steth).submit{value: curveAmountIn}(address(0));
            }
        } else {
            uint256 tvl_ = tvl();
            uint256 totalSupply_ = totalSupply();
            uint256 pendingWithdrawalLpTokens_ = pendingWithdrawalLpTokens;
            uint256 lockedAmount = FullMath.mulDivRoundingUp(
                tvl_,
                pendingWithdrawalLpTokens_,
                totalSupply_ + pendingWithdrawalLpTokens_
            );

            uint256 tokenOutBalance = IERC20(params.tokenOut).balanceOf(address(this));
            uint256 availableBalance = tokenOutBalance > lockedAmount ? tokenOutBalance - lockedAmount : 0;
            if (amountOut > availableBalance) {
                uint256 mellowAmountIn = FullMath.mulDiv(availableBalance, D6, D6 - fee);
                uint256 curveAmountIn = params.amountIn > mellowAmountIn ? params.amountIn - mellowAmountIn : 0;
                uint256 actualCurveMinAmountOut = amountOutMinimum > availableBalance
                    ? amountOutMinimum - availableBalance
                    : 0;
                amountOut = availableBalance + _swapOnCurve(curveAmountIn, actualCurveMinAmountOut);
            }
        }

        IERC20(params.tokenOut).safeTransfer(params.recipient, amountOut);
        if (params.tokenIn == steth) {
            _chargeProtocolFees(fee, protocolFee, params.amountIn, steth);
        }
        {
            uint256 swapPriceX96 = FullMath.mulDiv(amountOut, Q96, params.amountIn);
            (int256 amount0, int256 amount1) = (int256(params.amountIn), -int256(amountOut));
            if (params.tokenIn > params.tokenOut) {
                swapPriceX96 = FullMath.mulDiv(Q96, Q96, swapPriceX96);
                (amount0, amount1) = (amount1, amount0);
            }

            emit Swap(msg.sender, params.recipient, amount0, amount1, swapPriceX96, totalSupply());
        }
    }

    fallback() external payable {
        if (msg.data.length != 0) revert NonEmptyData();
    }

    receive() external payable {}

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param swapPriceX96 The price of the swap
    /// @param totalSupply The supply of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint256 swapPriceX96,
        uint256 totalSupply
    );
}
