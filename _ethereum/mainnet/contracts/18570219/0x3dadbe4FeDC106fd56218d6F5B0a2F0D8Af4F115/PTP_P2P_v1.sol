/*
 * Welcome to P2P Financial
 *
 * website          : https://p2p.financial
 * twitter          : https://twitter.com/P2P_Financial
 * telegram channel : https://t.me/P2PFinancial
 * telegram group   : https://t.me/P2P_Financial
 * docs             : https://docs.p2p.financial
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract P2P is Ownable, ReentrancyGuard {
    enum ContractState {
        Active,
        Paused
    }

    ContractState public contractState = ContractState.Active;

    enum OrderState {
        Open,
        Fulfilled,
        Settled
    }

    struct Fill {
        address fulfiller;
        uint256 tokensReceived;
        uint256 ethFulfilled;
        uint256 pricePerToken;
    }

    struct Withdrawal {
        uint256 withdrawAmount;
        uint256 feeAmount;
        uint256 refundedTokens;
    }

    struct Order {
        address requester;
        address whitelistedAddress;
        address tokenAddress;
        uint256 initialTokens;
        uint256 availableTokens;
        uint256 requestedETH;
        uint256 fulfilledETH;
        uint256 pricePerToken;
        bool partiallyFillable;
        OrderState state;
    }

    mapping(bytes32 => Order) public orders;
    uint256 private nonce;

    address payable public dividendsWallet;
    address payable public marketingWallet;
    ERC20 public ptpERC20;

    uint256 public fishFee = 100; // 1%
    uint256 public whaleFee = 30; // 0.3%

    function setFees(uint256 _fishFee, uint256 _whaleFee) external onlyOwner {
        require(_fishFee <= fishFee, "Fee can only be lowered");
        require(_whaleFee <= whaleFee, "Fee can only be lowered");
        fishFee = _fishFee;
        whaleFee = _whaleFee;
    }

    constructor(
        address payable _dividendsWallet,
        address payable _marketingWallet,
        address _ptpERC20
    ) {
        dividendsWallet = _dividendsWallet;
        marketingWallet = _marketingWallet;
        ptpERC20 = ERC20(_ptpERC20);
        whaleThreshold = ((2 * ptpERC20.totalSupply()) / 1000) * 1e18;
    }

    uint256 public whaleThreshold;

    function setWhaleThreshold(uint256 _threshold) external onlyOwner {
        require(
            _threshold <= ptpERC20.totalSupply() / 100,
            "Whale threshold can't be higher than 1%"
        );
        whaleThreshold = _threshold;
    }

    event OrderCreated(
        Order order,
        bytes32 indexed orderId,
        uint8 tokenDecimals
    );

    event OrderPriceUpdated(
        Order order,
        bytes32 indexed orderId,
        uint256 newPrice
    );

    event OrderFulfilled(Order order, bytes32 indexed orderId, Fill fill);

    event OrderSettled(
        Order order,
        bytes32 indexed orderId,
        Withdrawal withdrawal
    );

    event TransferTaxRecorded(address tokenAddress, uint256 transferTax);

    modifier whenNotPaused() {
        require(contractState == ContractState.Active, "Contract is paused");
        _;
    }


    function requestOrder(
        address tokenAddress,
        uint256 requesterTokenAmount,
        uint256 requestedETHAmount,
        bool partiallyFillable,
        address whitelistedAddress
    ) external nonReentrant whenNotPaused {
        require(
            requestedETHAmount > 0,
            "Requested ETH amount must be greater than 0"
        );
        require(
            requesterTokenAmount > 0,
            "Token amount must be greater than 0"
        );

        bytes32 orderId = keccak256(abi.encodePacked("PTP", ++nonce));

        Order storage order = orders[orderId];
        order.requester = msg.sender;
        order.tokenAddress = tokenAddress;
        order.partiallyFillable = partiallyFillable;
        order.whitelistedAddress = whitelistedAddress;
        order.state = OrderState.Open;

        // Get the initial token balance
        uint256 initialTokenBalance = IERC20(tokenAddress).balanceOf(
            address(this)
        );

        // Transfer tokens from the requester to the contract
        require(
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                requesterTokenAmount
            ),
            "Token transfer failed"
        );

        // Calculate the actual tokens transferred (this pre and post check is to account for potential taxes in the erc20 token)
        uint256 afterTokenBalance = IERC20(tokenAddress).balanceOf(
            address(this)
        );
        uint256 transferredTokenAmount = afterTokenBalance -
            initialTokenBalance;

        uint8 tokenDecimals = ERC20(tokenAddress).decimals();

        // Calculate any fractional tokens and return them to the creator
        uint256 fractionalTokenAmount = transferredTokenAmount %
            10 ** tokenDecimals;
        uint256 wholeTokenAmount = transferredTokenAmount -
            fractionalTokenAmount;

        // Transfer fractional tokens back to the creator
        if (fractionalTokenAmount > 0) {
            require(
                IERC20(tokenAddress).transfer(
                    msg.sender,
                    fractionalTokenAmount
                ),
                "Fractional token transfer failed"
            );
        }

        // Update the order with the whole token amount
        order.initialTokens = wholeTokenAmount;
        order.availableTokens = wholeTokenAmount;

        uint256 netTransferPercent = (transferredTokenAmount * 10000) /
            requesterTokenAmount;
        uint256 transferTax = 10000 - netTransferPercent;
        emit TransferTaxRecorded(order.tokenAddress, transferTax);

        // Calculate the adjusted requestedETH by multiplying it by the net %
        order.requestedETH = transferTax > 0
            ? (requestedETHAmount * netTransferPercent) / 10000
            : requestedETHAmount;

        uint256 formattedTransferredTokenAmount = wholeTokenAmount /
            10 ** tokenDecimals;

        order.pricePerToken =
            order.requestedETH /
            formattedTransferredTokenAmount;

        emit OrderCreated(orders[orderId], orderId, tokenDecimals);
    }

    function fulfillOrder(
        bytes32 orderId,
        uint256 expectedPricePerToken
    ) external payable nonReentrant whenNotPaused {
        Order storage order = orders[orderId];
        require(order.requester != address(0), "Order doesn't exist");
        require(
            order.pricePerToken == expectedPricePerToken,
            "Price per token mismatch"
        );

        // If there's a whitelisted address, ensure it is the sender
        if (order.whitelistedAddress != address(0)) {
            require(msg.sender == order.whitelistedAddress, "Not authorized");
        }

        require(
            order.state == OrderState.Open,
            "Order already fulfilled or cancelled"
        );
        require(msg.value > 0, "ETH amount must be greater than 0");

        uint256 tokensToFulfill;
        if (order.partiallyFillable == false) {
            require(
                msg.value == order.requestedETH,
                "No partial fills permitted"
            );
            tokensToFulfill = order.availableTokens;
        } else {
            // Calculate how many tokens the fulfiller receives based on the ratio of requestedTokenAmount to requestedETHAmount
            tokensToFulfill =
                (msg.value * 10 ** ERC20(order.tokenAddress).decimals()) /
                order.pricePerToken;
        }

        // Transfer tokens to fulfiller based on the calculated tokensToFulfill
        address tokenAddress = order.tokenAddress;

        require(tokensToFulfill > 0, "Token amount must be greater than 0");
        require(
            tokensToFulfill <= order.availableTokens,
            "Exceeds available tokens to fulfill"
        );

        order.availableTokens -= tokensToFulfill;
        order.fulfilledETH += msg.value;

        // Check if the order is fully fulfilled
        if (order.availableTokens == 0) {
            order.state = OrderState.Fulfilled;
        }

        require(
            IERC20(tokenAddress).transfer(msg.sender, tokensToFulfill),
            "Token transfer failed"
        );

        emit OrderFulfilled(
            orders[orderId],
            orderId,
            Fill(msg.sender, tokensToFulfill, msg.value, order.pricePerToken)
        );
    }

    function settleOrder(bytes32 orderId) external nonReentrant {
        Order storage order = orders[orderId];

        require(order.requester != address(0), "Order doesn't exist");
        require(order.requester == msg.sender, "Not authorized");
        require(order.state != OrderState.Settled, "Order already settled");

        order.state = OrderState.Settled;

        // Return unfulfilled tokens to the requester
        if (order.availableTokens > 0) {
            require(
                ERC20(order.tokenAddress).transfer(
                    order.requester,
                    order.availableTokens
                ),
                "Token transfer failed"
            );
        }

        uint256 transferredTokenAmount = order.availableTokens;
        order.availableTokens = 0;

        // Withdraw the fulfilled ETH
        uint256 fulfilledEth = order.fulfilledETH;
        uint256 withdrawAmount = 0;
        uint256 feeAmount = 0;

        if (fulfilledEth > 0) {
            // Deduct the fee from the fulfilled ETH
            uint256 feePercentage = ptpERC20.balanceOf(order.requester) >=
                whaleThreshold
                ? whaleFee
                : fishFee;

            withdrawAmount = (fulfilledEth * (10000 - feePercentage)) / 10000;
            (bool success, ) = msg.sender.call{value: withdrawAmount}("");

            require(success, "ETH transfer failed");

            feeAmount = fulfilledEth - withdrawAmount;

            // Distribute fees
            uint256 marketingFee = feeAmount / 5; // 20%
            uint256 dividendsFee = feeAmount - marketingFee; // 80% to be distributed as dividends

            (bool successMarketing, ) = marketingWallet.call{
                value: marketingFee
            }("");
            require(successMarketing, "Marketing Wallet - ETH transfer failed");

            (bool success3, ) = dividendsWallet.call{value: dividendsFee}("");
            require(success3, "Dividends wallet - ETH transfer failed");
        }

        emit OrderSettled(
            orders[orderId],
            orderId,
            Withdrawal(withdrawAmount, feeAmount, transferredTokenAmount)
        );
    }

    // Updates pricePerToken if the order is partially fillable or requestedETH if the order is AON
    function updatePrice(
        bytes32 orderId,
        uint256 newPrice
    ) external nonReentrant whenNotPaused {
        Order storage order = orders[orderId];

        require(order.requester != address(0), "Order doesn't exist");
        require(order.state == OrderState.Open, "Order cannot be updated");

        require(msg.sender == order.requester, "Not authorized");

        uint256 formattedAvailableTokens = order.availableTokens /
            10 ** ERC20(order.tokenAddress).decimals();

        if (order.partiallyFillable) {
            order.pricePerToken = newPrice;
            order.requestedETH =
                order.fulfilledETH +
                (formattedAvailableTokens * newPrice);
        } else {
            // New price will refer to the full bag if the order is AON
            order.requestedETH = newPrice;
            order.pricePerToken = order.requestedETH / formattedAvailableTokens;
        }

        emit OrderPriceUpdated(order, orderId, newPrice);
    }

    // Function to pause the contract (only callable by the owner)
    function pauseContract() external onlyOwner {
        contractState = ContractState.Paused;
    }

    // Function to unpause the contract (only callable by the owner)
    function unpauseContract() external onlyOwner {
        contractState = ContractState.Active;
    }

    function setDividendsWallet(
        address payable _dividendsWallet
    ) external onlyOwner {
        dividendsWallet = _dividendsWallet;
    }

    function setMarketingWallet(address payable _marketingWallet) external {
        require(msg.sender == marketingWallet, "Not authorized");
        marketingWallet = _marketingWallet;
    }
}
