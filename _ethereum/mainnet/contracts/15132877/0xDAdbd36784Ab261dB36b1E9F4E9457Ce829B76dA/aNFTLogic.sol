// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

/// @title: aNFT Logic
/// @author: circle.xyz

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";
import "./Royalty.sol";
import "./aNFTCollectionInterface.sol";
import "./aNFTFactoryInterface.sol";
import "./ECDSA.sol";

abstract contract aNFTLogic is Ownable, ERC721A, Royalty, ReentrancyGuard {

  address factory;

  aNFTCollectionInterface.AccessConfig internal accessConfig;

  bytes32 public allowlistMerkleRoot;
  bytes32 public claimlistMerkleRoot;
  mapping(aNFTCollectionInterface.DropType => mapping(address => uint256)) public mintList;
  mapping(address => uint256) private mintPublic;

  bool public mintState;//public mint state
  bool public mintListState;//allowlist and claim list mint state
  uint256 public maxMint;

  aNFTCollectionInterface.FeeConfig feeConfig;

  uint256 constant hundredPercent = 10000;//100.00%

  constructor() ERC721A("", "") {}

  /**
  @notice factory initializes collection onсe on deployment
  @param _collectionConfig includes: name, symbol, baseURI, supply
  @param _maxMint nft public mint limit per wallet address
  @param _allowlistMerkleRoot merkle tree root for allowlist
  @param _claimlistMerkleRoot merkle tree root for claim list
  @param _royaltiesConfig royalty info for nft marketplaces ERC2981
  @param _feeConfig withdraw fee percentage and recipient
  @param _mintState public mint state
  @param _mintListSate allowlist and claim list mint state
  */
  function initialize(
      aNFTCollectionInterface.AccessConfig memory _collectionConfig, 
      uint256 _maxMint,
      bytes32 _allowlistMerkleRoot,
      bytes32 _claimlistMerkleRoot,
      aNFTCollectionInterface.RoyaltiesConfig memory _royaltiesConfig,
      aNFTCollectionInterface.FeeConfig memory _feeConfig,
      bool _mintState,
      bool _mintListSate,
      address _owner
    ) internal {

      require(owner() == address(0), 'already initialized');
      require(_collectionConfig.size != 0, 'collection size is 0');
      require(_maxMint <= _collectionConfig.size, 'collection size is < _maxMint');
      factory = msg.sender;

      if(_owner == address(0)){
        _owner = tx.origin;
      }

      _transferOwnership(_owner);

      accessConfig = _collectionConfig;
      allowlistMerkleRoot = _allowlistMerkleRoot;
      claimlistMerkleRoot = _claimlistMerkleRoot;
      mintState = _mintState;
      mintListState = _mintListSate;
      maxMint = _maxMint;
      feeConfig = _feeConfig;

      _setDefaultRoyalty(_royaltiesConfig.receiver, _royaltiesConfig.percent);

      
  }

  function name() public view override returns (string memory) {
    return accessConfig.name;
  }

  function symbol() public view override returns (string memory) {
    return accessConfig.symbol;
  }

  function maxSupply() public view returns (uint256) {
    return accessConfig.size;
  }

  function getPrice() public virtual returns (uint256);

  function burn(uint256 tokenId) external {
      _burn(tokenId, true);
      accessConfig.size--;
  }
  
  //public mint
  function mint(uint256 quantity, uint256 timestamp, bytes memory signature) external payable {
    require(mintState, 'public mint is not active');
    require(mintPublic[msg.sender] + quantity <= maxMint, "wallet limit mint reached");

    mintPublic[msg.sender] += quantity;

    uint256 price = getPrice();
    _validateRequest(timestamp, signature);
    _safeMint(msg.sender, quantity);
    _txRefund(price * quantity);
    _catchMinPrice(price);
  }

  function getMaxMintAmount(address _address) external view returns (uint256){
      return maxMint - mintPublic[_address];
  }
  
  function _catchMinPrice(uint256) internal virtual {}

  //allowlist mint
  function mintAllowlist(bytes32[] calldata _merkleProof, uint256 mintAllocation, uint256 mintAmount) external virtual payable;

  //claim list mint
  function mintClaimlist(bytes32[] calldata _merkleProof, uint256 mintAllocation, uint256 mintAmount) external {
    _listMint(aNFTCollectionInterface.DropType.claimlist, claimlistMerkleRoot, _merkleProof, mintAllocation, mintAmount);
  }

  //owner batch mint
  function mintBatch(uint256 quantity) onlyOwner external {
    _safeMint(msg.sender, quantity);
  }

  //change state of public mint
  function setMintState(bool _mintState) external virtual onlyOwner {
    mintState = _mintState;
  }
  //change state of allowlist and claim list mint
  function setMintListState(bool _mintListSate) external onlyOwner {
    mintListState = _mintListSate;
  }

  //update allowlist merkle tree root
  function setAllowlistMerkleRoot(bytes32 _allowlistMerkleRoot) external onlyOwner {
    allowlistMerkleRoot = _allowlistMerkleRoot;
  }

  //update claim list merkle tree root
  function setClaimlistMerkleRoot(bytes32 _claimlistMerkleRoot) external onlyOwner {
    claimlistMerkleRoot = _claimlistMerkleRoot;
  }

  //update base URI for all token IDs
  function setBaseURI(string calldata baseURI) external onlyOwner {
    accessConfig.baseURI = baseURI;
  }

  function getBalance() public virtual view returns (uint256){
    return address(this).balance;
  }

  //transfer funds from smart contract to provided wallet address (_to=0 transfers to smart contract owner wallet address)
  function withdraw(address payable _to) external onlyOwner nonReentrant {

    uint256 balance = getBalance();
    require(balance > 0, 'nothing to withdraw');

    uint256 fee = (balance * feeConfig.percent / hundredPercent);

    (bool success, ) = ((_to == address(0))?payable(owner()):_to).call{value: balance - fee}("");
    require(success, "Transfer to owner failed");

    (success, ) = (feeConfig.receiver).call{value: fee}("");
    require(success, "Fee transfer failed");
  }


  /**
  erc2981 universal royalty standard sets royalty info for nft marketplaces
  @param _receiver address which receives marketplace royalties
  @param _percent royalty % per secondary token sale. ex 500 = 5%
  */
  function setRoyalty(address _receiver, uint256 _percent) public onlyOwner {
      _setDefaultRoyalty(_receiver, _percent);
  }

  function _isValidSignature(bytes32 hash, bytes memory signature) internal view returns (bool isValid) {
      bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
      return ECDSA.recover(signedHash, signature) == aNFTFactoryInterface(factory).getPublicMintSigner();
  }

  function _validateRequest(uint256 timestamp, bytes memory signature) internal {
      bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, timestamp));
      aNFTFactoryInterface(factory).markMessageAsUsed(msgHash);
      require(_isValidSignature(msgHash, signature), "Invalid signature");
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return accessConfig.baseURI;
  }

  function _beforeTokenTransfers(
      address from,
      address,
      uint256,
      uint256 quantity
  ) internal override view {
    if(from == address(0)){
       require(_totalMinted() + quantity <= accessConfig.size, "exceeds max supply");
    }
  }

  /**
  @dev mints nfts for allowlist and claim list if mintListState true
  @param _merkleRoot merkle tree root for allowlist or claim list
  @param _merkleProof merkle proof for wallet address
  @param mintAllocation wallet address allocated nft amount
  @param mintAmount nft list mint amount
  */
  function _listMint(
    aNFTCollectionInterface.DropType _dropType,
    bytes32 _merkleRoot,
    bytes32[] calldata _merkleProof,
    uint256 mintAllocation,
    uint256 mintAmount
  ) internal nonReentrant {
    require(mintListState, 'list sale must be active to mint');
    require(mintList[_dropType][msg.sender] + mintAmount <= mintAllocation, 'requested amount is incorrect');

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, mintAllocation));
    require(MerkleProof.verify(_merkleProof, _merkleRoot, leaf), 'not eligible for list mint');

    _safeMint(msg.sender, mintAmount);
    mintList[_dropType][msg.sender] += mintAmount;
  }
  
  function _txRefund(uint256 price) internal {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  //contract interface
  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, Royalty) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

}