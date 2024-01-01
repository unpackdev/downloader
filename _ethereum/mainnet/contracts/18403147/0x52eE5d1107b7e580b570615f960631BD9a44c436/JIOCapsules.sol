// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IERC721AUpgradeable.sol";
import "./ERC721AUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./MerkleProof.sol";
import "./ERC2981.sol";

error MintNotActive();
error AddressNotOnWhitelist();
error AddressNotOnWaitlist();
error AmountExceedsCurrentSupply();
error AmountExceedsWhitelistSupply();
error AmountExceedsWaitlistSupply();
error AmountExceedsMaxMints();
error InvalidMintQuantity();
error InvalidAmountOfEther();
error WalletAlreadyMinted();
error SalePriceNotSet();
error MerkleTreeNotSet();
error BaseTokenURINotSet();
error MintStartTimeNotSet();
error MintEndTimeNotSet();
error MintHasNotStarted();
error MintHasEnded();
error CannotSetMintActiveWithExpiredEndTime();
error UseSetMintStartTime();
error MintEndTimeMustBeGreaterThanMintStartTime();
error OnlyOneMintPhaseCanBeActive();
error WhitelistSupplyAmountExceedsMaxSupply();
error WaitlistSupplyAmountExceedsMaxSupply();

contract JIOCapsules is ERC721AUpgradeable, OwnableUpgradeable, ERC2981 {

  event MintedSuccessfully(address indexed from, uint256 quantity);

  uint256 public maxSupply;

  uint256 public whitelistSupply;
  uint256 public waitlistSupply;
  uint256 public salePrice;
  uint256 public mintStartTime;
  uint256 public mintEndTime;
  uint256 public maxMints;
  bool public waitlistMintActive;
  bool public whitelistMintActive;
  bool public publicMintActive;
  bool public ignoreTransactionLimit;
  
  string private baseTokenURI;
  
  bytes32 private merkleWhitelistRoot;
  bytes32 private merkleWaitlistRoot;

  mapping (address => uint8) public addressAirdropped;

  function initialize() initializerERC721A initializer public {
    __ERC721A_init('JIOCapsules', 'JIOCapsules');
    __Ownable_init();
    _setDefaultRoyalty(msg.sender, 500);
    maxMints = 2;
    waitlistMintActive = false;
    whitelistMintActive = false;
    publicMintActive = false;
    whitelistSupply = 1800;
    waitlistSupply = 5900;
    maxSupply = 6000;
    ignoreTransactionLimit = false;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    baseTokenURI = baseURI;
  }

  function setSalePrice(uint256 newPrice) external onlyOwner {
    salePrice = newPrice;
  }

  function setIgnoreTransactionLimit(bool value) external onlyOwner {
    ignoreTransactionLimit = value;
  }

  function setMaxMints(uint256 mintAmount) external onlyOwner {
    maxMints = mintAmount;
  }

  function setMaxSupply(uint256 amount) external onlyOwner {
    maxSupply = amount;
  }

  function setWhitelistSupply(uint256 amount) external onlyOwner {
    if (amount > maxSupply) revert WhitelistSupplyAmountExceedsMaxSupply();
    whitelistSupply = amount;
  }

  function setWaitlistSupply(uint256 amount) external onlyOwner {
    if (amount > maxSupply) revert WaitlistSupplyAmountExceedsMaxSupply();
    waitlistSupply = amount;
  }

  function setMerkleWaitlistRoot(bytes32 merkleRoot) external onlyOwner {
    merkleWaitlistRoot = merkleRoot;
  }

  function setMerkleWhitelistRoot(bytes32 merkleRoot) external onlyOwner {
    merkleWhitelistRoot = merkleRoot;
  }

  function setMintStartTime(uint256 timestamp, uint256 duration) external onlyOwner {
    mintStartTime = timestamp;
    mintEndTime = timestamp + duration;
  }

  function extendMintEndTime(uint256 timestamp) external onlyOwner {
    if (mintStartTime == 0) revert UseSetMintStartTime(); 
    if (timestamp <= mintStartTime) revert MintEndTimeMustBeGreaterThanMintStartTime();
    mintEndTime = timestamp;
  }

  function checkMintActiveRequirements(bool value) private view {
    if (value && mintStartTime == 0) revert MintStartTimeNotSet();
    if (value && mintEndTime == 0) revert MintEndTimeNotSet();
    if (value && block.timestamp > mintEndTime) revert CannotSetMintActiveWithExpiredEndTime();
    if (value && salePrice == 0) revert SalePriceNotSet();
    if (value && bytes(baseTokenURI).length == 0) revert BaseTokenURINotSet();
  }

  function setWhitelistMintActive(bool value) external onlyOwner {
    checkMintActiveRequirements(value);
    if (value && merkleWhitelistRoot == bytes32(0)) revert MerkleTreeNotSet();
    if (value && (publicMintActive || waitlistMintActive)) revert OnlyOneMintPhaseCanBeActive();
    whitelistMintActive = value;
  }

  function setWaitlistMintActive(bool value) external onlyOwner {
    checkMintActiveRequirements(value);
    if (value && merkleWaitlistRoot == bytes32(0)) revert MerkleTreeNotSet();
    if (value && (publicMintActive || whitelistMintActive)) revert OnlyOneMintPhaseCanBeActive();
    waitlistMintActive = value;
  }

  function setPublicMintActive(bool value) external onlyOwner {
    checkMintActiveRequirements(value);
    if (value && (waitlistMintActive || whitelistMintActive)) revert OnlyOneMintPhaseCanBeActive();
    publicMintActive = value;
  }

  function checkMintRequirements(uint256 quantity) private {
    uint256 currentSupply = totalSupply();
    if (quantity == 0) revert InvalidMintQuantity();
    if (_numberMinted(msg.sender) + quantity > maxMints) revert AmountExceedsMaxMints();
    if (currentSupply + quantity > maxSupply) revert AmountExceedsCurrentSupply();
    if (salePrice * quantity > msg.value) revert InvalidAmountOfEther();
    if (!ignoreTransactionLimit && _getAux(msg.sender) != 0) revert WalletAlreadyMinted();
  }

  function checkMintStartEnd() private view {
    if (block.timestamp < mintStartTime) revert MintHasNotStarted();
    if (block.timestamp > mintEndTime) revert MintHasEnded();
  }

  function waitlistMint(bytes32[] memory merkleProof, uint256 quantity) external payable {
    if (!waitlistMintActive) revert MintNotActive();
    checkMintStartEnd();
    bytes32 sender = keccak256(abi.encodePacked(msg.sender));
    if (!MerkleProof.verify(merkleProof, merkleWaitlistRoot, sender)) revert AddressNotOnWaitlist();
    checkMintRequirements(quantity);
    if (totalSupply() + quantity > waitlistSupply) revert AmountExceedsWaitlistSupply();
    _safeMint(msg.sender, quantity, "");
    _setAux(msg.sender, 1);
    refundIfOver(salePrice * quantity);
    emit MintedSuccessfully(msg.sender, quantity);
  }

  function whitelistMint(bytes32[] memory merkleProof, uint256 quantity) external payable {
    if (!whitelistMintActive) revert MintNotActive();
    checkMintStartEnd();
    bytes32 sender = keccak256(abi.encodePacked(msg.sender));
    if (!MerkleProof.verify(merkleProof, merkleWhitelistRoot, sender)) revert AddressNotOnWhitelist();
    checkMintRequirements(quantity);
    if (totalSupply() + quantity > whitelistSupply) revert AmountExceedsWhitelistSupply();
    _safeMint(msg.sender, quantity, "");
    _setAux(msg.sender, 1);
    refundIfOver(salePrice * quantity);
    emit MintedSuccessfully(msg.sender, quantity);
  }

  function publicMint(uint256 quantity) external payable {
    if (!publicMintActive) revert MintNotActive();
    checkMintStartEnd();
    checkMintRequirements(quantity);
    _safeMint(msg.sender, quantity, "");
    _setAux(msg.sender, 1);
    refundIfOver(salePrice * quantity);
    emit MintedSuccessfully(msg.sender, quantity);
  }

  function refundIfOver(uint256 price) private {
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function minted(address walletAddress) public view returns (bool) {
    if (!ignoreTransactionLimit) { 
      return _getAux(walletAddress) != 0;
    } else {
      return false;
    }
  }

  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Withdraw transfer failed.");
  }

  function ownerMint(uint256 quantity) external onlyOwner {
    uint256 currentSupply = totalSupply();
    if (currentSupply + quantity > maxSupply) revert AmountExceedsCurrentSupply();
    _safeMint(msg.sender, quantity, "");
  }

  function overdriveAirdrop(address[] memory receivers) external onlyOwner {
    uint256 currentSupply = totalSupply();
    if (currentSupply + receivers.length > maxSupply) revert AmountExceedsCurrentSupply();
    for (uint256 i; i < receivers.length;) {
      if (addressAirdropped[receivers[i]] == 0) {
        _safeMint(receivers[i], 1, "");
        addressAirdropped[receivers[i]] = 1;
      }
      unchecked {
        ++i;
      }
    }
  }

  function numberMinted(address walletAddress) public view returns(uint256) {
    return _numberMinted(walletAddress);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override (ERC721AUpgradeable)
    returns (string memory)
  {
    return string(abi.encodePacked(baseTokenURI, _toString(tokenId), '.json'));
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override (ERC721AUpgradeable, ERC2981)
    returns (bool)
  {
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    return ERC721AUpgradeable.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

} 
