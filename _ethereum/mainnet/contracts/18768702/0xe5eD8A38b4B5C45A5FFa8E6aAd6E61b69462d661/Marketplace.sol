// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0 < 0.9.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns(address);

function isOnSale(uint256 tokenId) external view returns(bool);

function getTokenPrice(uint256 tokenId) external view returns(uint256);

function getRoyaltyOfToken(uint256 tokenId) external view returns(uint256);

function getMinimumBidPercentageOfToken(uint256 tokenId) external view returns(uint256);

function getSecondaryOfToken(uint256 tokenId) external view returns(address);

function getArtistWalletAddress() external view returns(address);

function safeTransferFrom(
  address from,
  address to,
  uint256 tokenId
) external;

function setApprovalForAllByMarketplace(address newOwner) external;

function putOnSale(uint256 _tokenId) external;

function removeFromSale(uint256 _tokenId) external;
}

contract Marketplace is  Ownable {
  receive() external payable {
    revert("Contract does not accept Ether directly");
  }

    event _PutNftOnSale(
    address indexed artist,
    uint256 indexed token,
    uint256 price,
    uint256 saleType
  );

    event _RemoveNftFromSale(address _artist, uint256 _token);

    event _BuyNft(
    address indexed _buyer,
    address indexed _artist,
    uint256 indexed _token,
    uint256 _price,
    uint256 royaltyAmount,
    uint256 commissionAmount
  );
    
    event _Bid(
    address indexed _bidder,
    address indexed _artist,
    uint256 indexed _token,
    uint256 _price
  );

    event _ReturnBidAmount(
    address _bidder,
    address _artist,
    uint256 _token,
    uint256 _price
  );

    event _AcceptBid(
    address indexed _buyer,
    address indexed _artist,
    uint256 indexed _token,
    uint256 _price,
    uint256 royaltyAmount,
    uint256 commissionAmount
  );

    event _RejectBid(
    address indexed _bidder,
    address indexed _artist,
    uint256 indexed _token,
    uint256 _price
  );

    struct tokenDetails {
        bool putOnSale;
        uint256 price;
        uint256 saleType; // 1 for fixed price, 2 for auction
        uint256 lastBid;
        address lastBidder;
  }

    uint256 commissionPercentageToOwner = 250;
    address contractOwner;

  constructor() {
    contractOwner = msg.sender;
  }

    bool private locked;

    modifier noReentrant() {
    require(!locked, "Reentrant call");
    locked = true;
    _;
    locked = false;
  }


  function setCommissionPercentageToOwner(uint256 newPercentage) external onlyOwner {
    commissionPercentageToOwner = newPercentage;
  }

    address getCommissionWalletAddress = 0xF6e48Fc4cadF14B4E7e6dB9bE45a5Bfa3Ac74Be8;

  function setCommissionWallet(address newCommissionWallet) external onlyOwner {
    getCommissionWalletAddress = newCommissionWallet;
  }

  mapping(address => mapping(uint256 => tokenDetails)) tokenDetail;

  function getTokenDetails(address _artist, uint256 _token)
  public
  view
  returns(tokenDetails memory)
  {
    return tokenDetail[_artist][_token];
  }

  function putNftOnSale(
    address _artist,
    uint256 _token,
    uint256 _price,
    uint256 _saleType
  ) external {
    require(IERC721(_artist).ownerOf(_token) == msg.sender, "caller is not owner");

    if (tokenDetail[_artist][_token].lastBid > 0 && tokenDetail[_artist][_token].lastBidder != address(0)) {
      revert("Already on sale to bid, please accept preview bid");
    }

    require(_price > 0, "Invalid Price");
    require(_saleType > 0 && _saleType < 3, "Invalid Sale Type");

    tokenDetail[_artist][_token] = tokenDetails(true, _price, _saleType, 0, address(0));
        emit _PutNftOnSale(_artist, _token, _price, _saleType);
  }

  function removeNftFromSale(address _artist, uint256 _token) external {
    require(IERC721(_artist).ownerOf(_token) == msg.sender, "caller is not owner");

    require(tokenDetail[_artist][_token].putOnSale, "Already remove from sale");

    if (tokenDetail[_artist][_token].lastBid > 0 && tokenDetail[_artist][_token].lastBidder != address(0)) {
      returnAmount(tokenDetail[_artist][_token].lastBidder, tokenDetail[_artist][_token].lastBid, _artist, _token);
    }

    clearTokenDetails(_artist, _token);

        emit _RemoveNftFromSale(_artist, _token);
  }

  function BuyNft(address _artist, uint256 _token) external payable noReentrant {
    require(tokenDetail[_artist][_token].putOnSale, "Nft is not on sale");
    require(msg.value >= tokenDetail[_artist][_token].price, "Insufficient fund");

        address _owner = IERC721(_artist).ownerOf(_token);
    require(_owner != msg.sender, "Owner can not buy own NFT");

    if (tokenDetail[_artist][_token].saleType == 1) {
            uint256 royaltyPercentage = IERC721(_artist).getRoyaltyOfToken(_token);
            address artistWalletAddress = IERC721(_artist).getArtistWalletAddress();
            address commissionWalletAddress = getCommissionWalletAddress;

            uint256 price = msg.value;

            uint256 _commission = (price * commissionPercentageToOwner) / 10000;
            uint256 royaltyAmount = 0;

      if (royaltyPercentage > 0) {
        royaltyAmount = (price * royaltyPercentage) / 10000;
        price = price - royaltyAmount;

        (bool sent1, ) = artistWalletAddress.call{ value: royaltyAmount } ("");
        require(sent1, "Failed to send Ether for royalty");
      }

      price = price - _commission;

      transferCommissionAmount(_commission, commissionWalletAddress);


      (bool sent, ) = _owner.call{ value: price } ("");
      require(sent, "Failed to send Ether to owner");

      IERC721(_artist).safeTransferFrom(_owner, msg.sender, _token);
      IERC721(_artist).setApprovalForAllByMarketplace(msg.sender);

      tokenDetail[_artist][_token].putOnSale = false;

            emit _BuyNft(msg.sender, _artist, _token, msg.value, royaltyAmount, _commission);
    } else {
            uint256 price = tokenDetail[_artist][_token].price;
            address lastBidder = tokenDetail[_artist][_token].lastBidder;

      if (tokenDetail[_artist][_token].lastBid > 0) {
        price = tokenDetail[_artist][_token].lastBid;
      }

            uint256 minimumPercentage = IERC721(_artist).getMinimumBidPercentageOfToken(_token);

      if (minimumPercentage > 0 && lastBidder != address(0)) {
        require(
          getMinimumAmount(minimumPercentage, price, msg.value),
          "Amount should be greater than current price"
        );
      } else {
        require(price <= msg.value, "Amount should be greater than current price");
      }

      if (lastBidder != address(0) && price > 0) {
        returnAmount(lastBidder, price, _artist, _token);
      }

      tokenDetail[_artist][_token].lastBid = msg.value;
      tokenDetail[_artist][_token].lastBidder = msg.sender;

            emit _Bid(msg.sender, _artist, _token, msg.value);
    }
  }

  function getMinimumAmount(uint256 _minimumPercentage, uint256 lastPrice, uint256 _currentPrice)
  internal
  pure
  returns(bool)
  {
        uint256 AmountWithMinimumPercentage = lastPrice + ((lastPrice * _minimumPercentage) / 10000);

    if (_currentPrice >= AmountWithMinimumPercentage) {
      return true;
    }

    return false;
  }

  function returnAmount(address _bidder, uint256 _bid, address _artist, uint256 _token) internal {
    payable(_bidder).transfer(_bid);

        emit _ReturnBidAmount(_bidder, _artist, _token, _bid);
  }

  function acceptBid(address _artist, uint256 _token) external noReentrant {
    require(
      IERC721(_artist).ownerOf(_token) == msg.sender ||
      IERC721(_artist).getSecondaryOfToken(_token) == msg.sender,
      "caller is not owner"
    );

        address lastBidder = tokenDetail[_artist][_token].lastBidder;
        uint256 lastBid = tokenDetail[_artist][_token].lastBid;

    require(lastBidder != address(0), "something went wrong");

        uint256 royaltyPercentage = IERC721(_artist).getRoyaltyOfToken(_token);
        address artistWalletAddress = IERC721(_artist).getArtistWalletAddress();
        address commissionWalletAddress = getCommissionWalletAddress;

        uint256 price = lastBid;
       
        uint256 _commission = (price * commissionPercentageToOwner) / 10000;

    transferCommissionAmount(_commission, commissionWalletAddress);

        uint256 royaltyAmount = 0;

    if (royaltyPercentage > 0) {
      royaltyAmount = (price * royaltyPercentage) / 10000;
      price = price - royaltyAmount;

      (bool sent1, ) = artistWalletAddress.call{ value: royaltyAmount } ("");
      require(sent1, "Failed to send Ether for royalty");
    }
    price = price - _commission;

        address _owner = IERC721(_artist).ownerOf(_token);

    (bool sent, ) = _owner.call{ value: price } ("");
    require(sent, "Failed to send Ether");

    IERC721(_artist).safeTransferFrom(_owner, lastBidder, _token);
    IERC721(_artist).setApprovalForAllByMarketplace(lastBidder);

    clearTokenDetails(_artist, _token);

        emit _AcceptBid(lastBidder, _artist, _token, lastBid, royaltyAmount, _commission);
  }

  function transferCommissionAmount(uint256 _price, address commissionWalletAddress) internal {
    payable(commissionWalletAddress).transfer(_price);
  }

  function rejectBid(address _artist, uint256 _token) external noReentrant {
    require(
      IERC721(_artist).ownerOf(_token) == msg.sender ||
      IERC721(_artist).getSecondaryOfToken(_token) == msg.sender,
      "caller is not owner"
    );
    require(tokenDetail[_artist][_token].lastBid > 0, "There is no bid to reject");
    require(tokenDetail[_artist][_token].lastBidder != address(0), "something went wrong");

        address lastBidder = tokenDetail[_artist][_token].lastBidder;
        uint256 lastBid = tokenDetail[_artist][_token].lastBid;

    (bool sent, ) = lastBidder.call{ value: lastBid } ("");
    require(sent, "Failed to send Ether");

    clearTokenDetails(_artist, _token);
        emit _RejectBid(lastBidder, _artist, _token, lastBid);
  }

  function increaseAmount(address _artist, uint256 _token, uint256 _amount) external {
    require(IERC721(_artist).ownerOf(_token) == msg.sender, "caller is not owner");
    require(tokenDetail[_artist][_token].saleType == 1, "Can not increase amount for auction type");
    require(
      tokenDetail[_artist][_token].price < _amount,
      "Increase amount should be greater than previous amount"
    );

    tokenDetail[_artist][_token].price = _amount;
  }

  function decreaseAmount(address _artist, uint256 _token, uint256 _amount) external {
    require(IERC721(_artist).ownerOf(_token) == msg.sender, "caller is not owner");
    require(
      tokenDetail[_artist][_token].saleType == 1,
      "Can not decrease amount for auction type"
    );
    require(
      tokenDetail[_artist][_token].price > _amount,
      "Decrease amount should be lesser than previous amount"
    );

    tokenDetail[_artist][_token].price = _amount;
  }

  function clearTokenDetails(address _artist, uint256 _token) internal {
    tokenDetail[_artist][_token] = tokenDetails(false, 0, 0, 0, address(0));
  }

  // Fallback function to reject any incoming Ether
  fallback() external {
    revert("Fallback function: Contract does not accept Ether directly");
  }
}