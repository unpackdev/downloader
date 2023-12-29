// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./ERC20.sol";

import "./IWithdrawalQueue.sol";
import "./IWETH9.sol";

import "./FullMath.sol";
import "./CommonLibrary.sol";

import "./DefaultAccessControl.sol";

contract MellowStakingPool is DefaultAccessControl, ERC20 {
    error LimitUnderflow(uint256 value, uint256 minValue);
    error InvalidToken();
    error InvalidIndex();
    error InvalidState();
    error InvalidValue();
    error InvalidSender(address sender, address expectedSender);
    error NonEmptyData();
    error DeadlineExceeded();
    error InsufficientBalance(uint256 requestedAmount, uint256 balance);

    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

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
    uint256 public constant Q96 = 2 ** 96;
    uint256 public constant UNSTAKING_DELAY = 24 * 3600; // 1 day

    address public immutable weth;
    address public immutable steth;
    IWithdrawalQueue public immutable withdrawalQueue;
    uint256 public immutable minUnstakingAmount;
    uint256 public immutable maxUnstakingAmount;

    uint24 public fee = 250;
    uint256 public pendingWithdrawalLpTokens;
    uint256 public lastUnstakeRequestTimestamp;
    mapping(address => uint256) public userRequestedLpTokens;

    EnumerableSet.UintSet private _lidoNfts;

    constructor(
        address weth_,
        address steth_,
        address admin_,
        string memory name_,
        string memory symbol_,
        IWithdrawalQueue withdrawalQueue_
    ) DefaultAccessControl(admin_) ERC20(name_, symbol_) {
        weth = weth_;
        steth = steth_;
        withdrawalQueue = withdrawalQueue_;
        IERC20(steth_).safeApprove(address(withdrawalQueue_), type(uint256).max);
        minUnstakingAmount = withdrawalQueue_.MIN_STETH_WITHDRAWAL_AMOUNT();
        maxUnstakingAmount = withdrawalQueue_.MAX_STETH_WITHDRAWAL_AMOUNT();
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

    function updateFee(uint24 newFee) external {
        _requireAdmin();
        fee = newFee;
    }

    function deposit(uint256 amount, uint256 minLpAmount) external returns (uint256 lpAmount) {
        uint256 totalSupply_ = totalSupply();

        if (totalSupply_ == 0) {
            IERC20(weth).safeTransferFrom(msg.sender, address(this), amount);
            if (amount != minLpAmount || amount < 1e9) revert InvalidValue();
            _mint(address(this), amount);
            return minLpAmount;
        }

        uint256 tvl_ = tvl();
        lpAmount = FullMath.mulDiv(totalSupply_, amount, tvl_);
        if (lpAmount < minLpAmount) revert LimitUnderflow(lpAmount, minLpAmount);
        amount = FullMath.mulDiv(lpAmount, tvl_, totalSupply_);

        IERC20(weth).safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, lpAmount);
    }

    function registerWithdraw(uint256 lpAmount) external {
        uint256 userBalance = balanceOf(msg.sender);
        if (userBalance < lpAmount) lpAmount = userBalance;
        _burn(msg.sender, lpAmount);
        pendingWithdrawalLpTokens += lpAmount;
        userRequestedLpTokens[msg.sender] += lpAmount;
        withdraw();
    }

    function withdraw() public returns (uint256 amount, uint256 lpAmount) {
        lpAmount = userRequestedLpTokens[msg.sender];
        if (lpAmount == 0) return (0, 0);

        uint256 tvl_ = tvl();
        uint256 totalSupply_ = totalSupply();
        uint256 wethBalance = IERC20(weth).balanceOf(address(this));

        uint256 lpAmountAvaliableForWithdraw = FullMath.mulDiv(totalSupply_, wethBalance, tvl_);
        if (lpAmount > lpAmountAvaliableForWithdraw) lpAmount = lpAmountAvaliableForWithdraw;

        amount = FullMath.mulDiv(lpAmount, tvl_, totalSupply_);
        if (amount > wethBalance) amount = wethBalance;

        if (amount > 0) {
            IERC20(weth).safeTransfer(msg.sender, amount);
            pendingWithdrawalLpTokens -= lpAmount;
            userRequestedLpTokens[msg.sender] -= lpAmount;
        }
    }

    function requestLidoWithdrawals() external {
        claimLidoWithdrawals();
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
                _requireAtLeastOperator();
            }
        }

        lastUnstakeRequestTimestamp = block.timestamp;
        uint256[] memory mintedNfts = withdrawalQueue.requestWithdrawals(unstakingAmount, address(this));
        for (uint256 i = 0; i < mintedNfts.length; i++) {
            _lidoNfts.add(mintedNfts[i]);
        }
    }

    function claimLidoWithdrawals() public returns (uint256 claimedAmount) {
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
            withdrawalQueue.findCheckpointHints(requests, 1, withdrawalQueue.getLastCheckpointIndex())
        );
        uint256 balanceAfter = IERC20(weth).balanceOf(address(this));
        claimedAmount = balanceAfter - balanceBefore;
    }

    function coins(uint256 i) public view returns (address) {
        if (i == 0) {
            if (weth < steth) return weth;
            return steth;
        } else if (i == 1) {
            if (weth < steth) return steth;
            return weth;
        } else {
            revert InvalidIndex();
        }
    }

    // curve-like swap
    function exchange(uint128 i, uint128 j, uint256 dx, uint256 minDy) external returns (uint256 dy) {
        dy = exactInputSingle(
            ExactInputSingleParams({
                tokenIn: coins(i),
                tokenOut: coins(j),
                recipient: msg.sender,
                fee: 0, // unused parameter
                deadline: type(uint256).max,
                amountIn: dx,
                amountOutMinimum: minDy,
                sqrtPriceLimitX96: 0
            })
        );
    }

    // uniswap-like swap
    function exactInputSingle(ExactInputSingleParams memory params) public returns (uint256 amountOut) {
        if (params.deadline < block.timestamp) revert DeadlineExceeded();
        if (
            !(params.tokenIn == weth && params.tokenOut == steth) &&
            !(params.tokenIn == steth && params.tokenOut == weth)
        ) revert InvalidToken();

        if (params.tokenIn == weth) {
            amountOut = params.amountIn;
        } else {
            amountOut = FullMath.mulDiv(params.amountIn, D6 - fee, D6);
        }

        if (amountOut < params.amountOutMinimum) {
            revert LimitUnderflow(amountOut, params.amountOutMinimum);
        }

        if (params.sqrtPriceLimitX96 != 0) {
            uint256 priceX96 = FullMath.mulDiv(params.sqrtPriceLimitX96, params.sqrtPriceLimitX96, Q96);
            uint256 amountOutMinimum = FullMath.mulDiv(params.amountIn, priceX96, Q96);
            if (amountOut < amountOutMinimum) {
                revert LimitUnderflow(amountOut, amountOutMinimum);
            }
        }

        if (params.tokenIn == weth) {
            uint256 tokenOutBalance = IERC20(params.tokenOut).balanceOf(address(this));
            if (tokenOutBalance < amountOut) {
                revert InsufficientBalance(tokenOutBalance, amountOut);
            }
        } else {
            uint256 tokenAmounts = IERC20(weth).balanceOf(address(this)) +
                IERC20(steth).balanceOf(address(this)) +
                evaluateNfts();
            uint256 totalSupply_ = totalSupply();
            uint256 pendingWithdrawalLpTokens_ = pendingWithdrawalLpTokens;
            uint256 lockedAmount = FullMath.mulDivRoundingUp(
                tokenAmounts,
                pendingWithdrawalLpTokens_,
                totalSupply_ + pendingWithdrawalLpTokens_
            );
            uint256 tokenOutBalance = IERC20(params.tokenOut).balanceOf(address(this));
            if (tokenOutBalance < amountOut + lockedAmount) {
                revert InsufficientBalance(tokenOutBalance, amountOut + lockedAmount);
            }
        }

        IERC20(params.tokenIn).safeTransferFrom(msg.sender, address(this), params.amountIn);
        IERC20(params.tokenOut).safeTransfer(params.recipient, amountOut);
    }

    function _handleEth() private {
        if (msg.sender != address(withdrawalQueue)) revert InvalidSender(msg.sender, address(withdrawalQueue));
        if (msg.data.length != 0) revert NonEmptyData();
        IWETH9(weth).deposit{value: msg.value}();
    }

    fallback() external payable {
        _handleEth();
    }

    receive() external payable {
        _handleEth();
    }
}
