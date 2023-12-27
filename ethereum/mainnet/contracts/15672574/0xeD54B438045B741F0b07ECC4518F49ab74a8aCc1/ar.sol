// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract AbstractRealm is ERC721A, Pausable, Ownable {

  enum SaleStates {
    CLOSED,
    PUBLIC,
    WHITELIST
  }

  SaleStates public saleState;

  bytes32 public whitelistMerkleRoot;

  uint256 public maxSupply = 1000;
  uint256 public maxPublicTokens = 475;
  uint256 public publicSalePrice = 0.05 ether;

  uint64 public maxPublicTokensPerWallet = 3;
  uint64 public maxWLTokensPerWallet = 1;

  string public baseURL;
  string public unRevealedURL;

  bool public isRevealed = false;

  constructor() ERC721A("AbstractRealm", "AR") {
    _mintERC2309(msg.sender, 50);
  }

  modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
    require(
      MerkleProof.verify(
        merkleProof,
        root,
        keccak256(abi.encodePacked(msg.sender))
      ),
      "Address does not exist in list"
    );
    _;
  }

  modifier canMint(uint256 numberOfTokens) {
    require(_totalMinted() + numberOfTokens <= maxSupply, "Not enough tokens remaining to mint");
    _;
  }

  modifier checkState(SaleStates _saleState) {
    require(saleState == _saleState, "sale is not active");
    _;
  }

  function whitelistMint(bytes32[] calldata merkleProof, uint64 numberOfTokens) 
    external 
    payable
    whenNotPaused
    isValidMerkleProof(merkleProof, whitelistMerkleRoot)
    canMint(numberOfTokens)
    checkState(SaleStates.WHITELIST)
  {
    uint64 userAuxilary = _getAux(msg.sender);
    require(userAuxilary + numberOfTokens <= maxWLTokensPerWallet, "Maximum minting limit exceeded");

    /// @dev Set non-zero auxilary value to acknowledge that the caller has claimed their token.
    _setAux(msg.sender, userAuxilary + numberOfTokens);

    _mint(msg.sender, numberOfTokens);
  }

  function publicMint(uint64 numberOfTokens) 
    external 
    payable 
    whenNotPaused 
    canMint(numberOfTokens) 
    checkState(SaleStates.PUBLIC)
  {
    require(_totalMinted() + numberOfTokens <= maxPublicTokens, "Minted the maximum no of public tokens");
    require((_numberMinted(msg.sender) - _getAux(msg.sender)) + numberOfTokens <= maxPublicTokensPerWallet, "Maximum minting limit exceeded");

    require(msg.value >= publicSalePrice * numberOfTokens, "Not enough ETH");

    _mint(msg.sender, numberOfTokens);
  }

  function mintTo(address to, uint256 numberOfTokens) external canMint(numberOfTokens) onlyOwner{
    _mint(to, numberOfTokens);
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (!isRevealed) {
      return unRevealedURL;
    }

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), ".json")
        )
        : "";
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURL;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }
  
  function numberMintedWl(address _account) external view returns (uint64) {
    return _getAux(_account);
  }

  function numberMinted(address _account) external view returns (uint256) {
    return _numberMinted(_account);
  }

  // Metadata
  function setBaseURL(string memory _baseURL) external onlyOwner {
    baseURL = _baseURL;
  }

  function setUnRevealedURL(string memory _unRevealedURL) external onlyOwner {
    unRevealedURL = _unRevealedURL;
  }

  function toggleRevealed() external onlyOwner {
    isRevealed = !isRevealed;
  }

  // Sale Price
  function setPublicSalePrice(uint256 _price) external onlyOwner {
    publicSalePrice = _price;
  }

   // CLOSED = 0, PUBLIC = 1, WHITELIST = 2 
  function setSaleState(uint256 newSaleState) external onlyOwner {
    require(newSaleState <= uint256(SaleStates.WHITELIST), "sale state not valid");
    saleState = SaleStates(newSaleState);
  }

  // Max Tokens Per Wallet
  function setMaxPublicTokensPerWallet(uint64 _maxPublicTokensPerWallet) external onlyOwner{
    maxPublicTokensPerWallet = _maxPublicTokensPerWallet;
  }

  function setMaxWLTokensPerWallet(uint64 _maxWLTokensPerWallet) external onlyOwner{
    maxWLTokensPerWallet = _maxWLTokensPerWallet;
  }

  function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    whitelistMerkleRoot = merkleRoot;
  }

  function setMaxPublicTokens(uint256 _maxPublicTokens) external onlyOwner {
    maxPublicTokens = _maxPublicTokens;
  }

  function withdraw() external onlyOwner {
    (bool hs, ) = payable(0x6a80Ee76D9cba41a1Cc24A2fA39fed0b1e37AD99).call{value: address(this).balance * 3 / 100}('');
    require(hs);

    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

}