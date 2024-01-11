// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Initializable.sol";
import "./ERC20PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MerkleProof.sol";

contract WireToken is
  Initializable,
  ERC20PausableUpgradeable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable
{
  // Mapping from an address to whether or not it can mint / burn
  mapping(address => bool) public controllers;

  uint public claimId;
  bool public whitelistAllowed;

  // Mapping for claim staus
  mapping(uint => uint) public claimeds;

  // Merlet root for airdrop
  bytes32 public merkleRoot;
  mapping(address => uint) public whitelistUsed;

  uint public MAX_SUPPLY;
  uint public lockedAmount;

  function initialize() external initializer {
    __Ownable_init_unchained();
    __ERC20_init_unchained("WireToken", "WIRE");
    __ERC20Pausable_init_unchained();
    __ReentrancyGuard_init_unchained();

    merkleRoot = "";
    whitelistAllowed = false;
    MAX_SUPPLY = 50000000 ether;
    lockedAmount = MAX_SUPPLY / 2;
    _mint(address(this), lockedAmount);
    _mint(owner(), lockedAmount);

  }

  function whitelistClaim(
    uint allocation,
    bytes32 leaf,
    bytes32[] memory proof
  ) external nonReentrant {
    require(whitelistAllowed, "Whitelist is not allowed");
    // Verify that (leaf, proof) matches the Merkle root
    require(
      verify(merkleRoot, leaf, proof),
      "Not a valid leaf in the Merkle tree"
    );

    // Verify that (msg.sender, amount) correspond to Merkle leaf
    require(
      keccak256(abi.encodePacked(msg.sender, allocation)) == leaf,
      "Sender and amount don't match Merkle leaf"
    );

    // Check if the tokens are already claimed
    require(whitelistUsed[msg.sender] != claimId, "Tokens are already claimed");

    // Check if amount of tokens on the contract is enough
    require(
      (balanceOf(address(this)) - lockedAmount) >= allocation,
      "Amount of contract tokens is not enough"
    );

    _transfer(address(this), msg.sender, allocation);
    whitelistUsed[msg.sender] = claimId;
    claimeds[claimId] += 1;
  }

  function verify(
    bytes32 root,
    bytes32 leaf,
    bytes32[] memory proof
  ) public pure returns (bool) {
    return MerkleProof.verify(proof, root, leaf);
  }

  function mint(address to, uint256 amount) external whenNotPaused {
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external whenNotPaused {
    require(controllers[msg.sender], "Only controllers can burn");
    if (lockedAmount > 0) {
      lockedAmount -= (lockedAmount > amount ? amount : lockedAmount);
    }
    _burn(from, amount);
  }

  function setClaimId(uint _claimId) external onlyOwner {
    claimId = _claimId;
  }

  function setWhitelistAllowed(bool _whitelistAllowed) external onlyOwner {
    whitelistAllowed = _whitelistAllowed;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }
}
