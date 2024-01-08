// SPDX-License-Identifier: AGPLV3
pragma solidity 0.8.4;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Constants.sol";

// Uniswap pool interface
interface IUniPool{
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function totalSupply() external view returns (uint256);
}

// Balancer vault interface
interface IVault {
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );
}

// Balancer pool interface
interface IBasePool {
    function getVault() external view returns (IVault);
    function getPoolId() external view returns (bytes32);
}

interface ICurve {
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
}

struct UserInfo {
    uint256 amount;
    int256 rewardDebt;
}

interface IMC {
    function userInfo(uint256 poolId, address user) external view returns (UserInfo memory);
}

/* @notice Contract for helping bots to quickly asses users token amounts while minimizing number
 *      of calls to a node. Works for any standard ERC20 token, balancer or uniswap (uni, sushi etc) style pools, and curve meta pools.
 */
contract tokenCounter is Constants, Ownable {
    using SafeERC20 for IERC20;


    IMC masterChef = IMC(address(0x001C249c09090D79Dc350A286247479F08c7aaD7));
    mapping(address => bool) msPool;
    mapping(address => uint256) msPoolId;
    event LogMCToken(address token, uint256 poolId, bool add);
    
    function addMCToken(address token, uint256 poolId, bool add) external onlyOwner {
        msPool[token] = add;
        msPoolId[token] = poolId;
        emit LogMCToken(token, poolId, add);
    }

    /*
     * @notice get balances of batch of users
     * @param token address of token
     * @param users users to get balances for
     */
    function getTokenAmounts(address token, address[] memory users) public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory amounts = new uint256[](users.length);
        uint256[] memory msAmounts = new uint256[](users.length);
        bool ms = msPool[token];
        for (uint256 i; i < users.length; i++) {
            amounts[i] = IERC20(token).balanceOf(users[i]);
            if (ms) msAmounts[i] += masterChef.userInfo(msPoolId[token], users[i]).amount;
        }
        return (amounts, msAmounts);
    }

    /*
     * @notice calculate composition of lp token
     *      value of lp is defined by (in uniswap routerv2):
     *          lp = Math.min(input0 * poolBalance / reserve0, input1 * poolBalance / reserve1)
     *      which in turn implies:
     *          input0 = reserve0 * lp / poolBalance
     *          input1 = reserve1 * lp / poolBalance
     * @param pool address of uniswap pool
     * @param users users to get lp values for
     */
    function getLpAmountsUni(address pool, address[] memory users) external view returns (uint256[] memory, uint256[] memory, uint256[2][] memory) {
        uint256[] memory userLpAmounts = new uint256[](users.length);
        uint256[] memory userMcAmounts = new uint256[](users.length);
        (userLpAmounts, userMcAmounts) = getTokenAmounts(pool, users);

        (uint112 resA, uint112 resB, ) = IUniPool(pool).getReserves();
        uint256 poolBalance = IUniPool(pool).totalSupply();
        uint256[2][] memory lpPositions = new uint256[2][](users.length);

        for (uint256 i; i < users.length; i++) {
            lpPositions[i][0] = ((userLpAmounts[i] + userMcAmounts[i]) * uint256(resA) * DEFAULT_DECIMALS_FACTOR / poolBalance) / DEFAULT_DECIMALS_FACTOR;
            lpPositions[i][1] = ((userLpAmounts[i] + userMcAmounts[i]) * uint256(resB) * DEFAULT_DECIMALS_FACTOR / poolBalance) / DEFAULT_DECIMALS_FACTOR;
        }

        return (userLpAmounts, userMcAmounts, lpPositions);
    }

    /*
     * @notice calculate composition of lp token in balancer pool
     *      value of lp is defined by balancer can be found @https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/pool-weighted/contracts/WeightedMath.sol
     *
     *   exactBPTInForTokensOut                                                                    
     *   (per token)                                                                              
     *   aO = amountOut                  /        bptIn         \                                
     *   b = balance           a0 = b * | ---------------------  |                              
     *   bptIn = bptAmountIn             \       totalBPT       /                              
     *   bpt = totalBPT                                                                       
     *
     * @param pool address of balancer pool
     * @param users users to get lp values for
     */
    function getLpAmountsBalancer(address pool, address[] memory users) external view returns (uint256[] memory, uint256[] memory, uint256[2][] memory) {
        uint256[] memory userLpAmounts = new uint256[](users.length);
        uint256[] memory userMcAmounts = new uint256[](users.length);
        (userLpAmounts, userMcAmounts) = getTokenAmounts(pool, users);

        IVault vault = IBasePool(pool).getVault();
        bytes32 poolId = IBasePool(pool).getPoolId();
        (,uint256[] memory balances,) = vault.getPoolTokens(poolId);
        
        uint256 poolBalance = IERC20(pool).totalSupply();
        uint256[2][] memory lpPositions = new uint256[2][](users.length);

        for (uint256 i; i < users.length; i++) {
            lpPositions[i][0] = ((userLpAmounts[i] + userMcAmounts[i]) * uint256(balances[0]) * DEFAULT_DECIMALS_FACTOR / poolBalance) / DEFAULT_DECIMALS_FACTOR;
            lpPositions[i][1] = ((userLpAmounts[i] + userMcAmounts[i]) * uint256(balances[1]) * DEFAULT_DECIMALS_FACTOR / poolBalance) / DEFAULT_DECIMALS_FACTOR;
        }

        return (userLpAmounts, userMcAmounts, lpPositions);
    }

    /*
     * @notice calculate PWRD value of users curve meta pool position
     */
    function getCurvePwrd(address pool, address[] memory users) external view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        uint256[] memory userLpAmounts = new uint256[](users.length);
        uint256[] memory userMcAmounts = new uint256[](users.length);
        (userLpAmounts, userMcAmounts) = getTokenAmounts(pool, users);

        uint256[] memory lpPositions = new uint256[](users.length);

        for (uint256 i; i < users.length; i++) {
            uint256 amount = userLpAmounts[i] + userMcAmounts[i];
            if (amount > 0)
                lpPositions[i] = ICurve(pool).calc_withdraw_one_coin(amount, 0);
        }

        return (userLpAmounts, userMcAmounts, lpPositions);
    }
}

