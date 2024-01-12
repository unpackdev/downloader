// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

/*
  We can save on gas by declaring our errors and reverting
  on these instead of using requires. Thanks, Impostors! :)
*/

error CollectionTooSmall();
error FailedToWithdraw();
error InvalidValue();
error MaxAlreadyMinted();
error NotControllerOrOwner();
error OutOfTokens();
error PublicSaleNotActive();

/**
  @title K-NOR Genesis
  @author @cryptoro311
  @dev Based off the Azuki ERC721A contract for gas optimization
*/
contract KnorGenesis is ERC721A, Ownable, ReentrancyGuard {
  constructor() ERC721A("K-NOR Genesis", "KNOR") {}

  /// The total cap of tokens that can be minted in this collection
  uint256 public maxSupply = 200;

  /**
    Overwriting the ERC721A `_startTokenId` function to start with token 1 instead of 0

    @return The initial starting token id of the collection
  */
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /**
    Set the max supply of this collection

    @param _size The new token cap size

    @dev This is for testing failure states around token supply and not for production
  */
  function setMaxSupply(uint256 _size) public onlyOwner {
    if (_size < _nextTokenId() - _startTokenId()) revert CollectionTooSmall();
    maxSupply = _size;
  }

  //
  // Contract administration
  //

  /**
    A mapping of addresses that are allowed to perform various controlling
    functions of this contract.
  */
  mapping(address => bool) public controllers;

  /**
    A modifier that verifies either an owner or controller is performing an action
  */
  modifier onlyControllersOrOwner() {
    if (msg.sender != owner() && !controllers[msg.sender]) revert NotControllerOrOwner();
    _;
  }

  /**
    Add/remove a new controller for the collection that is allowed to perform various
    administrative tasks.

    @param _controller The address of our new controller
    @param _enabled Whether we want to enable or disable this controller
  */
  function setController(address _controller, bool _enabled) external onlyOwner {
    controllers[_controller] = _enabled;
  }

  /**
    A simple view into whether or not an address is set as a controller

    @param _controller The address of our potential controller

    @return Whether or not this address is a controller
  */
  function isController(address _controller) public view returns (bool) {
    return controllers[_controller] == true;
  }

  /**
    Withdraw money from this smart contract and into the owners wallet

    @dev This can only be run by the owner and the entire balance must be withdrawn at once
  */
  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    if (!success) revert FailedToWithdraw();
  }

  //
  // Metadata
  //

  /// The url where our metadata is hosted at (should end in a slash)
  string public baseTokenURI;

  /**
    Update the url that we host our metadata (json files) at

    @param _uri Our new hosting address
  */
  function setBaseTokenURI(string memory _uri) external onlyControllersOrOwner {
    baseTokenURI = _uri;
  }

  /**
    Overrides the ERC721A contract's `_baseURI` function to use our custom url

    @return The base url that our metadata (json files) is hosted at
  */
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  //
  // Public Sale
  //

  /// Our initial mint price
  uint256 public mintPrice = 0.08 ether;
  /// The mint limit for each wallet
  uint256 public maxPerWallet = 3;
  /// The start time of our public sale
  uint256 public publicSaleStartTime;
  /// A flag stating whether or not our public sale is enabled
  bool public publicSaleEnabled;

  /**
    A modifier that makes sure that our public sale is active before
    performing various functions
  */
  modifier activePublicSale() {
    if (!publicSaleEnabled || publicSaleStartTime == 0 || block.timestamp < publicSaleStartTime) {
      revert PublicSaleNotActive();
    }
    _;
  }

  /**
    A public function that checks to see if the public sale is currently active

    @return Whether or not our public sale is active
  */
  function isPublicSaleActive() public view returns (bool) {
    return publicSaleEnabled && publicSaleStartTime > 0 && block.timestamp >= publicSaleStartTime;
  }

  /**
    Update our public sale's status & start time

    @param _enabled Whether or not we want to enable the public mint
    @param _time Once enabled, what time should we allow minting at
  */
  function setPublicSale(bool _enabled, uint256 _time) external onlyControllersOrOwner {
    publicSaleEnabled = _enabled;
    publicSaleStartTime = _time;
  }

  /**
    Update our mint price

    @param _price The new minting price for our collection
  */
  function setMintPrice(uint256 _price) external onlyControllersOrOwner {
    mintPrice = _price;
  }

  /**
    Update the amount of tokens a single wallet can mint

    @param _per The amount of tokens per wallet
  */
  function setMaxPerWallet(uint256 _per) external onlyControllersOrOwner {
    maxPerWallet = _per;
  }

  /**
    Update the url that we host our metadata (json files) at

    @param _owner The address we're checking

    @return The number of tokens minted by a specific address
  */
  function numberMinted(address _owner) public view returns (uint256) {
    return _numberMinted(_owner);
  }

  /**
    Mint a token from this collection. Mints will happen in order (1, 2, 3, etc.)
    but actual metadata will be randomized.

    @param _quantity The amount you want to mint in this transaction
  */
  function mint(uint256 _quantity) external payable activePublicSale {
    if (totalSupply() + _quantity > maxSupply) revert OutOfTokens();
    if (numberMinted(msg.sender) + _quantity > maxPerWallet) revert MaxAlreadyMinted();
    if (msg.value != mintPrice * _quantity) revert InvalidValue();

    _mint(msg.sender, _quantity);
  }
}
