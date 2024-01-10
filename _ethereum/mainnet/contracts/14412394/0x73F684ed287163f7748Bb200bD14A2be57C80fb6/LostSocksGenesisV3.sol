// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ControllableUpgradeable.sol";
import "./ERC721AUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./ILostSocksThread.sol";

/// @title Lost Socks Genesis V3
contract LostSocksGenesisV3 is
  Initializable,
  OwnableUpgradeable,
  PausableUpgradeable,
  ControllableUpgradeable,
  ERC721AUpgradeable
{
  using StringsUpgradeable for uint256;
  using MerkleProofUpgradeable for bytes32[];

  event NameChange(uint256 indexed id, string newName);
  event DescriptionChange(uint256 indexed id, string newDescription);

  /* -------------------------------------------------------------------------- */
  /*                                Token Details                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Max genesis token count.
  uint256 public constant LSG_MAX = 2_500;

  /// @notice Max mints per transaction.
  uint256 public constant LSG_PER_TX = 10;

  /// @notice Max mints at presale.
  uint256 public constant LSG_PER_WL = 3;

  /// @notice Purchase price.
  uint256 public constant LSG_PRICE = 0.069 ether;

  /* -------------------------------------------------------------------------- */
  /*                                Utility Token                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Utility token use for changing name / description.
  ILostSocksThread public utilityToken;

  /// @notice Price of utilityToken to change name
  uint256 public nameChangePrice;

  /// @notice Price of utilityToken to change description
  uint256 public descriptionChangePrice;

  /// @notice false = cant change name/description
  bool public renameState;

  /// @notice Name of token by ID
  mapping(uint256 => string) public nameOf;

  /// @notice Description of token by ID
  mapping(uint256 => string) public descriptionOf;

  /// @notice Name of token by ID
  mapping(string => bool) internal _isNameReserved;

  /* -------------------------------------------------------------------------- */
  /*                                Sale Details                                */
  /* -------------------------------------------------------------------------- */

  /// @notice 0 = CLOSED, 1 = WHITELIST, 2 = PUBLIC.
  uint256 public saleState;

  /// @notice Whitelist merkle root.
  bytes32 public root;

  /// @notice Amount of tokens minted by address during presale.
  mapping(address => uint256) public presaleBought;

  /* -------------------------------------------------------------------------- */
  /*                              Metadata Details                              */
  /* -------------------------------------------------------------------------- */

  /// @notice Token metadata uri.
  string public baseURI;

  /// @notice Token metadata uri hosted on ipfs.
  string public ipfsURI;

  /// @notice An array of bitpacked uint256 to keep track of left/right token traits.
  uint256[] internal _dna;

  /* -------------------------------------------------------------------------- */
  /*                             Marketplace Details                            */
  /* -------------------------------------------------------------------------- */

  /// @notice Check if marketplaces pre-approve is enabled.
  bool public marketplacesApproved;

  /// @notice OpenSea proxy registry.
  address public opensea;

  /// @notice LooksRare marketplace transfer manager.
  address public looksrare;

  /* -------------------------------------------------------------------------- */
  /*                               Reedem Details                               */
  /* -------------------------------------------------------------------------- */

  /// @notice End time for reedems.
  uint256 public redeemEnd;

  /// @notice token id => redeem state.
  mapping(uint256 => bool) public redeemed;

  function initialize(
    string memory newBaseURI,
    address newUtilityToken,
    bytes32 newRoot
  ) external initializer {
    // Initialize the contract
    __Ownable_init();
    __Pausable_init();
    __Controllable_init();
    __ERC721A_init("Lost Socks Genesis", "LSG");

    // Set initializer variables
    baseURI = newBaseURI;
    utilityToken = ILostSocksThread(newUtilityToken);
    root = newRoot;

    // Set initial variables
    opensea = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    looksrare = 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e;
    marketplacesApproved = true;
    nameChangePrice = 50 ether;
    descriptionChangePrice = 50 ether;
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Sale Logic                                 */
  /* -------------------------------------------------------------------------- */

  /// @notice Purchase one or more Lost Socks tokens.
  /// @param amount Number of tokens to buy.
  function buy(uint256 amount) external payable {
    if (block.timestamp <= redeemEnd) {
      require(totalSupply() + amount <= LSG_MAX - 423, "Max genesis supply exceeded");
    } else {
      require(totalSupply() + amount <= LSG_MAX, "Max genesis supply exceeded");
    }

    if (msg.sender != owner()) {
      require(saleState == 2, "Invalid sale state");
      require(msg.value == LSG_PRICE * amount, "Invalid ether amount");
      require(amount > 0 && amount <= LSG_PER_TX, "Invalid claim amount");
    }

    _safeMint(msg.sender, amount);
  }

  /// @notice Redeem new genesis tokens for each old one you have.
  /// @param ids Array of token ids.
  function redeem(uint256[] calldata ids) external {
    require(block.timestamp <= redeemEnd, "Reedem window already closed");
    for (uint256 i; i < ids.length; i++) {
      require(!redeemed[ids[i]] && ids[i] < 474 && ids[i] > 49, "Invalid token id");
      require(ownerOf(ids[i]) == msg.sender, "ERC721: caller is not the owner");
      redeemed[ids[i]] = true;
    }

    _safeMint(msg.sender, ids.length);
  }

  /* -------------------------------------------------------------------------- */
  /*                       Change name / description                            */
  /* -------------------------------------------------------------------------- */

  /// @notice Change name of token.
  /// @param id Token id.
  /// @param newName New token name.
  function changeName(uint256 id, string memory newName) public {
    require(renameState, "Changing name is not allowed");
    require(msg.sender == ownerOf(id), "ERC721: caller is not the owner");
    require(isValidName(newName) == true, "Invalid new name");
    require(sha256(bytes(newName)) != sha256(bytes(nameOf[id])), "New name already set");
    require(isNameReserved(newName) == false, "New name already reserved");

    // Burn utility token
    utilityToken.burn(msg.sender, nameChangePrice);

    // If already named, de-reserve old name
    if (bytes(nameOf[id]).length > 0) _setIsNameReserved(nameOf[id], false);
    _setIsNameReserved(newName, true);

    // Set new name and emit event
    nameOf[id] = newName;
    emit NameChange(id, newName);
  }

  /// @notice Change description of token.
  /// @param id Token id.
  /// @param newDescription New token description.
  function changeDescription(uint256 id, string memory newDescription) public {
    require(renameState, "Changing description is not allowed");
    require(msg.sender == ownerOf(id), "ERC721: caller is not the owner");

    // burn utility token
    utilityToken.burn(msg.sender, descriptionChangePrice);

    descriptionOf[id] = newDescription;
    emit DescriptionChange(id, newDescription);
  }

  /// @notice Set if a name is reserved.
  /// @param str Token name.
  /// @param isReserved New reserved state.
  function _setIsNameReserved(string memory str, bool isReserved) internal {
    _isNameReserved[toLower(str)] = isReserved;
  }

  /// @notice Check if name is reserved.
  /// @param str Name to be checked.
  function isNameReserved(string memory str) public view returns (bool) {
    return _isNameReserved[toLower(str)];
  }

  /// @notice Check if name is valid.
  /// @param str Name to be checked.
  function isValidName(string memory str) public pure returns (bool) {
    bytes memory bStr = bytes(str);

    if (bStr.length == 0) return false; // Empty
    if (bStr.length > 25) return false; // Longer than 25 characters
    if (bStr[0] == 0x20) return false; // Leading space
    if (bStr[bStr.length - 1] == 0x20) return false; // Trailing space

    bytes1 lastChar = bStr[0];
    for (uint256 i; i < bStr.length; i++) {
      bytes1 char = bStr[i];
      if (char == 0x20 && lastChar == 0x20) return false; // Continous spaces
      if (
        !(char >= 0x30 && char <= 0x39) && // 9-0
        !(char >= 0x41 && char <= 0x5A) && // A-Z
        !(char >= 0x61 && char <= 0x7A) && // a-z
        !(char == 0x20) // space
      ) return false;

      lastChar = char;
    }

    return true;
  }

  /// @notice Convert string to lower.
  /// @param str Name to be checked.
  function toLower(string memory str) public pure returns (string memory) {
    bytes memory bStr = bytes(str);
    bytes memory bLower = new bytes(bStr.length);
    for (uint256 i = 0; i < bStr.length; i++) {
      // Uppercase character
      if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
        bLower[i] = bytes1(uint8(bStr[i]) + 32);
      } else bLower[i] = bStr[i];
    }
    return string(bLower);
  }

  /* -------------------------------------------------------------------------- */
  /*                               Metadata Logic                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Retrieve if a sock position is left (rare trait).
  /// @param tokenId Sock token id.
  function isLeft(uint256 tokenId) external view returns (bool) {
    require(_exists(tokenId), "Query for nonexisting token");
    uint256 tokenIndex = tokenId % 256;
    uint256 dnaIndex = (tokenId - tokenIndex) / 256;
    return (_dna[dnaIndex] >> tokenIndex) & 1 == 1;
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Owner Logic                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Set redeemEnd to `newRedeemEnd`.
  /// @param newRedeemEnd New redeem end.
  function setRedeemEnd(uint256 newRedeemEnd) external onlyOwner {
    redeemEnd = newRedeemEnd;
  }

  /// @notice Set baseURI to `newBaseURI`.
  /// @param newBaseURI New base uri.
  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  /// @notice Set ipfsURI to `newIpfsURI`.
  /// @param newIpfsURI New IPFS base uri.
  function setIpfsURI(string memory newIpfsURI) external onlyOwner {
    ipfsURI = newIpfsURI;
  }

  /// @notice Set `_dna` to `newDNA`.
  /// @param newDNA New dna bytes.
  function setDNA(uint256[] memory newDNA) external onlyOwner {
    _dna = newDNA;
  }

  /// @notice Set saleState.
  /// @param newSaleState New sale state.
  function setSaleState(uint256 newSaleState) external onlyOwner {
    saleState = newSaleState;
  }

  /// @notice Set marketplace addresses.
  /// @param newOpensea Opensea's proxy registry contract address.
  /// @param newLooksrare Looksrare's transfer manager contract address.
  function setMarketplaces(address newOpensea, address newLooksrare) external onlyOwner {
    opensea = newOpensea;
    looksrare = newLooksrare;
  }

  /// @notice Set root.
  /// @param newRoot New merkle root.
  function setRoot(bytes32 newRoot) external onlyOwner {
    root = newRoot;
  }

  /// @notice Set utilityToken
  /// @param newUtilityToken new token
  function setUtilityToken(address newUtilityToken) external onlyOwner {
    utilityToken = ILostSocksThread(newUtilityToken);
  }

  /// @notice Set saleState.
  /// @param newRenameState New rename state.
  function setRenameState(bool newRenameState) external onlyOwner {
    renameState = newRenameState;
  }

  /// @notice Set rename prices
  /// @param newNameChangePrice new nameChangePrice
  /// @param newDescriptionChangePrice new descriptionChangePrice
  function setRenamePrices(uint256 newNameChangePrice, uint256 newDescriptionChangePrice) external onlyOwner {
    nameChangePrice = newNameChangePrice;
    descriptionChangePrice = newDescriptionChangePrice;
  }

  /// @notice Add or edit contract controllers.
  /// @param addrs Array of addresses to be added/edited.
  /// @param state New controller state of addresses.
  function setControllers(address[] calldata addrs, bool state) external onlyOwner {
    for (uint256 i = 0; i < addrs.length; i++) super._setController(addrs[i], state);
  }

  /// @notice Toggle marketplaces pre-approve feature.
  function toggleMarketplacesApproved() external onlyOwner {
    marketplacesApproved = !marketplacesApproved;
  }

  /// @notice Toggle contract paused state.
  function togglePaused() external onlyOwner {
    if (paused()) _unpause();
    else _pause();
  }

  /// @notice Withdraw ether from the contract.
  function withdraw() external {
    address creatorAddress = 0x0EA462f88BFA7ed17041381350976B145D12f011;
    address developerAddress = 0x74D864Bcd1a8ba1c1851E2CAEc33760f83dfF837;

    uint256 creatorAmount = (address(this).balance * 7930) / 10000;
    uint256 developerAmount = (address(this).balance * 2070) / 10000;

    (bool success1, ) = creatorAddress.call{value: creatorAmount}("");
    (bool success2, ) = developerAddress.call{value: developerAmount}("");
    require(success1 && success2, "Withdraw failed");
  }

  /* -------------------------------------------------------------------------- */
  /*                                ERC-721 Logic                               */
  /* -------------------------------------------------------------------------- */

  /// @notice See {ERC721-tokenURI}.
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(baseURI, tokenId.toString()));
  }

  /// @notice Retrieve tokens owned by `account`.
  /// @param account Token owner.
  function walletOfOwner(address account) external view returns (uint256[] memory) {
    uint256 balance = super.balanceOf(account);
    uint256[] memory ids = new uint256[](balance);

    for (uint256 i = 0; i < balance; i++) ids[i] = super.tokenOfOwnerByIndex(account, i);
    return ids;
  }

  /// @notice See {ERC721-isApprovedForAll}.
  /// @dev Overriden to bypass marketplace operators, pre-approving sales.
  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    bool isMarketplace = operator == address(ProxyRegistry(opensea).proxies(owner)) || operator == looksrare;

    if (!marketplacesApproved)
      return isMarketplace || isController(operator) || super.isApprovedForAll(owner, operator);
    return isController(operator) || super.isApprovedForAll(owner, operator);
  }

  /// @notice See {ERC721A-_beforeTokenTransfers}
  /// @dev Overriden to block transfer while contract is paused (avoiding bugs).
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal override whenNotPaused {
    super._beforeTokenTransfers(from, to, startTokenId, quantity);
  }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}
