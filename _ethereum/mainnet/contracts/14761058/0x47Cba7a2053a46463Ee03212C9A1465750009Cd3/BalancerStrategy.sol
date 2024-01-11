// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./AccessControl.sol";
import "./Address.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";

import "./IBalancer.sol";
import "./ILiquidityGauge.sol";
import "./IBalancerGaugeFactory.sol";
import "./IExchange.sol";

import "./IAlluoStrategy.sol";

contract BalancerStrategy is AccessControl, IAlluoStrategy, IBalancerStructs {
    using Address for address;
    using SafeERC20 for IERC20;

    IBalancer public constant balancer =
        IBalancer(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    IBalancerGaugeFactory public constant gaugeFactory =
        IBalancerGaugeFactory(0x4E7bBd911cf1EFa442BC1b2e9Ea01ffE785412EC);
    IExchange public constant exchange =
        IExchange(0x29c66CF57a03d41Cfe6d9ecB6883aa0E2AbA21Ec);
    uint8 public constant unwindDecimals = 2;

    constructor(
        address voteExecutor,
        address gnosis,
        bool isTesting
    ) {
        if (isTesting) _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        else {
            require(voteExecutor.isContract(), "BalancerStrategy: 1!contract");
            require(gnosis.isContract(), "BalancerStrategy: 2!contract");
            _grantRole(DEFAULT_ADMIN_ROLE, gnosis);
            _grantRole(DEFAULT_ADMIN_ROLE, voteExecutor);
        }
    }

    function invest(bytes calldata data, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bytes memory)
    {
        (bytes32 poolId, uint8 tokenIndex, bool stake) = decodeEntryParams(
            data
        );
        (data);
        (address[] memory tokens, , ) = balancer.getPoolTokens(poolId);

        IERC20 token = IERC20(tokens[tokenIndex]);
        token.safeApprove(address(balancer), amount);

        uint256[] memory amounts = new uint256[](tokens.length);
        amounts[tokenIndex] = amount;

        bytes memory userData = abi.encode(
            uint256(JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT),
            amounts,
            0
        );

        JoinPoolRequest memory request = JoinPoolRequest(
            tokens,
            amounts,
            userData,
            false
        );

        balancer.joinPool(poolId, address(this), address(this), request);

        if (stake) {
            (address lp, ) = balancer.getPool(poolId);
            ILiquidityGauge gauge = gaugeFactory.getPoolGauge(lp);
            uint256 lpAmount = IERC20(lp).balanceOf(address(this));
            IERC20(lp).approve(address(gauge), lpAmount);

            // deposit without claim
            gauge.deposit(lpAmount, address(this), false);
        }

        return abi.encode(poolId, tokenIndex, stake);
    }

    function exitAll(
        bytes calldata data,
        uint256 unwindPercent,
        address outputCoin,
        address receiver,
        bool
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bytes32 poolId, uint8 tokenIndex, bool stake) = decodeExitParams(data);
        (address[] memory tokens, , ) = balancer.getPoolTokens(poolId);
        (address lp, ) = balancer.getPool(poolId);

        uint256 lpAmount;
        if (stake) {
            ILiquidityGauge gauge = gaugeFactory.getPoolGauge(lp);
            lpAmount =
                (gauge.balanceOf(address(this)) * unwindPercent) /
                (10**(2 + unwindDecimals));
            gauge.withdraw(lpAmount, true);
        } else {
            lpAmount =
                (IERC20(lp).balanceOf(address(this)) * unwindPercent) /
                (10**(2 + unwindDecimals));
        }

        uint256[] memory amounts = new uint256[](tokens.length);

        {
            bytes memory exitData = abi.encode(
                uint256(ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT),
                lpAmount,
                tokenIndex
            );

            ExitPoolRequest memory request = ExitPoolRequest(
                tokens,
                amounts,
                exitData,
                false
            );

            balancer.exitPool(
                poolId,
                address(this),
                payable(address(this)),
                request
            );
        }

        address tokenAddress = tokens[tokenIndex];
        exchangeAll(IERC20(tokenAddress), IERC20(outputCoin));

        IERC20(outputCoin).safeTransfer(
            receiver,
            IERC20(outputCoin).balanceOf(address(this))
        );
    }

    function exitOnlyRewards(
        bytes calldata,
        address,
        address,
        bool
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // no rewards action supported
        return;
    }

    function encodeEntryParams(
        bytes32 poolId,
        uint8 tokenId,
        bool stake
    ) external pure returns (bytes memory) {
        return abi.encode(poolId, tokenId, stake);
    }

    function encodeExitParams(
        bytes32 poolId,
        uint8 tokenId,
        bool stake
    ) external pure returns (bytes memory) {
        return abi.encode(poolId, tokenId, stake);
    }

    function decodeEntryParams(bytes calldata data)
        public
        pure
        returns (
            bytes32,
            uint8,
            bool
        )
    {
        require(data.length == 32 * 3, "BalancerStrategy: length en");
        return abi.decode(data, (bytes32, uint8, bool));
    }

    function decodeExitParams(bytes calldata data)
        public
        pure
        returns (
            bytes32,
            uint8,
            bool
        )
    {
        require(data.length == 32 * 3, "BalancerStrategy: length ex");
        return abi.decode(data, (bytes32, uint8, bool));
    }

    function multicall(
        address[] calldata destinations,
        bytes[] calldata calldatas
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = destinations.length;
        require(length == calldatas.length, "BalancerStrategy: lengths");
        for (uint256 i = 0; i < length; i++) {
            destinations[i].functionCall(calldatas[i]);
        }
    }

    function exchangeAll(IERC20 fromCoin, IERC20 toCoin) private {
        if (fromCoin == toCoin) return;
        uint256 amount = IERC20(fromCoin).balanceOf(address(this));
        if (amount == 0) return;

        fromCoin.safeApprove(address(exchange), amount);
        exchange.exchange(address(fromCoin), address(toCoin), amount, 0);
    }
}
