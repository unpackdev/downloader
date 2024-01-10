// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract NFT is ERC721, ERC721Enumerable, Ownable {
  using Strings for uint256;
  using SafeMath for uint256;

  string private _baseURIExtended =
    'ipfs://QmPfSkotTWofTDiwdkdcfYezdtcdt47ec8mgTcaAi5ToKV/';
  uint256 public MAX_SUPPLY = 1000;
  uint256 public tierSupply = 0;
  uint256 public maxBalance = 1;

  bool public isActive = false;
  uint256 public price = 0.15 ether;
  uint256 public maxMint = 1;
  uint256 public startAt = 0;

  bool public whiteListIsActive = false;
  uint256 public whiteListPrice = 0.15 ether;
  uint256 public whiteListMaxMint = 1;
  uint256 public whiteListStartAt = 0;

  address private feeAddress = address(0);

  mapping(address => bool) internal whiteList;

  event Mint(uint256 tokenId, address owner);

  constructor(string memory _name, string memory _symbol)
    payable
    ERC721(_name, _symbol)
  {}

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIExtended;
  }

  function setBaseURI(string memory uri) public onlyOwner {
    _baseURIExtended = uri;
  }

  function setTierSupply(uint256 num) public onlyOwner {
    tierSupply = num;
  }

  function setMaxBalance(uint256 num) public onlyOwner {
    maxBalance = num;
  }

  function setFeeAddress(address _feeAddress) public onlyOwner {
    feeAddress = _feeAddress;
  }

  function withdraw(address to) public virtual onlyOwner {
    uint256 balance = address(this).balance;
    if (feeAddress == address(0)) {
      payable(to).transfer(balance);
      return;
    }
    uint256 fee = balance.div(20); // 5% = 1 / 20
    uint256 main = balance.sub(fee);
    payable(to).transfer(main);
    payable(feeAddress).transfer(fee);
  }

  function preserve(uint256 qty, address to) public virtual onlyOwner {
    require(totalSupply().add(qty) <= MAX_SUPPLY, 'NFT: sold out');
    _mint(qty, to);
  }

  function getTokenIdsByOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 count = balanceOf(_owner);
    uint256[] memory tokensIds = new uint256[](count);

    for (uint256 i; i < count; i++) {
      tokensIds[i] = tokenOfOwnerByIndex(_owner, i);
    }

    return tokensIds;
  }

  // 公售
  function toggleIsActive() public onlyOwner {
    isActive = !isActive;
  }

  function setPrice(uint256 num) public onlyOwner {
    price = num;
  }

  function setMaxMint(uint256 num) public onlyOwner {
    maxMint = num;
  }

  function setStartAt(uint256 timestamp) public onlyOwner {
    startAt = timestamp;
  }

  function mint(uint256 qty) external payable virtual {
    require(isActive && block.timestamp >= startAt, 'NFT: not on sale');
    uint256 currentSupply = totalSupply().add(qty);
    require(
      currentSupply <= MAX_SUPPLY && currentSupply <= tierSupply,
      'NFT: sold out'
    );
    require(
      balanceOf(msg.sender).add(qty) <= maxBalance,
      'NFT: exceed max balance'
    );
    require(qty <= maxMint, 'NFT: exceed max mint');
    require(msg.value >= price.mul(qty), 'NFT: insufficient ether');
    _mint(qty, msg.sender);
  }

  // 白名單
  function toggleWhiteListIsActive() public onlyOwner {
    whiteListIsActive = !whiteListIsActive;
  }

  function setWhiteListPrice(uint256 _price) public onlyOwner {
    whiteListPrice = _price;
  }

  function setWhiteListMaxMint(uint256 num) public onlyOwner {
    whiteListMaxMint = num;
  }

  function setWhiteListStartAt(uint256 timestamp) public onlyOwner {
    whiteListStartAt = timestamp;
  }

  function setWhiteList(address[] calldata list) external onlyOwner {
    for (uint256 i = 0; i < list.length; i++) {
      whiteList[list[i]] = true;
    }
  }

  function mintWhiteList(uint256 qty) external payable virtual {
    require(
      whiteListIsActive && block.timestamp >= whiteListStartAt,
      'NFT: not on sale'
    );
    require(whiteList[msg.sender], 'NFT: forbidden');
    uint256 currentSupply = totalSupply().add(qty);
    require(
      currentSupply <= MAX_SUPPLY && currentSupply <= tierSupply,
      'NFT: sold out'
    );
    require(
      balanceOf(msg.sender).add(qty) <= maxBalance,
      'NFT: exceed max balance'
    );
    require(qty <= maxMint, 'NFT: exceed max mint');
    require(msg.value >= price.mul(qty), 'NFT: insufficient ether');
    whiteList[msg.sender] = false;
    _mint(qty, msg.sender);
  }

  function _mint(uint256 quantity, address to) internal virtual {
    uint256 currentSupply = totalSupply();
    for (uint256 i = 0; i < quantity; i++) {
      uint256 tokenId = currentSupply + i;
      _safeMint(to, tokenId);
      emit Mint(tokenId, to);
    }
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      'ERC721Metadata: URI query for nonexistent token'
    );

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json'))
        : '';
  }

  // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
