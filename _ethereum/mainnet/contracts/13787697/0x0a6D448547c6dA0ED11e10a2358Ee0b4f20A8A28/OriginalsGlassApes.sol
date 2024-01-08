// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// ========== Imports ==========
import "./AdminControl.sol";
import "./IRemixOriginal.sol";
import "./ERC1155RandomMint.sol";
import "./IMintClubIncinerator.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./IERC721.sol";
import "./Strings.sol";


contract OriginalsGlassApes is ERC1155, ERC1155Burnable, ERC1155RandomMint, Pausable, ReentrancyGuard, AdminControl, Ownable, IRemixOriginal {
  using Strings for uint256;

  // ========== Mint Window Maximum Supply ==========
  uint16 internal GOLD_WINDOW_MAX_SUPPLY = 100;
  uint16 internal ANY_WINDOW_MAX_SUPPLY = 250;
  uint16 internal REMIX_WINDOW_MAX_SUPPLY = 149;

  uint8 constant GOLD_TOKEN_ID = 1;
  uint8 constant BASIC_TOKEN_ID = 2;

  uint256 internal MAX_TOKEN_COUNT = 85;
  uint256 internal SUPPLY_PER_ADDITIONAL_TOKEN = 10;

  // ========== Immutable Variables ==========

  /// @notice Mint Token Address
  address payable public immutable INCINERATOR_CONTRACT_ADDRESS;
  /// @notice Remix Contract Address
  address payable public immutable REMIX_CONTRACT_ADDRESS;
  /// @notice An address to withdraw balance to
  address payable public immutable PAYABLE_ADDRESS_1;
  /// @notice An address to withdraw balance to
  address payable public immutable PAYABLE_ADDRESS_2;

  // ========== Mutable Variables ==========

  string public baseURI;

  mapping(address => mapping(TokenRequirementType => uint256)) numMintsPerAddress;

  enum TokenRequirementType {
    NONE,
    GOLD,
    BASIC,
    ANY
  }

  struct MintWindow {
    TokenRequirementType tokenRequirement;
    bool remixHolderRequired;
    uint mintCostToken;
    uint256 mintCostETH;
    uint256 maximumSupply;
    uint16 walletLimit;
  }

  mapping(address => mapping(MintWindowType => uint256)) numberOfTokensMintedPerWindowByAddress;

  enum MintWindowType {
    GOLD,
    ANY,
    REMIX,
    PUBLIC
  }

  mapping(MintWindowType => MintWindow) public mintWindows;
  MintWindowType public currentMintWindow;

  mapping(MintWindowType => uint256) public numMintsByWindow;

  // ========== Constructor ==========

  constructor(
    address payable _INCINERATOR_CONTRACT_ADDRESS,
    address payable _REMIX_CONTRACT_ADDRESS,
    address _payableAddress1,
    address _payableAddress2,
    uint256[] memory tokenSupply
  ) ERC1155(baseURI)
    ERC1155RandomMint(tokenSupply)
  {
    // TODO: Check that the base URI is correct
    baseURI = "https://storageapi.fleek.co/apedao-bucket/glass-apes/";
    REMIX_CONTRACT_ADDRESS = _REMIX_CONTRACT_ADDRESS;
    INCINERATOR_CONTRACT_ADDRESS = _INCINERATOR_CONTRACT_ADDRESS;

    PAYABLE_ADDRESS_1 = payable(_payableAddress1);
    PAYABLE_ADDRESS_2 = payable(_payableAddress2);

    // Define Planned Mint Windows
    mintWindows[MintWindowType.GOLD] = MintWindow(
      TokenRequirementType.GOLD,
      true,
      2,
      0, // Free
      GOLD_WINDOW_MAX_SUPPLY,
      5
    );

    mintWindows[MintWindowType.ANY] = MintWindow(
      TokenRequirementType.ANY,
      true,
      1,
      0.05 ether, // 0.05 ETH
      ANY_WINDOW_MAX_SUPPLY,
      5
    );

    mintWindows[MintWindowType.REMIX] = MintWindow(
      TokenRequirementType.NONE,
      true,
      0,
      0.07 ether, // 0.07 ETH
      REMIX_WINDOW_MAX_SUPPLY,
      5
    );

    mintWindows[MintWindowType.PUBLIC] = MintWindow(
      TokenRequirementType.NONE,
      false,
      0,
      0.09 ether, // 0.09 ETH
      totalTokenSupply, // No Maximum
      0
    );

    // Start with the current mint window as gold and pause sale
    currentMintWindow = MintWindowType.GOLD;
    _pause();
  }

  // ========== Minting ==========

  function mint(uint256 _quantity) public payable whenNotPaused nonReentrant {
    require(mintWindows[currentMintWindow].tokenRequirement == TokenRequirementType.NONE, "Mint tokens are required to mint.");

    canMint(_quantity);

    _mint(msg.sender, _quantity);

    numMintsByWindow[currentMintWindow] += _quantity;
    numberOfTokensMintedPerWindowByAddress[msg.sender][currentMintWindow] += _quantity;
  }

  function mintWithTokens(uint256 _numGoldTokens, uint256 _basicGoldTokens) public payable whenNotPaused nonReentrant {
    require(mintWindows[currentMintWindow].tokenRequirement != TokenRequirementType.NONE, "Mint tokens are required to mint.");

    uint256 _tokens;

    if(mintWindows[currentMintWindow].tokenRequirement == TokenRequirementType.GOLD) {
      require(_numGoldTokens > 0, "Gold token must be greater than 0");
      require(_basicGoldTokens == 0, "only gold tokens are required to mint");

      _tokens = _numGoldTokens;
    }

    if(mintWindows[currentMintWindow].tokenRequirement == TokenRequirementType.BASIC) {
      require(_basicGoldTokens > 0, "Basic token must be greater than 0");
      require(_numGoldTokens == 0, "only basic tokens are required to mint");

      _tokens = _basicGoldTokens;
    }

    if(mintWindows[currentMintWindow].tokenRequirement == TokenRequirementType.ANY) {
      require(_numGoldTokens > 0 || _basicGoldTokens > 0, "Gold or Basic token must be greater than 0");

      _tokens = _basicGoldTokens + _numGoldTokens;
    }

    // Calculate quantity
    require(_tokens % mintWindows[currentMintWindow].mintCostToken == 0, "Quantity must be a multiple of mint cost token");
    uint256 _quantity = _tokens / mintWindows[currentMintWindow].mintCostToken;

    canMint(_quantity);

    // Burn Mint Tokens
    IMintClubIncinerator incineratorContract = IMintClubIncinerator(INCINERATOR_CONTRACT_ADDRESS);

    // If Gold token is required
    if((getMintTokenRequirement() == TokenRequirementType.GOLD || getMintTokenRequirement() == TokenRequirementType.ANY) && _numGoldTokens > 0) {
      incineratorContract.burnGoldTokens(msg.sender, _numGoldTokens);
    }

    // If Basic token is required
    if((getMintTokenRequirement() == TokenRequirementType.BASIC || getMintTokenRequirement() == TokenRequirementType.ANY) && _basicGoldTokens > 0) {
      incineratorContract.burnBasicTokens(msg.sender, _basicGoldTokens);
    }

    _mint(msg.sender, _quantity);

    numMintsByWindow[currentMintWindow] += _quantity;
    numberOfTokensMintedPerWindowByAddress[msg.sender][currentMintWindow] += _quantity;
  }

  function canMint(uint256 _quantity) internal view {
    require(_quantity > 0, "Quantity must be greater than 0");
    require(numMintsByWindow[currentMintWindow] + _quantity <= mintWindows[currentMintWindow].maximumSupply, "Quantity must be less than remaining supply for this window");

    // Check mint cost
    uint256 mintPrice = mintWindows[currentMintWindow].mintCostETH;
    require(msg.value >= mintPrice * _quantity, "Insufficient ETH for minting");

    // Check Wallet Limit
    uint256 walletLimit = mintWindows[currentMintWindow].walletLimit;
    require(walletLimit == 0 || (numberOfTokensMintedPerWindowByAddress[msg.sender][currentMintWindow] + _quantity <= walletLimit), "You have reached your wallet limit for this window");

    // Check if Remix Holder is required
    if(mintWindows[currentMintWindow].remixHolderRequired) {
      IERC721 remixContract = IERC721(REMIX_CONTRACT_ADDRESS);
      require(remixContract.balanceOf(msg.sender) > 0, "You must be a Remix holder to mint");
    }
  }

  function ownerMint(address _to, uint256 _tokenId, uint256 _quantity) public onlyAdmin {
    require(_tokenId > 0 && _tokenId <= MAX_TOKEN_COUNT, "Not a valid token");

    if (_tokenId <= 50) {
      require(mintableTokenCount[_tokenId] >= _quantity, "Not enough left");
      mintableTokenCount[_tokenId] -= _quantity;
      numTokensMinted += _quantity;
    } else { // additional token
      require(totalSupply(_tokenId) + _quantity <= SUPPLY_PER_ADDITIONAL_TOKEN, "Not enough left");
    }

    _mint(_to, _tokenId, _quantity, "");
  }

  // ========== Public Methods ==========

  function getMintTokenRequirement() public view returns (TokenRequirementType) {
    return mintWindows[currentMintWindow].tokenRequirement;
  }

  function isRemixHolderRequired() public view returns (bool) {
    return mintWindows[currentMintWindow].remixHolderRequired;
  }

  function getMintCostETH() public view returns (uint256) {
    return mintWindows[currentMintWindow].mintCostETH;
  }

  function getMintCostToken() public view returns (uint256) {
    return mintWindows[currentMintWindow].mintCostToken;
  }

  function getMaximumSupply() public view returns (uint256) {
    return mintWindows[currentMintWindow].maximumSupply;
  }

  function getRemainingSupply() public view returns (uint256) {
    return mintWindows[currentMintWindow].maximumSupply - numMintsByWindow[currentMintWindow];
  }

  function getWalletLimit() public view returns (uint16) {
    return mintWindows[currentMintWindow].walletLimit;
  }

  function getNumMintedInCurrentWindow(address _address) public view returns (uint256) {
    return numberOfTokensMintedPerWindowByAddress[_address][currentMintWindow];
  }

  // ========== Admin ==========

  function setMintTokenRequirement(TokenRequirementType _tokenRequirement) public onlyAdmin {
    mintWindows[currentMintWindow].tokenRequirement = _tokenRequirement;
  }

  function setRemixHolderRequired(bool _value) public onlyAdmin {
    mintWindows[currentMintWindow].remixHolderRequired = _value;
  }

  function setMintCostETH(uint256 _mintCost) public onlyAdmin {
    mintWindows[currentMintWindow].mintCostETH = _mintCost;
  }

  function setMintCostToken(uint256 _mintCost) public onlyAdmin {
    mintWindows[currentMintWindow].mintCostToken = _mintCost;
  }

  function setMaximumSupply(uint16 _maximumSupply) public onlyAdmin {
    mintWindows[currentMintWindow].maximumSupply = _maximumSupply;
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

  function withdraw() public onlyAdmin {
    Address.sendValue(payable(PAYABLE_ADDRESS_1), address(this).balance * 60 / 100);
    Address.sendValue(payable(PAYABLE_ADDRESS_2), address(this).balance);
  }

  function pause() public onlyAdmin {
    _pause();
  }

  function unpause() public onlyAdmin {
    _unpause();
  }

  // ============ Overrides ========

  function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AdminControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal override(ERC1155, ERC1155Supply) {
    super._mint(account, id, amount, data);
  }

  function _mintBatch(address account, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply) {
    super._mintBatch(account, ids, amounts, data);
  }

  function _burn(address account, uint256 id, uint256 amount) internal override(ERC1155, ERC1155Supply) {
    super._burn(account, id, amount);
  }

  function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal override(ERC1155, ERC1155Supply) {
    super._burnBatch(account, ids, amounts);
  }

  function uri(uint256 _tokenId) public view override returns (string memory) {
    require(_tokenId > 0 && _tokenId <= MAX_TOKEN_COUNT, "URI requested for invalid token");
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, _tokenId.toString()))
        : baseURI;
  }

}
