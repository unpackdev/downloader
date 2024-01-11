// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./Withdrawable.sol";
import "./TokenTransferProxy.sol";
import "./Utils.sol";
import "./Partner.sol";
import "./TokenBalanceLibrary.sol";
import "./ExchangeHandler.sol";

import "./SafeERC20.sol";

/// @title The primary contract for Totle
contract TotlePrimary is Withdrawable, Pausable {
    /*
     *   State Variables
     */

    TokenTransferProxy public tokenTransferProxy;

    /*
     *   Types
     */

    // Structs
    struct Order {
        address payable exchangeHandler;
        bytes encodedPayload;
    }

    struct Trade {
        address sourceToken;
        address destinationToken;
        uint256 amount;
        Order[] orders;
    }

    struct Swap {
        Trade[] trades;
        uint256 minimumDestinationAmount;
        uint256 minimumExchangeRate;
        uint256 sourceAmount;
        uint256 tradeToTakeFeeFrom;
        bool takeFeeFromSource; //Takes the fee before the trade if true, takes it after if false
        address payable redirectAddress;
    }

    struct SwapCollection {
        Swap[] swaps;
        uint256 expirationBlock;
        bytes32 id;
        uint256 maxGasPrice;
        address payable partnerContract;
        uint8 tokenCount;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /*
     *   Events
     */

    event LogSwapCollection(
        bytes32 indexed id,
        address indexed partnerContract,
        address indexed user
    );

    event LogSwap(
        bytes32 indexed id,
        address sourceAsset,
        address destinationAsset,
        uint256 sourceAmount,
        uint256 destinationAmount,
        address feeAsset,
        uint256 feeAmount
    );

    /// @notice Constructor
    /// @param _tokenTransferProxy address of the TokenTransferProxy
    /// @param _signer the suggester's address that signs the payloads. More can be added with add/removeSigner functions
    constructor(address _tokenTransferProxy, address _signer) {
        tokenTransferProxy = TokenTransferProxy(_tokenTransferProxy);
    }

    /*
     *   Public functions
     */

    /// @notice Performs the requested set of swaps
    /// @param swaps The struct that defines the collection of swaps to perform
    function performSwapCollection(SwapCollection memory swaps)
        public
        payable
        whenNotPaused
    {
        // Initialize token balances
        TokenBalanceLibrary.TokenBalance[]
            memory balances = new TokenBalanceLibrary.TokenBalance[](
                swaps.tokenCount
            );
        // Set the ETH balance to what was given with the function call
        balances[0] = TokenBalanceLibrary.TokenBalance(
            address(Utils.eth_address()),
            msg.value
        );
        // Iterate over swaps and execute individually
        for (
            uint256 swapIndex = 0;
            swapIndex < swaps.swaps.length;
            swapIndex++
        ) {
            performSwap(
                swaps.id,
                swaps.swaps[swapIndex],
                balances,
                swaps.partnerContract
            );
        }
        emit LogSwapCollection(swaps.id, swaps.partnerContract, msg.sender);
        // Transfer all assets from swap to user
        transferAllTokensToUser(balances);
    }

    /*
     *   Internal functions
     */

    function performSwap(
        bytes32 swapCollectionId,
        Swap memory swap,
        TokenBalanceLibrary.TokenBalance[] memory balances,
        address payable partnerContract
    ) internal {
        // Get the asset for the swap from the user if not already available
        transferFromSenderDifference(
            balances,
            swap.trades[0].sourceToken,
            swap.sourceAmount
        );

        uint256 amountSpentFirstTrade = 0;
        uint256 amountReceived = 0;
        uint256 feeAmount = 0;
        // Iterated over and execute the trades in this swap
        for (
            uint256 tradeIndex = 0;
            tradeIndex < swap.trades.length;
            tradeIndex++
        ) {
            // If we are supposed to take the trade from the input of this trade, then collect it now
            if (
                tradeIndex == swap.tradeToTakeFeeFrom && swap.takeFeeFromSource
            ) {
                feeAmount = takeFee(
                    balances,
                    swap.trades[tradeIndex].sourceToken,
                    partnerContract,
                    tradeIndex == 0 ? swap.sourceAmount : amountReceived
                );
            }
            uint256 tempSpent;
            (tempSpent, amountReceived) = performTrade(
                swap.trades[tradeIndex],
                balances,
                Utils.min(
                    tradeIndex == 0 ? swap.sourceAmount : amountReceived,
                    balances[
                        TokenBalanceLibrary.findToken(
                            balances,
                            swap.trades[tradeIndex].sourceToken
                        )
                    ].balance
                )
            );
            // If this is the first trade in the swap then we need to initialize
            if (tradeIndex == 0) {
                amountSpentFirstTrade = tempSpent + feeAmount;
                if (feeAmount != 0) {
                    amountSpentFirstTrade += feeAmount;
                }
            }
            // If we are supposed to take the trade from the output of this trade, then collect it now
            if (
                tradeIndex == swap.tradeToTakeFeeFrom && !swap.takeFeeFromSource
            ) {
                feeAmount = takeFee(
                    balances,
                    swap.trades[tradeIndex].destinationToken,
                    partnerContract,
                    amountReceived
                );
                amountReceived -= feeAmount;
            }
        }
        emit LogSwap(
            swapCollectionId,
            swap.trades[0].sourceToken,
            swap.trades[swap.trades.length - 1].destinationToken,
            amountSpentFirstTrade,
            amountReceived,
            swap.takeFeeFromSource
                ? swap.trades[swap.tradeToTakeFeeFrom].sourceToken
                : swap.trades[swap.tradeToTakeFeeFrom].destinationToken,
            feeAmount
        );
        // Validate the swap got a better rate and destination amount than the minimums defined in swap
        require(
            amountReceived >= swap.minimumDestinationAmount,
            "Get less than minimumDestinationAmount"
        );
        require(
            !minimumRateFailed(
                swap.trades[0].sourceToken,
                swap.trades[swap.trades.length - 1].destinationToken,
                swap.sourceAmount,
                amountReceived,
                swap.minimumExchangeRate
            ),
            "minimumExchangeRate not met"
        );
        // Handle forwarding assets if needed
        if (
            swap.redirectAddress != msg.sender &&
            swap.redirectAddress != address(0x0)
        ) {
            uint256 destinationTokenIndex = TokenBalanceLibrary.findToken(
                balances,
                swap.trades[swap.trades.length - 1].destinationToken
            );
            uint256 amountToSend = Math.min(
                amountReceived,
                balances[destinationTokenIndex].balance
            );
            transferTokens(
                balances,
                destinationTokenIndex,
                swap.redirectAddress,
                amountToSend
            );
            TokenBalanceLibrary.removeBalance(
                balances,
                swap.trades[swap.trades.length - 1].destinationToken,
                amountToSend
            );
        }
    }

    function performTrade(
        Trade memory trade,
        TokenBalanceLibrary.TokenBalance[] memory balances,
        uint256 availableToSpend
    ) internal returns (uint256 totalSpent, uint256 totalReceived) {
        uint256 tempSpent = 0;
        uint256 tempReceived = 0;
        // Iterate over orders and execute consecutively
        for (
            uint256 orderIndex = 0;
            orderIndex < trade.orders.length;
            orderIndex++
        ) {
            if (tempSpent >= trade.amount) {
                break;
            }
            (tempSpent, tempReceived) = performOrder(
                trade.orders[orderIndex],
                availableToSpend - totalSpent,
                trade.sourceToken,
                balances
            );
            totalSpent += tempSpent;
            totalReceived += tempReceived;
        }
        // Update balances after performing order
        TokenBalanceLibrary.addBalance(
            balances,
            trade.destinationToken,
            totalReceived
        );
        TokenBalanceLibrary.removeBalance(
            balances,
            trade.sourceToken,
            totalSpent
        );
    }

    function performOrder(
        Order memory order,
        uint256 targetAmount,
        address tokenToSpend,
        TokenBalanceLibrary.TokenBalance[] memory balances
    ) internal returns (uint256 spent, uint256 received) {
        // Hand off order settlement to handler, handling both tokens and ETH as the from asset
        if (tokenToSpend == Utils.eth_address()) {
            (spent, received) = ExchangeHandler(order.exchangeHandler)
                .performOrder{value: targetAmount}(
                order.encodedPayload,
                targetAmount,
                targetAmount
            );
        } else {
            transferTokens(
                balances,
                TokenBalanceLibrary.findToken(balances, tokenToSpend),
                order.exchangeHandler,
                targetAmount
            );
            (spent, received) = ExchangeHandler(order.exchangeHandler)
                .performOrder(order.encodedPayload, targetAmount, targetAmount);
        }
    }

    function minimumRateFailed(
        address sourceToken,
        address destinationToken,
        uint256 sourceAmount,
        uint256 destinationAmount,
        uint256 minimumExchangeRate
    ) internal returns (bool failed) {
        uint256 sourceDecimals = sourceToken == Utils.eth_address()
            ? 18
            : Utils.getDecimals(sourceToken);
        uint256 destinationDecimals = destinationToken == Utils.eth_address()
            ? 18
            : Utils.getDecimals(destinationToken);
        uint256 rateGot = Utils.calcRateFromQty(
            sourceAmount,
            destinationAmount,
            sourceDecimals,
            destinationDecimals
        );
        return rateGot < minimumExchangeRate;
    }

    function takeFee(
        TokenBalanceLibrary.TokenBalance[] memory balances,
        address token,
        address payable partnerContract,
        uint256 amountTraded
    ) internal returns (uint256 feeAmount) {
        Partner partner = Partner(partnerContract);
        uint256 feePercentage = partner.getTotalFeePercentage();
        feeAmount = calculateFee(amountTraded, feePercentage);
        uint256 tokenIndex = TokenBalanceLibrary.findToken(balances, token);
        TokenBalanceLibrary.removeBalance(
            balances,
            tokenIndex,
            feeAmount
        );
        transferTokens(
            balances,
            tokenIndex,
            partnerContract,
            feeAmount
        );
        return feeAmount;
    }

    function transferFromSenderDifference(
        TokenBalanceLibrary.TokenBalance[] memory balances,
        address token,
        uint256 sourceAmount
    ) internal {
        if (token == Utils.eth_address()) {
            require(
                sourceAmount >= balances[0].balance,
                "Not enough ETH to perform swap"
            );
        } else {
            uint256 tokenIndex = TokenBalanceLibrary.findToken(balances, token);
            if (sourceAmount > balances[tokenIndex].balance) {
                uint256 transferAmount = sourceAmount - balances[tokenIndex].balance;
                tokenTransferProxy.transferFrom(
                    token,
                    msg.sender,
                    address(this),
                    transferAmount
                );
                TokenBalanceLibrary.addBalance(balances, token, transferAmount);
            }
        }
    }

    function transferAllTokensToUser(
        TokenBalanceLibrary.TokenBalance[] memory balances
    ) internal {
        for (
            uint256 balanceIndex = 0;
            balanceIndex < balances.length;
            balanceIndex++
        ) {
            if (
                balanceIndex != 0 &&
                balances[balanceIndex].tokenAddress == address(0x0)
            ) {
                return;
            }
            transferTokens(
                balances,
                balanceIndex,
                payable(msg.sender),
                balances[balanceIndex].balance
            );
        }
    }

    function transferTokens(
        TokenBalanceLibrary.TokenBalance[] memory balances,
        uint256 tokenIndex,
        address payable destination,
        uint256 tokenAmount
    ) internal {
        if (tokenAmount > 0) {
            if (balances[tokenIndex].tokenAddress == Utils.eth_address()) {
                destination.transfer(tokenAmount);
            } else {
                SafeERC20.safeTransfer(
                    IERC20(balances[tokenIndex].tokenAddress),
                    destination,
                    tokenAmount
                );
            }
        }
    }

    // @notice Calculates the fee amount given a fee percentage and amount
    // @param amount the amount to calculate the fee based on
    // @param fee the percentage, out of 1 eth (e.g. 0.01 ETH would be 1%)
    function calculateFee(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return SafeMath.div(SafeMath.mul(amount, fee), 1 * (10**18));
    }

    /*
     *   Payable receive function
     */

    /// @notice payable receive to allow handler or exchange contracts to return ether
    /// @dev only accounts containing code (ie. contracts) can send ether to contract
    receive() external payable whenNotPaused {
        // Check in here that the sender is a contract! (to stop accidents)
        uint256 size;
        address sender = msg.sender;
        assembly {
            size := extcodesize(sender)
        }
        if (size == 0) {
            revert("EOA cannot send ether to primary receive function");
        }
    }
}
