pragma solidity ^0.7.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


struct UnipumpGroupData
{
    uint64 tokenListId;
    address leader;

    uint32 runTimeout;
    bool aborted;
    bool complete;
    
    uint32 startTimeout;
    uint16 maxRunTimeHours;  
    uint16 leaderProfitShareOutOf10000;
    
    uint256 leaderUppCollateral;
    uint256 requiredMemberUppFee;
    uint256 minEthToJoin;

    uint256 minEthToStart;
    uint256 maxEthAcceptable;

    // ^-- parameters
    
    address[] members;
    uint256 totalContributions;

    // ^-- pre-start
}

struct UnipumpGroupDataMappings
{
    // To work around deficiencies in solidity

    mapping (address => bool) authorizedTraders;
    // ^-- any time before finish/abort

    mapping (address => uint256) contributions;
    // ^-- pre-start

    mapping (address => uint256) balances;
    mapping (address => mapping (address => bool)) withdrawals;
    // ^-- operational
}

struct UnipumpTokenList
{
    address owner;
    bool locked;
    address[] tokens;
    mapping (address => uint256) tokenIndexes;    
}
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library UnipumpGroupLibrary
{
    using SafeMath for uint256;

    function joinGroup(
        UnipumpGroupData storage groupData,
        UnipumpGroupDataMappings storage groupDataMappings,
        address unipump
    )
        public
    {
        require (!groupData.aborted, "Aborted");
        require (groupData.runTimeout == 0, "Started");
        uint256 totalContributions = groupData.totalContributions;
        address leader = groupData.leader;
        require (leader != address(0), "Group does not exist");
        uint256 contribution = groupDataMappings.contributions[msg.sender];
        bool isLeader = msg.sender == leader;
        if (contribution == 0 && !isLeader) {
            IERC20(unipump).transferFrom(msg.sender, address(this), groupData.requiredMemberUppFee);
            groupData.members.push(msg.sender);
        }
        contribution += msg.value;
        totalContributions += msg.value;
        require (contribution >= groupData.minEthToJoin || isLeader, "Insufficient ETH");
        require (totalContributions <= groupData.maxEthAcceptable, "Too much ETH for group");
        groupDataMappings.contributions[msg.sender] = contribution;
        groupData.totalContributions = totalContributions;
    }

    function abortGroup(UnipumpGroupData storage groupData)
        public
    {
        require (!groupData.aborted, "Aborted");
        require (groupData.runTimeout == 0, "Started");
        address leader = groupData.leader;
        require (leader != address(0), "Group does not exist");
        if (msg.sender != leader) {
            require (block.timestamp >= groupData.startTimeout, "Leader only");
        }
        groupData.aborted = true;
        groupData.startTimeout = uint32(block.timestamp);
    }

    function startGroup(
        UnipumpGroupData storage groupData,
        UnipumpGroupDataMappings storage groupDataMappings,
        address weth
    )
        public
    {
        require (!groupData.aborted, "Aborted");
        require (groupData.runTimeout == 0, "Started");
        require (msg.sender == groupData.leader, "Leader only");
        uint256 totalContributions = groupData.totalContributions;
        require (totalContributions >= groupData.minEthToStart, "Insufficient ETH");
        groupData.runTimeout = uint32(block.timestamp + groupData.maxRunTimeHours * 60 * 60);
        groupDataMappings.balances[weth] = totalContributions;
        IWETH(weth).deposit{ value: totalContributions }();
    }

    function finishGroup(
        UnipumpGroupData storage groupData,
        UnipumpGroupDataMappings storage groupDataMappings,
        address weth
    )
        public
    {
        require (!groupData.complete, "Already complete");
        require (groupData.runTimeout > 0, "Not started");
        address leader = groupData.leader;
        if (msg.sender != leader) {
            require (block.timestamp >= groupData.runTimeout, "Leader only");
        }
        groupData.complete = true;
        groupData.runTimeout = uint32(block.timestamp);
        IWETH(weth).withdraw(groupDataMappings.balances[weth]);
    }
    
    function validatePath(
        mapping (address => uint256) storage mainTokenList,
        mapping (address => uint256) storage groupTokenList,
        address[] memory path,
        address weth
    )
        private
        view
    {
        require (path.length >= 2);
        for (uint256 x = 0; x < path.length; ++x) {
            address token = path[x];
            require (token == weth || mainTokenList[token] > 0 || groupTokenList[token] > 0, "Token not approved");
        }
    }

    function prepareSwap(
        UnipumpGroupData storage groupData,
        UnipumpGroupDataMappings storage groupDataMappings,
        address[] memory path,
        uint256 amountIn,
        IUniswapV2Router02 uniswapV2Router
    )
        private
        returns (uint256 groupBalanceIn, uint256 balanceIn, uint256 balanceOut)
    {
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];
        require (msg.sender == groupData.leader || groupDataMappings.authorizedTraders[msg.sender], "Leader only");
        require (!groupData.complete, "Already complete");
        require (groupData.runTimeout > 0, "Not started");
        groupBalanceIn = groupDataMappings.balances[tokenIn];
        require (groupBalanceIn >= amountIn);
        balanceIn = IERC20(tokenIn).balanceOf(address(this));
        balanceOut = IERC20(tokenOut).balanceOf(address(this));
        IERC20(tokenIn).approve(address(uniswapV2Router), amountIn);
    }

    function updateBalances(
        UnipumpGroupDataMappings storage groupDataMappings,        
        mapping (address => uint256) storage totalTraded,
        address[] memory path,
        uint256 groupBalanceIn,
        uint256 balanceIn,
        uint256 balanceOut
    )
        private
    {
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];
        uint256 newBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 newBalanceOut = IERC20(tokenOut).balanceOf(address(this));
        
        groupDataMappings.balances[tokenIn] = groupBalanceIn.add(newBalanceIn).sub(balanceIn);
        groupDataMappings.balances[tokenOut] = groupDataMappings.balances[tokenOut].add(newBalanceOut).sub(balanceOut);

        totalTraded[tokenIn] += newBalanceIn > balanceIn ? newBalanceIn - balanceIn : balanceIn - newBalanceIn;
        totalTraded[tokenOut] += newBalanceOut > balanceOut ? newBalanceOut - balanceOut : balanceOut - newBalanceOut;
    }

    function swapExactTokensForTokens(
        UnipumpGroupData storage groupData,
        UnipumpGroupDataMappings storage groupDataMappings,
        mapping (address => uint256) storage mainTokenList,
        mapping (address => uint256) storage groupTokenList,
        mapping (address => uint256) storage totalTraded,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        uint256 deadline,
        address weth,
        IUniswapV2Router02 uniswapV2Router
    ) 
        public        
        returns (uint256[] memory amounts)
    {
        validatePath(mainTokenList, groupTokenList, path, weth);
        (uint256 groupBalanceIn, uint256 balanceIn, uint256 balanceOut) = prepareSwap(groupData, groupDataMappings, path, amountIn, uniswapV2Router);
        amounts = uniswapV2Router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            deadline);
        updateBalances(groupDataMappings, totalTraded, path, groupBalanceIn, balanceIn, balanceOut);
    }

    function swapTokensForExactTokens(
        UnipumpGroupData storage groupData,
        UnipumpGroupDataMappings storage groupDataMappings,
        mapping (address => uint256) storage mainTokenList,
        mapping (address => uint256) storage groupTokenList,
        mapping (address => uint256) storage totalTraded,
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        uint256 deadline,
        address weth,
        IUniswapV2Router02 uniswapV2Router
    ) 
        public
        returns (uint256[] memory amounts)
    {
        validatePath(mainTokenList, groupTokenList, path, weth);
        (uint256 groupBalanceIn, uint256 balanceIn, uint256 balanceOut) = prepareSwap(groupData, groupDataMappings, path, amountInMax, uniswapV2Router);
        amounts = uniswapV2Router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            address(this),
            deadline);
        updateBalances(groupDataMappings, totalTraded,path, groupBalanceIn, balanceIn, balanceOut);
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        UnipumpGroupData storage groupData,
        UnipumpGroupDataMappings storage groupDataMappings,
        mapping (address => uint256) storage mainTokenList,
        mapping (address => uint256) storage groupTokenList,
        mapping (address => uint256) storage totalTraded,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        uint256 deadline,
        address weth,
        IUniswapV2Router02 uniswapV2Router
    ) 
        public
    {
        validatePath(mainTokenList, groupTokenList, path, weth);
        (uint256 groupBalanceIn, uint256 balanceIn, uint256 balanceOut) = prepareSwap(groupData, groupDataMappings, path, amountIn, uniswapV2Router);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            deadline);
        updateBalances(groupDataMappings, totalTraded, path, groupBalanceIn, balanceIn, balanceOut);
    }

    function addAuthorizedTrader(
        UnipumpGroupData storage groupData,
        UnipumpGroupDataMappings storage groupDataMappings,
        address trader
    ) 
        public
    {
        require (msg.sender == groupData.leader, "Leader only");
        require (!groupData.complete, "Already complete");
        require (!groupData.aborted, "Aborted");
        groupDataMappings.authorizedTraders[trader] = true;
    }

    function removeAuthorizedTrader(
        UnipumpGroupData storage groupData,
        UnipumpGroupDataMappings storage groupDataMappings,
        address trader
    ) 
        public
    {
        require (msg.sender == groupData.leader, "Leader only");
        require (!groupData.complete, "Already complete");
        require (!groupData.aborted, "Aborted");
        groupDataMappings.authorizedTraders[trader] = false;
    }

    function withdraw(
        UnipumpGroupData storage groupData,
        UnipumpGroupDataMappings storage groupDataMappings,
        address token,
        address unipump,
        address weth,
        address caller
    )
        public
    {
        uint256 contribution = groupDataMappings.contributions[caller];
        bool isLeader = caller == groupData.leader;
        if (groupData.aborted) {            
            // token parameter is ignored - we send eth/upp back
            require (!groupDataMappings.withdrawals[caller][address(0)], "Already withdrawn");
            groupDataMappings.withdrawals[caller][address(0)] = true;
            if (isLeader) {
                IERC20(unipump).transfer(msg.sender, groupData.leaderUppCollateral);
            }
            else {
                IERC20(unipump).transfer(msg.sender, groupData.requiredMemberUppFee);
            }
            if (contribution > 0) {
                (bool success,) = msg.sender.call{ value: contribution }("");
                require (success, "Transfer failed");
            }
            return;
        }
        if (token == address(0)) { token = weth; }
        require (groupData.complete, "Cannot yet withdraw");
        require (!groupDataMappings.withdrawals[caller][token], "Already withdrawn");
        groupDataMappings.withdrawals[caller][token] = true;
        uint256 totalContributions = groupData.totalContributions;
        uint256 finalBalance = groupDataMappings.balances[token];
        uint256 extra = 0;
        if (token == weth) {
            uint256 leaderPayout = finalBalance > totalContributions ? (finalBalance - totalContributions) * groupData.leaderProfitShareOutOf10000 / 10000 : 0;
            finalBalance -= leaderPayout;
            if (isLeader) { extra = leaderPayout; }
        }
        else if (token == unipump) {
            uint256 finalWethBalance = groupDataMappings.balances[weth];
            uint256 totalUppPot = groupData.leaderUppCollateral + (groupData.requiredMemberUppFee * groupData.members.length);
            if (finalWethBalance >= totalContributions) {
                if (isLeader) {
                    IERC20(unipump).transfer(msg.sender, totalUppPot);
                }
            }
            else {
                uint256 forMembers = totalUppPot.mul(totalContributions - finalWethBalance) / totalContributions;
                if (isLeader) {
                    IERC20(unipump).transfer(msg.sender, totalUppPot - forMembers);
                }
                else {
                    IERC20(unipump).transfer(msg.sender, forMembers.mul(contribution) / totalContributions);
                }
            }
        }
        uint256 toSend = extra + finalBalance.mul(contribution) / totalContributions;
        if (toSend > 0) {
            if (token == weth) {
                (bool success,) = msg.sender.call{ value: toSend }("");
                require (success, "Transfer failed");
            }
            else {
                require (IERC20(token).transfer(msg.sender, toSend));
            }
        }
    }

    function withdrawMany(
        UnipumpGroupData storage groupData,
        UnipumpGroupDataMappings storage groupDataMappings,
        address[] memory tokens,
        address unipump,
        address weth
    )
        public
    {
        for (uint256 x = 0; x < tokens.length; ++x) {
            withdraw(groupData, groupDataMappings, tokens[x], unipump, weth, msg.sender);
        }
    }

    function emergencyWithdrawal(
        UnipumpGroupData storage groupData,
        UnipumpGroupDataMappings storage groupDataMappings,
        address member,
        address[] memory tokens,
        address unipump,
        address weth
    )
        public
    {
        require (
            (groupData.complete && block.timestamp > groupData.runTimeout + 60 * 60 * 24 * 30) || // 30 days after group is complete
            (groupData.aborted && block.timestamp > groupData.startTimeout + 60 * 60 * 24 * 30)   // 30 days after group is aborted
        );
        for (uint256 x = 0; x < tokens.length; ++x) {
            withdraw(groupData, groupDataMappings, tokens[x], unipump, weth, member);
        }
    }
}