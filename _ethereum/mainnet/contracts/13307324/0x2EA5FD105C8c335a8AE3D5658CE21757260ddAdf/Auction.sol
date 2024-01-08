// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./EnumerableSet.sol";


contract Auction is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    EnumerableSet.UintSet private collection;
    IERC721Enumerable private _token;
    uint8 private _tokenAmountBuyLimit;
    uint256 private _soldTokensAmount;

    event SaleStart(uint256 indexed _saleDuration, uint256 indexed _saleStartTime);
    event SalePaused(uint256 indexed _currentPrice, uint256 indexed _timeElapsed);

    uint256 public saleDuration;
    uint256 public saleStartTime;
    uint256 public saleStartPrice;
    uint256 public saleFinalPrice;

    bool public saleActive;

    modifier whenSaleActive() {
        require(saleActive, "DAU: Sale is not active");
        _;
    }

    modifier whenSalePaused() {
        require(!saleActive, "DAU: Sale is not paused");
        _;
    }

    constructor(IERC721Enumerable token_, uint8 tokenAmountBuyLimit_) {
        _token = token_;
        _tokenAmountBuyLimit = tokenAmountBuyLimit_;
    }

    function tokenAddress() external view virtual onlyOwner returns (address) {
        return address(_token);
    }

    function setTokenAddress(IERC721Enumerable token_) public virtual onlyOwner {
        require(collection.length() == 0, "DAU: The collection have to be empty");
        _token = token_;
    }

    function tokenAmountBuyLimit() public view virtual returns (uint8) {
        return _tokenAmountBuyLimit;
    }

    function setTokenAmountBuyLimit(uint8 tokenAmountBuyLimit_) public virtual onlyOwner {
        require(tokenAmountBuyLimit_ > 0);
        _tokenAmountBuyLimit = tokenAmountBuyLimit_;
    }

    function startSale(
        uint256 saleDuration_, uint256 saleStartPrice_, uint256 saleFinalPrice_
    ) external onlyOwner whenSalePaused {
        require(saleStartPrice_ > saleFinalPrice_,  "DAU: Start price price have to be greater than final price");
        saleStartPrice = saleStartPrice_;
        saleFinalPrice = saleFinalPrice_;
        saleStartTime = block.timestamp;
        saleDuration = saleDuration_;

        saleActive = true;
        emit SaleStart(saleDuration, saleStartTime);
    }

    function pauseSale() external onlyOwner whenSaleActive {
        uint256 currentSalePrice = price();
        saleActive = false;
        emit SalePaused(currentSalePrice, getElapsedSaleTime());
    }

    function price() public view whenSaleActive returns (uint256) {
        uint256 elapsed = getElapsedSaleTime();
        if (elapsed >= saleDuration) {
            return saleFinalPrice;
        }
        uint256 currentPrice = ((saleDuration - elapsed) * saleStartPrice) / saleDuration;
        if (currentPrice <= saleFinalPrice) {
            return saleFinalPrice;
        }
        return currentPrice;
    }

    function getElapsedSaleTime() internal view returns (uint256) {
        return saleStartTime > 0 ? block.timestamp - saleStartTime : 0;
    }

    function remainingSaleTime() public view returns (uint256) {
        require(saleStartTime > 0, "DAU: Public sale hasn't started yet");
        if (getElapsedSaleTime() >= saleDuration) {
            return 0;
        }

        return (saleStartTime + saleDuration) - block.timestamp;
    }

    function soldTokensAmount() public view returns (uint256) {
        return _soldTokensAmount;
    }

    function remainingTokensAmount() public view returns (uint256) {
        return collection.length() - soldTokensAmount();
    }

    function _transferToken(address recipient, uint256 tokenId) internal {
        _token.transferFrom(address(this), recipient, tokenId);
    }

    function addToCollection(uint256[] memory tokens) external onlyOwner whenSalePaused {
        for (uint16 index; index < tokens.length; index += 1) {
            require(_token.ownerOf(tokens[index]) == address(this));
            collection.add(tokens[index]);
        }
    }

    function _removeItem(uint256 tokenId, address recipient) internal {
        collection.remove(tokenId);
        if (_token.ownerOf(tokenId) == address(this)) {
            _transferToken(recipient, tokenId);
        }
    }

    function removeFromCollection(uint256[] memory tokens, address recipient) external onlyOwner whenSalePaused {
        for (uint16 index; index < tokens.length; index += 1) {
            _removeItem(tokens[index], recipient);
        }
    }

    function clearCollection(address recipient) external onlyOwner whenSalePaused {
        _soldTokensAmount = 0;
        uint256 collectionLength = collection.length();
        while(collectionLength > 0) {
            collectionLength -= 1;
            _removeItem(collection.at(collectionLength), recipient);
        }
    }

    function _processPurchaseToken(address recipient) internal returns (uint256) {
        uint256 tokenId = collection.at(_soldTokensAmount);
        _transferToken(recipient, tokenId);
        _soldTokensAmount += 1;
        return tokenId;
    }

    function _preValidatePurchase(uint256 tokensAmount) internal view {
        require(msg.sender != address(0));
        require(tokensAmount > 0, "DAU: Need buy at least one token");
        require(tokensAmount <= tokenAmountBuyLimit(), "DAU: Limited amount of tokens in transaction");
        require(tokensAmount <= remainingTokensAmount(), "DAU: Limited amount of remaining tokens");
        require(remainingSaleTime() > 0, "DAU: Sale is over");
    }

    function buyTokens(uint256 tokensAmount) external payable whenSaleActive nonReentrant returns (uint256[] memory) {
        _preValidatePurchase(tokensAmount);

        uint256 costToMint = price() * tokensAmount;
        require(costToMint <= msg.value, "DAU: Insufficient funds");

        uint256[] memory tokens = new uint256[](tokensAmount);
        for (uint index = 0; index < tokensAmount; index += 1) {
            tokens[index] = _processPurchaseToken(msg.sender);
        }

        return tokens;
    }

    function withdraw(address payable wallet, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance);
        wallet.transfer(amount);
    }
}
