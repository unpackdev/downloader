// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "./Ownable.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IMintableERC721S.sol";

/**
 * @title Mintable Sale S
 *
 * @notice Mintable Sale S sales fixed amount of NFTs (tokens) for a fixed price in a fixed period of time;
 *      it can be used in a 10k sale campaign and the smart contract is generic and
 *      can sell any type of mintable NFT (see IMintableERC721S interface)
 *
 * @dev Technically, all the "fixed" parameters can be changed on the go after smart contract is deployed
 *      and operational, but this ability is reserved for quick fix-like adjustments, and to provide
 *      an ability to restart and run a similar sale after the previous one ends
 *
 * @dev When buying a token from this smart contract, next token is minted to the recipient
 *
 * @dev Supports functionality to limit amount of tokens that can be minted to each address
 *
 * @dev Deployment and setup:
 *      1. Deploy smart contract, specify smart contract address during the deployment:
 *         - Mintable ER721 P deployed instance address
 *      2. Execute `initialize` function and set up the sale Sarameters;
 *         sale is not active until it's initialized
 *
 */
contract MintableSaleS is Ownable {
  /**
   * @dev Next token ID to mint;
   *      initially this is the first "free" ID which can be minted;
   *      at any point in time this should point to a free, mintable ID
   *      for the token
   *
   * @dev `nextId` cannot be zero, we do not ever mint NFTs with zero IDs
   */
  uint32 public nextId = 1;

  /**
   * @dev Last token ID to mint;
   *      once `nextId` exceeds `finalId` the sale Sauses
   */
  uint32 public finalId;

  // ----- SLOT.1 (224/256)
  /**
   * @notice Price of a single item (token) minted
   *      When buying several tokens at once the price accumulates accordingly, with no discount
   *
   * @dev Maximum item price is ~18.44 ETH
   */
  uint64 public itemPrice;

  /**
   * @notice Sale start unix timestamp; the sale is active after the start (inclusive)
   */
  uint32 public saleStart;

  /**
   * @notice Sale end unix timestamp; the sale is active before the end (exclusive)
   */
  uint32 public saleEnd;

  /**
   * @notice Once set, limits the amount of tokens one address can buy for the duration of the sale;
   *       When unset (zero) the amount of tokens is limited only by the amount of tokens left for sale
   */
  uint32 public mintLimit;

  /**
   * @notice Counter of the tokens sold (minted) by this sale smart contract
   */
  uint32 public soldCounter;

  // ----- NON-SLOTTED
  /**
   * @dev Mintable ERC721 contract address to mint
   */
  address public immutable tokenContract;

  // ----- NON-SLOTTED
  /**
   * @dev Developer fee
   */
  uint256 public immutable developerFee;

  // ----- NON-SLOTTED
  /**
   * @dev Address of developer to receive withdraw fees
   */
  address public immutable developerAddress;

  // ----- NON-SLOTTED
  /**
   * @dev Number of mints performed by address
   */
  mapping(address => uint32) mints;

  /**
	 * @dev Smart contract unique identifier, a random number
	 *
	 * @dev Should be regenerated each time smart contact source code is changed
	 *      and changes smart contract itself is to be redeployed
	 *
	 * @dev Generated using https://www.random.org/bytes/
	 */
	uint256 public constant UID = 0x3f38351a8d513731422d6b64f354f3cf7ea9ae952d15c73513da3b92754e778f;

  /**
   * @dev Fired in initialize()
   *
   * @param _by an address which executed the initialization
   * @param _itemPrice price of one token created
   * @param _nextId next ID of the token to mint
   * @param _finalId final ID of the token to mint
   * @param _saleStart start of the sale, unix timestamp
   * @param _saleEnd end of the sale, unix timestamp
   * @param _mintLimit mint limit
   */
  event Initialized(
    address indexed _by,
    uint64 _itemPrice,
    uint32 _nextId,
    uint32 _finalId,
    uint32 _saleStart,
    uint32 _saleEnd,
    uint32 _mintLimit
  );

  /**
   * @dev Fired in buy(), buyTo(), buySingle(), and buySingleTo()
   *
   * @param _by an address which executed and payed the transaction, probably a buyer
   * @param _to an address which received token(s) minted
   * @param _amount number of tokens minted
   * @param _value ETH amount charged
   */
  event Bought(address indexed _by, address indexed _to, uint32 _amount, uint256 _value);

  /**
   * @dev Fired in withdraw() and withdrawTo()
   *
   * @param _by an address which executed the withdrawal
   * @param _to an address which received the ETH withdrawn
   * @param _value ETH amount withdrawn
   */
  event Withdrawn(address indexed _by, address indexed _to, uint256 _value);

  /**
   * @dev Creates/deploys MintableSale and binds it to Mintable ERC721
   *      smart contract on construction
   *
   * @param _tokenContract deployed Mintable ERC721 smart contract; sale will mint ERC721
   *      tokens of that type to the recipient
   */
  constructor(address _tokenContract, uint256 _developerFee, address _developerAddress) {
    // verify the input is set
    require(_tokenContract != address(0), "token contract is not set");

    // verify that developer address is correct
    require(_developerAddress != address(0), "developer address is not set");

    // verify input is valid smart contract of the expected interfaces
    require(
      IERC165(_tokenContract).supportsInterface(type(IMintableERC721S).interfaceId)
      && IERC165(_tokenContract).supportsInterface(type(IMintableERC721S).interfaceId),
      "unexpected token contract type"
    );

    // assign the addresses
    tokenContract = _tokenContract;
    
    // assign the developer fee
    developerFee = _developerFee;

    // assign the developer address
    developerAddress = _developerAddress;
  }

  /**
   * @notice Number of tokens left on sale
   *
   * @dev Doesn't take into account if sale is active or not,
   *      if `nextId - finalId < 1` returns zero
   *
   * @return number of tokens left on sale
   */
  function itemsOnSale() public view returns(uint32) {
    // calculate items left on sale, taking into account that
    // finalId is on sale (inclusive bound)
    return finalId >= nextId? finalId + 1 - nextId: 0;
  }

  /**
   * @notice Number of tokens available on sale
   *
   * @dev Takes into account if sale is active or not, doesn't throw,
   *      returns zero if sale is inactive
   *
   * @return number of tokens available on sale
   */
  function itemsAvailable() public view returns(uint32) {
    // delegate to itemsOnSale() if sale is active, return zero otherwise
    return isActive()? itemsOnSale(): 0;
  }

  /**
   * @notice Active sale is an operational sale capable of minting and selling tokens
   *
   * @dev The sale is active when all the requirements below are met:
   *      1. Price is set (`itemPrice` is not zero)
   *      2. `finalId` is not reached (`nextId <= finalId`)
   *      3. current timestamp is between `saleStart` (inclusive) and `saleEnd` (exclusive)
   *
   * @dev Function is marked as virtual to be overridden in the helper test smart contract (mock)
   *      in order to test how it affects the sale Srocess
   *
   * @return true if sale is active (operational) and can sell tokens, false otherwise
   */
  function isActive() public view virtual returns(bool) {
    // evaluate sale state based on the internal state variables and return
    return itemPrice > 0 && nextId <= finalId && saleStart <= block.timestamp && saleEnd > block.timestamp;
  }

  /**
   * @dev Restricted access function to set up sale Sarameters, all at once,
   *      or any subset of them
   *
   * @dev To skip parameter initialization, set it to `-1`,
   *      that is a maximum value for unsigned integer of the corresponding type;
   *      `_aliSource` and `_aliValue` must both be either set or skipped
   *
   * @dev Example: following initialization will update only _itemPrice and _batchLimit,
   *      leaving the rest of the fields unchanged
   *      initialize(
   *          100000000000000000,
   *          0xFFFFFFFF,
   *          0xFFFFFFFF,
   *          0xFFFFFFFF,
   *          0xFFFFFFFF,
   *          10
   *      )
   *
   * @dev Requires next ID to be greater than zero (strict): `_nextId > 0`
   *
   * @dev Requires transaction sender to have `ROLE_SALE_MANAGER` role
   *
   * @param _itemPrice price of one token created;
   *      setting the price to zero deactivates the sale
   * @param _nextId next ID of the token to mint, will be increased
   *      in smart contract storage after every successful buy
   * @param _finalId final ID of the token to mint; sale is capable of producing
   *      `_finalId - _nextId + 1` tokens
   * @param _saleStart start of the sale, unix timestamp
   * @param _saleEnd end of the sale, unix timestamp; sale is active only
   *      when current time is within _saleStart (inclusive) and _saleEnd (exclusive)
   * @param _mintLimit how many tokens is allowed to buy for the duration of the sale,
   *      set to zero to disable the limit
   */
  function initialize(
    uint64 _itemPrice,  // <<<--- keep type in sync with the body type(uint64).max !!!
    uint32 _nextId,  // <<<--- keep type in sync with the body type(uint32).max !!!
    uint32 _finalId,  // <<<--- keep type in sync with the body type(uint32).max !!!
    uint32 _saleStart,  // <<<--- keep type in sync with the body type(uint32).max !!!
    uint32 _saleEnd,  // <<<--- keep type in sync with the body type(uint32).max !!!
    uint32 _mintLimit  // <<<--- keep type in sync with the body type(uint32).max !!!
  ) public onlyOwner {
    // verify the inputs
    require(_nextId > 0, "zero nextId");

    // no need to verify extra parameters - "incorrect" values will deactivate the sale

    // initialize contract state based on the values supplied
    // take into account our convention that value `-1` means "do not set"
    // 0xFFFFFFFFFFFFFFFF, 64 bits
    if(_itemPrice != type(uint64).max) {
      itemPrice = _itemPrice;
    }
    // 0xFFFFFFFF, 32 bits
    if(_nextId != type(uint32).max) {
      nextId = _nextId;
    }
    // 0xFFFFFFFF, 32 bits
    if(_finalId != type(uint32).max) {
      finalId = _finalId;
    }
    // 0xFFFFFFFF, 32 bits
    if(_saleStart != type(uint32).max) {
      saleStart = _saleStart;
    }
    // 0xFFFFFFFF, 32 bits
    if(_saleEnd != type(uint32).max) {
      saleEnd = _saleEnd;
    }
    // 0xFFFFFFFF, 32 bits
    if(_mintLimit != type(uint32).max) {
      mintLimit = _mintLimit;
    }

    // emit an event - read values from the storage since not all of them might be set
    emit Initialized(
      msg.sender,
      itemPrice,
      nextId,
      finalId,
      saleStart,
      saleEnd,
      mintLimit
    );
  }

  /**
   * @notice Buys two tokens in a batch.
   *      Accepts ETH as payment and mints a token
   */
  function buy() public payable {
    // delegate to `buyTo` with the transaction sender set to be a recipient
    buyTo(msg.sender);
  }

  /**
   * @notice Buys two tokens in a batch to an address specified.
   *      Accepts ETH as payment and mints tokens
   *
   * @param _to address to mint tokens to
   */
  function buyTo(address _to) public payable {
    // verify the inputs
    require(_to != address(0), "recipient not set");

    // verify mint limit
    if(mintLimit != 0) {
      require(mints[msg.sender] + 2 <= mintLimit, "mint limit reached");
    }

    // verify there is enough items available to buy the amount
    // verifies sale is in active state under the hood
    require(itemsAvailable() >= 2, "inactive sale or not enough items available");

    // calculate the total price required and validate the transaction value
    uint256 totalPrice = uint256(itemPrice) * 2;
    require(msg.value >= totalPrice, "not enough funds");

    // mint token to to the recipient
    IMintableERC721S(tokenContract).mint(_to, true);

    // increment `nextId`
    nextId += 2;
    // increment `soldCounter`
    soldCounter += 2;
    // increment sender mints
    mints[msg.sender] += 2;

    // if ETH amount supplied exceeds the price
    if(msg.value > totalPrice) {
      // send excess amount back to sender
      payable(msg.sender).transfer(msg.value - totalPrice);
    }

    // emit en event
    emit Bought(msg.sender, _to, 2, totalPrice);
  }

  /**
   * @notice Buys single token.
   *      Accepts ETH as payment and mints a token
   */
  function buySingle() public payable {
    // delegate to `buySingleTo` with the transaction sender set to be a recipient
    buySingleTo(msg.sender);
  }

  /**
   * @notice Buys single token to an address specified.
   *      Accepts ETH as payment and mints a token
   *
   * @param _to address to mint token to
   */
  function buySingleTo(address _to) public payable {
    // verify the inputs and transaction value
    require(_to != address(0), "recipient not set");

    // verify mint limit
    if(mintLimit != 0) {
      require(mints[msg.sender] + 1 <= mintLimit, "mint limit reached");
    }

    // verify sale is in active state
    require(isActive(), "inactive sale");

    require(msg.value >= itemPrice, "not enough funds");

    // mint token to the recipient
    IMintableERC721S(tokenContract).mint(_to, false);

    // increment `nextId`
    nextId++;
    // increment `soldCounter`
    soldCounter++;
    // increment sender mints
    mints[msg.sender]++;

    // if ETH amount supplied exceeds the price
    if(msg.value > itemPrice) {
      // send excess amount back to sender
      payable(msg.sender).transfer(msg.value - itemPrice);
    }

    // emit en event
    emit Bought(msg.sender, _to, 1, itemPrice);
  }

  /**
   * @dev Restricted access function to withdraw ETH on the contract balance,
   *      sends ETH back to transaction sender
   */
  function withdraw() public {
    // delegate to `withdrawTo`
    withdrawTo(msg.sender);
  }

  /**
   * @dev Restricted access function to withdraw ETH on the contract balance,
   *      sends ETH to the address specified
   *
   * @param _to an address to send ETH to
   */
  function withdrawTo(address _to) public onlyOwner {
    // verify withdrawal address is set
    require(_to != address(0), "address not set");

    // ETH value to send
    uint256 _value = address(this).balance;
    
    uint256 computedDevFee = _value * developerFee / 100;
    
    _value -= computedDevFee;

    // verify sale balance is positive (non-zero)
    require(_value > 0, "zero balance");

    // send the entire balance to the transaction sender
    payable(_to).transfer(_value);
    payable(developerAddress).transfer(computedDevFee);

    // emit en event
    emit Withdrawn(msg.sender, _to, _value);
  }
}
