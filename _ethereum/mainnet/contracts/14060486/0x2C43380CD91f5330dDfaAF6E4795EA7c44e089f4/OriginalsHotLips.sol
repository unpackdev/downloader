// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title OriginalsHotLips
 * @dev A gas-efficient ERC721 for the REMIX Hot Lips
 * @note Based on Nuclear nerds ERC721 contract by @nftchance & @masonnft
 */

import "./AdminControl.sol";
import "./IRemixOriginal.sol";
import "./IMintClubIncinerator.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./console.sol";

contract OriginalsHotLips is ERC721Enumerable, Pausable, ReentrancyGuard, AdminControl, Ownable, IRemixOriginal {
  using Strings for uint256;

  uint256 internal MAX_SUPPLY = 200;

  // ========== Immutable Variables ==========

  /// @notice Mint Token Address
  address payable public immutable INCINERATOR_CONTRACT_ADDRESS;
  /// @notice Remix Contract Address
  address payable public immutable REMIX_CONTRACT_ADDRESS;
  /// @notice An address to withdraw balance to
  address payable public immutable PAYABLE_ADDRESS_1;

  // ========== Mutable Variables ==========

  string public baseURI;

  mapping(address => mapping(MintTokenRequirementType => uint256)) numMintsPerAddress;

  enum MintTokenRequirementType {
    NONE,
    GOLD,
    BASIC,
    ANY
  }

  enum RemixHolderRequirementType {
    NONE,
    ANY
  }

  // Mint Windows
  struct MintWindow {
    MintTokenRequirementType tokenRequirement;
    RemixHolderRequirementType remixHolderRequirement;
    bool whitelistRequired;
    uint256 mintCostETH;
    uint16 walletLimit;
  }

  enum MintWindowType {
    GOLD,
    SILVER,
    ANY,
    PUBLIC
  }

  mapping(MintWindowType => MintWindow) public mintWindows;
  MintWindowType public currentMintWindow;

  mapping(address => mapping(MintWindowType => uint256)) numberOfTokensMintedPerWindowByAddress;

  // Mint tokens pricing/discount
  uint256 GOLD_TOKENS_REQUIRED_PER_MINT = 2;
  uint256 GOLD_TOKENS_PLUS_ETH_PER_MINT = 0 ether;

  uint256 BASIC_TOKENS_REQUIRED_PER_MINT = 1;
  uint256 BASIC_TOKENS_PLUS_ETH_PER_MINT = 0.06 ether;

  bytes32 public whitelistMerkleTreeRoot;

  // Proxies
  mapping(address => bool) public projectProxy;

  // ========== Constructor ==========

  constructor(
    address payable _INCINERATOR_CONTRACT_ADDRESS,
    address payable _REMIX_CONTRACT_ADDRESS,
    address _payableAddress
  ) ERC721("Hot Lips", "HOTLIPS")
  {
    baseURI = "https://storageapi.fleek.co/apedao-bucket/hot-lips/";
    REMIX_CONTRACT_ADDRESS = _REMIX_CONTRACT_ADDRESS;
    INCINERATOR_CONTRACT_ADDRESS = _INCINERATOR_CONTRACT_ADDRESS;

    PAYABLE_ADDRESS_1 = payable(_payableAddress);

    // Define Planned Mint Windows
    mintWindows[MintWindowType.GOLD] = MintWindow(
      MintTokenRequirementType.GOLD,
      RemixHolderRequirementType.NONE,
      true,
      0.06 ether, // Mint Cost
      1
    );

    mintWindows[MintWindowType.SILVER] = MintWindow(
      MintTokenRequirementType.BASIC,
      RemixHolderRequirementType.NONE,
      true,
      0.08 ether, // 0.08 ETH
      1
    );

    mintWindows[MintWindowType.ANY] = MintWindow(
      MintTokenRequirementType.NONE,
      RemixHolderRequirementType.ANY,
      false,
      0.1 ether, // 0.1 ETH
      5
    );

    mintWindows[MintWindowType.PUBLIC] = MintWindow(
      MintTokenRequirementType.NONE,
      RemixHolderRequirementType.NONE,
      false,
      0.1 ether, // 0.1 ETH
      0
    );

    // Start with the current mint window as gold and pause sale
    currentMintWindow = MintWindowType.GOLD;
    _pause();
  }

  // ========== Minting ==========

  function mint(uint256 _quantity) public payable whenNotPaused nonReentrant {
    require(mintWindows[currentMintWindow].whitelistRequired == false, "Whitelist is required for this mint window");
    require(meetsRemixRequirements(mintWindows[currentMintWindow].remixHolderRequirement), "You must meet the Remix requirements for this mint window");

    canMint(_quantity);
    calcluateMintCost(_quantity);

    internalMint(_quantity);

    numberOfTokensMintedPerWindowByAddress[msg.sender][currentMintWindow] += _quantity;
  }

  /**
    * @notice Mints a token for the given address, if the address is on a whitelist.
   */
  function mintWhitelist(uint256 _quantity, uint list, bytes32[] calldata proof) public payable whenNotPaused nonReentrant {
    require(mintWindows[currentMintWindow].whitelistRequired == true, "Whitelist is not required for this mint window");

    string memory payload = string(abi.encodePacked(_msgSender()));
    require(_verify(_leaf(list, payload), proof), "Invalid Merkle Tree proof supplied.");

    canMint(_quantity);
    calcluateMintCost(_quantity);

    internalMint(_quantity);

    numberOfTokensMintedPerWindowByAddress[msg.sender][currentMintWindow] += _quantity;
  }

  function mintWhitelistWithTokens(uint256 _numGoldTokens, uint256 _basicGoldTokens, uint priorityTier, bytes32[] calldata proof) public payable whenNotPaused nonReentrant {
    require(mintWindows[currentMintWindow].whitelistRequired == true, "Whitelist is not required for this mint window");

    string memory payload = string(abi.encodePacked(_msgSender()));
    require(_verify(_leaf(priorityTier, payload), proof), "Invalid Merkle Tree proof supplied.");

    MintTokenRequirementType tokenRequirement;
    if(priorityTier == 0) {
      tokenRequirement = MintTokenRequirementType.GOLD;
    } else if(priorityTier == 1) {
      tokenRequirement = MintTokenRequirementType.ANY;
    }

    internalMintWithTokens(_numGoldTokens, _basicGoldTokens, tokenRequirement);
  }

  function mintWithTokens(uint256 _numGoldTokens, uint256 _numBasicTokens) public payable whenNotPaused nonReentrant {
    require(mintWindows[currentMintWindow].whitelistRequired == false, "Whitelist is required for this mint window");
    require(meetsRemixRequirements(mintWindows[currentMintWindow].remixHolderRequirement), "You must meet the Remix requirements for this mint window");

    internalMintWithTokens(_numGoldTokens, _numBasicTokens, mintWindows[currentMintWindow].tokenRequirement);
  }

  function internalMintWithTokens(uint256 _numGoldTokens, uint256 _numBasicTokens, MintTokenRequirementType tokenRequirement) internal {
    require(tokenRequirement != MintTokenRequirementType.NONE, "Mint tokens are not supported to mint");

    uint256 _quantity = calculateMintQuantityAndCost(tokenRequirement, _numGoldTokens, _numBasicTokens);
    
    canMint(_quantity);

    // Burn Mint Tokens
    IMintClubIncinerator incineratorContract = IMintClubIncinerator(INCINERATOR_CONTRACT_ADDRESS);

    if((getMintTokenRequirement() == MintTokenRequirementType.GOLD || getMintTokenRequirement() == MintTokenRequirementType.ANY) && _numGoldTokens > 0) {
      incineratorContract.burnGoldTokens(msg.sender, _numGoldTokens);
    }
    
    if((getMintTokenRequirement() == MintTokenRequirementType.BASIC || getMintTokenRequirement() == MintTokenRequirementType.ANY) && _numBasicTokens > 0) {
      incineratorContract.burnBasicTokens(msg.sender, _numBasicTokens);
    }

    internalMint(_quantity);

    numberOfTokensMintedPerWindowByAddress[msg.sender][currentMintWindow] += _quantity;
  }

  function canMint(uint256 _quantity) internal view {
    require(_quantity > 0, "Quantity must be greater than 0");

    // Check Wallet Limit
    uint256 walletLimit = mintWindows[currentMintWindow].walletLimit;
    require(walletLimit == 0 || (numberOfTokensMintedPerWindowByAddress[msg.sender][currentMintWindow] + _quantity <= walletLimit), "You have reached your wallet limit for this window");
  }

  function calcluateMintCost(uint256 _quantity) internal view {
    uint256 mintPrice = mintWindows[currentMintWindow].mintCostETH;
    require(msg.value >= mintPrice * _quantity, "Insufficient ETH for minting");
  }

  function calculateMintQuantityAndCost(MintTokenRequirementType tokenRequirement, uint256 _numGoldTokens, uint256 _numBasicTokens) internal view returns (uint256) {
    if(tokenRequirement == MintTokenRequirementType.GOLD) {
      require(_numGoldTokens > 0, "Gold token must be greater than 0");
      require(_numBasicTokens == 0, "only gold tokens are required to mint");
      require(_numGoldTokens % GOLD_TOKENS_REQUIRED_PER_MINT == 0, "Quantity must be a multiple of mint cost token");
    }

    if(tokenRequirement == MintTokenRequirementType.BASIC) {
      require(_numBasicTokens > 0, "Basic token must be greater than 0");
      require(_numGoldTokens == 0, "only basic tokens are required to mint");
      require(_numBasicTokens % BASIC_TOKENS_REQUIRED_PER_MINT == 0, "Quantity must be a multiple of mint cost token");
    }

    if(tokenRequirement == MintTokenRequirementType.ANY) {
      require(_numGoldTokens > 0 || _numBasicTokens > 0, "Gold or Basic token must be greater than 0");
      require(_numGoldTokens % GOLD_TOKENS_REQUIRED_PER_MINT == 0, "Quantity must be a multiple of mint cost token");
      require(_numBasicTokens % BASIC_TOKENS_REQUIRED_PER_MINT == 0, "Quantity must be a multiple of mint cost token");
    }

    uint256 _goldQuantity = _numGoldTokens / GOLD_TOKENS_REQUIRED_PER_MINT;
    uint256 _goldCostETH = _goldQuantity * GOLD_TOKENS_PLUS_ETH_PER_MINT;

    uint256 _basicQuantity = _numBasicTokens / BASIC_TOKENS_REQUIRED_PER_MINT;
    uint256 _basicCostETH = _basicQuantity * BASIC_TOKENS_PLUS_ETH_PER_MINT;

    require(msg.value >= _goldCostETH + _basicCostETH, "Insufficient ETH for minting");

    uint256 _quantityToMint = _goldQuantity + _basicQuantity;

    return _quantityToMint;
  }

  function meetsRemixRequirements(RemixHolderRequirementType requirement) internal view returns (bool) {
    if(requirement == RemixHolderRequirementType.NONE) {
      return true;
    }

    IERC721Enumerable remixContract = IERC721Enumerable(REMIX_CONTRACT_ADDRESS);
    uint256 remixBalance = remixContract.balanceOf(msg.sender);

    require(remixBalance > 0, "You must be a Remix holder to mint");

    if(requirement == RemixHolderRequirementType.ANY) {  
      return true;
    }

    return false;
  }

  function ownerMint(address _to, uint256 _tokenId) public onlyAdmin {
    require(_tokenId > 0 && _tokenId <= MAX_SUPPLY, "Not a valid token");

    _mint(_to, _tokenId);
  }

  function internalMint(uint256 _quantity) internal {
    uint256 totalSupply = _owners.length;
    require(totalSupply + _quantity <= MAX_SUPPLY, "Exceeds max supply.");

    for(uint i = 1; i <= _quantity; i++) { 
        _mint(_msgSender(), totalSupply + i);
    }
  }

  // ========== Public Methods ==========

  function getMintTokenRequirement() public view returns (MintTokenRequirementType) {
    return mintWindows[currentMintWindow].tokenRequirement;
  }

  function isRemixHolderRequired() public view returns (bool) {
    return mintWindows[currentMintWindow].remixHolderRequirement != RemixHolderRequirementType.NONE;
  }

  function getRemixHolderRequirement() public view returns (RemixHolderRequirementType) {
    return mintWindows[currentMintWindow].remixHolderRequirement;
  }

  function getMintCostETH() public view returns (uint256) {
    return mintWindows[currentMintWindow].mintCostETH;
  }

  function getWalletLimit() public view returns (uint16) {
    return mintWindows[currentMintWindow].walletLimit;
  }

  function getNumMintedInCurrentWindow(address _address) public view returns (uint256) {
    return numberOfTokensMintedPerWindowByAddress[_address][currentMintWindow];
  }

  // ========== Admin ==========

  function setMintTokenRequirement(MintTokenRequirementType _tokenRequirement) public onlyAdmin {
    mintWindows[currentMintWindow].tokenRequirement = _tokenRequirement;
  }

  function setRemixHolderRequirement(RemixHolderRequirementType _value) public onlyAdmin {
    mintWindows[currentMintWindow].remixHolderRequirement = _value;
  }

  function setMintCostETH(uint256 _mintCost) public onlyAdmin {
    mintWindows[currentMintWindow].mintCostETH = _mintCost;
  }

  function setWalletLimit(uint16 _walletLimit) public onlyAdmin {
    mintWindows[currentMintWindow].walletLimit = _walletLimit;
  }

  function setBaseURI(string memory _baseURI) public onlyAdmin {
    baseURI = _baseURI;
  }

  function setCurrentMintWindow(MintWindowType _mintWindow) public onlyAdmin {
    currentMintWindow = _mintWindow;
  }

  function setWhitelistMerkleTreeRoot(bytes32 _root) public onlyAdmin {
    whitelistMerkleTreeRoot = _root;
  }

  function withdraw() public onlyAdmin {
    PAYABLE_ADDRESS_1.call{value: address(this).balance}("");
  }

  function pause() public onlyAdmin {
    _pause();
  }

  function unpause() public onlyAdmin {
    _unpause();
  }

  function flipProxyState(address proxyAddress) public onlyAdmin {
    projectProxy[proxyAddress] = !projectProxy[proxyAddress];
  }

  // ========== MerkleTree Helpers ==========

  function _leaf(uint list, string memory payload) internal pure returns (bytes32) {
      return keccak256(abi.encodePacked(payload, list));
  }

  function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
      return MerkleProof.verify(proof, whitelistMerkleTreeRoot, leaf);
  }

  // ============ Overrides ========

  function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AdminControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(address from, address to, uint256 id) internal override(ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, id);
  }

  function _mint(address account, uint256 id) internal override(ERC721) {
    super._mint(account, id);
  }

  function burn(uint256 tokenId) public { 
    require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
    _burn(tokenId);
  }

  function _burn(uint256 id) internal override(ERC721) {
    super._burn(id);
  }

  function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
    if(projectProxy[operator]) return true;
    return super.isApprovedForAll(_owner, operator);
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_tokenId > 0 && _tokenId <= MAX_SUPPLY, "URI requested for invalid token");
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, _tokenId.toString()))
        : baseURI;
  }

}
