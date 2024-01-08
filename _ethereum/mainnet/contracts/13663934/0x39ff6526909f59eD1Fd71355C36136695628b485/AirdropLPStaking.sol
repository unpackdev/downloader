pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./Address.sol";
import "./Context.sol";
import "./Ownable.sol";


interface IUniswapV2RouterBase {
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

interface IUniswapV2Router is IUniswapV2RouterBase {
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

interface AirdropTokenInterface is IERC20 {
    function setLiquidityIncreaseEnabled(bool _enabled) external;
}

contract AirdropLpStaking is Context, Ownable {
    using Address for address;

    // structs

    struct EpochData {
        uint totStaked;
        uint totETH;
    }

    struct EvalBalance {
        uint accBal;  // accumulated balance (paid + unpaid) up to that epoch
        uint epoch;
    }

    EpochData[] private _epochLiquidity;
    mapping (address => EvalBalance) private _lastEvalBalance;  // balance at last operation
    mapping (address => uint256) private _staked;  // staked tokens by each person
    mapping (address => uint256) private _paid;  // ETH paid by address

    uint256 public totStaked = 0;
    uint256 public totETH = 0;
    uint256 public totETHPaid = 0;
    uint256 public currentEpoch = 0;

    IUniswapV2Router public immutable uniswapV2Router;
    IERC20 LPTokens;
    AirdropTokenInterface airdropToken;
    address airdropTokenAddress;
    bool LPTokensSet = false;

    // Events
    event Claim(address indexed _to, uint _amount);
    event Stake(address indexed _addr, uint _amountLP);
    event Unstake(address indexed _addr, uint _amountLP);
    event EthReceived(uint _amount);
    event Epoch(uint _newEdpochId);

    constructor () public {
        uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function getAmountStaked (address a) public view returns(uint) {
        return _staked[a];
    }

    function getAmountPaid (address a) public view returns(uint) {
        return _paid[a];
    }

    function balanceOf(address a, bool includeCurrentEpoch) public view returns(uint) {
        if (_lastEvalBalance[a].epoch == 0 && _lastEvalBalance[a].accBal == 0 && _staked[a] == 0) return 0;
        uint bal = claimableBalance(a);
        if (includeCurrentEpoch) {
            bal += currentEpochBalance(a);
        }
        return bal;
    }

    /**
    * Returns the amount of balance that can be claimed by user
    */
        function claimableBalance(address a) public view returns(uint) {
        return _accumulatedClaimableBalance(a) - _paid[a];
    }

    /**
    * Returns the claimable balance of the current epoch
    */
    function currentEpochBalance(address a) public view returns(uint) {
        uint bal;
        uint lastEpochId = currentEpoch-1;
        if (totStaked>0) {
            bal = (_staked[a] * (totETH - _epochLiquidity[lastEpochId].totETH) / totStaked);
        }
        return bal;
    }

    /**
    * Returns the claimable balance from epoch 0 up to currentEpoch-1, not considering what has already been paid
    */
    function _accumulatedClaimableBalance(address a) private view returns(uint) {
        uint bal = _lastEvalBalance[a].accBal;
        for (uint i=_lastEvalBalance[a].epoch+1; i<currentEpoch; i++) {
            uint prevEth = _epochLiquidity[i-1].totETH;
            if (_epochLiquidity[i].totStaked > 0) {
                bal += (_staked[a] * (_epochLiquidity[i].totETH - prevEth) / _epochLiquidity[i].totStaked);
            }
        }
        return bal;
    }

    function stake(uint amount) public {
        require(LPTokens.balanceOf(msg.sender) >= amount, "Not enough LP balance");
        _nextEpoch();
        updateLastBalance(msg.sender);
        LPTokens.transferFrom(msg.sender, address(this), amount);
        totStaked += amount;
        _staked[msg.sender] += amount;
        emit Stake(msg.sender, amount);
    }

    function stakeETH() public payable {
            _stakeETH(msg.value);
    }

    function _stakeETH(uint amount) private {
        uint beforeEth = address(this).balance - amount;
        uint beforeAirdropTokenAmount = airdropToken.balanceOf(address(this));

        // block fees on liquidity
        airdropToken.setLiquidityIncreaseEnabled(false);

        // swap 50% of ETH
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = airdropTokenAddress;
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount/2}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint afterAirdropTokenAmount = airdropToken.balanceOf(address(this));

        // add LP
        uint tokensAmount = afterAirdropTokenAmount - beforeAirdropTokenAmount;
        airdropToken.approve(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            tokensAmount
        );
        (uint amountToken, uint amountETH, uint liquidity) = uniswapV2Router.addLiquidityETH{value: amount/2}(
            airdropTokenAddress,
            tokensAmount,
            0, 0, address(this), block.timestamp
        );

        // send to contract the airdropTokens left
        if (airdropToken.balanceOf(address(this)) > 0)
            airdropToken.transfer(airdropTokenAddress, airdropToken.balanceOf(address(this)));

        // set stake constants
        _nextEpoch();
        updateLastBalance(msg.sender);
        totStaked += liquidity;
        _staked[msg.sender] += liquidity;

        // re-enable fees on liquidity
        airdropToken.setLiquidityIncreaseEnabled(true);

        emit Stake(msg.sender, amount);
    }

    function unStake(uint amount, bool callClaim) public {
        require(_staked[msg.sender] >= amount, "Not enough LP balance");
        _nextEpoch();
        updateLastBalance(msg.sender);
        LPTokens.transfer(msg.sender, amount);
        totStaked -= amount;
        _staked[msg.sender] -= amount;
        if (callClaim) {
            claim(claimableBalance(msg.sender), false);
        }
        emit Unstake(msg.sender, amount);
    }

    receive() external payable {
        totETH += msg.value;
        emit EthReceived(msg.value);
    }

    function claim(uint amount, bool autoStake) public {
        uint balance = claimableBalance(msg.sender);
        require(amount <= balance, "Amount required is more than claimable balance");
        if (autoStake) {
            _stakeETH(amount);
        } else {
            payable(msg.sender).send(amount);
        }
        totETHPaid += amount;
        _paid[msg.sender] += amount;
        updateLastBalance(msg.sender);
        emit Claim(msg.sender, amount);
    }

    function _nextEpoch() private {
        _epochLiquidity.push(
            EpochData(totStaked, totETH)
        );
        currentEpoch++;
        emit Epoch(currentEpoch);
    }

    // update last bance for user, setting it at the complete epoch right before the current one
    function updateLastBalance(address a) public {
        uint balance = _accumulatedClaimableBalance(a);
        _lastEvalBalance[a].accBal = balance;
        _lastEvalBalance[a].epoch = currentEpoch-1;
    }

    function setLPToken (address newAddr) public onlyOwner {
        require(!LPTokensSet, "LP Tokens already set");
        LPTokens = IERC20(newAddr);
        LPTokensSet = true;
    }

    function setAirdropToken (address newAddr) public onlyOwner {
        require(airdropTokenAddress == address(0), "Address already set");
        airdropTokenAddress = newAddr;
        // give allowance
        airdropToken = AirdropTokenInterface(airdropTokenAddress);
    }


}