// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

// fixed price PASS contract. Users pay specific erc20 tokens to purchase PASS from creator DAO
contract FixedPrice is
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
  event PermanentURI(string _value, uint256 indexed _id);
  event ChangeBeneficiary(address _newBeneficiary);
  event BaseURIFrozen();

  address public TIMELOCK;

  bool public baseURIFrozen;
  uint256 public rate; // price rate of erc20 tokens/PASS
  uint256 public maxSupply; // Maximum supply of PASS
  address public erc20; // erc20 token used to purchase PASS
  address payable public platform; // thePass platform's commission account
  address payable public receivingAddress; // thePass benfit receiving account
  uint256 public platformRate; // thePass platform's commission rate in pph

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
    uint256 _rate,
    uint256 _maxSupply,
    uint256 _platformRate
  ) public virtual initializer {
    __Ownable_init(_timelock);
    TIMELOCK = _timelock;

    __ERC721_init(_name, _symbol);
    tokenIdTracker = CountersUpgradeable.Counter({_value: 1});

    platform = _platform;
    platformRate = _platformRate;

    _baseURIextended = _bURI;
    erc20 = _erc20;
    rate = _rate;
    maxSupply = _maxSupply;
    receivingAddress = _receivingAddress;
  }

  // only contract owner can setTokenURI
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

  function changeBeneficiary(address payable _newBeneficiary)
    public
    nonReentrant
    onlyOwner
  {
    require(_newBeneficiary != address(0), "FixedPrice: new address is zero");

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

  // only contract owner can setTokenURI
  function setTokenURI(uint256 tokenId, string memory _tokenURI)
    public
    onlyOwner
  {
    _setTokenURI(tokenId, _tokenURI);
  }

  // user buy PASS from contract with specific erc20 tokens
  function mint() public nonReentrant returns (uint256 tokenId) {
    require(address(erc20) != address(0), "FixPrice: erc20 address is null.");
    require((tokenIdTracker.current() <= maxSupply), "exceeds maximum supply");

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

  function mintEth() public payable nonReentrant returns (uint256 tokenId) {
    require(address(erc20) == address(0), "ERC20 address is NOT null.");
    require((tokenIdTracker.current() <= maxSupply), "Exceeds maximum supply");

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

  // withdraw erc20 tokens from contract
  // anyone can withdraw reserve of erc20 tokens to receivingAddress
  function withdraw() public nonReentrant {
    if (address(erc20) == address(0)) {
      emit Withdraw(receivingAddress, _getBalance());

      (bool success, ) = payable(receivingAddress).call{value: _getBalance()}(
        ""
      );
      require(success, "Failed to send Ether");
    } else {
      uint256 amount = IERC20Upgradeable(erc20).balanceOf(address(this)); // get the amount of erc20 tokens reserved in contract
      IERC20Upgradeable(erc20).safeTransfer(receivingAddress, amount); // transfer erc20 tokens to contract owner address

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
