// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

/// @author Dopex
/// @title Dopex token sale contract
contract DopexTokenSale {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // DPX Token
  IERC20 public dpx;

  // rDPX Token
  IERC20 public rdpx;

  // Withdrawer
  address public owner;

  // Keeps track of ETH deposited
  uint256 public weiDeposited;

  // Time when the token sale starts for whitelisted address
  uint256 public saleWhitelistStart;

  // Time when the token sale starts
  uint256 public saleStart;

  // Time when the token sale closes
  uint256 public saleClose;

  // Max cap on wei raised
  uint256 public maxDeposits;

  // DPX Tokens allocated to this contract
  uint256 public dpxTokensAllocated;

  // rDXP Tokens allocated to this contract
  uint256 public rdpxTokensAllocated;

  // Total sale participants
  uint256 public totalSaleParticipants;

  // Max ETH that can be deposited by whitelisted addresses
  uint256 public maxWhitelistDeposit;

  // Merkleroot of whitelisted addresses
  bytes32 public merkleRoot;

  // Amount each user deposited
  mapping(address => uint256) public deposits;

  // This is a packed array of booleans.
  mapping(uint256 => uint256) private claimedBitMap;

  /// Emits on ETH deposit
  /// @param purchaser contract caller purchasing the tokens on behalf of beneficiary
  /// @param beneficiary will be able to claim tokens after saleClose
  /// @param isWhitelistDeposit is the deposit done via the whitelist function
  /// @param value amount of ETH deposited
  event TokenDeposit(
    address indexed purchaser,
    address indexed beneficiary,
    bool indexed isWhitelistDeposit,
    uint256 value
  );

  /// Emits on token claim
  /// @param claimer contract caller claiming on behalf of beneficiary
  /// @param beneficiary receives the tokens they claimed
  /// @param amount token amount beneficiary claimed
  event TokenClaim(
    address indexed claimer,
    address indexed beneficiary,
    uint256 amount
  );

  /// Emits on eth withdraw
  /// @param amount amount of Eth that was withdrawn
  event WithdrawEth(uint256 amount);

  /// @param _dpx DPX
  /// @param _rdpx rDPX
  /// @param _owner withdrawer
  /// @param _saleWhitelistStart time when the token sale starts for whitelisted addresses
  /// @param _saleStart time when the token sale starts
  /// @param _saleClose time when the token sale closes
  /// @param _maxDeposits max cap on wei raised
  /// @param _dpxTokensAllocated DPX tokens allocated to this contract
  /// @param _rdpxTokensAllocated rDPX tokens allocated to this contract
  /// @param _maxWhitelistDeposit max deposit that can be done via the whitelist deposit fn
  /// @param _merkleRoot the merkle root of all the whitelisted addresses
  constructor(
    address _dpx,
    address _rdpx,
    address _owner,
    uint256 _saleWhitelistStart,
    uint256 _saleStart,
    uint256 _saleClose,
    uint256 _maxDeposits,
    uint256 _dpxTokensAllocated,
    uint256 _rdpxTokensAllocated,
    uint256 _maxWhitelistDeposit,
    bytes32 _merkleRoot
  ) {
    require(_owner != address(0), "invalid owner address");
    require(_dpx != address(0), "invalid token address");
    require(_rdpx != address(0), "invalid token address");
    require(_saleStart >= block.timestamp, "invalid saleStart");
    require(_saleClose > _saleStart, "invalid saleClose");
    require(_maxDeposits > 0, "invalid maxDeposits");
    require(_dpxTokensAllocated > 0, "invalid dpxTokensAllocated");
    require(_rdpxTokensAllocated > 0, "invalid rdpxTokensAllocated");

    dpx = IERC20(_dpx);
    rdpx = IERC20(_rdpx);
    owner = _owner;
    saleWhitelistStart = _saleWhitelistStart;
    saleStart = _saleStart;
    saleClose = _saleClose;
    maxDeposits = _maxDeposits;
    dpxTokensAllocated = _dpxTokensAllocated;
    rdpxTokensAllocated = _rdpxTokensAllocated;
    maxWhitelistDeposit = _maxWhitelistDeposit;
    merkleRoot = _merkleRoot;
  }

  /// Checks if a whitelisted address has already deposited using the whitelist deposit fn
  /// @param index the index of the whitelisted address in the merkle tree
  function isWhitelistedAddressDeposited(uint256 index)
    public
    view
    returns (bool)
  {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    uint256 claimedWord = claimedBitMap[claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  /// Sets a whitelisted address to have used the whitelist deposit fn
  /// @param index the index of the whitelisted address in the merkle tree
  function _setWhitelistedAddressDeposited(uint256 index) internal {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    claimedBitMap[claimedWordIndex] =
      claimedBitMap[claimedWordIndex] |
      (1 << claimedBitIndex);
  }

  /// Deposit fallback
  /// @dev must be equivalent to deposit(address beneficiary)
  receive() external payable {
    address beneficiary = msg.sender;

    require(beneficiary != address(0), "invalid address");
    require(msg.value > 0, "invalid amount");
    require(
      (weiDeposited + msg.value) <= maxDeposits,
      "maximum deposits reached"
    );
    require(saleStart <= block.timestamp, "sale hasn't started yet");
    require(block.timestamp <= saleClose, "sale has closed");

    // Update total sale participants
    if (deposits[beneficiary] == 0) {
      totalSaleParticipants = totalSaleParticipants.add(1);
    }

    deposits[beneficiary] = deposits[beneficiary].add(msg.value);
    weiDeposited = weiDeposited.add(msg.value);
    emit TokenDeposit(msg.sender, beneficiary, false, msg.value);
  }

  /// Deposit for whitelisted address
  /// @param index the index of the whitelisted address in the merkle tree
  /// @param beneficiary will be able to claim tokens after saleClose
  /// @param merkleProof the merkle proof
  function depositForWhitelistedAddress(
    uint256 index,
    address beneficiary,
    bytes32[] calldata merkleProof
  ) external payable {
    require(!isWhitelistedAddressDeposited(index), "deposit already used");
    require(beneficiary != address(0), "invalid address");
    require(
      msg.value > 0 && msg.value <= maxWhitelistDeposit,
      "invalid amount"
    );
    require(
      (weiDeposited + msg.value) <= maxDeposits,
      "maximum deposits reached"
    );
    require(saleWhitelistStart <= block.timestamp, "sale hasn't started yet");
    require(block.timestamp <= saleClose, "sale has closed");

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, beneficiary));
    require(MerkleProof.verify(merkleProof, merkleRoot, node), "invalid proof");

    // Mark it claimed and send the token.
    _setWhitelistedAddressDeposited(index);

    // Update total sale participants
    if (deposits[beneficiary] == 0) {
      totalSaleParticipants = totalSaleParticipants.add(1);
    }

    deposits[beneficiary] = deposits[beneficiary].add(msg.value);

    weiDeposited = weiDeposited.add(msg.value);

    emit TokenDeposit(msg.sender, beneficiary, true, msg.value);
  }

  /// Deposit
  /// @param beneficiary will be able to claim tokens after saleClose
  /// @dev must be equivalent to receive()
  function deposit(address beneficiary) public payable {
    require(beneficiary != address(0), "invalid address");
    require(msg.value > 0, "invalid amount");
    require(
      (weiDeposited + msg.value) <= maxDeposits,
      "maximum deposits reached"
    );
    require(saleStart <= block.timestamp, "sale hasn't started yet");
    require(block.timestamp <= saleClose, "sale has closed");

    // Update total sale participants
    if (deposits[beneficiary] == 0) {
      totalSaleParticipants = totalSaleParticipants.add(1);
    }

    deposits[beneficiary] = deposits[beneficiary].add(msg.value);
    weiDeposited = weiDeposited.add(msg.value);
    emit TokenDeposit(msg.sender, beneficiary, false, msg.value);
  }

  /// Claim
  /// @param beneficiary receives the tokens they claimed
  /// @dev claim calculation must be equivalent to claimAmount(address beneficiary)
  function claim(address beneficiary) external returns (uint256) {
    require(deposits[beneficiary] > 0, "no deposit");
    require(block.timestamp > saleClose, "sale hasn't closed yet");

    // total DPX allocated * user share in the ETH deposited
    uint256 beneficiaryClaim = dpxTokensAllocated
    .mul(deposits[beneficiary])
    .div(weiDeposited);
    deposits[beneficiary] = 0;

    dpx.safeTransfer(beneficiary, beneficiaryClaim);

    rdpx.safeTransfer(
      beneficiary,
      rdpxTokensAllocated.div(totalSaleParticipants)
    );

    emit TokenClaim(msg.sender, beneficiary, beneficiaryClaim);

    return beneficiaryClaim;
  }

  /// @dev Withdraws eth deposited into the contract. Only owner can call this.
  function withdraw() external {
    require(owner == msg.sender, "caller is not the owner");

    uint256 ethBalance = payable(address(this)).balance;

    payable(msg.sender).transfer(ethBalance);

    emit WithdrawEth(ethBalance);
  }

  /// View beneficiary's claimable token amount
  /// @param beneficiary address to view claimable token amount
  /// @dev claim calculation must be equivalent to the one in claim(address beneficiary)
  function claimAmount(address beneficiary) external view returns (uint256) {
    if (weiDeposited == 0) {
      return 0;
    }

    // total DPX allocated * user share in the ETH deposited
    return dpxTokensAllocated.mul(deposits[beneficiary]).div(weiDeposited);
  }
}
