// SPDX-License-Identifier: ISC
pragma solidity ^0.8.10;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ERC2981.sol";

contract Marketplace is Ownable {
    // Structures
    struct SellOrder {
        uint basePrice; // if 0, auction is disabled
        uint start;
        uint end;
        uint directSalePrice; // if 0, direct sale is disabled
        address paymentToken;
        bool claimed;
    }

    struct Bid {
        address bidder;
        uint price;
        uint timestamp;
    }

    // Events
    event NewSellOrder(uint indexed tokenId, uint indexed basePrice, address indexed paymentToken);
    event SellOrderChanged(uint indexed tokenId, uint indexed basePrice, address indexed paymentToken);
    event NewBid(address indexed who, uint indexed tokenId, uint indexed price);

    // Maps
    // address(0) represents the native token (BNB)
    mapping (address => bool) public isPaymentTokenWhitelisted; // token address => is whitelisted
    mapping (uint => SellOrder) public sellOrders; // token id => sell order
    mapping (uint => Bid[]) public bids; // token id => bids
    mapping (address => uint) public totalValueSold; // payment token => total value sold

    // NFT collection that will be sold
    IERC721 public nft;

    // if true, add one minute to the end of a sell if the bid is placed one minute or less before its end
    bool public shouldExtendEnd;

    // If true, if a bid price exceeds the direct sale price, it automatically buys the item insted of keep bidding.
    // Otherwise it disables the direct sale
    bool public shouldStopBidding;

    // address that will receive unsold items
    address public recoverAddress;

    // minimum change in price from the previous bid
    uint public minPriceIncrease;

    // Array with all whitelisted payment tokens
    address[] private whitelistedPaymentTokens;

    // fees denominator
    uint public feePrecision = 1e5;

    // addresses that will receive part of the generated tokens throgh sales
    address[] private withdrawAddresses;
    uint public withdrawAddressesCounter;

    /**
     * @notice Constructor
     * @param _nft Address of COC NFT
     * @param _recoverAddress Address that will receive unsold NFTs
     * @param _minBidPriceIncrease Minimum price increase from previous bid
     * @param _shouldExtendEnd If true, enable sale extension in case of a bid race
     * @param _shouldStopBidding If true, if a bid price exceeds the direct sale price,
            it automatically buys the item instead of keep bidding. Otherwise it disables
            the direct sale
     */
    constructor (address _nft, address _recoverAddress, uint _minBidPriceIncrease, bool _shouldExtendEnd,
        bool _shouldStopBidding) {
        nft = IERC721(_nft);

        require(_minBidPriceIncrease > 0, "Marketplace: min bid price must be greater than 0");

        recoverAddress = _recoverAddress;
        minPriceIncrease = _minBidPriceIncrease;
        shouldExtendEnd = _shouldExtendEnd;
        shouldStopBidding = _shouldStopBidding;

        // Whitelist BNB
        isPaymentTokenWhitelisted[address(0)] = true;
    }

    /**
     * @notice Buy a NFT directly
     * @param _tokenId Token ID of the item to buy
     */
    function buy(uint _tokenId) external payable {
        require (nft.ownerOf(_tokenId) == address(this), "Marketplace: item not in sale");

        SellOrder storage sellOrder = sellOrders[_tokenId];

        // Check if auction is enabled
        require (sellOrder.directSalePrice > 0 && ! sellOrder.claimed, "Marketplace: buy directly disabled");

        // Takes funds from the caller
        processPaymentFrom(sellOrder.paymentToken, msg.sender, sellOrder.directSalePrice);

        // Transfer the NFT
        nft.transferFrom(address(this), msg.sender, _tokenId);

        // Close the sale
        sellOrder.claimed = true;

        // Update statistics
        totalValueSold[sellOrder.paymentToken] += sellOrder.directSalePrice;
    }

    /**
     * @notice Make a bid
     * @param _tokenId Token ID of the item
     * @param _price Price of the bid
     */
    function bid(uint _tokenId, uint _price) external payable {
        require (nft.ownerOf(_tokenId) == address(this), "Marketplace: item not in sale");

        SellOrder storage sellOrder = sellOrders[_tokenId];

        // Check if auction is enabled
        require (sellOrder.basePrice > 0 && ! sellOrder.claimed, "Marketplace: auction disabled");

        // Check time constraints
        require (block.timestamp >= sellOrder.start, "Marketplace: auction not started yet");
        require (block.timestamp <= sellOrder.end, "Marketplace: auction already finished");

        // If there is at least one bid, check that the price is greater
        uint bidsLength = bids[_tokenId].length;
        if (bidsLength > 0) {
            Bid memory lastBid = bids[_tokenId][bidsLength - 1];
            require (_price >= lastBid.price + minPriceIncrease, "Marketplace: price too low");

            // Refund previous bidder
            processPaymentTo(sellOrder.paymentToken, lastBid.bidder, lastBid.price);
        } else {
            require (_price >= sellOrder.basePrice, "Marketplace: price below base price");
        }

        // Takes funds from the new one
        processPaymentFrom(sellOrder.paymentToken, msg.sender, _price);

        // Add the new bid
        Bid memory newBid = Bid({
            bidder: msg.sender,
            price: _price,
            timestamp: block.timestamp
        });

        bids[_tokenId].push(newBid);

        // Check if the price is greater than direct sale price
        if (_price >= sellOrder.directSalePrice && sellOrder.directSalePrice != 0) {
            // Buys the item
            if (shouldStopBidding) {
                // Transfer the NFT
                nft.transferFrom(address(this), msg.sender, _tokenId);

                // TODO: Apply marketplace fee

                // Close the sale
                sellOrder.claimed = true;

                // Update statistics
                totalValueSold[sellOrder.paymentToken] += _price;
            }

            // Disable direct sale
            else {
                sellOrder.directSalePrice = 0;
            }
        }

        // If expected, add one minute to the sellOrder.end if the bid is placed one minute or less before sellOrder.end
        uint secondsBeforeEnd = sellOrder.end - block.timestamp;
        if (secondsBeforeEnd <= 60 && shouldExtendEnd) {
            sellOrder.end += 60;
        }

        emit NewBid(msg.sender, _tokenId, _price);
    }

    /**
     * @notice Claim an item when the sale ends
     * @param _tokenId Token ID to claim
     */
    function claim(uint _tokenId) external {
        SellOrder storage sellOrder = sellOrders[_tokenId];
        require (! sellOrder.claimed, "Marketplace: token already claimed");
        require (block.timestamp > sellOrder.end, "Marketplace: sell not ended");

        uint bidsLength = bids[_tokenId].length;
        Bid memory lastBid = bids[_tokenId][bidsLength - 1];

        // Check if the caller can claim the NFT
        require (lastBid.bidder == msg.sender, "Marketplace: not last bidder");

        // Transfer the NFT
        nft.transferFrom(address(this), msg.sender, _tokenId);

        // TODO: Apply marketplace fee

        // Update the sell order
        sellOrder.claimed = true;

        // Update statistics
        totalValueSold[sellOrder.paymentToken] += lastBid.price;
    }

    /**
     * @notice Returns all the bids of a token
     * @param _tokenId Token ID of the item
     */
    function getBids(uint _tokenId) external view returns (Bid[] memory) {
        return bids[_tokenId];
    }

    /**
     * @notice Returns all whitelisted payment tokens
     */
    function getWhitelistedPaymentTokens() external view returns (address[] memory) {
        return whitelistedPaymentTokens;
    }

    /**
     * @notice Returns all the address that will receive part of the revenues
     */
    function getWithdrawAddresses() external view returns (address[] memory) {
        return withdrawAddresses;
    }

    // PRIVILEGED FUNCTIONS

    /**
     * @notice Sell an item
     * @param _tokenId Token ID of the item
     * @param _basePrice Base price for the token
     * @param _directSalePrice Price in case of direct sale. If 0, direct sale is disabled
     * @param _paymentToken Payment token that will be used for this sale. Native BNB is represented by address(0)
     * @param _start Start of the sale
     * @param _end End of the sale
     */
    function sell(uint _tokenId, uint _basePrice, uint _directSalePrice, address _paymentToken, uint _start, uint _end) public onlyOwner {
        require (isPaymentTokenWhitelisted[_paymentToken], "Marketplace: invalid payment token");
        require (nft.ownerOf(_tokenId) == msg.sender, "Marketplace: not NFT owner");
        require (block.timestamp < _start, "Marketplace: invalid start");
        require (_start < _end, "Marketplace: invalid timestamps");
        require(_basePrice > 0 || _directSalePrice > 0, "Marketplace: at least one of _basePrice or _directSalePrice must be set");
        require(_directSalePrice == 0 || _basePrice < _directSalePrice , "Marketplace: _directSalePrice must be greater than _basePrice");

        // Takes the NFT from the owner
        nft.transferFrom(msg.sender, address(this), _tokenId);

        SellOrder storage sellOrder = sellOrders[_tokenId];
        sellOrder.basePrice = _basePrice;
        sellOrder.start = _start;
        sellOrder.end = _end;
        sellOrder.directSalePrice = _directSalePrice;
        sellOrder.paymentToken = _paymentToken;
        sellOrder.claimed = false;

        emit NewSellOrder(_tokenId, _basePrice, _paymentToken);
    }

    /**
     * @notice Change a sell order
     * @param _tokenId Token ID of the item
     * @param _basePrice Base price for the token
     * @param _directSalePrice Price in case of direct sale. If 0, direct sale is disabled
     * @param _paymentToken Payment token that will be used for this sale. Native BNB is represented by address(0)
     * @param _start Start of the sale
     * @param _end End of the sale
     */
    function changeSellOrder(uint _tokenId, uint _basePrice, uint _directSalePrice, address _paymentToken, uint _start, uint _end) external onlyOwner {
        SellOrder storage sellOrder = sellOrders[_tokenId];

        require (! sellOrder.claimed, "Marketplace: item already claimed");
        require (isPaymentTokenWhitelisted[_paymentToken], "Marketplace: invalid payment token");
        require (block.timestamp < _start && block.timestamp < sellOrder.start, "Marketplace: invalid start");
        require (_start < _end, "Marketplace: invalid timestamps");

        sellOrder.basePrice = _basePrice;
        sellOrder.start = _start;
        sellOrder.end = _end;
        sellOrder.directSalePrice = _directSalePrice;
        sellOrder.paymentToken = _paymentToken;

        emit SellOrderChanged(_tokenId, _basePrice, _paymentToken);
    }

    /**
     * @notice Sell multiple items
     * @param _tokenIds Token ID of the items
     * @param _basePrices Base prices for each token
     * @param _paymentTokens Payment token that will be used for each sale. Native BNB is represented by address(0)
     * @param _starts Start of each sale
     * @param _ends End of each sale
     */
    function sellBatch(uint[] memory _tokenIds, uint[] memory _basePrices, uint[] memory _directSalePrices,
        address[] memory _paymentTokens, uint[] memory _starts, uint[] memory _ends) external onlyOwner {

        // Check array lengths
        require (_tokenIds.length == _basePrices.length && _basePrices.length == _paymentTokens.length && _paymentTokens.length == _directSalePrices.length
            && _directSalePrices.length == _starts.length && _starts.length == _ends.length, "Marketplace: inconsistent array lengths");

        for (uint i = 0; i < _tokenIds.length; i++) {
            sell(_tokenIds[i], _basePrices[i], _directSalePrices[i], _paymentTokens[i], _starts[i], _ends[i]);
        }
    }

    /**
     * @notice Recover unsold items
     */
    function recover(uint _tokenId) external onlyOwner {
        SellOrder storage sellOrder = sellOrders[_tokenId];
        require (block.timestamp > sellOrder.end, "Marketplace: sell not ended");
        require (bids[_tokenId].length == 0, "Marketplace: item has bids");
        require (nft.ownerOf(_tokenId) == address(this), "Marketplace: token already recover");

        // Transfer the NFT
        nft.transferFrom(address(this), recoverAddress, _tokenId);
    }

    /**
     * @notice Add a new address to the withdraw list. From now on this address will
            receive part of the generated revenues
     * @param _address Address to add
     */
    function addAddressToWithdrawList(address _address) external onlyOwner {
        require (_address != address(0), "Marketplace: invalid address");

        bool filled = false;
        for (uint i = 0; i < withdrawAddresses.length && !filled; i++) {
            if (withdrawAddresses[i] == address(0)) {
                withdrawAddresses[i] = _address;
                filled = true;
            }
        }

        if (!filled) {
            withdrawAddresses.push(_address);
        }

        withdrawAddressesCounter += 1;
    }

    /**
     * @notice Add a new address to the withdraw list. From now on this address will
            receive part of the generated revenues
     * @param _index Index of the address to remove
     */
    function removeAddressFromWithdrawList(uint _index) external onlyOwner {
        require (_index < withdrawAddresses.length, "Marketplace: invalid index");

        uint lastIndex = withdrawAddresses.length - 1;

        withdrawAddresses[_index] = withdrawAddresses[lastIndex];
        delete withdrawAddresses[lastIndex];

        withdrawAddressesCounter -= 1;
    }

    /**
     * @notice Withdraw payment tokens received
     */
    function withdraw(address _paymentToken) external onlyOwner {
        uint balance;
        if (_paymentToken == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(_paymentToken).balanceOf(address(this));
        }

        uint amount = balance / withdrawAddressesCounter;
        for (uint i = 0; i < withdrawAddresses.length; i++) {
            if ( withdrawAddresses[i] != address(0)) {
                processPaymentTo(_paymentToken, withdrawAddresses[i], amount);
            }
        }
    }

    /**
     * @notice Set if a payment token is whitelisted or not
     * @param _token Address of the payment token
     */
    function whitelistPaymentToken(address _token) external onlyOwner {
        require (! isPaymentTokenWhitelisted[_token], "Marketplace: token already whitelisted");

        isPaymentTokenWhitelisted[_token] = true;
        whitelistedPaymentTokens.push(_token);
    }

    // INTERNAL FUNCTIONS
    // Takes funds from the bidder based on the payment token
    function processPaymentFrom(address _token, address _from, uint _amount) internal {
        // BNB
        if (_token == address(0)) {
            require (msg.value >= _amount, "Marketplace: not enough funds");
        }

        // Other tokens
        else {
            IERC20(_token).transferFrom(_from, address(this), _amount);
        }
    }

    // Refund a bidder if it gets outbidded
    function processPaymentTo(address _token, address _to, uint _amount) internal {
        // BNB
        if (_token == address(0)) {
            payable(_to).transfer(_amount);
        }

        // Other tokens
        else {
            IERC20(_token).transfer(_to, _amount);
        }
    }
}
