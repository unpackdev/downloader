// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract Gladiators is Ownable, ERC721Enumerable, ERC721Pausable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdTracker;

  // Maximum elements
  uint256 public maxElements = 10000;

  // Price per mint
  uint256 public mintPrice = 6 * 10**16;

  // Maximum mint amount per one wallet
  uint8 public maxMintAtOnce = 5;

  // Creator's address
  address public creatorAddress;

  // Dev Address
  address public devAddress;
  
  // baseTokenURI
  string public baseTokenURI;
  

  struct NFT {
    string hash_value;
    address nft_creator;
  }
  NFT[] public nft_list;

  event CreateGladiator(uint256 indexed id);

  constructor(
    string memory _name,
    string memory _symbol,
    string memory baseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(baseURI);
    pause(true);
  }

  /**
   * @dev Allow mint when sale is open
   */
  modifier saleIsOpen {
    require(_totalSupply() <= maxElements, "Sale end");
    if (_msgSender() != owner()) {
      require(!paused(), "Pausable: paused");
    }
    _;
  }

  /**
   * @dev Get `totalSupply`
   */
  function _totalSupply() internal view returns (uint) {
    return _tokenIdTracker.current();
  }

  /**
   * @dev Get `totalMint`
   */
  function totalMint() public view returns (uint256) {
    return _totalSupply();
  }

  /**
   * @dev Create `hash_list`
   * `amount` must be less than `maxMintAtOnce`
   */
  function batchCreate(string[] memory hash_list, uint amount) public {
    require(amount < maxMintAtOnce, 'Amount is less than maxMintAtOnce');
    for(uint i = 0 ; i < amount ; i++) {
      _create(hash_list[i]);
    }
  }

  /**
   * @dev Set `nft_list`
   */
  function _create(string memory hash_val) private {
    NFT memory temp = NFT(hash_val, msg.sender);
    nft_list.push(temp);
  }

  /**
   * @dev Mint NFTs
   * Payable function
   * Sum of `total` and `_count` must be less than `maxElements`
   * `total` must be less than `maxElements`
   * `_count` must be less than `maxMintAtOnce`
   * `msg.value` must be more than total price
   */
  function mint(address _to, uint256 _count) public payable saleIsOpen {
    uint256 total = _totalSupply();
    require(total + _count <= maxElements, "Max limit");
    require(total <= maxElements, "Sale end");
    require(_count <= maxMintAtOnce, "Exceeds number");
    require(msg.value >= price(_count), "Value below price");

    for (uint256 i = 0; i < _count; i++) {
      _mintAnElement(_to);
    }
  }

  /**
   * @dev Mint one element
   */
  function _mintAnElement(address _to) private {
    uint id = _totalSupply();
    _tokenIdTracker.increment();
    _safeMint(_to, id);
    emit CreateGladiator(id);
  }

  /**
   * @dev Get total price
   * `maxMintAtOnce` must not be zero
   */
  function price(uint256 _count) public view returns (uint256) {
    return mintPrice.mul(_count);
  }

  /**
   * @dev Get `baseTokenURI`
   * Overrided
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  /**
   * @dev Set `baseTokenURI`
   * Only `owner` can call
   */
  function setBaseURI(string memory baseURI) public onlyOwner {
    baseTokenURI = baseURI;
  }

  /**
   * @dev Get owner of wallet
   */
  function walletOfOwner(address _owner) external view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);

    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }

    return tokensId;
  }

  /**
   * @dev Pause
   * Only `owner` can call
   */
  function pause(bool val) public onlyOwner {
    if (val == true) {
      _pause();
      return;
    }
    _unpause();
  }

  /**
   * @dev Withdraw all
   * Only `owner` can call
   */
  function withdrawAll() public onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0);
    _widthdraw(devAddress, balance.mul(66).div(100));
    _widthdraw(creatorAddress, address(this).balance);
  }

  /**
   * @dev Withdraw
   */
  function _widthdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Transfer failed.");
  }

  /**
   * @dev BeforeTokenTransfer
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override( ERC721Enumerable, ERC721Pausable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev supportsInterface
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev Set wallet of dev
   * Only `owner` can call
   */
  function setDevWallet(address _new_dev) public onlyOwner {
    devAddress = _new_dev;
  }

  /**
   * @dev Set wallet of creator
   * Only `owner` can call
   */
  function setCreatorWallet(address _new_creator) public onlyOwner {
    creatorAddress = _new_creator;
  }

  /**
   * @dev Set `maxMintAtOnce`
   * Only `owner` can call
   * `maxMintAtOnce` must not be zero
   */
  function setMaxMintAtOnce(uint8 _maxMintAtOnce) external onlyOwner {
    require(_maxMintAtOnce > 0, "Gladiator: MAX_MINT_INVALID");
    maxMintAtOnce = _maxMintAtOnce;
  }

  /**
   * @dev Set `mintPrice`
   * Only `owner` can call
   * `mintPrice` must not be zero
   */
  function setMintPrice(uint8 _mintPrice) external onlyOwner {
    require(_mintPrice > 0, "Gladiator: MINT_PRICE_INVALID");
    maxMintAtOnce = _mintPrice;
  }

  /**
   * @dev Set `maxMintAtOnce`
   * Only `owner` can call
   * `maxMintAtOnce` must not be zero
   */
  function setMaxElements(uint8 _maxElements) external onlyOwner {
    require(_maxElements > 0, "Gladiator: MAX_ELEMENTS_INVALID");
    maxElements = _maxElements;
  }
}