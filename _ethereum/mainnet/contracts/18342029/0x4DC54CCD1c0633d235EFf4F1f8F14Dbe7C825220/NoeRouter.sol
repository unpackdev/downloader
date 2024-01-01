// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

struct UserInfo {
    uint256 amount; // How many tokens the user has provided.
    uint256 stakingTime; // The time at which the user staked tokens.
    uint256 rewardClaimed;
}

struct PoolInfo {
    address tokenAddress;
    address rewardTokenAddress;
    uint256 maxPoolSize;
    uint256 currentPoolSize;
    uint256 maxContribution;
    uint256 minContribution;
    uint256 rewardNum;
    uint256 rewardDen;
    uint256 emergencyFees; // it is the fees in percentage, final fees is emergencyFees/1000
    uint256 lockDays;
    bool poolType; // true for public staking, false for whitelist staking
    bool poolActive;
}

interface StakingContract {
    function userInfo(
        uint _pid,
        address _user
    ) external view returns (UserInfo memory);

    function poolLength() external view returns (uint);

    function poolInfo(uint _pid) external view returns (PoolInfo memory);
}

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid owner address");
        owner = newOwner;
    }
}

contract NoeRouter is Ownable {
    uint256 public feePercentage; // Fee percentage in basis points (1 basis point = 0.01%)
    address public feeReceiver;
    address public stakingAddress;
    uint256 public feeWaiveAmount; // Staked tokens required to waive of fees
    address public stakedToken; // Token to be staked to waive off fees
    IUniswapV2Router02 public uniswapRouter;
    IWETH public WETH;

    // analytics
    uint256 public feeCollectedInEth;
    mapping(uint256 => uint256) public totalSwapCount;
    // 0 => token -> token
    // 1 => eth -> token
    // 2 => token -> eth
    // 3 => eth -> weth
    // 4 => weth -> eth
    mapping(address => uint256) public feeCollectedInToken;
    address[] public feeTokens;

    constructor() {
        address currentRouter;

        if (block.chainid == 56) {
            currentRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BSC Router
        } else if (block.chainid == 97) {
            currentRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // BSC Testnet
        } else if (block.chainid == 43114) {
            currentRouter = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4; //Avax Mainnet
        } else if (block.chainid == 137) {
            currentRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; //Polygon Ropsten
        } else if (block.chainid == 250) {
            currentRouter = 0xF491e7B69E4244ad4002BC14e878a34207E38c29; //SpookySwap FTM
        } else if (block.chainid == 3) {
            currentRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //Ropsten
        } else if (block.chainid == 1 || block.chainid == 4) {
            currentRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //Mainnet
        } else {
            revert();
        }

        uniswapRouter = IUniswapV2Router02(currentRouter);
        WETH = IWETH(uniswapRouter.WETH());
        feeReceiver = 0xb34F424Ed9402e9AEDf7cCB1bD5d9c032a6f9796;
        feePercentage = 100;
        feeWaiveAmount = 500000 * 1e18;
        stakedToken = 0xBbE626Be0abD64e8efd72A934F08ff9E81C909c8;
        stakingAddress = 0x93F14F74eda31874D25191A1bB41a21DC7987833;
    }

    // ------------------ only owner functions ------------------

    function setFeeReceiver(address _newFeeReceiver) external onlyOwner {
        feeReceiver = _newFeeReceiver;
    }

    function setFeePercentage(uint256 _newFeePercentage) external onlyOwner {
        feePercentage = _newFeePercentage;
    }

    function setStakingAddress(address _newStakingAddress) external onlyOwner {
        stakingAddress = _newStakingAddress;
    }

    function setFeeWaiveAmount(uint256 _newFeeWaiveAmount) external onlyOwner {
        feeWaiveAmount = _newFeeWaiveAmount;
    }

    function setStakedToken(address _newStakedToken) external onlyOwner {
        stakedToken = _newStakedToken;
    }

    function withdrawEth() external onlyOwner returns (bool) {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        return success;
    }

    function withdrawERC20(
        address _tokenAddress
    ) external onlyOwner returns (bool) {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        bool success = token.transfer(msg.sender, balance);
        return success;
    }

    // ------------------ public functions ------------------

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountsOut,
        uint256 amountIn,
        address[] memory path,
        uint256 deadline,
        uint256 slippage
    ) external {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        bool waiveFee = isWaiveApplicable(msg.sender);
        uint256 feeAmount = waiveFee ? 0 : (amountIn * feePercentage) / 10000;
        uint256 amountInAfterFee = amountIn - feeAmount;

        IERC20(path[0]).approve(address(uniswapRouter), amountIn);
        uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountInAfterFee,
            calcAmountOutMin(slippage, amountsOut, waiveFee),
            path,
            msg.sender,
            deadline
        );

        // no need to transfer fees if fee is waived
        if (waiveFee) return;
        address tokenPath = path[0];
        path = new address[](2);
        path[0] = tokenPath;
        path[1] = uniswapRouter.WETH();

        try
            uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                feeAmount,
                0,
                path,
                feeReceiver,
                block.timestamp
            )
        {
            feeCollectedInEth += uniswapRouter.getAmountsOut(feeAmount, path)[
                1
            ];
        } catch {
            require(
                IERC20(path[0]).transfer(feeReceiver, feeAmount),
                "Token transfer failed"
            );
            if (!isTokenInList(path[0])) {
                feeTokens.push(path[0]);
            }
            feeCollectedInToken[path[0]] += feeAmount;
        }
        totalSwapCount[0]++;
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountsOut,
        address[] memory path,
        uint256 deadline,
        uint256 slippage
    ) external payable {
        bool waiveFee = isWaiveApplicable(msg.sender);
        uint256 feeAmount = waiveFee ? 0 : (msg.value * feePercentage) / 10000;
        uint256 amountInAfterFee = msg.value - feeAmount;

        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amountInAfterFee
        }(
            calcAmountOutMin(slippage, amountsOut, waiveFee),
            path,
            msg.sender,
            deadline
        );

        (bool success, ) = payable(feeReceiver).call{value: feeAmount}("");
        require(success, "Fee transfer failed");
        feeCollectedInEth += feeAmount;
        totalSwapCount[1]++;
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountsOut,
        uint256 amountIn,
        address[] memory path,
        uint256 deadline,
        uint256 slippage
    ) external {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);

        uint256 balanceBeforeSwap = address(this).balance;
        IERC20(path[0]).approve(address(uniswapRouter), amountIn);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            calcAmountOutMin(slippage, amountsOut, true),
            path,
            address(this),
            deadline
        );

        bool waiveFee = isWaiveApplicable(msg.sender);
        uint256 ethRecieved = address(this).balance - balanceBeforeSwap;
        uint256 feeAmount = waiveFee
            ? 0
            : (ethRecieved * feePercentage) / 10000;
        (bool success1, ) = payable(msg.sender).call{
            value: (ethRecieved - feeAmount)
        }("");
        require(success1, "Eth transfer failed");
        (bool success2, ) = payable(feeReceiver).call{value: feeAmount}("");
        require(success2, "Fee transfer failed");
        feeCollectedInEth += feeAmount;
        totalSwapCount[2]++;
    }

    function swapEthToWeth() public payable {
        uint256 feeAmount = (msg.value * feePercentage) / 10000;
        uint256 amountInAfterFee = msg.value - feeAmount;

        WETH.deposit{value: amountInAfterFee}();
        WETH.transfer(msg.sender, amountInAfterFee);
        (bool success, ) = payable(feeReceiver).call{value: feeAmount}("");
        require(success, "Fee transfer failed");
        feeCollectedInEth += feeAmount;
        totalSwapCount[3]++;
    }

    function swapWethToEth(uint256 amountIn) public payable {
        WETH.transferFrom(msg.sender, address(this), amountIn);
        uint256 feeAmount = (amountIn * feePercentage) / 10000;
        uint256 amountInAfterFee = amountIn - feeAmount;

        WETH.withdraw(amountIn);
        (bool success, ) = payable(msg.sender).call{value: amountInAfterFee}(
            ""
        );
        require(success, "Eth transfer failed");
        (success, ) = payable(feeReceiver).call{value: feeAmount}("");
        require(success, "Fee transfer failed");
        feeCollectedInEth += feeAmount;
        totalSwapCount[4]++;
    }

    // calculate amountOutMin with slippage
    function calcAmountOutMin(
        uint256 _slippage,
        uint256 amountsOut, // slippage in basis points (1 basis point = 0.1%)
        bool waiveFee
    ) internal view returns (uint256) {
        if (waiveFee) {
            return (amountsOut * (1000 - _slippage)) / 1000;
        } else {
            return
                (amountsOut * (10000 - (_slippage * 10) - feePercentage)) /
                10000;
        }
    }

    // check if user has staked tokens more than fee waive amount
    function isWaiveApplicable(address _user) public view returns (bool) {
        // staking contract is not available instead of bsc mainnet
        if (block.chainid != 56) {
            return false;
        }

        StakingContract stakingContract = StakingContract(stakingAddress);
        for (uint256 i = 0; i < stakingContract.poolLength(); i++) {
            UserInfo memory userInfo = stakingContract.userInfo(i, _user);
            PoolInfo memory poolInfo = stakingContract.poolInfo(i);

            if (
                userInfo.amount >= feeWaiveAmount &&
                poolInfo.tokenAddress == stakedToken
            ) {
                return true;
            }
        }
        return false;
    }

    function isTokenInList(address token) internal view returns (bool) {
        for (uint256 i = 0; i < feeTokens.length; i++) {
            if (feeTokens[i] == token) {
                return true;
            }
        }
        return false;
    }

    struct TokenFee {
        address tokenAddress;
        uint256 feeAmount;
    }

    function getAllTokenFees() external view returns (TokenFee[] memory) {
        TokenFee[] memory tokenFeesData = new TokenFee[](feeTokens.length);

        for (uint256 i = 0; i < feeTokens.length; i++) {
            tokenFeesData[i] = TokenFee(
                feeTokens[i],
                feeCollectedInToken[feeTokens[i]]
            );
        }

        return tokenFeesData;
    }

    receive() external payable {}
}