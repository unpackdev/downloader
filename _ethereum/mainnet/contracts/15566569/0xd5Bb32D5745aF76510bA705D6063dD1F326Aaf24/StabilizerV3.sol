// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IApeToken.sol";
import "./IConvexStakingWrapperFrax.sol";
import "./ICurveStableSwap.sol";
import "./IFraxStaking.sol";

contract StabilizerV3 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IConvexStakingWrapperFrax public constant apeUSDConvexStakingWrapperFrax =
        IConvexStakingWrapperFrax(0x6a20FC1654A2167d00614332A5aFbB7EBcD9d414);
    IFraxStaking public constant apeUSDFraxStaking =
        IFraxStaking(0xa810D1268cEF398EC26095c27094596374262826);
    ICurveStableSwap public constant apeUSDCurvePool =
        ICurveStableSwap(0x04b727C7e246CA70d496ecF52E6b6280f3c8077D);

    IApeToken public immutable apeApeUSD;
    IERC20 public immutable apeUSD;

    struct RewardData {
        address token;
        uint256 amount;
    }

    event Seize(address token, uint256 amount);

    constructor(address _apeApeUSD) {
        apeApeUSD = IApeToken(_apeApeUSD);
        apeUSD = IERC20(apeApeUSD.underlying());
    }

    // --- VIEW ---

    function getAmountCurveLP(uint256 amount) external view returns (uint256) {
        return apeUSDCurvePool.calc_token_amount([amount, 0], true); // [apeUSD, FRAX/USDC LP]
    }

    function getAmountApeUSD(uint256 amount) external view returns (uint256) {
        return apeUSDCurvePool.calc_withdraw_one_coin(amount, 0); // 0: apeUSD
    }

    function getApeUSDBorrowBalance() external view returns (uint256) {
        return apeApeUSD.borrowBalanceStored(address(this));
    }

    function getAllLocks()
        external
        view
        returns (IFraxStaking.LockedStake[] memory)
    {
        return apeUSDFraxStaking.lockedStakesOf(address(this));
    }

    function getTotalLPLocked() external view returns (uint256) {
        return apeUSDFraxStaking.lockedLiquidityOf(address(this));
    }

    function getTotalLPLockedValue() external view returns (uint256) {
        uint256 amount = apeUSDFraxStaking.lockedLiquidityOf(address(this));
        uint256 price = apeUSDCurvePool.get_virtual_price();
        return (amount * price) / 1e18;
    }

    function getClaimableRewards() external view returns (RewardData[] memory) {
        IConvexStakingWrapperFrax.EarnedData[]
            memory convexRewards = apeUSDConvexStakingWrapperFrax.earned(
                address(this)
            );
        uint256[] memory fraxRewards = apeUSDFraxStaking.earned(address(this));
        address[] memory fraxRewardTokens = apeUSDFraxStaking
            .getAllRewardTokens();

        RewardData[] memory claimableRewards = new RewardData[](
            convexRewards.length + fraxRewards.length
        );
        for (uint256 i = 0; i < convexRewards.length; i++) {
            claimableRewards[i] = RewardData({
                token: convexRewards[i].token,
                amount: convexRewards[i].amount
            });
        }
        for (uint256 i = 0; i < fraxRewards.length; i++) {
            claimableRewards[i + convexRewards.length] = RewardData({
                token: fraxRewardTokens[i],
                amount: fraxRewards[i]
            });
        }
        return claimableRewards;
    }

    // --- DEPOSIT ---

    function depositApeUSD(uint256 amount, uint256 minCurveLP)
        public
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        if (amount > 0) {
            // Borrow apeUSD.
            require(
                apeApeUSD.borrow(payable(address(this)), amount) == 0,
                "borrow failed"
            );
        }

        // Approve apeUSD and add liquidity to Curve pool.
        uint256 apeUSDBalance = apeUSD.balanceOf(address(this));
        if (apeUSDBalance > 0) {
            apeUSD.safeIncreaseAllowance(
                address(apeUSDCurvePool),
                apeUSDBalance
            );
            apeUSDCurvePool.add_liquidity(
                [apeUSDBalance, 0], // [apeUSD, FRAX/USDC LP]
                minCurveLP,
                address(this)
            );
        }

        // Approve Curve LP, and deposit LP to Convex staking wrapper (for Frax).
        uint256 lpBalance = apeUSDCurvePool.balanceOf(address(this));
        if (lpBalance > 0) {
            apeUSDCurvePool.approve(
                address(apeUSDConvexStakingWrapperFrax),
                lpBalance
            );
            apeUSDConvexStakingWrapperFrax.deposit(lpBalance, address(this));
        }
        return lpBalance;
    }

    // --- STAKE ---

    function stakeLock(uint256 lpAmount, uint256 period)
        public
        onlyOwner
        nonReentrant
    {
        uint256 stakedBalance = apeUSDConvexStakingWrapperFrax.balanceOf(
            address(this)
        );
        require(lpAmount <= stakedBalance, "insufficient LP");

        // Approve Convex staking wrapped LP, and stake LP to Frax staking.
        apeUSDConvexStakingWrapperFrax.approve(
            address(apeUSDFraxStaking),
            lpAmount
        );
        apeUSDFraxStaking.stakeLocked(lpAmount, period);
    }

    function increaseLockAmount(uint256 lpAmount, bytes32 kekID)
        public
        onlyOwner
        nonReentrant
    {
        uint256 stakedBalance = apeUSDConvexStakingWrapperFrax.balanceOf(
            address(this)
        );
        require(lpAmount <= stakedBalance, "insufficient LP");

        // Approve Convex staking wrapped LP, and stake LP to Frax staking.
        apeUSDConvexStakingWrapperFrax.approve(
            address(apeUSDFraxStaking),
            lpAmount
        );
        apeUSDFraxStaking.lockAdditional(kekID, lpAmount);
    }

    function extendLock(bytes32 kekID, uint256 newEndingTime)
        public
        onlyOwner
        nonReentrant
    {
        apeUSDFraxStaking.lockLonger(kekID, newEndingTime);
    }

    // --- WITHDRAW ---

    function withdrawApeUSD(uint256 lpAmount, uint256 minApeUSD)
        public
        onlyOwner
        nonReentrant
    {
        uint256 stakedBalance = apeUSDConvexStakingWrapperFrax.balanceOf(
            address(this)
        );
        require(lpAmount <= stakedBalance, "insufficient LP");

        if (lpAmount > 0) {
            // Withdraw from Convex staking wrapper (for Frax) and unwrap it back to Curve LP.
            apeUSDConvexStakingWrapperFrax.withdrawAndUnwrap(lpAmount);
        }

        // Remove liquidity from Curve pool.
        uint256 lpBalance = apeUSDCurvePool.balanceOf(address(this));
        if (lpBalance > 0) {
            apeUSDCurvePool.remove_liquidity_one_coin(
                lpBalance,
                0, // 0: apeUSD
                minApeUSD,
                address(this)
            );
        }

        // Approve and repay apeUSD.
        uint256 repayAmount = apeUSD.balanceOf(address(this));
        uint256 borrowBalance = apeApeUSD.borrowBalanceCurrent(address(this));
        if (repayAmount > borrowBalance) {
            repayAmount = borrowBalance;
        }
        apeUSD.safeIncreaseAllowance(address(apeApeUSD), repayAmount);
        require(
            apeApeUSD.repayBorrow(payable(address(this)), repayAmount) == 0,
            "repay failed"
        );
    }

    // --- UNSTAKE ---

    function unstake(bytes32 kekID) public onlyOwner nonReentrant {
        apeUSDFraxStaking.withdrawLocked(kekID, address(this));
    }

    // --- CLAIM REWARDS ---

    function claimRewards() public onlyOwner nonReentrant {
        // Claim CRV and CVX.
        apeUSDConvexStakingWrapperFrax.getReward(address(this));

        // Claim FXS.
        apeUSDFraxStaking.getReward(address(this));
    }

    // --- SEIZE ---

    function seize(address token) public onlyOwner nonReentrant {
        if (
            token == address(apeUSD) ||
            token == address(apeUSDConvexStakingWrapperFrax)
        ) {
            uint256 borrowBalance = apeApeUSD.borrowBalanceCurrent(
                address(this)
            );
            require(borrowBalance == 0, "borrow balance not zero");
        }
        uint256 bal = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(owner(), bal);
        emit Seize(token, bal);
    }
}
