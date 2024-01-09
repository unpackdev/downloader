// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./MerkleProof.sol";

/// @title Celestial Key
contract CelestialKey is Ownable, Pausable, ERC721A("Celestial Key", "CKEY") {
  using Strings for uint256;
  using MerkleProof for bytes32[];

  /// @notice Max total supply.
  uint256 public constant CKEY_MAX = 4444;
  /// @notice Max transaction amount.
  uint256 public constant CKEY_PER_TX = 5;
  /// @notice Max transaction amount in early access.
  uint256 public constant CKEY_PER_TX_EARLY = 2;
  /// @notice Early claim price.
  uint256 public constant CKEY_EARLY_PRICE = 0.044 ether;
  /// @notice Public claim price.
  uint256 public constant CKEY_PRICE = 0.088 ether;

  /// @notice 0 = FREE, 1 = EARLY, 2 = PUBLIC
  uint256 public saleState;

  /// @notice Metadata baseURI.
  string public baseURI;
  /// @notice Metadata unrevealed uri.
  string public unrevealedURI;
  /// @notice Metadata baseURI extension.
  string public baseExtension;

  /// @notice OpenSea proxy registry.
  address public opensea = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
  /// @notice LooksRare marketplace transfer manager.
  address public looksrare = 0x3f65A762F15D01809cDC6B43d8849fF24949c86a;
  /// @notice Check if marketplaces pre-approve is enabled.
  bool public marketplacesApproved = true;

  /// @notice Free claim merkle root.
  bytes32 public freeClaimRoot;
  /// @notice Early access merkle root.
  bytes32 public earlyAccessRoot;
  /// @notice Amount minted by address on free mint.
  mapping(address => uint256) public freeClaimed;
  /// @notice Amount minted by address on early access.
  mapping(address => uint256) public earlyClaimed;
  ///@notice Amount mintes by address on public mint.
  mapping(address => uint256) public publicClaimed;
  /// @notice Authorized callers mapping.
  mapping(address => bool) public auth;

  /// @notice Require the sender to be the owner() or authorized.
  modifier onlyAuth() {
    require(auth[msg.sender], "Sender is not authorized");
    _;
  }

  constructor(
    string memory newUnrevealedURI,
    bytes32 freeClaimRoot_,
    bytes32 earlyAccessRoot_
  ) {
    unrevealedURI = newUnrevealedURI;
    freeClaimRoot = freeClaimRoot_;
    earlyAccessRoot = earlyAccessRoot_;
    _pause();
  }

  /// @notice Claim one free token.
  function claimFree(bytes32[] memory proof) external {
    if (msg.sender != owner()) {
      require(saleState == 0, "Invalid sale state");
      require(freeClaimed[msg.sender] == 0, "User already minted a free token");
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      require(proof.verify(freeClaimRoot, leaf), "Invalid proof");
    }

    freeClaimed[msg.sender]++;
    _safeMint(msg.sender, 1);
  }

  /// @notice Claim one or more tokens for whitelisted user.
  function claimEarly(uint256 amount, bytes32[] memory proof) external payable {
    if (msg.sender != owner()) {
      require(saleState == 1, "Invalid sale state");
      require(amount > 0 && amount + earlyClaimed[msg.sender] <= CKEY_PER_TX_EARLY, "Invalid claim amount");
      require(msg.value == CKEY_EARLY_PRICE * amount, "Invalid ether amount");
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      require(proof.verify(earlyAccessRoot, leaf), "Invalid proof");
    }

    earlyClaimed[msg.sender] += amount;
    _safeMint(msg.sender, amount);
  }

  /// @notice Claim one or more tokens.
  function claim(uint256 amount) external payable {
    require(totalSupply() + amount <= CKEY_MAX, "Max supply exceeded");
    if (msg.sender != owner()) {
      require(saleState == 2, "Invalid sale state");
      require(amount > 0 && amount + publicClaimed[msg.sender] <= CKEY_PER_TX, "Invalid claim amount");
      require(msg.value == CKEY_PRICE * amount, "Invalid ether amount");
    }

    publicClaimed[msg.sender] += amount;
    _safeMint(msg.sender, amount);
  }

  /// @notice See {IERC721-tokenURI}.
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (bytes(unrevealedURI).length > 0) return unrevealedURI;
    return string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension));
  }

  /// @notice Set baseURI to `newBaseURI`, baseExtension to `newBaseExtension` and deletes unrevealedURI, triggering a reveal.
  function setBaseURI(string memory newBaseURI, string memory newBaseExtension) external onlyOwner {
    baseURI = newBaseURI;
    baseExtension = newBaseExtension;
    delete unrevealedURI;
  }

  /// @notice Set unrevealedURI to `newUnrevealedURI`.
  function setUnrevealedURI(string memory newUnrevealedURI) external onlyOwner {
    unrevealedURI = newUnrevealedURI;
  }

  /// @notice Set unrevealedURI to `newUnrevealedURI`.
  function setSaleState(uint256 newSaleState) external onlyOwner {
    saleState = newSaleState;
  }

  /// @notice Set freeClaimRoot to `newMerkleRoot`.
  function setFreeClaimRoot(bytes32 newMerkleRoot) external onlyOwner {
    freeClaimRoot = newMerkleRoot;
  }

  /// @notice Set earlyAccessRoot to `newMerkleRoot`.
  function setEarlyAccessRoot(bytes32 newMerkleRoot) external onlyOwner {
    earlyAccessRoot = newMerkleRoot;
  }

  /// @notice Set opensea to `newOpensea`.
  function setOpensea(address newOpensea) external onlyOwner {
    opensea = newOpensea;
  }

  /// @notice Set looksrare to `newLooksrare`.
  function setLooksrare(address newLooksrare) external onlyOwner {
    looksrare = newLooksrare;
  }

  /// @notice Set `addresses` authorization to `authorized`.
  function setAuth(address[] calldata addresses, bool authorized) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) auth[addresses[i]] = authorized;
  }

  /// @notice Toggle marketplaces pre-approve feature.
  function toggleMarketplacesApproved() external onlyOwner {
    marketplacesApproved = !marketplacesApproved;
  }

  /// @notice Toggle paused state.
  function togglePaused() external onlyOwner {
    if (paused()) _unpause();
    else _pause();
  }

  /// @notice Withdraw `amount` of ether to msg.sender.
  function withdraw(uint256 amount) external onlyOwner {
    payable(msg.sender).transfer(amount);
  }

  /// @notice Withdraw `amount` of `token` to the sender.
  function withdrawERC20(IERC20 token, uint256 amount) external onlyOwner {
    token.transfer(msg.sender, amount);
  }

  /// @notice Withdraw `tokenId` of `token` to the sender.
  function withdrawERC721(IERC721 token, uint256 tokenId) external onlyOwner {
    token.safeTransferFrom(address(this), msg.sender, tokenId);
  }

  /// @notice Withdraw `tokenId` with amount of `value` from `token` to the sender.
  function withdrawERC1155(
    IERC1155 token,
    uint256 tokenId,
    uint256 value
  ) external onlyOwner {
    token.safeTransferFrom(address(this), msg.sender, tokenId, value, "");
  }

  /// @notice See {ERC721-isApprovedForAll}.
  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    if (!marketplacesApproved) return auth[operator] || super.isApprovedForAll(owner, operator);
    return
      auth[operator] ||
      operator == address(ProxyRegistry(opensea).proxies(owner)) ||
      operator == looksrare ||
      super.isApprovedForAll(owner, operator);
  }

  /// @notice See {ERC721A-_beforeTokenTransfers}
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal override {
    require(!paused(), "Pausable: paused");
    super._beforeTokenTransfers(from, to, startTokenId, quantity);
  }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}
