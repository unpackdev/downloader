// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./ERC721A.sol";

contract Avatar is ERC721A, Ownable, ReentrancyGuard, Pausable {
  event AvatarClaimed(address from, address to, uint256 indexed attr, uint256 indexed id);

  uint256 public constant MAX_SUPPLY = 1000;
  bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

  uint256 private _price = 0.0025 ether;
  uint256 private _maxPerMint = 5;
  string private _contractBaseURI;
  address payable private _paymentSplitter;

  mapping(uint256 => uint256) private _attributes;
  mapping(uint256 => bool) private _used;
  mapping(address => bool) private _admins;

  constructor(string memory name, string memory symbol, string memory baseURI) ERC721A(name, symbol) {
    _contractBaseURI = baseURI;
    _pause();
  }

  function adminMint(address to, uint256[] memory attributes) external nonReentrant adminOrOwner {
    _tokenMint(to, attributes);
  }

  // Standard minting function. Can be paused.
  function mint(uint256[] memory attributes) external payable nonReentrant whenNotPaused {
    uint256 quantity = attributes.length;
    require(_price * quantity <= msg.value, "Insufficient funds sent");
    _tokenMint(msg.sender, attributes);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
    require(_attributes[tokenId] > 0, "Invalid token attribute");
    string memory currentBaseURI = _contractBaseURI;
    return
      bytes(currentBaseURI).length > 0
      ? string(
        abi.encodePacked(
          currentBaseURI,
            _hexString(_attributes[tokenId]),
          ".json" // By default no extension is used, this makes it a json type
        )
      )
      : "";
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function withdraw() external onlyOwner {
    bool success;
    if (_paymentSplitter == address(0x0)) {
      (success, ) = payable(msg.sender).call{value: address(this).balance}("");
    } else {
      (success, ) = _paymentSplitter.call{value: address(this).balance}("");
    }
    require(success, "Transfer failed.");
  }

  function setPrice(uint256 price) external onlyOwner {
    _price = price;
  }

  function getPrice() external view returns (uint256) {
    return _price;
  }

  function setMaxPerMint(uint256 max) external onlyOwner {
    _maxPerMint = max;
  }

  function getMaxPerMint() external view returns (uint256) {
    return _maxPerMint;
  }

  function setPaymentSplitter(address payable paymentSplitter) external onlyOwner {
    _paymentSplitter = paymentSplitter;
  }

  function addAdmin(address admin) external onlyOwner {
    _admins[admin] = true;
  }

  function removeAdmin(address admin) external onlyOwner {
    delete _admins[admin];
  }

  function getUri() external onlyOwner view returns (string memory) {
    return _contractBaseURI;
  }

  function setUri(string memory uri) external onlyOwner {
    _contractBaseURI = uri;
  }

  // Required by ERC721A
  function _baseURI() internal view override returns (string memory) {
    return _contractBaseURI;
  }

  function _tokenMint(address to, uint256[] memory attributes) internal {
    uint256 quantity = attributes.length;
    require(quantity > 0, "Attributes cannot be empty");
    require(quantity <= _maxPerMint, "Cannot mint that many at once");

    uint256 totalMinted = totalSupply();
    require(totalMinted + quantity < MAX_SUPPLY, "Not enough tokens left to mint");

    // Unlikely to overflow
    unchecked {
      for (uint256 i = 0; i < quantity; i++) {
        uint256 attr = attributes[i];
        uint256 lookup = _cleanAttribute(attr);
        require(!_used[lookup], "Attribute has already been claimed");
        _attributes[_currentIndex + i] = attr;
        _used[lookup] = true;
      }
    }
    _safeMint(to, quantity);
  }

  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal override {
    // We only support Claim events during minting
    for (uint256 i = 0; i < quantity; i++) {
      uint256 tid = startTokenId + i;
      uint256 attr = _attributes[tid];
      emit AvatarClaimed(from, to, attr, tid);
    }
  }

  function _hexString(uint256 value) internal pure returns (string memory) {
    bytes memory buffer = new bytes(64);
    for (uint256 i = 63; i > 0; --i) {
      buffer[i] = _HEX_SYMBOLS[value & 0xf];
      value >>= 4;
    }
    buffer[0] = _HEX_SYMBOLS[value & 0xf];
    return string(buffer);
  }

  function _cleanAttribute(uint256 value) internal pure returns (uint256) {
    return value & 0x00000000000000000000000000000000000000000000000000ff00ff00ff00ff;
  }

  modifier adminOrOwner() {
    require(msg.sender == owner() || _admins[msg.sender], "Unauthorized");
    _;
  }
}
