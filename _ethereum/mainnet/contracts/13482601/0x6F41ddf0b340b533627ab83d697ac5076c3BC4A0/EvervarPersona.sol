// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

contract EvervarPersona is ERC721Enumerable, Ownable {
  using Counters for Counters.Counter;
  using SafeMath for uint256;
  using Strings for uint256;
  using ECDSA for bytes32;

  Counters.Counter public tokenIdCounter;
  Counters.Counter public reserveIdCounter;

  uint256 public constant MAX_PERSONA = 10000;
  uint256 public constant RESERVED_MINTS = 200;

  bool public SALE_IS_ACTIVE = false;
  bool public PRESALE_IS_ACTIVE = false;
  uint256 public LIMIT_PER_ACCOUNT = 10;
  uint256 public RENAME_PRICE = 10000000000000000; // 0.01 ETH
  uint256 public mintPrice = 50000000000000000; // 0.05 ETH

  mapping(address => uint256) public earlyMintAllowance;
  mapping(address => uint256) private _publicSaleMintCounts;

  event NameAndDescription(
    uint256 indexed _tokenId,
    string _name,
    string _description
  );

  string private _baseTokenURI;

  constructor() ERC721("Evervar:Persona", "E:P") {
    tokenIdCounter.increment();
  }

  function mintPersona(uint256 _count) external payable {
    require(SALE_IS_ACTIVE, "Sale not active");
    require(
      _count <= LIMIT_PER_ACCOUNT,
      "You can't mint more than 10 personas at once"
    );

    _mintPersona(_msgSender(), _count);

    _publicSaleMintCounts[_msgSender()] += _count;
  }

  function setRenamePrice(uint256 _price) public onlyOwner {
    RENAME_PRICE = _price;
  }

  function setNameAndDescription(
    uint256 tokenId,
    string memory name,
    string memory description
  ) public payable {
    address owner = ERC721.ownerOf(tokenId);

    require(
      _msgSender() == owner,
      "You cannot set the name for the persona of someone else."
    );

    uint256 amountPaid = msg.value;

    require(
      amountPaid == RENAME_PRICE,
      "Please send enough ETH to cover the costs"
    );

    emit NameAndDescription(tokenId, name, description);
  }

  function earlyMintPersona(uint256 _count) external payable {
    require(PRESALE_IS_ACTIVE, "Sale not active");
    require(_count <= 5, "You can't mint more than 5 personas at once");

    _mintPersona(_msgSender(), _count);
  }

  function _mintPersona(address to, uint256 _count) internal virtual {
    require(_count > 0, "Count too low");
    require(msg.value >= price(_count), "Value below price");
    require(
      tokenIdCounter.current().sub(1).add(RESERVED_MINTS).add(_count) <=
        MAX_PERSONA,
      "Exceeds available mints"
    );

    for (uint256 i = 0; i < _count; i++) {
      _safeMint(to, tokenIdCounter.current().add(RESERVED_MINTS));
      tokenIdCounter.increment();
    }
  }

  function reservePersona(address reserveAddress, uint256 _amount)
    external
    onlyOwner
  {
    require(
      reserveIdCounter.current() + _amount <= RESERVED_MINTS,
      "There isnt anymore reserved left to mint"
    );
    for (uint256 i = 0; i < _amount; i++) {
      _safeMint(reserveAddress, reserveIdCounter.current());
      reserveIdCounter.increment();
    }
  }

  function price(uint256 _count) public view returns (uint256) {
    return mintPrice * _count;
  }

  function setEarlyMintAllowance(
    address[] calldata earlyMintAddresses,
    uint256[] calldata allowableAmounts
  ) external onlyOwner {
    for (uint256 i = 0; i < earlyMintAddresses.length; i++) {
      earlyMintAllowance[earlyMintAddresses[i]] = allowableAmounts[i];
    }
  }

  function setMintLimit(uint256 _mintLimit) external onlyOwner {
    LIMIT_PER_ACCOUNT = _mintLimit;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function toggleSaleStatus() external onlyOwner {
    SALE_IS_ACTIVE = !SALE_IS_ACTIVE;
  }

  function togglePreSaleStatus() external onlyOwner {
    PRESALE_IS_ACTIVE = !PRESALE_IS_ACTIVE;
  }

  function withdrawAll(address payable _to) public payable onlyOwner {
    (bool sent, ) = _to.call{value: address(this).balance}("");
    require(sent);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
  {
    return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
  }
}
