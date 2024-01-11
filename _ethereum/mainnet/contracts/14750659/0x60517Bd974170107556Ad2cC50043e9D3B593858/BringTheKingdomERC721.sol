// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Royalty.sol";

contract BringTheKingdomERC721 is ERC721Royalty, ERC721Enumerable, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using Strings for uint256;

  // Locked         - 0
  // Open           - 1
  // Ended          - 2
  enum SalePhase {
    WaitingToStart,
    InProgress,
    Finished
  }

  address private immutable signer = 0x304cE1e59421aCBc6adA104ba1b5F07f2f4676Cb;
  address private immutable oneTenthAddress = 0xd0FD9e61e6666b8A64eB7Cf030104098621E50f2;
  address private immutable nineTenthsAddress = 0x9b29249acCAC9A4D833165B17600d52330413B20;
  address private royaltiesAddress = 0xb296Ee82732E907f068b8461513073cFb128EE2B;
  string private _baseURIextended;

  uint96 private constant ROYALTIES_BPS = 1000; // = 10%
  uint256 public constant MAX_TOKENS_PER_WALLET = 500;
  uint256 public constant MAX_TOKENS_PER_MINT = 500;
  uint256 public constant MAX_TOKENS = 1000;
  uint256 public constant FREE_RESERVED_COUNT = 100;

  uint256 private teamMintedCounter;
  uint256 public tokenMintPrice = 1 ether; //1 ETH initial

  bool public metadataIsFrozen;
  bool public giveawayAllowed;
  bool public giveawayFrozen;

  mapping(bytes => bool) public usedSignatures;

  SalePhase public phase;

  constructor() ERC721("BRING THE KINGDOM", "BTK") {
    _setDefaultRoyalty(royaltiesAddress, ROYALTIES_BPS);
  }

  // /// Freezes the metadata
  // /// @dev sets the state of `metadataIsFrozen` to true
  // /// @notice permamently freezes the metadata so that no more changes are possible
  function freezeMetadata() external onlyOwner {
    // require(!metadataIsFrozen, "Metadata is already frozen");
    metadataIsFrozen = true;
  }

  // /// Adjust the mint price
  // /// @dev modifies the state of the `mintPrice` variable
  // /// @notice sets the price for minting a token
  // /// @param newPrice_ The new price for minting
  function adjustMintPrice(uint256 newPrice_) external onlyOwner {
    tokenMintPrice = newPrice_;
  }

  // /// Advance Phase
  // /// @dev Advance the sale phase state
  // /// @notice Advances sale phase state incrementally

  function enterNextPhase(SalePhase phase_) external onlyOwner {
    require(
      uint8(phase_) == uint8(phase) + 1 && (uint8(phase_) >= 0 && uint8(phase_) <= 3),
      "can only advance phases"
    );

    phase = phase_;
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
    super._burn(tokenId);
  }

  /// Disburse payments
  /// @dev transfers amounts that correspond to addresses passeed in as args
  /// @param payees_ recipient addresses
  /// @param amounts_ amount to payout to address with corresponding index in the `payees_` array
  function disbursePayments(address[] memory payees_, uint256[] memory amounts_)
    external
    onlyOwner
  {
    require(payees_.length == amounts_.length, "Payees and amounts length mismatch.");

    for (uint256 i; i < payees_.length; i++) {
      makePaymentTo(payees_[i], amounts_[i]);
    }
  }

  /// Make a payment
  /// @dev internal fn called by `disbursePayments` to send Ether to an address
  function makePaymentTo(address address_, uint256 amt_) private {
    (bool success, ) = address_.call{value: amt_}("");
    require(success, "Transfer failed.");
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    require(
      super.balanceOf(to) + 1 <= MAX_TOKENS_PER_WALLET,
      "Transfer would exceed max per wallet for receiver."
    );
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIextended;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Royalty, ERC721Enumerable)
    returns (bool)
  {
    return interfaceId == type(ERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
    require(!metadataIsFrozen, "Metadata is permanently frozen.");
    _baseURIextended = baseURI_;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "URI query for nonexistent token.");

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
  }

  function _saleIsActive() private view {
    require(uint8(phase) == 1, "Sale not active.");
  }

  modifier saleIsActive() {
    _saleIsActive();
    _;
  }

  function _notOverMaxSupply(uint256 supplyToMint, uint256 maxSupplyOfTokens) private pure {
    require(supplyToMint <= maxSupplyOfTokens, "Reached Max Allowed to Buy."); // if it goes over 10000
  }

  function _isNotOverMaxPerMint(uint256 supplyToMint) private pure {
    require(supplyToMint <= MAX_TOKENS_PER_MINT, "Reached Max to MINT per Purchase.");
  }

  function recoverSigner(bytes32 hash, bytes memory signature) public pure returns (address) {
    bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

    return ECDSA.recover(messageDigest, signature);
  }

  function freeMintByContractOwner(uint256 numberOfTokens, address receiver) public onlyOwner nonReentrant {
    _isNotOverMaxPerMint(numberOfTokens);
    _notOverMaxSupply(numberOfTokens + totalSupply(), MAX_TOKENS);
    require(teamMintedCounter < FREE_RESERVED_COUNT, "All free tokens are minted.");
    require(
      super.balanceOf(msg.sender) + numberOfTokens <= MAX_TOKENS_PER_MINT,
      "You can hold a max of 500 tokens."
    );

    for (uint256 i = 0; i < numberOfTokens; i++) {
      uint256 mintIndex = teamMintedCounter + 1;

      if (mintIndex <= MAX_TOKENS) {
        _safeMint(receiver, mintIndex);
        teamMintedCounter++;
      }
    }
  }

  function mint(uint256 numberOfTokens) public payable saleIsActive nonReentrant {
    _isNotOverMaxPerMint(numberOfTokens);
    _notOverMaxSupply(numberOfTokens + totalSupply(), MAX_TOKENS);
    require(
      super.balanceOf(msg.sender) + numberOfTokens <= MAX_TOKENS_PER_MINT,
      "You can hold a max of 500 tokens."
    );
    require(tokenMintPrice * numberOfTokens <= msg.value, "Ether is not enough.");

    for (uint256 i = 0; i < numberOfTokens; i++) {
      uint256 mintIndex = totalSupply() + 1;

      if (mintIndex <= MAX_TOKENS) {
        _safeMint(msg.sender, mintIndex);
      }
    }

    uint256 oneTenth = msg.value.div(100).mul(10);
    uint256 nineTenths = msg.value.div(100).mul(90);

    (bool oneTenthSuccess, ) = oneTenthAddress.call{value: oneTenth}("");
    require(oneTenthSuccess, "Withdraw transaction #1 failed");

    (bool nineTenthsSuccess, ) = nineTenthsAddress.call{value: nineTenths}("");
    require(nineTenthsSuccess, "Withdraw transaction #2 failed");
  }

  function enableGiveaway() public onlyOwner {
    require(!giveawayFrozen, "Giveaway can not be enabled, it is frozen!");
    giveawayAllowed = true;
  }

  function disableGiveaway() public onlyOwner {
    giveawayAllowed = false;
    giveawayFrozen = true;
  }

  function freeMint(bytes32 hash, bytes memory signature) public saleIsActive nonReentrant {
    require(giveawayAllowed, "Giveaway not enabled");

    _isNotOverMaxPerMint(1);
    _notOverMaxSupply(1 + totalSupply(), MAX_TOKENS);

    require(teamMintedCounter < FREE_RESERVED_COUNT, "All Giveaway Spots are already used!");
    require(
      recoverSigner(hash, signature) == signer && !usedSignatures[signature],
      "Free giveaway not allowed for your address!"
    );
    require(
      super.balanceOf(msg.sender) + 1 <= MAX_TOKENS_PER_MINT,
      "You can hold a max of 500 tokens"
    );

    _safeMint(msg.sender, totalSupply() + 1);

    teamMintedCounter++;
    usedSignatures[signature] = true;
  }
}
