// LICENSE ATTRIBUTION
// The MIT License (MIT)
//
// Copyright (c) 2020-2021 Alethea Tech PTE LTD
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IMintableERC721.sol";

/**
 * @title Mintable Sale
 *
 * @notice Mintable Sale sales fixed amount of NFTs (tokens) for a fixed price in a fixed period of time;
 *      it can be used in a 10k sale campaign and the smart contract is generic and
 *      can sell any type of mintable NFT (see MintableERC721 interface)
 *
 * @dev Technically, all the "fixed" parameters can be changed on the go after smart contract is deployed
 *      and operational, but this ability is reserved for quick fix-like adjustments, and to provide
 *      an ability to restart and run a similar sale after the previous one ends
 *
 * @dev When buying a token from this smart contract, next token is minted to the recipient
 *
 * @dev Deployment and setup:
 *      1. Deploy smart contract, specify smart contract address during the deployment:
 *         - Mintable ER721 deployed instance address
 *      2. Execute `initialize` function and set up the sale parameters;
 *         sale is not active until it's initialized
 *
 */
contract MintableSale is Ownable {
  // ----- SLOT.1 (256/256)
  /**
   * @notice Price of a single item (token) minted
   *      When buying several tokens at once the price accumulates accordingly, with no discount
   *
   * @dev Maximum item price is ~18.44 ETH
   */
  uint64 public itemPrice;

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
   *      once `nextId` exceeds `finalId` the sale pauses
   */
  uint32 public finalId;

  /**
   * @notice Sale start unix timestamp; the sale is active after the start (inclusive)
   */
  uint32 public saleStart;

  /**
   * @notice Sale end unix timestamp; the sale is active before the end (exclusive)
   */
  uint32 public saleEnd;

  /**
   * @notice Once set, limits the amount of tokens one can buy in a single transaction;
   *       When unset (zero) the amount of tokens is limited only by block size and
   *       amount of tokens left for sale
   */
  uint32 public batchLimit;

  /**
   * @notice Counter of the tokens sold (minted) by this sale smart contract
   */
  uint32 public soldCounter;

  // ----- NON-SLOTTED
  /**
   * @dev Mintable ERC721 contract address to mint
   */
  address public immutable tokenContract;

  /**
   * @dev Fired in initialize()
   *
   * @param _by an address which executed the initialization
   * @param _itemPrice price of one token created
   * @param _nextId next ID of the token to mint
   * @param _finalId final ID of the token to mint
   * @param _saleStart start of the sale, unix timestamp
   * @param _saleEnd end of the sale, unix timestamp
   * @param _batchLimit how many tokens is allowed to buy in a single transaction
   */
  event Initialized(
    address indexed _by,
    uint64 _itemPrice,
    uint32 _nextId,
    uint32 _finalId,
    uint32 _saleStart,
    uint32 _saleEnd,
    uint32 _batchLimit
  );

  /**
   * @dev Fired in buy(), buyTo(), buySingle(), and buySingleTo()
   *
   * @param _by an address which executed and payed the transaction, probably a buyer
   * @param _to an address which received token(s) minted
   * @param _amount number of tokens minted
   * @param _value ETH amount charged
   */
  event Bought(address indexed _by, address indexed _to, uint256 _amount, uint256 _value);

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
  constructor(address _tokenContract) {
    // verify the input is set
    require(_tokenContract != address(0), "token contract is not set");

    // verify input is valid smart contract of the expected interfaces
    require(
      IERC165(_tokenContract).supportsInterface(type(IMintableERC721).interfaceId)
      && IERC165(_tokenContract).supportsInterface(type(IMintableERC721).interfaceId),
      "unexpected token contract type"
    );

    // assign the addresses
    tokenContract = _tokenContract;
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
    return finalId > nextId? finalId + 1 - nextId: 0;
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
   *      in order to test how it affects the sale process
   *
   * @return true if sale is active (operational) and can sell tokens, false otherwise
   */
  function isActive() public view virtual returns(bool) {
    // evaluate sale state based on the internal state variables and return
    return itemPrice > 0 && nextId <= finalId && saleStart <= block.timestamp && saleEnd > block.timestamp;
  }

  /**
   * @dev Restricted access function to set up sale parameters, all at once,
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
   * @param _batchLimit how many tokens is allowed to buy in a single transaction,
   *      set to zero to disable the limit
   */
  function initialize(
    uint64 _itemPrice,  // <<<--- keep type in sync with the body type(uint64).max !!!
    uint32 _nextId,  // <<<--- keep type in sync with the body type(uint32).max !!!
    uint32 _finalId,  // <<<--- keep type in sync with the body type(uint32).max !!!
    uint32 _saleStart,  // <<<--- keep type in sync with the body type(uint32).max !!!
    uint32 _saleEnd,  // <<<--- keep type in sync with the body type(uint32).max !!!
    uint32 _batchLimit  // <<<--- keep type in sync with the body type(uint32).max !!!
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
    if(_batchLimit != type(uint32).max) {
      batchLimit = _batchLimit;
    }

    // emit an event - read values from the storage since not all of them might be set
    emit Initialized(
      msg.sender,
      itemPrice,
      nextId,
      finalId,
      saleStart,
      saleEnd,
      batchLimit
    );
  }

  /**
   * @notice Buys several (at least two) tokens in a batch.
   *      Accepts ETH as payment and mints a token
   *
   * @param _amount amount of tokens to create, two or more
   */
  function buy(uint32 _amount) public payable {
    // delegate to `buyTo` with the transaction sender set to be a recipient
    buyTo(msg.sender, _amount);
  }

  /**
   * @notice Buys several (at least two) tokens in a batch to an address specified.
   *      Accepts ETH as payment and mints tokens
   *
   * @param _to address to mint tokens to
   * @param _amount amount of tokens to create, two or more
   */
  function buyTo(address _to, uint32 _amount) public payable {
    // verify the inputs
    require(_to != address(0), "recipient not set");
    require(_amount > 1 && (batchLimit == 0 || _amount <= batchLimit), "incorrect amount");

    // verify there is enough items available to buy the amount
    // verifies sale is in active state under the hood
    require(itemsAvailable() >= _amount, "inactive sale or not enough items available");

    // calculate the total price required and validate the transaction value
    uint256 totalPrice = uint256(itemPrice) * _amount;
    require(msg.value >= totalPrice, "not enough funds");

    // mint token to to the recipient
    IMintableERC721(tokenContract).mintBatch(_to, nextId, _amount);

    // increment `nextId`
    nextId += _amount;
    // increment `soldCounter`
    soldCounter += _amount;

    // if ETH amount supplied exceeds the price
    if(msg.value > totalPrice) {
      // send excess amount back to sender
      payable(msg.sender).transfer(msg.value - totalPrice);
    }

    // emit en event
    emit Bought(msg.sender, _to, _amount, totalPrice);
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
    require(msg.value >= itemPrice, "not enough funds");

    // verify sale is in active state
    require(isActive(), "inactive sale");

    // mint token to the recipient
    IMintableERC721(tokenContract).mint(_to, nextId);

    // increment `nextId`
    nextId++;
    // increment `soldCounter`
    soldCounter++;

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

    // verify sale balance is positive (non-zero)
    require(_value > 0, "zero balance");

    // send the entire balance to the transaction sender
    payable(_to).transfer(_value);

    // emit en event
    emit Withdrawn(msg.sender, _to, _value);
  }
}
