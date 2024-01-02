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
  uint8 public mintableTokenPerPrivateMint = 1;
  uint8 public mintableTokenPerPublicMint = 1;
  string private _contractURI;
  mapping(address => uint8) public whitelistMintCount;
  mapping(address => uint8) public privateMintCount;
  mapping(address => uint8) public publicMintCount;

  uint256 public PublicMintPrice = 0;
  uint256 public WhitelistMintPrice = 0;
  uint256 public PrivateMintPrice = 0;

  string public BaseURI;
  string public NotRevealedURI;
  bytes32 public whitelistMintMerkleRoot;
  bytes32 public privateMintMerkleRoot;

  bool private pubSaleActive;
  enum ContractStatus {
    DEPLOY,
    PRIVATE,
    WL,
    SALE,
    SOLD
  }

  enum MintStatus {
    WL,
    PRIVATE,
    PUBLIC
  }

  bool public REVEAL;
  ContractStatus public contractStatus;

  constructor() ERC721('Tiny Blazers', 'Tiny') {
    contractStatus = ContractStatus.DEPLOY;
    _setDefaultRoyalty(msg.sender, 250);
  }

  function whitelistMint(
    bytes32[] calldata _merkleProof,
    uint8 _quantity
  ) external payable nonReentrant {
    require(
      verifyWhitelistMintAddress(_merkleProof, msg.sender),
      'Tiny: INVALID_PROOF'
    );
    require(contractStatus != ContractStatus.SOLD, 'Tiny: sold out');
    require(
      contractStatus == ContractStatus.WL,
      'Tiny: whitelist not started or is ended'
    );
    require(_quantity > 0, 'Tiny: mint at least 1 token');

    uint256 _price = WhitelistMintPrice * _quantity;
    require(msg.value >= _price, 'Tiny: you need to send more ETH');
    require(totalSupply() + _quantity <= MAX_SUPPLY, 'Tiny: max supply exceed');
    require(
      whitelistMintCount[msg.sender] + _quantity <= mintableTokenPerWL,
      'Tiny: max limit for minting reached'
    );
    _mintToken(msg.sender, _quantity, MintStatus.WL, _price);
  }

  function privateMint(
    bytes32[] calldata _merkleProof,
    uint8 _quantity
  ) external payable nonReentrant {
    require(
      verifyPrivateMintAddress(_merkleProof, msg.sender),
      'Tiny: INVALID_PROOF'
    );
    require(contractStatus != ContractStatus.SOLD, 'Tiny: sold out');
    require(
      contractStatus == ContractStatus.PRIVATE,
      'Tiny: private mint not started or is ended'
    );
    require(_quantity > 0, 'Tiny: mint at least 1 token');

    uint256 _price = PrivateMintPrice * _quantity;
    require(msg.value >= _price, 'Tiny: you need to send more ETH');
    require(totalSupply() + _quantity <= MAX_SUPPLY, 'Tiny: max supply exceed');
    require(
      privateMintCount[msg.sender] + _quantity <= mintableTokenPerPrivateMint,
      'Tiny: max limit for minting reached'
    );
    _mintToken(msg.sender, _quantity, MintStatus.PRIVATE, _price);
  }

  function mint(uint8 _quantity) external payable nonReentrant {
    require(contractStatus != ContractStatus.SOLD, 'Tiny: sold out');
    require(contractStatus == ContractStatus.SALE, 'Tiny: sale not started');
    uint256 _price = PublicMintPrice * _quantity;
    require(msg.value >= _price, 'Tiny: you need to send more ETH');
    require(totalSupply() + _quantity <= MAX_SUPPLY, 'Tiny: max supply exceed');
    require(_quantity > 0, 'Tiny: mint at least 1 token');
    require(
      publicMintCount[msg.sender] + _quantity <= mintableTokenPerPublicMint,
      'Tiny: max limit for minting reached'
    );
    _mintToken(msg.sender, _quantity, MintStatus.PUBLIC, _price);
  }

  function _mintToken(
    address _address,
    uint8 _quantity,
    MintStatus _mintStatus,
    uint256 _price
  ) private {
    for (uint8 i = 0; i < _quantity; ) {
      uint256 mintIndex = totalSupply();
      _safeMint(_address, mintIndex);
      unchecked {
        i++;
      }
    }

    if (_price == 0) {
      handleMintWithZeroPrice(_address, _quantity, _mintStatus);
    } else {
      handleMintWithNonZeroPrice(_address, _quantity, _price, _mintStatus);
    }
  }

  function handleMintWithZeroPrice(
    address _address,
    uint8 _quantity,
    MintStatus _mintStatus
  ) private {
    if (totalSupply() + _quantity == MAX_SUPPLY) {
      contractStatus = ContractStatus.SOLD;
    }

    if (MintStatus.WL == _mintStatus) {
      whitelistMintCount[_address] += _quantity;
    } else if (MintStatus.PUBLIC == _mintStatus) {
      publicMintCount[_address] += _quantity;
    } else if (MintStatus.PRIVATE == _mintStatus) {
      privateMintCount[_address] += _quantity;
    }
  }

  function handleMintWithNonZeroPrice(
    address _address,
    uint8 _quantity,
    uint256 _price,
    MintStatus _mintStatus
  ) private {
    (bool sent, ) = _address.call{value: msg.value - _price}('');
    require(sent, 'Tiny: TX_FAILED');
    handleMintWithZeroPrice(_address, _quantity, _mintStatus);
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

  function privateSale(
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

  function setWhitelistMintMerkleRoot(
    bytes32 _merkleRootHash
  ) external onlyOwner {
    whitelistMintMerkleRoot = _merkleRootHash;
  }

  function setPrivateMintMerkleRoot(
    bytes32 _merkleRootHash
  ) external onlyOwner {
    privateMintMerkleRoot = _merkleRootHash;
  }

  function verifyWhitelistMintAddress(
    bytes32[] calldata _merkleProof,
    address _address
  ) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_address));
    return MerkleProof.verify(_merkleProof, whitelistMintMerkleRoot, leaf);
  }

  function verifyPrivateMintAddress(
    bytes32[] calldata _merkleProof,
    address _address
  ) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_address));
    return MerkleProof.verify(_merkleProof, privateMintMerkleRoot, leaf);
  }

  function setMintableTokenPerPublicMint(
    uint8 _newMintableTokenPerPublicMint
  ) external onlyOwner {
    mintableTokenPerPublicMint = _newMintableTokenPerPublicMint;
  }

  function setMintableTokenPerWL(
    uint8 _newMintableTokenPerWL
  ) external onlyOwner {
    mintableTokenPerWL = _newMintableTokenPerWL;
  }

  function setMintableTokenPerPrivateMint(
    uint8 _newMintableTokenPerPrivateMint
  ) external onlyOwner {
    mintableTokenPerPrivateMint = _newMintableTokenPerPrivateMint;
  }

  function setPublicMintPrice(uint256 _newPublicMintPrice) external onlyOwner {
    PublicMintPrice = _newPublicMintPrice;
  }

  function setWhitelistMintPrice(
    uint256 _newWhitelistMintPrice
  ) external onlyOwner {
    WhitelistMintPrice = _newWhitelistMintPrice;
  }

  function setPrivateMintPrice(
    uint256 _newPrivateMintPrice
  ) external onlyOwner {
    PrivateMintPrice = _newPrivateMintPrice;
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

  function startPrivateMint() external onlyOwner {
    require(
      !pubSaleActive,
      'Tiny: private mint has been started, can not start private mint'
    );
    contractStatus = ContractStatus.PRIVATE;
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
