// SPDX-License-Identifier: MIT
//
// No-gas required token swapping to ETH.
// https://xc.bitx.cx
//
// Keeps gas cost and fee
// 90% fee sent to $bitx stakers
// $Bitx: 0xD150e07f602bf3239BE3DE4341E10BE1678a3f8b
//
// Buy & Stake: https://token.bitx.cx
//
// Developed by @Rotwang9000 for https://Bitx.cx
// https://t.me/BitXcx
//
// Register for Airdrop: https://t.me/BitxLiveBot

pragma solidity ^0.8.20;


import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Permit.sol";
import "./IUniswapV2Router02.sol";

interface IRewardPot {
    function addToRewardPot() external payable;
}

contract Bitxchange is Ownable {
    IUniswapV2Router02 public uniswapRouter;
    IRewardPot public rewardPot;
    uint256 public feePercentage = 750; // 0.75% fee, scaled by 10^4
    uint256 public estimatedGasForSwap = 250000;
    address public relayer;

    event FeeUpdated(uint256 newFee);
    event RewardPotUpdated(address newRewardPot);
    event SwapSuccessful(address indexed from, uint256 receivedETH);

    constructor(
        address _uniswapRouter,
        address _rewardPot,
        address _relayer
    ) Ownable(msg.sender) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        rewardPot = IRewardPot(_rewardPot);
        relayer = _relayer;
    }

    // Payable function
    function receiveFunds() public payable {}

    receive() external payable {}

    // Payable fallback function (Solidity 0.6.0 and later)
    fallback() external payable {}

    // Owner deposits ETH into the contract
    function depositETH() external payable {}

    modifier onlyRelayer() {
        require(
            msg.sender == relayer || msg.sender == owner(),
            "Not the relayer"
        );
        _;
    }

	function uniswapAddress() public view returns(address){
		return address(uniswapRouter);
	}

    // Owner can withdraw ETH
    function withdrawETH(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    function setRelayer(address _newRelayer) external onlyOwner {
        relayer = _newRelayer;
    }

    function setFeePercentage(uint256 _newFee) external onlyOwner {
        feePercentage = _newFee;
        emit FeeUpdated(_newFee);
    }

    function setEstimatedGasForSwap(
        uint256 _newEstimatedGasForSwap
    ) external onlyOwner {
        estimatedGasForSwap = _newEstimatedGasForSwap;
    }

    function setUniswapRouter(address _newRouter) external onlyOwner {
        require(_newRouter != address(0), "Invalid address");
        uniswapRouter = IUniswapV2Router02(_newRouter);
    }

    function setRewardPot(address _newRewardPot) external onlyOwner {
        require(_newRewardPot != address(0), "Invalid address");
        rewardPot = IRewardPot(_newRewardPot);
        emit RewardPotUpdated(_newRewardPot);
    }

    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) external onlyRelayer {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(amount <= balance, "Not enough tokens to rescue");
        require(IERC20(token).transfer(to, amount), "Transfer failed");
    }

    function tryGetAmountsOut(
        uint amountIn,
        address[] memory path
    ) internal view returns (bool success, uint256 amountOut) {
        try uniswapRouter.getAmountsOut(amountIn, path) returns (
            uint256[] memory amounts
        ) {
            return (true, amounts[1]);
        } catch {
            return (false, 0);
        }
    }

    // Function to check if a swap is possible
    function canSwap(
        address token,
        uint256 amountIn,
        uint256 userGasPrice
    ) public view returns (bool) {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapRouter.WETH();

        // Check if there's enough liquidity for the swap
        (bool success, uint256 amountOut) = tryGetAmountsOut(amountIn, path);
        if (!success || amountOut == 0) {
            return false;
        }

        // Estimate gas cost and check against the minimum output amount
        uint256 estimatedGasCost = estimatedGasForSwap * userGasPrice;
        if (estimatedGasCost >= amountOut) {
            return false;
        }

        return true;
    }

    function getSwapQuote(
        address token,
        uint256 amount,
        uint256 slippage,
        uint256 userGasPrice
    )
        public
        view
        returns (uint256 minAmountOut, uint256 estimatedGasCost, bool canDoSwap)
    {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapRouter.WETH();

        // Get the expected output amount based on the input amount and path
        (bool success, uint256 expectedAmountOut) = tryGetAmountsOut(
            amount,
            path
        );
        require(success, "No liquidity for this token");

        // Apply slippage
        minAmountOut = (expectedAmountOut * (10000 - slippage)) / 10000;

        // Benchmark gas for Uniswap swap: 184,523 (from Ethereum.org)
        // Adding a 20% buffer for other operations and fluctuations: ~221,428
        //uint256 estimatedGasForSwap = 221428;

        // Calculate estimated gas cost based on user-provided gas price
        estimatedGasCost = estimatedGasForSwap * userGasPrice;

        return (
            minAmountOut,
            estimatedGasCost,
            canSwap(token, amount, userGasPrice)
        );
    }

    function swapTokensWithPermit(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 minAmountOut,
        uint expectedAmountOut,
        uint unpaidFees,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable onlyRelayer {
        IERC20Permit(token).permit(
            from,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );

        // Perform the swap
        return
            swapTokensWithTransfer(
                token,
                from,
                to,
                amount,
                minAmountOut,
                expectedAmountOut,
                unpaidFees
            );
    }

    function swapTokensWithTransfer(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 minAmountOut,
        uint expectedAmountOut,
        uint unpaidFees
    ) public payable onlyRelayer {
        require(
            IERC20(token).transferFrom(from, address(this), amount),
            "Transfer Failed"
        );

        return
            swapTokensForETH(
                token,
                to,
                amount,
                minAmountOut,
                expectedAmountOut,
                unpaidFees
            );
    }

    function swapTokensForETH(
        address token,
        address to,
        uint256 amount,
        uint256 minAmountOut,
        uint expectedAmountOut,
        uint unpaidFees
    ) public payable onlyRelayer {
        uint256 gasCost = gasleft();

        // Estimate gas cost and check against minAmountOut
        uint256 estimatedGasCost = estimatedGasForSwap * tx.gasprice;
        require(
            estimatedGasCost + unpaidFees < minAmountOut,
            "Estimated gas cost exceeds minAmountOut"
        );
        require(
            expectedAmountOut >= minAmountOut,
            "Expected amount less than minimum requested"
        );

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapRouter.WETH();

        // Check tokens are in the contract
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "Token not in contract"
        );

        // Perform the swap
        IERC20(token).approve(address(uniswapRouter), amount);

        uint256[] memory amounts = uniswapRouter.swapExactTokensForETH(
            amount,
            minAmountOut,
            path,
            address(this),
            block.timestamp
        );
        gasCost = ((gasCost - gasleft()) + 100000) * tx.gasprice; // including extra for the transfers after this
        gasCost = gasCost + unpaidFees;
        uint receivedETH = amounts[1];
        if (gasCost > receivedETH) {
            payable(msg.sender).transfer(gasCost);
        } else {
            payable(msg.sender).transfer(gasCost);

            receivedETH = amounts[1] - gasCost;
            // Calculate the fee-free zone and the excess amount
            uint256 feeFreeZone = expectedAmountOut > minAmountOut
                ? expectedAmountOut - minAmountOut
                : 0;
            uint256 excessAmount = receivedETH > expectedAmountOut
                ? receivedETH - expectedAmountOut
                : 0;

            // Calculate and send the fee
            uint256 totalFee = (((receivedETH - feeFreeZone - excessAmount) *
                feePercentage) / 10000) + (excessAmount * 40) / 100; // 40% of the excess amount

            // Send 90% of the total fee to the reward pot
            rewardPot.addToRewardPot{value: (totalFee * 90) / 100}();

            // The remaining fee stays in the contract

            // Send the remaining ETH back to the original sender
            payable(to).transfer(receivedETH - totalFee);
        }

        emit SwapSuccessful(to, receivedETH);
    }

    function swapTokensForETH_UserPaysGas_withPermit(
        address token,
        uint256 amount,
        uint256 minAmountOut,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
		if(deadline > block.timestamp){
			IERC20Permit(token).permit(
				msg.sender,
				address(this),
				amount,
				deadline,
				v,
				r,
				s
			);
		}
        // Perform the swap
        return swapTokensForETH_UserPaysGas(token, amount, minAmountOut);
    }

    function swapTokensForETH_UserPaysGas(
        address token,
        uint256 amount,
        uint256 minAmountOut
    ) public payable {
        // Perform the swap
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(address(uniswapRouter), amount);

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapRouter.WETH();

        uint256[] memory amounts = uniswapRouter.swapExactTokensForETH(
            amount,
            minAmountOut,
            path,
            address(this),
            block.timestamp
        );
        uint256 receivedETH = amounts[1];

        // Calculate and send the fee
        uint256 fee = (receivedETH * feePercentage) / 10000;

        // Send 90% of the fee to the reward pot
        rewardPot.addToRewardPot{value: (fee * 90) / 100}();

        // The remaining 10% fee stays in the contract

        // Send the remaining ETH back to the original sender
        payable(msg.sender).transfer(receivedETH - fee);

        emit SwapSuccessful(msg.sender, receivedETH);
    }
}
