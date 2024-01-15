// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./AccessControl.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

import "./IAlluoStrategy.sol";
import "./ICvxBooster.sol";
import "./ICvxBaseRewardPool.sol";
import "./IWrappedEther.sol";
import "./IExchange.sol";
import "./IFraxFarmERC20.sol";
import "./IConvexWrapper.sol";

contract CurveFraxConvexStrategy is AccessControl, IAlluoStrategy {
    using Address for address;
    using SafeERC20 for IERC20;
    event Locked(bytes32 data);

    ICvxBooster public constant cvxBooster =
        ICvxBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    IExchange public constant exchange =
        IExchange(0x29c66CF57a03d41Cfe6d9ecB6883aa0E2AbA21Ec);
    IERC20 public constant cvxRewards =
        IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IERC20 public constant crvRewards =
        IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20 public constant fraxRewards = 
        IERC20(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
    uint8 public constant unwindDecimals = 2;

    receive() external payable {
    }

    constructor(
        address voteExecutor,
        address gnosis,
        bool isTesting
    ) {
        if (isTesting) _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        else {
            require(
                voteExecutor.isContract(),
                "CurveConvexStrategy: 1!contract"
            );
            require(gnosis.isContract(), "CurveConvexStrategy: 2!contract");
            _grantRole(DEFAULT_ADMIN_ROLE, gnosis);
            _grantRole(DEFAULT_ADMIN_ROLE, voteExecutor);
        }
    }

    function invest(bytes calldata data, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bytes memory)
    {
        (
            address curvePool,
            IERC20 crvLpToken,
            IERC20 poolToken,
            uint8 poolSize,
            uint8 tokenIndexInCurve,
            uint256 poolId,
            IERC20 stakeToken, 
            address fraxPool,
            uint256 duration
        ) = decodeEntryParams(data);
        poolToken.safeIncreaseAllowance(curvePool, amount);
        // prepare amounts array for curve
        uint256[4] memory fourPoolTokensAmount;
        fourPoolTokensAmount[tokenIndexInCurve] = amount;

        // encode call to curve - this ugly code handles different curve pool
        // sizes and function selectors
        bytes memory curveCall;
        if (poolSize == 2) {
            curveCall = abi.encodeWithSelector(
                0x0b4c7e4d,
                uint256[2]([fourPoolTokensAmount[0], fourPoolTokensAmount[1]]),
                0
            );
        } else if (poolSize == 3) {
            curveCall = abi.encodeWithSelector(
                0x4515cef3,
                uint256[3](
                    [
                        fourPoolTokensAmount[0],
                        fourPoolTokensAmount[1],
                        fourPoolTokensAmount[2]
                    ]
                ),
                0
            );
        } else {
            curveCall = abi.encodeWithSelector(
                0x029b2f34,
                fourPoolTokensAmount,
                0
            );
        }

        // execute call
        curvePool.functionCall(curveCall);
        bytes32 kek_id;
        // skip investment in convex, if poolId is uint256 max value
        if (poolId != type(uint256).max) {
            // invest tokens to convex
            uint256 crvLpAmount = crvLpToken.balanceOf(address(this));
            crvLpToken.safeIncreaseAllowance(address(stakeToken), crvLpAmount);
            // Deposit these crvLptokens into the convex wrapper to get staked fraxLP tokens
            IConvexWrapper(address(stakeToken)).deposit(crvLpAmount, address(this));
            uint256 fraxLpAmount = stakeToken.balanceOf(address(this));
            stakeToken.safeIncreaseAllowance(fraxPool, fraxLpAmount);
            // Now stake and lock these LP tokens into the frax farm.
            kek_id = IFraxFarmERC20(fraxPool).stakeLocked(fraxLpAmount, duration);
        }
        emit Locked(kek_id);

        return
            encodeExitParams(
                curvePool,
                address(poolToken),
                address(crvLpToken),
                tokenIndexInCurve,
                poolId,
                address(fraxPool),
                kek_id
            );
    }

    function exitAll(
        bytes calldata data,
        uint256 unwindPercent,
        address outputCoin,
        address receiver,
        bool swapRewards
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        (
            address curvePool,
            IERC20 poolToken,
            IERC20 crvLpToken,
            uint8 tokenIndexInCurve,
            uint256 convexPoolId,
            address fraxPool,
            bytes32 kek_id
        ) = decodeExitParams(data);
        uint256 lpAmount;
        if (convexPoolId != type(uint256).max) {
            // Withdraw locked fraxLP tokens.
            // Get all rewards accumulated.

            address[] memory fraxPoolRewards = IFraxFarmERC20(fraxPool).getAllRewardTokens();
            IFraxFarmERC20(fraxPool).withdrawLocked(kek_id, address(this));
            // Get rewards from Frax
            IFraxFarmERC20(fraxPool).getReward(address(this));
            // Get rewards from Convex
            IConvexWrapper(IFraxFarmERC20(fraxPool).stakingToken()).getReward(address(this));

            // Simply send all frax rewards to receiver.
            for (uint256 i; i < fraxPoolRewards.length; i++) {
                IERC20(fraxPoolRewards[i]).transfer(receiver, IERC20(fraxPoolRewards[i]).balanceOf(address(this)));
            }
            // Withdraw all the curveLPs and curve rewards.
            lpAmount =
                ( IERC20(IFraxFarmERC20(fraxPool).stakingToken()).balanceOf(address(this)) * unwindPercent) /
                (10**(2 + unwindDecimals));

            IConvexWrapper(IFraxFarmERC20(fraxPool).stakingToken()).withdrawAndUnwrap(lpAmount);
        } else {
            lpAmount = crvLpToken.balanceOf(address(this)) * unwindPercent / 10000;
        }

        if (lpAmount == 0) return;

        // exit with coin that we used for entry
        bytes memory curveCall = abi.encodeWithSignature(
            "remove_liquidity_one_coin(uint256,int128,uint256)",
            lpAmount,
            tokenIndexInCurve,
            0
        );
        curvePool.functionCall(curveCall);
        // execute exchanges and transfer all tokens to receiver
        exchangeAll(poolToken, IERC20(outputCoin));
        manageRewardsAndWithdraw(swapRewards, IERC20(outputCoin), receiver);
    }

    function exitOnlyRewards(
        bytes calldata data,
        address outputCoin,
        address receiver,
        bool swapRewards
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {

        (
            ,
            ,
            ,
            ,
            uint256 convexPoolId,
            address fraxPool,
        ) = decodeExitParams(data);
        if (convexPoolId != type(uint256).max) {
            // Withdraw locked fraxLP tokens.
            // Get all rewards accumulated.
            address[] memory fraxPoolRewards = IFraxFarmERC20(fraxPool).getAllRewardTokens();
            // Get rewards from Frax
            IFraxFarmERC20(fraxPool).getReward(address(this));
            // Get rewards from Convex
            IConvexWrapper(IFraxFarmERC20(fraxPool).stakingToken()).getReward(address(this), address(this));
            // Simply send all rewards to receiver.
            for (uint256 i; i < fraxPoolRewards.length; i++) {
                IERC20(fraxPoolRewards[i]).transfer(receiver, IERC20(fraxPoolRewards[i]).balanceOf(address(this)));
            }
        } else {
            ICvxBaseRewardPool rewards = getCvxRewardPool(convexPoolId);
            rewards.getReward(address(this), true);
        }
        manageRewardsAndWithdraw(swapRewards, IERC20(outputCoin), receiver);
    }
    function multicall(
        address[] calldata destinations,
        bytes[] calldata calldatas
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = destinations.length;
        require(length == calldatas.length, "CurveConvexStrategy: lengths");
        for (uint256 i = 0; i < length; i++) {
            destinations[i].functionCall(calldatas[i]);
        }
    }

    function encodeEntryParams(
        address curvePool,
        address crvLpToken,
        address poolToken,
        uint8 poolSize,
        uint8 tokenIndexInCurve,
        uint256 convexPoolId,
        address stakeToken,
        address fraxPool,
        uint256 duration
    ) external pure returns (bytes memory) {
        return
            abi.encode(
                curvePool,
                crvLpToken,
                poolToken,
                poolSize,
                tokenIndexInCurve,
                convexPoolId,
                stakeToken, 
                fraxPool,
                duration
            );
    }

    function encodeExitParams(
        address curvePool,
        address poolToken,
        address crvLpToken,
        uint8 tokenIndexInCurve,
        uint256 convexPoolId,
        address fraxPool,
        bytes32 kek
    ) public pure returns (bytes memory) {
        return
            abi.encode(
                curvePool,
                poolToken,
                crvLpToken,
                tokenIndexInCurve,
                convexPoolId,
                fraxPool,
                kek
            );
    }

    function decodeEntryParams(bytes calldata data)
        public
        pure
        returns (
            address,
            IERC20,
            IERC20,
            uint8,
            uint8,
            uint256,
            IERC20,
            address,
            uint256
        )
    {
        require(data.length == 32 * 9, "CurveConvexStrategy: length en");
        return
            abi.decode(data, (address, IERC20, IERC20, uint8, uint8, uint256, IERC20, address, uint256));
    }

    function decodeExitParams(bytes calldata data)
        public
        pure
        returns (
            address,
            IERC20,
            IERC20,
            uint8,
            uint256,
            address,
            bytes32
        )
    {
        require(data.length == 32 * 7, "CurveConvexStrategy: length ex");
        return abi.decode(data, (address, IERC20, IERC20, uint8, uint256, address,bytes32));
    }

    function exchangeAll(IERC20 fromCoin, IERC20 toCoin) private {
        if (fromCoin == toCoin) return;
        uint256 amount = IERC20(fromCoin).balanceOf(address(this));
        if (amount == 0) return;

        fromCoin.safeApprove(address(exchange), amount);
        exchange.exchange(address(fromCoin), address(toCoin), amount, 0);
    }

    function manageRewardsAndWithdraw(
        bool swapRewards,
        IERC20 outputCoin,
        address receiver
    ) private {
        if (swapRewards) {
            exchangeAll(cvxRewards, outputCoin);
            exchangeAll(crvRewards, outputCoin);
        } else {
            cvxRewards.safeTransfer(
                receiver,
                cvxRewards.balanceOf(address(this))
            );

            crvRewards.safeTransfer(
                receiver,
                crvRewards.balanceOf(address(this))
            );
        }

        outputCoin.safeTransfer(receiver, outputCoin.balanceOf(address(this)));
    }

    function getCvxRewardPool(uint256 poolId)
        private
        view
        returns (ICvxBaseRewardPool)
    {
        (, , , address pool, , ) = cvxBooster.poolInfo(poolId);
        return ICvxBaseRewardPool(pool);
    }
}