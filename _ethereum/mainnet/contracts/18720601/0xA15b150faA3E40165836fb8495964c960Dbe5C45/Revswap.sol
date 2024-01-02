// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapV2Router02.sol";
import "./IERC20.sol";
import "./draft-IERC20Permit.sol";
import "./Ownable.sol";

interface IERC20PermitWithNonce {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract Revswap is Ownable {
    // Constants and state variables
    address public constant rvsToken =
        0xf282484234D905D7229a6C22A0e46bb4b0363eE0;
    address public constant swapRouterAddress =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public immutable swapRouter =
        IUniswapV2Router02(swapRouterAddress);
    uint256 public minRVSForBonification = 5000;
    uint256 public feePercentage = 100; // 1% fee
    uint256 public feePercentageForHolders = 200; // 2% fee

    // Events
    event TokensSwapped(
        address indexed user,
        address indexed token,
        uint256 totalToSwap,
        uint256 totalETHSwapped,
        uint256 gasCost
    );

    // Structs
    struct SwapDetails {
        address tokenIn;
        uint256 amountIn;
        uint256 amountOutMin;
        address recipient;
    }

    struct PermitDetails {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct PermitDetailsWithNonce {
        uint256 nonce;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // Swap functions
    function swapTokenForETHNoNonce(
        SwapDetails memory swapDetails,
        PermitDetails memory permitDetails,
        uint256 deadline
    ) external onlyOwner {
        _swapTokenForETH(swapDetails, deadline, true, permitDetails);
    }

    function swapTokenForETHWithNonce(
        SwapDetails memory swapDetails,
        PermitDetailsWithNonce memory permitDetails,
        uint256 deadline
    ) external onlyOwner {
        _swapTokenForETHWithNonce(swapDetails, permitDetails, deadline);
    }

    function swapTokenForETHAlreadyApproved(
        SwapDetails memory swapDetails,
        uint256 deadline
    ) external onlyOwner {
        _swapTokenForETH(swapDetails, deadline, false, PermitDetails(0, 0, 0));
    }

    // Helper functions
    function _swapTokenForETH(
        SwapDetails memory swapDetails,
        uint256 deadline,
        bool usePermit,
        PermitDetails memory permitDetails
    ) internal {
        uint256 gasStart = gasleft();

        if (usePermit) {
            IERC20Permit(swapDetails.tokenIn).permit(
                swapDetails.recipient,
                address(this),
                swapDetails.amountIn,
                deadline,
                permitDetails.v,
                permitDetails.r,
                permitDetails.s
            );
        }

        require(
            IERC20(swapDetails.tokenIn).transferFrom(
                swapDetails.recipient,
                address(this),
                swapDetails.amountIn
            ),
            "Transfer of tokens failed."
        );

        _performSwap(swapDetails, deadline, gasStart);
    }

    function _swapTokenForETHWithNonce(
        SwapDetails memory swapDetails,
        PermitDetailsWithNonce memory permitDetails,
        uint256 deadline
    ) internal {
        uint256 gasStart = gasleft();

        IERC20PermitWithNonce(swapDetails.tokenIn).permit(
            swapDetails.recipient,
            address(this),
            permitDetails.nonce,
            deadline,
            true,
            permitDetails.v,
            permitDetails.r,
            permitDetails.s
        );

        require(
            IERC20(swapDetails.tokenIn).transferFrom(
                swapDetails.recipient,
                address(this),
                swapDetails.amountIn
            ),
            "Transfer of tokens failed."
        );

        _performSwap(swapDetails, deadline, gasStart);
    }

    function _performSwap(
        SwapDetails memory swapDetails,
        uint256 deadline,
        uint256 gasStart
    ) internal {
        IERC20(swapDetails.tokenIn).approve(
            address(swapRouter),
            swapDetails.amountIn
        );

        address[] memory path = new address[](2);
        path[0] = swapDetails.tokenIn;
        path[1] = swapRouter.WETH();
        uint256[] memory amounts = swapRouter.swapExactTokensForETH(
            swapDetails.amountIn,
            swapDetails.amountOutMin,
            path,
            address(this),
            deadline
        );

        uint256 ethAmount = amounts[amounts.length - 1];
        uint256 feeToApply = IERC20(rvsToken).balanceOf(swapDetails.recipient) >
            minRVSForBonification * 10 ** 18
            ? feePercentage
            : feePercentageForHolders;
        uint256 fee = (ethAmount * feeToApply) / 10000;
        uint256 gasCost = (gasStart - gasleft()) * tx.gasprice;

        _transferFunds(swapDetails.recipient, ethAmount, gasCost, fee);
        emit TokensSwapped(
            swapDetails.recipient,
            swapDetails.tokenIn,
            swapDetails.amountIn,
            ethAmount,
            gasCost
        );
    }

    function _transferFunds(
        address recipient,
        uint256 ethAmount,
        uint256 gasCost,
        uint256 fee
    ) internal {
        (bool sentToRecipient, ) = recipient.call{
            value: ethAmount - gasCost - fee
        }("");
        require(sentToRecipient, "Failed to send ETH to recipient");

        (bool sentToOwner, ) = owner().call{value: gasCost + fee}("");
        require(sentToOwner, "Failed to refund gas cost to owner");
    }

    // Management functions
    function withdrawETH(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send ETH");
    }

    function setFeePercentage(
        uint256 _feePercentage,
        uint256 _feePercentageForHolders
    ) external onlyOwner {
        require(
            _feePercentage <= 1000 && _feePercentageForHolders <= 1000,
            "Fee cannot be greater than 10%"
        );
        feePercentage = _feePercentage;
        feePercentageForHolders = _feePercentageForHolders;
    }

    function setMinRVSForBonification(
        uint256 _minRVSForBonification
    ) external onlyOwner {
        minRVSForBonification = _minRVSForBonification;
    }

    // Receive function
    receive() external payable {}
}
