// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./MerkleProofUpgradeable.sol";
import "./ISeed.sol";

contract SeedMinter is
  Initializable,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable
{
  // seed NFT contract address
  address public seed;

  // seed NFT sale price of native token
  uint256 public price;
  // SCR contract address
  address public scr;
  // SCR amount condition of free claim
  uint256 public scrAmountCondi;
  // store the merkle root hash of whitelist
  mapping(uint256 => bytes32) public whitelistRootHashes;
  // user claimed flag, true means claimed; user can only
  // free claim once whenever the claim method is whitelist or SCR
  mapping(address => bool) public claimed;

  // flag of pay mint feature gate
  bool public onMint;
  // flag of free claim with whitelist feature gate
  bool public onClaimWithWhitelist;
  // flag of free claim with SCR feature gate
  bool public onClaimWithSCR;

  // NFT minter address
  address public minter;

  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  event MintEnabled(address account);

  event MintDisabled(address account);

  event ClaimWithWhitelistEnabled(address account);

  event ClaimWithWhitelistDisabled(address account);

  event ClaimWithSCREnabled(address account);

  event ClaimWithSCRDisabled(address account);

  event MinterChanged(address indexed oldMinter, address indexed newMinter);

  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  /// @dev used to restrict methods that only minter address can call
  modifier onlyMinter() {
    require(_msgSender() == minter, "Only minter can call this method");
    _;
  }

  /// @dev used to restrict that each user can only free claim once, whether it is through the whitelist condition or the points condition, they can only free claim for free once
  modifier noClaimed() {
    require(!claimed[_msgSender()], "You have claimed");
    _;
  }

  /// @dev used to restrict methods that only can call when pay mint feature gate is open
  modifier enableMint() {
    require(onMint, "Mint is not open");
    _;
  }

  /// @dev used to restrict methods that only can call when claim with whitelist feature gate is open
  modifier enableClaimWithWhitelist() {
    require(onClaimWithWhitelist, "Claim with whitelist is not open");
    _;
  }

  /// @dev used to restrict methods that only can call when claim with SCR feature gate is open
  modifier enableClaimWithSCR() {
    require(onClaimWithSCR, "Claim with SCR is not open");
    _;
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------
  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address seed_,
    address scr_,
    uint256 scrAmountCondi_
  ) public initializer {
    seed = seed_;

    scr = scr_;
    scrAmountCondi = scrAmountCondi_ * 10 ** IERC20Metadata(scr_).decimals();

    // set default minter
    minter = msg.sender;
    // `onMint` is disabled by default
    // `onClaimWithWhitelist` is disabled by default
    // `onClaimWithSCR` is disabled by default

    __Ownable_init();
    __ReentrancyGuard_init();
  }

  /// @dev claim for free with whitelist, need to specify whitelist ID and Merkle Proof when calling
  /// `enableClaimWithWhitelist` modifier is used to restrict methods that only can call when claim with whitelist feature gate is open
  /// `noClaimed` modifier is used to restrict that each user can only free claim once, whether it is through the whitelist condition or the points condition, they can only free claim for free once
  /// `nonReentrant` modifier is used to restrict the current method from re-entering
  function claimWithWhitelist(
    uint256 whitelistId,
    bytes32[] calldata proof
  ) external enableClaimWithWhitelist noClaimed nonReentrant {
    require(
      _verifyWhitelist(whitelistId, proof, _msgSender()),
      "You are not in the whitelist"
    );

    // set claimed flag to true
    claimed[_msgSender()] = true;

    _mint(_msgSender(), ISeed(seed).totalSupply());
  }

  /// @dev claim for free with SCR
  /// `enableClaimWithSCR` modifier is used to restrict methods that only can call when claim with SCR feature gate is open
  /// `noClaimed` modifier is used to restrict that each user can only free claim once, whether it is through the whitelist condition or the SCR condition, they can only free claim for free once
  /// `nonReentrant` modifier is used to restrict the current method from re-entering
  function claimWithSCR() external enableClaimWithSCR noClaimed nonReentrant {
    require(scr != address(0), "SCR is not set");

    uint256 scrBalance = IERC20(scr).balanceOf(_msgSender());
    require(
      scrAmountCondi != 0 && scrBalance >= scrAmountCondi,
      "You don't have enough SCR"
    );

    // set claimed flag to true
    claimed[_msgSender()] = true;

    _mint(_msgSender(), ISeed(seed).totalSupply());
  }

  /// @dev used for airdrop, only minter can call, need to specify the receiving addresses
  function airdrop(address[] calldata to) external onlyMinter {
    uint256 id = ISeed(seed).totalSupply();
    for (uint256 i = 0; i < to.length; i++) {
      _mint(to[i], id);
      id++;
    }
  }

  /// @dev buy SEED directly with payment, supporting buy multiple NFTs at once
  /// `payable` modifier indicates that the current method can receive native token
  /// `enableMint` modifier is used to restrict methods that only can call when pay mint feature gate is open
  /// `nonReentrant` modifier is used to restrict the current method from re-entering
  function mint(uint256 amount) external payable enableMint nonReentrant {
    require(amount > 0, "Mint amount must bigger than zero");

    uint256 payValue = amount * price;
    require(price != 0 && msg.value >= payValue, "Insufficient payment");

    // refund the extra native token
    if (msg.value > payValue) {
      payable(_msgSender()).transfer(msg.value - payValue);
    }

    uint256 id = ISeed(seed).totalSupply();
    for (uint256 i = 0; i < amount; i++) {
      _mint(_msgSender(), id);
      id++;
    }
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  /// @dev verify whether an address is in the whitelist
  function _verifyWhitelist(
    uint256 whitelistId,
    bytes32[] calldata proof,
    address addr
  ) internal view returns (bool) {
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr))));
    return
      MerkleProofUpgradeable.verify(
        proof,
        whitelistRootHashes[whitelistId],
        leaf
      );
  }

  /// @dev mint SEED
  function _mint(address to, uint256 tokenId) internal {
    ISeed(seed).mint(to, tokenId);
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------
  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  /// @dev change minter address
  function changeMinter(address minter_) external onlyOwner {
    address oldMinter = minter;
    minter = minter_;
    emit MinterChanged(oldMinter, minter_);
  }

  /// @dev set SCR contract address
  function setSCR(address scr_) external onlyOwner {
    scr = scr_;
  }

  /// @dev set the SCR amount condition for free claim NFT
  /// for example: if the condition is `50_000` SCR, then pass in the integer `50_000`
  function setSCRAmountCondi(uint256 scrAmountCondi_) external onlyOwner {
    require(scr != address(0), "SCR is not set");

    scrAmountCondi = scrAmountCondi_ * 10 ** IERC20Metadata(scr).decimals();
  }

  /// @dev set SEED contract address
  function updateSeed(address seed_) external onlyOwner {
    seed = seed_;
  }

  /// @dev set whitelist, need to pass in whitelist ID and Merkle Tree Root Hash when calling
  /// the whitelist has different batches, when adding a new whitelist, a new whitelist ID is required
  /// start from 0 !!
  function setWhitelist(
    uint256 whitelistId,
    bytes32 rootHash
  ) external onlyOwner {
    whitelistRootHashes[whitelistId] = rootHash;
  }

  /// @dev set claimed addresses
  function setClaimed(address[] calldata addr) external onlyOwner {
    for (uint256 i = 0; i < addr.length; i++) {
      claimed[addr[i]] = true;
    }
  }

  /// @dev set NFT price, the decimals of the price is the same as the decimals of the chain native token
  function setPrice(uint256 price_) external onlyOwner {
    price = price_;
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------
  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  /// @dev pause pay mint feature, after paused, can't mint new NFT
  function pauseMint() public onlyOwner {
    onMint = false;
    emit MintDisabled(_msgSender());
  }

  /// @dev unpause pay mint feature, after unpaused, can mint new NFT
  function unpauseMint() public onlyOwner {
    onMint = true;
    emit MintEnabled(_msgSender());
  }

  /// @dev pause free claim with whitelist feature, after paused, can't free claim new NFT with whitelist
  function pauseClaimWithWhitelist() public onlyOwner {
    onClaimWithWhitelist = false;
    emit ClaimWithWhitelistDisabled(_msgSender());
  }

  /// @dev unpause free claim with whitelist feature, after unpaused, can free claim new NFT with whitelist
  function unpauseClaimWithWhitelist() public onlyOwner {
    onClaimWithWhitelist = true;
    emit ClaimWithWhitelistEnabled(_msgSender());
  }

  /// @dev pause free claim with SCR feature, after paused, can't free claim new NFT with SCR
  function pauseClaimWithSCR() public onlyOwner {
    onClaimWithSCR = false;
    emit ClaimWithSCRDisabled(_msgSender());
  }

  /// @dev unpause free claim with SCR feature, after unpaused, can free claim new NFT with SCR
  function unpauseClaimWithSCR() public onlyOwner {
    onClaimWithSCR = true;
    emit ClaimWithSCREnabled(_msgSender());
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------
  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  /// @dev set `Seed` contract's max supply
  function setSeedMaxSupply(uint256 maxSupply) external onlyOwner {
    ISeed(seed).setMaxSupply(maxSupply);
  }

  /// @dev set `Seed` contract's SCR contract address
  function setSeedSCR(address scr_) external onlyOwner {
    ISeed(seed).setSCR(scr_);
  }

  /// @dev set `Seed` contract's base URI
  function setSeedBaseURI(string memory baseURI) external onlyOwner {
    ISeed(seed).setBaseURI(baseURI);
  }

  /// @dev set `Seed` contract's URI level range rules
  function setSeedURILevelRange(
    uint256[] calldata uriLevelRanges
  ) external onlyOwner {
    ISeed(seed).setURILevelRange(uriLevelRanges);
  }

  /// @dev pause `Seed` contract
  function pauseSeed() external onlyOwner {
    ISeed(seed).pause();
  }

  /// @dev unpause `Seed` contract
  function unpauseSeed() external onlyOwner {
    ISeed(seed).unpause();
  }

  /// @dev transfer `Seed` contract's ownership
  function transferSeedOwnership(address newOwner) external onlyOwner {
    ISeed(seed).transferOwnership(newOwner);
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------
  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  receive() external payable {}

  /// @dev transfer all native token balance of this contract to the owner address
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(owner()).transfer(balance);
  }
}
