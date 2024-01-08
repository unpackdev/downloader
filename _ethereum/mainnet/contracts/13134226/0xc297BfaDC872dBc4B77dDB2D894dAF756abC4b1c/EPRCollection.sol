// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ReentrancyGuard.sol";

import "./BaseERC721.sol";

contract EPRCollection is BaseERC721, ReentrancyGuard {
  /**
  * @notice contract can receive Ether.
  */
  receive() external payable {}

  event Deposit(address from, uint256 amount, uint256 tokenId);
  event Withdraw(address to, uint256 amount, uint256 tokenId);
  event OnMarket(uint256 tokenId, uint256 price);
  event OffMarket(uint256 tokenId);
  event Purchase(address seller, address buyer, uint256 tokenId, uint256 amount);

  uint256 constant NULL = 0;
  uint256 public faceValue;

  struct Coin {
    uint256 tokenId;
    uint256 price;
    uint256 fundedValue;
    bool forSale;
  }

  mapping(uint256 => Coin) public coins;

  uint256[] public tokenIds;

  /**
  * @dev Initializes the contract with a mint limit
  * @param _mintLimit the maximum tokens a given address may own at a given time
  */
  constructor(
    uint256 _mintLimit,
    uint256 _faceValue,
    string memory _name,
    string memory _symbol,
    string memory _baseURI,
    string memory _contractURI
  ) BaseERC721(
    _name,
    _symbol,
    _mintLimit,
    _baseURI,
    _contractURI
  ) payable {
    faceValue = _faceValue;
    tokenIds = new uint256[](_mintLimit);
  }

  function createCoin(uint256 _tokenId) internal pure returns (Coin memory) {
    return Coin({
      forSale: false,
      price: uint256(0),
      fundedValue: uint256(0),
      tokenId: _tokenId
    });
  }

  /**
   * @dev Creates `amount` new tokens for `to`.
   *
   * See {ERC20-_mint}.
   *
   * Requirements:
   * - the caller must have the `MINTER_ROLE`.
   * - the total supply must be less than the collection mint limit
   */
  function mint() onlyMinter public returns (uint256) {
    uint256 _tokenId = BaseERC721._mint();
    Coin memory _coin = createCoin(_tokenId);
    coins[_tokenId] = _coin;

    return _tokenId;
  }

  function getBalance() public view returns (uint) {
    return address(this).balance;
  }

  function fund(uint256 _tokenId) nonReentrant onlyMinter external payable {
    confirmTokenExists(_tokenId);
    // Fetch the product
    Coin storage _coin = coins[_tokenId];
    // Ensure the coin is unfunded
    require(_coin.fundedValue == uint256(0), "funded value must be nil");
    // Ensure the amount is exactly equal to the face faceValue
    require(msg.value == faceValue, "value must be face value");
    _coin.fundedValue = msg.value;

    emit Deposit(msg.sender, msg.value, _tokenId);
  }

  function defund(uint256 _tokenId) nonReentrant onlyMinter external {
    confirmTokenExists(_tokenId);
    // confirm the token is fully funded
    confirmTokenFunded(_tokenId);
    // Fetch the product
    Coin storage _coin = coins[_tokenId];
    // Transfer the funded balance to the caller
    payable(address(uint160(msg.sender))).transfer(_coin.fundedValue);
    // Update the coin's funded value
    _coin.fundedValue = uint256(0);
    // Emit a Withdraw event
    emit Withdraw(msg.sender, _coin.fundedValue, _coin.tokenId);
  }

  // callable by owner only, after specified time
  function withdraw(Coin memory _coin) private {
    confirmTokenFunded(_coin.tokenId);
    require(_coin.fundedValue != NULL, 'funded value cannot be nil');
    // transfer the balance to the caller
    payable(address(uint160(msg.sender))).transfer(_coin.fundedValue);
    emit Withdraw(msg.sender, _coin.fundedValue, _coin.tokenId);
  }

  //  function burnToken(address owner, uint256 tokenId) public {
  // public vs external
  // https://ethereum.stackexchange.com/questions/19380/external-vs-public-best-practices#:~:text=The%20difference%20is%20because%20in,can%20read%20directly%20from%20calldata.&text=Internal%20calls%20are%20executed%20via,internally%20by%20pointers%20to%20memory.
  function burn(uint256 _tokenId) nonReentrant external {
    // Ensure the coin exists
    confirmTokenExists(_tokenId);
    // Only the token owner may burn
    confirmTokenOwner(_tokenId);
    // Fetch the coin
    Coin storage _coin = coins[_tokenId];
    // Token may not be for sale
    require(_coin.forSale == false, "coin cannot be for sale");
    withdraw(_coin);
    ERC721._burn(_tokenId); // emits Transfer event
    _coin.fundedValue = uint256(0); // TODO : ::: ::: ::: :::: reentry attack
  }

  // https://stackoverflow.com/questions/67317392/how-to-transfer-a-nft-from-one-account-to-another-using-erc721
  function allowBuy(uint256 _tokenId, uint256 _price) external {
    // Make sure the coin exists

    confirmTokenExists(_tokenId);
    // Only the token owner may invoke
    confirmTokenOwner(_tokenId);
    // Token must be funded
    confirmTokenFunded(_tokenId);
    // Purchase price must be at least as much as the face value
    require(_price >= faceValue, 'price must be greater than face value');

    Coin storage _coin = coins[_tokenId];
    _coin.price = _price;
    _coin.forSale = true;

    emit OnMarket(_tokenId, _price);
  }

  function disallowBuy(uint256 _tokenId) external {
    // Ensure the coin exists
    confirmTokenExists(_tokenId);
    // Only the token owner may invoke
    confirmTokenOwner(_tokenId);
    // Token must be funded
    confirmTokenFunded(_tokenId);

    Coin storage _coin = coins[_tokenId];
    _coin.price = uint256(0);
    _coin.forSale = false;

    emit OffMarket(_tokenId);
  }

  function buy(uint256 _tokenId) nonReentrant external payable {
    // Ensure the coin exists
    confirmTokenExists(_tokenId);
    // Capture the seller
    address _seller = ownerOf(_tokenId);
    // Require that the buyer is not the seller
    require(_seller != msg.sender, "buyer cannot be seller");
    // Fetch the product
    Coin storage _coin = coins[_tokenId];
    // Require that the coin is on offer
    require(_coin.forSale == true, "coin is not for sale");
    // Require that the price is non zero
    require(_coin.price > 0, "coin must have a price greater than face value");
    // Require that there is enough Ether in the transaction
    require(msg.value == _coin.price, "value does not equal the price");

    BaseERC721._buy(_tokenId);

    safeTransferFrom(_seller, msg.sender, _tokenId);
    // Transfer the payment to the seller
    payable(_seller).transfer(msg.value);

    _coin.forSale = false;
    _coin.price = uint256(0);

    emit Purchase(_seller, msg.sender, _tokenId, msg.value);
  }

  /// @notice Returns all the relevant information about a specific coin.
  function getCoin(uint256 _tokenId) external view
  returns (
    bool forSale,
    uint256 price,
    uint256 fundedValue,
    string memory uri,
    address owner
  ) {
    Coin memory _coin = coins[_tokenId];

    forSale = _coin.forSale;
    price = _coin.price;
    fundedValue = _coin.fundedValue;

    if (_exists(_tokenId)) {
      owner = ownerOf(_tokenId);
      uri = tokenURI(_tokenId);
    }
    else {
      owner = address(0);
      uri = '';
    }
  }

  function confirmTokenFunded(uint256 _tokenId) internal view {
    // Fetch the product
    Coin memory _coin = coins[_tokenId];
    // Ensure the coin is fully funded
    require(_coin.fundedValue == faceValue, "token must be funded");
  }

  function confirmTokenUnfunded(uint256 _tokenId) internal view {
    // Fetch the product
    Coin memory _coin = coins[_tokenId];
    // Ensure the coin is fully funded
    require(_coin.fundedValue == uint256(0), "token must be unfunded");
  }
}
