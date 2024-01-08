//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.7;
import "./IERC20.sol";
import "./TransferHelper.sol";

/// @title Rainbow base aggregator contract
contract BaseAggregator {
    /// @dev Used to prevent re-entrancy
    uint256 internal status;

    /// @dev modifier that prevents reentrancy attacks on specific methods
    modifier nonReentrant() {
        // On the first call to nonReentrant, status will be 1
        require(status != 2, "NON_REENTRANT");

        // Any calls to nonReentrant after this point will fail
        status = 2;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        status = 1;
    }

    /** INTERNAL **/

    /// @dev internal method that executes ERC20 to ETH token swaps with the ability to take a fee from the output
    function _fillQuoteTokenToEth(
        address sellTokenAddress,
        address payable swapTarget,
        bytes calldata swapCallData,
        uint256 sellAmount,
        uint256 feePercentageBasisPoints
    ) internal {
        // 1 - Get the initial eth amount
        uint256 initialEthAmount = address(this).balance - msg.value;

        // 2 - Move the tokens to this contract
        TransferHelper.safeTransferFrom(
            sellTokenAddress,
            msg.sender,
            address(this),
            sellAmount
        );

        // 3 - Approve the aggregator's contract to swap the tokens
        if (
            IERC20(sellTokenAddress).allowance(address(this), swapTarget) <
            sellAmount
        ) {
            TransferHelper.safeApprove(
                sellTokenAddress,
                swapTarget,
                type(uint256).max
            );
        }

        // 4 - Call the encoded swap function call on the contract at `swapTarget`,
        // passing along any ETH attached to this function call to cover protocol fees.
        (bool success, ) = swapTarget.call{value: msg.value}(swapCallData);
        require(success, "SWAP_CALL_FAILED");

        // 5 - Substract the fees and send the rest to the user
        // Fees will be held in this contract
        uint256 finalEthAmount = address(this).balance;
        uint256 ethDiff = finalEthAmount - initialEthAmount;

        if (feePercentageBasisPoints > 0) {
            uint256 fees = (ethDiff * feePercentageBasisPoints) / 10000;
            uint256 amountMinusFees = ethDiff - fees;
            TransferHelper.safeTransferETH(msg.sender, amountMinusFees);
            // when there's no fee, 1inch sends the fund directly to the user
            // we check to prevent sending 0 ETH in that case
        } else if (ethDiff > 0) {
            TransferHelper.safeTransferETH(msg.sender, ethDiff);
        }
    }

    /// @dev internal method that executes ERC20 to ERC20 token swaps with the ability to take a fee from the input
    function _fillQuoteTokenToToken(
        address sellTokenAddress,
        address buyTokenAddress,
        address payable swapTarget,
        bytes calldata swapCallData,
        uint256 sellAmount,
        uint256 feeAmount
    ) internal {
        // 1 - Get the initial balance of the output token
        uint256 boughtAmount = IERC20(buyTokenAddress).balanceOf(address(this));

        // 2 - Move the tokens to this contract (which includes our fees)
        TransferHelper.safeTransferFrom(
            sellTokenAddress,
            msg.sender,
            address(this),
            sellAmount
        );

        // 3 - Approve the aggregator's contract to swap the tokens if needed
        if (
            IERC20(sellTokenAddress).allowance(address(this), swapTarget) <
            sellAmount - feeAmount
        ) {
            TransferHelper.safeApprove(
                sellTokenAddress,
                swapTarget,
                type(uint256).max
            );
        }

        // 4 - Call the encoded swap function call on the contract at `swapTarget`,
        // passing along any ETH attached to this function call to cover protocol fees.
        // the swapCallData is passing sellAmount - feeAmount as the input
        // so we can keep the fees in this contract
        (bool success, ) = swapTarget.call{value: msg.value}(swapCallData);
        require(success, "SWAP_CALL_FAILED");

        // 5 - Send tokens to the user
        boughtAmount =
            IERC20(buyTokenAddress).balanceOf(address(this)) -
            boughtAmount;
        TransferHelper.safeTransfer(buyTokenAddress, msg.sender, boughtAmount);
    }

    /** EXTERNAL **/

    /// @param buyTokenAddress the address of token that the user should receive
    /// @param swapTarget the address of the aggregator contract that will exec the swap
    /// @param swapCallData the calldata that will be passed to the aggregator contract
    /// @param feeAmount the amount of ETH that we will take as a fee
    function fillQuoteEthToToken(
        address buyTokenAddress,
        address payable swapTarget,
        bytes calldata swapCallData,
        uint256 feeAmount
    ) public payable nonReentrant {
        // 1 - Call the encoded swap function call on the contract at `swapTarget`,
        // passing along any ETH attached to this function call to cover protocol fees
        // minus our fees, which are kept in this contract
        (bool success, ) = swapTarget.call{value: msg.value - feeAmount}(
            swapCallData
        );
        require(success, "SWAP_CALL_FAILED");

        // 2 - Send the received tokens back to the user
        TransferHelper.safeTransfer(
            buyTokenAddress,
            msg.sender,
            IERC20(buyTokenAddress).balanceOf(address(this))
        );
    }

    /// @param sellTokenAddress the address of token that the user is selling
    /// @param buyTokenAddress the address of token that the user should receive
    /// @param swapTarget the address of the aggregator contract that will exec the swap
    /// @param swapCallData the calldata that will be passed to the aggregator contract
    /// @param sellAmount the amount of tokens that the user is selling
    /// @param feeAmount the amount of the tokens to sell that we will take as a fee
    function fillQuoteTokenToToken(
        address sellTokenAddress,
        address buyTokenAddress,
        address payable swapTarget,
        bytes calldata swapCallData,
        uint256 sellAmount,
        uint256 feeAmount
    ) public payable nonReentrant {
        _fillQuoteTokenToToken(
            sellTokenAddress,
            buyTokenAddress,
            swapTarget,
            swapCallData,
            sellAmount,
            feeAmount
        );
    }

    /// @dev method that executes ERC20 to ERC20 token swaps with the ability to take a fee from the input
    // and accepts a signature to use permit, so the user doesn't have to make an previous approval transaction
    /// @param sellTokenAddress the address of token that the user is selling
    /// @param buyTokenAddress the address of token that the user should receive
    /// @param swapTarget the address of the aggregator contract that will exec the swap
    /// @param swapCallData the calldata that will be passed to the aggregator contract
    /// @param sellAmount the amount of tokens that the user is selling
    /// @param feeAmount the amount of the tokens to sell that we will take as a fee
    /// @param permitSignature struct containing the value, nonce, deadline, v, r and s values of the permit signature
    function fillQuoteTokenToTokenWithPermit(
        address sellTokenAddress,
        address buyTokenAddress,
        address payable swapTarget,
        bytes calldata swapCallData,
        uint256 sellAmount,
        uint256 feeAmount,
        TransferHelper.Permit calldata permitSignature
    ) public payable nonReentrant {
        // 1 - Apply permit
        TransferHelper.permit(
            permitSignature,
            sellTokenAddress,
            msg.sender,
            address(this)
        );

        //2 - Call fillQuoteTokenToToken
        _fillQuoteTokenToToken(
            sellTokenAddress,
            buyTokenAddress,
            swapTarget,
            swapCallData,
            sellAmount,
            feeAmount
        );
    }

    /// @dev method that executes ERC20 to ETH token swaps with the ability to take a fee from the output
    /// @param sellTokenAddress the address of token that the user is selling
    /// @param swapTarget the address of the aggregator contract that will exec the swap
    /// @param swapCallData the calldata that will be passed to the aggregator contract
    /// @param sellAmount the amount of tokens that the user is selling
    /// @param feePercentageBasisPoints the amount of ETH that we will take as a fee in 10000 basis points
    function fillQuoteTokenToEth(
        address sellTokenAddress,
        address payable swapTarget,
        bytes calldata swapCallData,
        uint256 sellAmount,
        uint256 feePercentageBasisPoints
    ) public payable nonReentrant {
        _fillQuoteTokenToEth(
            sellTokenAddress,
            swapTarget,
            swapCallData,
            sellAmount,
            feePercentageBasisPoints
        );
    }

    /// @dev method that executes ERC20 to ETH token swaps with the ability to take a fee from the output
    // and accepts a signature to use permit, so the user doesn't have to make an previous approval transaction
    /// @param sellTokenAddress the address of token that the user is selling
    /// @param swapTarget the address of the aggregator contract that will exec the swap
    /// @param swapCallData the calldata that will be passed to the aggregator contract
    /// @param sellAmount the amount of tokens that the user is selling
    /// @param feePercentageBasisPoints the amount of ETH that we will take as a fee in 10000 basis points
    /// @param permitSignature struct containing the amount, nonce, deadline, v, r and s values of the permit signature
    function fillQuoteTokenToEthWithPermit(
        address sellTokenAddress,
        address payable swapTarget,
        bytes calldata swapCallData,
        uint256 sellAmount,
        uint256 feePercentageBasisPoints,
        TransferHelper.Permit calldata permitSignature
    ) public payable nonReentrant {
        // 1 - Apply permit
        TransferHelper.permit(
            permitSignature,
            sellTokenAddress,
            msg.sender,
            address(this)
        );

        // 2 - call fillQuoteTokenToEth
        _fillQuoteTokenToEth(
            sellTokenAddress,
            swapTarget,
            swapCallData,
            sellAmount,
            feePercentageBasisPoints
        );
    }
}
