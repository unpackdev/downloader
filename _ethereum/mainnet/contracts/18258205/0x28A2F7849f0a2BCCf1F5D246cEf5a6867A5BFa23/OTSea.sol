/*
        [....     [... [......  [.. ..                      
      [..    [..       [..    [..    [..                    
    [..        [..     [..     [..         [..       [..    
    [..        [..     [..       [..     [.   [..  [..  [.. 
    [..        [..     [..          [.. [..... [..[..   [.. 
      [..     [..      [..    [..    [..[.        [..   [.. 
        [....          [..      [.. ..    [....     [.. [...
    
    OTSea Platform.

    https://otsea.xyz/
    https://t.me/OTSeaPortal
    https://twitter.com/OTSeaERC20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./IERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./console.sol";

contract OTSea is Ownable, ReentrancyGuard {
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

    address payable public opWallet1;
    address payable public opWallet2;
    address payable public dividendsWallet;
    address payable public marketingWallet;
    ERC20 public otseaERC20;

    uint256 public fishFee = 100; // 1%
    uint256 public whaleFee = 30; // 0.3%

    function setFees(uint256 _fishFee, uint256 _whaleFee) external onlyOwner {
        require(_fishFee <= fishFee, "Fee can only be lowered");
        require(_whaleFee <= whaleFee, "Fee can only be lowered");
        fishFee = _fishFee;
        whaleFee = _whaleFee;
    }

    constructor(
        address payable _opWallet1,
        address payable _opWallet2,
        address payable _dividendsWallet,
        address payable _marketingWallet,
        address _otseaErc20
    ) {
        opWallet1 = _opWallet1;
        opWallet2 = _opWallet2;
        dividendsWallet = _dividendsWallet;
        marketingWallet = _marketingWallet;
        otseaERC20 = ERC20(_otseaErc20);
        whaleThreshold = ((2 * otseaERC20.totalSupply()) / 1000) * 1e18;
    }

    uint256 public whaleThreshold;

    function setWhaleThreshold(uint256 _threshold) external onlyOwner {
        require(
            _threshold <= otseaERC20.totalSupply() / 100,
            "Whale threshold can't be higher than 1%"
        );
        whaleThreshold = _threshold;
    }

    event OrderCreated(Order order, bytes32 indexed orderId, uint8 tokenDecimals);

    event OrderPriceUpdated(Order order, bytes32 indexed orderId, uint256 newPrice);

    event OrderFulfilled(Order order, bytes32 indexed orderId, Fill fill);

    event OrderSettled(Order order, bytes32 indexed orderId, Withdrawal withdrawal);

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
        require(requestedETHAmount > 0, "Requested ETH amount must be greater than 0");
        require(requesterTokenAmount > 0, "Token amount must be greater than 0");

        bytes32 orderId = keccak256(abi.encodePacked("OTSea", ++nonce));

        Order storage order = orders[orderId];
        order.requester = msg.sender;
        order.tokenAddress = tokenAddress;
        order.partiallyFillable = partiallyFillable;
        order.whitelistedAddress = whitelistedAddress;
        order.state = OrderState.Open;

        // Get the initial token balance
        uint256 initialTokenBalance = IERC20(tokenAddress).balanceOf(address(this));

        // Transfer tokens from the requester to the contract
        require(
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), requesterTokenAmount),
            "Token transfer failed"
        );

        // Calculate the actual tokens transferred (this pre and post check is to account for potential taxes in the erc20 token)
        uint256 afterTokenBalance = IERC20(tokenAddress).balanceOf(address(this));
        uint256 transferredTokenAmount = afterTokenBalance - initialTokenBalance;

        uint8 tokenDecimals = ERC20(tokenAddress).decimals();

        // Calculate any fractional tokens and return them to the creator
        uint256 fractionalTokenAmount = transferredTokenAmount % 10 ** tokenDecimals;
        uint256 wholeTokenAmount = transferredTokenAmount - fractionalTokenAmount;

        // Transfer fractional tokens back to the creator
        if (fractionalTokenAmount > 0) {
            require(
                IERC20(tokenAddress).transfer(msg.sender, fractionalTokenAmount),
                "Fractional token transfer failed"
            );
        }

        // Update the order with the whole token amount
        order.initialTokens = wholeTokenAmount;
        order.availableTokens = wholeTokenAmount;

        uint256 netTransferPercent = (transferredTokenAmount * 10000) / requesterTokenAmount;
        uint256 transferTax = 10000 - netTransferPercent;
        emit TransferTaxRecorded(order.tokenAddress, transferTax);

        // Calculate the adjusted requestedETH by multiplying it by the net %
        order.requestedETH = transferTax > 0
            ? (requestedETHAmount * netTransferPercent) / 10000
            : requestedETHAmount;

        uint256 formattedTransferredTokenAmount = wholeTokenAmount / 10 ** tokenDecimals;

        order.pricePerToken = order.requestedETH / formattedTransferredTokenAmount;

        emit OrderCreated(orders[orderId], orderId, tokenDecimals);
    }

    function fulfillOrder(
        bytes32 orderId,
        uint256 expectedPricePerToken
    ) external payable nonReentrant whenNotPaused {
        Order storage order = orders[orderId];
        require(order.requester != address(0), "Order doesn't exist");
        require(order.pricePerToken == expectedPricePerToken, "Price per token mismatch");

        // If there's a whitelisted address, ensure it is the sender
        if (order.whitelistedAddress != address(0)) {
            require(msg.sender == order.whitelistedAddress, "Not authorized");
        }

        require(order.state == OrderState.Open, "Order already fulfilled or cancelled");
        require(msg.value > 0, "ETH amount must be greater than 0");

        uint256 tokensToFulfill;
        if (order.partiallyFillable == false) {
            require(msg.value == order.requestedETH, "No partial fills permitted");
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
        require(tokensToFulfill <= order.availableTokens, "Exceeds available tokens to fulfill");

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
                ERC20(order.tokenAddress).transfer(order.requester, order.availableTokens),
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
            uint256 feePercentage = otseaERC20.balanceOf(order.requester) >= whaleThreshold
                ? whaleFee
                : fishFee;

            withdrawAmount = (fulfilledEth * (10000 - feePercentage)) / 10000;
            (bool success, ) = msg.sender.call{value: withdrawAmount}("");

            require(success, "ETH transfer failed");

            feeAmount = fulfilledEth - withdrawAmount;

            // Distribute fees
            uint256 marketingFee = feeAmount / 20; // 5%
            uint256 op1Fee = feeAmount / 10; // 10%
            uint256 op2Fee = feeAmount / 10; // 10%
            uint256 dividendsFee = feeAmount - marketingFee - op1Fee - op2Fee; // 75% to be distributed as dividends

            (bool successMarketing, ) = marketingWallet.call{value: marketingFee}("");
            require(successMarketing, "Marketing Wallet - ETH transfer failed");

            (bool success1, ) = opWallet1.call{value: op1Fee}("");
            require(success1, "Operations Wallet 1 - ETH transfer failed");

            (bool success2, ) = opWallet2.call{value: op2Fee}("");
            require(success2, "Operation Wallet 2 - ETH transfer failed");

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
    function updatePrice(bytes32 orderId, uint256 newPrice) external nonReentrant whenNotPaused {
        Order storage order = orders[orderId];

        require(order.requester != address(0), "Order doesn't exist");
        require(order.state == OrderState.Open, "Order cannot be updated");

        require(msg.sender == order.requester, "Not authorized");

        uint256 formattedAvailableTokens = order.availableTokens /
            10 ** ERC20(order.tokenAddress).decimals();

        if (order.partiallyFillable) {
            order.pricePerToken = newPrice;
            order.requestedETH = order.fulfilledETH + (formattedAvailableTokens * newPrice);
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

    function setOpWallet1(address payable _opWallet1) external {
        require(msg.sender == opWallet1, "Not authorized");
        opWallet1 = _opWallet1;
    }

    function setOpWallet2(address payable _opWallet2) external {
        require(msg.sender == opWallet2, "Not authorized");
        opWallet2 = _opWallet2;
    }

    function setDividendsWallet(address payable _dividendsWallet) external {
        require(msg.sender == dividendsWallet, "Not authorized");
        dividendsWallet = _dividendsWallet;
    }

    function setMarketingWallet(address payable _marketingWallet) external {
        require(msg.sender == marketingWallet, "Not authorized");
        marketingWallet = _marketingWallet;
    }
}
