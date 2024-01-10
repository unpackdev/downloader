// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./AccessControl.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./EnumerableSet.sol";

import "./UniversalCurveConvexStrategy.sol";
import "./IVoteExecutor.sol";
import "./ICvxBaseRewardPool.sol";
import "./ICvxBooster.sol";
import "./IEntry.sol";

import "./console.sol";

contract Unwinder is IEntry, AccessControl {
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;

    struct VotePool {
        Entry entry;
        bool isVoteActive;
    }

    IERC20 public constant cvxRewards =
        IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IERC20 public constant crvRewards =
        IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    ICvxBooster public constant convex =
        ICvxBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

    UniversalCurveConvexStrategy public strategy;
    address public exchange;
    IVoteExecutor public voteExecutor;

    uint256 public nextVotePoolId;
    EnumerableSet.UintSet private activePools;
    mapping(uint256 => VotePool) private votePools;

    // To make unwinder working, grant sufficient roles to address of this contract:
    // VoteExecutor - execute(Entry[] memory _entries)
    // UniversalCurveConvexStrategy - withdraw(ICvxBaseRewardPool pool, uint256 lpAmount)
    // UniversalCurveConvexStrategy - exitOneCoin(address pool, uint256 coinIndex, uint256 lpBurnAmount)
    // UniversalCurveConvexStrategy - withdrawTokens(IERC20 token, address destination, uint256 amount)
    // UniversalCurveConvexStrategy - executeCall(address destination, bytes calldata _calldata)
    constructor(
        address curveConvexStrategy,
        address _exchange,
        address gnosis,
        address _voteExecutor,
        bool isTesting
    ) {
        strategy = UniversalCurveConvexStrategy(curveConvexStrategy);
        exchange = _exchange;
        voteExecutor = IVoteExecutor(_voteExecutor);

        require(gnosis.isContract(), "Unwinder: not contract");
        _grantRole(DEFAULT_ADMIN_ROLE, gnosis);
        if (isTesting) _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function executeVote(Entry[] memory _entries)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        voteExecutor.execute(_entries);
        for (uint256 i = 0; i < _entries.length; i++) {
            votePools[nextVotePoolId].isVoteActive = true;
            votePools[nextVotePoolId].entry = _entries[i];

            activePools.add(nextVotePoolId);

            nextVotePoolId++;
        }
    }

    function unwind(
        uint256[] calldata votePoolIds,
        uint256 unwindPercent,
        address outputCoin,
        address receiver,
        bool swapRewards
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        unwindPools(
            votePoolIds,
            outputCoin,
            receiver,
            swapRewards,
            unwindPercent
        );

        for (uint256 i = 0; i < votePoolIds.length; i++) {
            delete votePools[votePoolIds[i]];
            activePools.remove(votePoolIds[i]);
        }
    }

    function unwindAny(
        Entry[] memory entries,
        uint256 unwindPercent,
        address outputCoin,
        address receiver,
        bool swapRewards
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Do not call with votes that has been executed via this contract!

        for (uint256 i = 0; i < entries.length; i++) {
            unwindAndExchange(entries[i], outputCoin, unwindPercent);
        }

        manageRewardsAndWithdraw(swapRewards, outputCoin, receiver);
    }

    function unwindAll(
        uint256 unwindPercent,
        address outputCoin,
        address receiver,
        bool swapRewards
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        unwindPools(
            activePools.values(),
            outputCoin,
            receiver,
            swapRewards,
            unwindPercent
        );

        uint256 length = activePools.length();
        for (uint256 i = 0; i < length; i++) {
            uint256 id = activePools.at(0);
            delete votePools[id];
            activePools.remove(id);
        }
    }

    function unwindOnlyRewards(
        uint256[] calldata votePoolIds,
        address outputCoin,
        address receiver,
        bool swapRewards
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < votePoolIds.length; i++) {
            Entry memory entry = votePools[votePoolIds[i]].entry;
            ICvxBaseRewardPool rewards = getCvxRewardPool(entry.convexPoold);

            strategy.claimAll(rewards);
        }

        manageRewardsAndWithdraw(swapRewards, outputCoin, receiver);
    }

    function getActivePools() external view returns (uint256[] memory) {
        return activePools.values();
    }

    function getVotePool(uint256 votePoolId)
        external
        view
        returns (Entry memory, bool)
    {
        VotePool memory pool = votePools[votePoolId];

        return (pool.entry, pool.isVoteActive);
    }

    function unwindPools(
        uint256[] memory votePoolIds,
        address outputCoin,
        address receiver,
        bool swapRewards,
        uint256 unwindPercent
    ) private {
        for (uint256 i = 0; i < votePoolIds.length; i++) {
            Entry memory entry = votePools[votePoolIds[i]].entry;
            unwindAndExchange(entry, outputCoin, unwindPercent);
        }

        manageRewardsAndWithdraw(swapRewards, outputCoin, receiver);
    }

    function unwindAndExchange(
        Entry memory entry,
        address outputCoin,
        uint256 unwindPercent
    ) private {
        ICvxBaseRewardPool rewards = getCvxRewardPool(entry.convexPoold);

        require(unwindPercent <= 100, "Unwinder: unwind >100%");
        uint256 lpAmount = (rewards.balanceOf(address(strategy)) *
            unwindPercent) / 100;

        if (lpAmount == 0) return;

        // step 1 - withdraw Curve LPs and all rewards
        strategy.withdraw(rewards, lpAmount);

        // step 2 - exit with coin that we used for entry
        strategy.exitOneCoin(
            entry.curvePool,
            entry.tokenIndexInCurve,
            lpAmount
        );

        // step 3 - exchange all tokens to requested output coin:
        // (cvx, crv, entry.poolToken) => outputCoin
        // we will miss cvx and crv, we will accumulate them from other
        // entries and make exchange outside loop (if requested)
        exchangeAllOnStrategy(entry.poolToken, outputCoin);
    }

    function manageRewardsAndWithdraw(
        bool swapRewards,
        address outputCoin,
        address receiver
    ) private {
        if (swapRewards) {
            exchangeAllOnStrategy(address(cvxRewards), outputCoin);
            exchangeAllOnStrategy(address(crvRewards), outputCoin);
        } else {
            strategy.withdrawTokens(
                cvxRewards,
                receiver,
                cvxRewards.balanceOf(address(strategy))
            );
            strategy.withdrawTokens(
                crvRewards,
                receiver,
                crvRewards.balanceOf(address(strategy))
            );
        }

        strategy.withdrawTokens(
            IERC20(outputCoin),
            receiver,
            IERC20(outputCoin).balanceOf(address(strategy))
        );
    }

    function exchangeAllOnStrategy(address fromCoin, address toCoin) private {
        if (fromCoin == toCoin) return;
        uint256 amount = IERC20(fromCoin).balanceOf(address(strategy));
        if (amount == 0) return;

        bytes memory approveCall = abi.encodeWithSelector(
            0x095ea7b3, // approve(address,uint256)
            exchange,
            amount
        );
        bytes memory exchangeCall = abi.encodeWithSelector(
            0x0ed2fc95, // exchange(address,address,uint256,uint256)
            fromCoin,
            toCoin,
            amount,
            0
        );

        // say strategy to approve coin for exchange and execute exchange
        strategy.executeCall(fromCoin, approveCall);
        strategy.executeCall(exchange, exchangeCall);
    }

    function getCvxRewardPool(uint256 poolId)
        private
        view
        returns (ICvxBaseRewardPool)
    {
        (, , , address pool, , ) = convex.poolInfo(poolId);
        return ICvxBaseRewardPool(pool);
    }
}
