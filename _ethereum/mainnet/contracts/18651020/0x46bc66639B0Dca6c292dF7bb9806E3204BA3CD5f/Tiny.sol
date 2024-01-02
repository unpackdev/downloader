// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Ownable2Step.sol";
import "./ERC2981.sol";
import "./Strings.sol";

contract TinyBlazers is
  ERC2981,
  ReentrancyGuard,
  Ownable2Step,
  ERC721Enumerable
{
  using Strings for uint256;

  uint256 public MAX_SUPPLY = 2000;
  uint8 public mintableTokenPerWL = 1;
  uint8 public mintableTokenForEachAddress = 3;
  string private _contractURI;
  mapping(address => uint8) private whitelistMintCount;
  mapping(address => uint8) private publicMintCount;

  uint256 public PublicMintPrice = 0;
  uint256 public WhitelistMintPrice = 0;

  string public BaseURI;
  string public NotRevealedURI;
  bytes32 public merkleRoot;
  bool private pubSaleActive;
  enum ContractStatus {
    DEPLOY,
    WL,
    SALE,
    SOLD
  }

  bool public REVEAL;
  ContractStatus public contractStatus;

  constructor() ERC721('Tiny Blazers', 'Tiny') {
    contractStatus = ContractStatus.DEPLOY;
    _setDefaultRoyalty(msg.sender, 300);
  }

  function whitelistMint(
    bytes32[] calldata _merkleProof,
    uint8 _quantity
  ) external payable nonReentrant {
    require(verifyAddress(_merkleProof, msg.sender), 'Tiny: INVALID_PROOF');
    require(contractStatus != ContractStatus.SOLD, 'Tiny: sold out');
    require(
      contractStatus == ContractStatus.WL,
      'Tiny: whitelist not started or is ended'
    );
    require(msg.value >= PublicMintPrice, 'Tiny: you need to send more ETH');
    require(
      totalSupply() + mintableTokenPerWL <= MAX_SUPPLY,
      'Tiny: max supply exceed'
    );
    require(
      whitelistMintCount[msg.sender] + _quantity <= mintableTokenPerWL,
      'Tiny: max limit for minting reached'
    );
    _mintToken(msg.sender, _quantity, true);
  }

  function mint(uint8 _quantity) external payable nonReentrant {
    require(contractStatus != ContractStatus.SOLD, 'Tiny: sold out');
    require(contractStatus == ContractStatus.SALE, 'Tiny: sale not started');
    uint256 _price = PublicMintPrice * _quantity;
    require(msg.value >= _price, 'Tiny: you need to send more ETH');
    require(totalSupply() + _quantity <= MAX_SUPPLY, 'Tiny: max supply exceed');
    require(_quantity > 0, 'Tiny: mint at least 1 token');
    require(
      publicMintCount[msg.sender] + _quantity <= mintableTokenForEachAddress,
      'Tiny: max limit for minting reached'
    );
    _mintToken(msg.sender, _quantity, false);
  }

  function _mintToken(
    address _address,
    uint8 _quantity,
    bool _isWhitelistMint
  ) private {
    for (uint8 i = 0; i < _quantity; ) {
      uint256 mintIndex = totalSupply();
      _safeMint(_address, mintIndex);
      unchecked {
        i++;
      }
    }

    uint256 _price = _isWhitelistMint
      ? WhitelistMintPrice * _quantity
      : PublicMintPrice * _quantity;

    if (_price == 0) {
      handleMintWithZeroPrice(_address, _quantity, _isWhitelistMint);
    } else {
      handleMintWithNonZeroPrice(_address, _quantity, _price, _isWhitelistMint);
    }
  }

  function handleMintWithZeroPrice(
    address _address,
    uint8 _quantity,
    bool _isWhitelistMint
  ) private {
    if (totalSupply() + _quantity == MAX_SUPPLY) {
      contractStatus = ContractStatus.SOLD;
    }

    if (_isWhitelistMint) {
      whitelistMintCount[_address] += _quantity;
    } else {
      publicMintCount[_address] += _quantity;
    }
  }

  function handleMintWithNonZeroPrice(
    address _address,
    uint8 _quantity,
    uint256 _price,
    bool _isWhitelistMint
  ) private {
    (bool sent, ) = _address.call{value: msg.value - _price}('');
    require(sent, 'Tiny: TX_FAILED');
    handleMintWithZeroPrice(_address, _quantity, _isWhitelistMint);
  }

  function arrayQuantity(
    uint8[] memory _quantityArray
  ) private pure returns (uint256) {
    uint256 _quantity;
    for (uint8 i; i < _quantityArray.length; ) {
      _quantity += _quantityArray[i];
      unchecked {
        i++;
      }
    }
    return _quantity;
  }

  function privateMint(
    address[] memory _addresses,
    uint8[] memory _quantities
  ) external onlyOwner nonReentrant {
    require(contractStatus != ContractStatus.SOLD, 'Tiny: sold out');
    require(
      _quantities.length == _addresses.length,
      'Tiny: array length are not equal'
    );
    uint256 _quantity = arrayQuantity(_quantities);
    require(_quantity > 0, 'Tiny: mint at least 1 token');

    require(totalSupply() + _quantity <= MAX_SUPPLY, 'Tiny: max supply exceed');
    if (totalSupply() + _quantity == MAX_SUPPLY) {
      contractStatus = ContractStatus.SOLD;
    }

    for (uint8 i; i < _addresses.length; ) {
      require(_addresses[i] != address(0), 'Tiny: zero address not allowed');
      for (uint8 j = 0; j < _quantities[i]; ) {
        uint256 mintIndex = totalSupply();
        _safeMint(_addresses[i], mintIndex);
        unchecked {
          j++;
        }
      }
      unchecked {
        i++;
      }
    }
  }

  function setMerkleRoot(bytes32 _merkleRootHash) external onlyOwner {
    merkleRoot = _merkleRootHash;
  }

  function verifyAddress(
    bytes32[] calldata _merkleProof,
    address _address
  ) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_address));
    return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
  }

  function setMintableTokenForEachAddress(
    uint8 _newMintableTokenForEachAddress
  ) external onlyOwner {
    mintableTokenForEachAddress = _newMintableTokenForEachAddress;
  }

  function setMintableTokenPerWL(
    uint8 _newMintableTokenPerWL
  ) external onlyOwner {
    mintableTokenPerWL = _newMintableTokenPerWL;
  }

  function setPublicMintPrice(uint256 _newPublicMintPrice) external onlyOwner {
    PublicMintPrice = _newPublicMintPrice;
  }

  function setWhitelistMintPrice(
    uint256 _newWhitelistMintPrice
  ) external onlyOwner {
    WhitelistMintPrice = _newWhitelistMintPrice;
  }

  function withdraw(uint256 _value) external onlyOwner {
    require(_value > 0, 'Tiny: value must be greater than zero');
    require(address(this).balance >= _value, 'Tiny: insufficient balance');

    payable(owner()).transfer(_value);
  }

  function startSale() external onlyOwner {
    require(!pubSaleActive, 'Tiny: public sale already active');
    pubSaleActive = true;
    contractStatus = ContractStatus.SALE;
  }

  function startWhitelist() external onlyOwner {
    require(
      !pubSaleActive,
      'Tiny: sale has been started, can not start whitelist'
    );
    contractStatus = ContractStatus.WL;
  }

  function startReveal() external onlyOwner {
    REVEAL = true;
  }

  function setNotRevealedURI(string memory _URI) external onlyOwner {
    NotRevealedURI = _URI;
  }

  function setBaseURI(string memory _URI) external onlyOwner {
    BaseURI = _URI;
  }

  function setContractURI(string calldata _newContractURI) external onlyOwner {
    _contractURI = _newContractURI;
  }

  function tokenURI(
    uint256 _id
  ) public view override(ERC721) returns (string memory) {
    require(_exists(_id), 'Tiny: invalid token ID');
    return
      REVEAL
        ? string(abi.encodePacked(BaseURI, _id.toString()))
        : NotRevealedURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function burn(uint256 _quantity) external onlyOwner nonReentrant {
    require(
      contractStatus != ContractStatus.SOLD,
      'Tiny: contract is sold out'
    );

    require(_quantity != 0, 'Tiny: quantity should not equal zero');

    uint256 remainingSupply = MAX_SUPPLY - totalSupply();

    require(
      _quantity <= remainingSupply,
      'Tiny: quantity exceeds available supply'
    );

    if (_quantity == remainingSupply) {
      contractStatus = ContractStatus.SOLD;
    }

    MAX_SUPPLY -= _quantity;
  }

  function setRoyaltyInfo(
    address _receiver,
    uint96 _royaltyFeesInBips
  ) external onlyOwner {
    require(_receiver != address(0), 'Tiny: zero address not allowed');
    _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal override(ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721Enumerable, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _mint(address to, uint256 tokenId) internal virtual override {
    uint256 newTokenId = tokenId + 1;
    super._mint(to, newTokenId);
  }
}
