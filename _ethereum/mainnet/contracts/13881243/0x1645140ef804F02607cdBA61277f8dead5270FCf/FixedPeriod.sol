// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

/**
 * @dev Users pay specific erc20 tokens to purchase PASS from creator DAO in a fixed period.
 * The price of PASS decreases linerly over time.
 * Price formular: f(x) = initialRate - solpe * x
 * f(x) = PASS Price when current time is x + startTime
 * startTime <= x <= endTime
 */
contract FixedPeriod is
  Initializable,
  ContextUpgradeable,
  OwnableUpgradeable,
  ERC721Upgradeable,
  ReentrancyGuardUpgradeable
{
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using StringsUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event Mint(address indexed from, uint256 indexed tokenId);
  event Withdraw(address indexed to, uint256 amount);
  event SetBaseURI(string baseURI_);
  event ChangeBeneficiary(address _newBeneficiary);
  event PermanentURI(string _value, uint256 indexed _id);
  event BaseURIFrozen();
  event ChangeBeneficiaryUnlock(uint256 cooldownStartTimestamp);

  address public TIMELOCK;

  bool public baseURIFrozen;
  uint256 public initialRate; // initial exchange rate of erc20 tokens/PASS
  uint256 public startTime; // start time of PASS sales
  uint256 public endTime; // endTime = startTime + salesValidity
  uint256 public maxSupply; // Maximum supply of PASS
  uint256 public slope; // slope = initialRate / salesValidity
  address public erc20; // erc20 token used to purchase PASS
  address payable public platform; // The Pass platform commission account
  address payable public receivingAddress; // creator's receivingAddress account
  uint256 public platformRate; // The Pass platform commission rate in pph

  // Optional mapping for token URIs
  mapping(uint256 => string) private _tokenURIs;

  // Base URI
  string private _baseURIextended;

  // token id counter. For erc721 contract, PASS number = token id
  CountersUpgradeable.Counter private tokenIdTracker;

  function initialize(
    string memory _name,
    string memory _symbol,
    string memory _bURI,
    address _timelock,
    address _erc20,
    address payable _platform,
    address payable _receivingAddress,
    uint256 _initialRate,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _maxSupply,
    uint256 _platformRate
  ) public virtual initializer {
    __Ownable_init(_timelock);

    __ERC721_init(_name, _symbol);
    tokenIdTracker = CountersUpgradeable.Counter({_value: 1});

    platform = _platform;
    platformRate = _platformRate;

    _baseURIextended = _bURI;
    erc20 = _erc20;
    initialRate = _initialRate;
    startTime = _startTime;
    endTime = _endTime;
    slope = _initialRate / (_endTime - _startTime);
    maxSupply = _maxSupply;
    receivingAddress = _receivingAddress;
  }

  // only contract admin can set Base URI
  function setBaseURI(string memory baseURI_) public onlyOwner {
    require(!baseURIFrozen, "baseURI has been frozen");
    _baseURIextended = baseURI_;
    emit SetBaseURI(baseURI_);
  }

  // only contract admin can freeze Base URI
  function freezeBaseURI() public onlyOwner {
    require(!baseURIFrozen, "baseURI has been frozen");
    baseURIFrozen = true;
    emit BaseURIFrozen();
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIextended;
  }

  function _getBalance() internal view returns (uint256) {
    return address(this).balance;
  }

  function getCurrentCostToMint() public view returns (uint256 cost) {
    return _getCurrentCostToMint();
  }

  function _getCurrentCostToMint() internal view returns (uint256) {
    require(
      (block.timestamp >= startTime) && (block.timestamp <= endTime),
      "Not in the period"
    );
    return initialRate - (slope * (block.timestamp - startTime));
  }

  // only contract admin can change receivingAddress account
  function changeBeneficiary(address payable _newBeneficiary)
    public
    nonReentrant
    onlyOwner
  {
    require(_newBeneficiary != address(0), "FixedPeriod: new address is zero");

    receivingAddress = _newBeneficiary;
    emit ChangeBeneficiary(_newBeneficiary);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "URI query for nonexistent token");

    string memory _tokenURI = _tokenURIs[tokenId];

    // If token URI exists, return the token URI.
    if (bytes(_tokenURI).length > 0) {
      return _tokenURI;
    } else {
      return super.tokenURI(tokenId);
    }
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI)
    internal
    virtual
  {
    require(_exists(tokenId), "URI set of nonexistent token");

    string memory tokenURI_ = _tokenURIs[tokenId];
    require(bytes(tokenURI_).length == 0, "already set TokenURI");

    _tokenURIs[tokenId] = _tokenURI;
    emit PermanentURI(_tokenURI, tokenId);
  }

  // only contract admin can set Token URI
  function setTokenURI(uint256 tokenId, string memory _tokenURI)
    public
    onlyOwner
  {
    _setTokenURI(tokenId, _tokenURI);
  }

  // user buy PASS from contract with specific erc20 tokens
  function mint() public nonReentrant returns (uint256 tokenId) {
    require(address(erc20) != address(0), "ERC20 address is null.");
    require((tokenIdTracker.current() <= maxSupply), "Exceeds maximum supply");
    uint256 rate = _getCurrentCostToMint();

    tokenId = tokenIdTracker.current(); // accumulate the token id

    IERC20Upgradeable(erc20).safeTransferFrom(
      _msgSender(),
      address(this),
      rate
    );

    if (platform != address(0)) {
      IERC20Upgradeable(erc20).safeTransfer(
        platform,
        (rate * platformRate) / 100
      );
    }

    _safeMint(_msgSender(), tokenId); // mint PASS to user address
    emit Mint(_msgSender(), tokenId);

    tokenIdTracker.increment(); // automate token id increment
  }

  // user buy PASS from contract with ETH
  function mintEth() public payable nonReentrant returns (uint256 tokenId) {
    require(address(erc20) == address(0), "ERC20 address is NOT null.");
    require((tokenIdTracker.current() <= maxSupply), "Exceeds maximum supply");

    uint256 rate = _getCurrentCostToMint();
    require(msg.value >= rate, "Not enough ether sent.");
    if (msg.value - rate > 0) {
      (bool success, ) = payable(_msgSender()).call{value: msg.value - rate}(
        ""
      );
      require(success, "Failed to send Ether");
    }

    tokenId = tokenIdTracker.current(); // accumulate the token id

    _safeMint(_msgSender(), tokenId); // mint PASS to user address
    emit Mint(_msgSender(), tokenId);

    if (platform != address(0)) {
      (bool success, ) = platform.call{value: (rate * (platformRate)) / 100}(
        ""
      );
      require(success, "Failed to send Ether");
    }

    tokenIdTracker.increment(); // automate token id increment
  }

  // anyone can withdraw reserve of erc20 tokens/ETH to creator's receivingAddress account
  function withdraw() public nonReentrant {
    if (address(erc20) == address(0)) {
      uint256 amount = _getBalance();
      (bool success, ) = receivingAddress.call{value: amount}(""); // withdraw ETH to receivingAddress account
      require(success, "Failed to send Ether");

      emit Withdraw(receivingAddress, amount);
    } else {
      uint256 amount = IERC20Upgradeable(erc20).balanceOf(address(this));
      IERC20Upgradeable(erc20).safeTransfer(receivingAddress, amount); // withdraw erc20 tokens to receivingAddress account

      emit Withdraw(receivingAddress, amount);
    }
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Upgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
