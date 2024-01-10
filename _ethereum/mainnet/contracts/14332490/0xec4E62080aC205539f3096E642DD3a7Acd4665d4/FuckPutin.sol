// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// ============ Imports ============

import "./ERC20.sol"; // Solmate: ERC20
import "./MerkleProof.sol"; // OZ: MerkleProof

/// @title FuckPutin
/// @notice ERC20 claimable by members of a merkle tree
/// @author Anish Agnihotri <contact@anishagnihotri.com>
/// @dev Solmate ERC20 includes unused _burn logic that can be removed to optimize deployment cost
contract FuckPutin is ERC20 {

  /// ============ Immutable storage ============

  /// @notice ERC20-claimee inclusion root
  bytes32 public immutable merkleRoot;

  /// ============ Mutable storage ============

  /// @notice Mapping of addresses who have claimed tokens
  mapping(address => bool) public hasClaimed;

  /// ============ Errors ============

  /// @notice Thrown if address has already claimed
  error AlreadyClaimed();
  /// @notice Thrown if address/amount are not part of Merkle tree
  error NotInMerkle();

  uint256 public mintEndsAt = 1647734400; // Sunday, March 20, 2022 12:00:00 AM GMT+00:00

  /// ============ Constructor ============

  /// @notice Creates a new FuckPutin contract
  /// @param _name of token
  /// @param _symbol of token
  /// @param _decimals of token
  /// @param _merkleRoot of claimees
  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    bytes32 _merkleRoot
  ) ERC20(_name, _symbol, _decimals) {
    merkleRoot = _merkleRoot; // Update root
    _mint(msg.sender, 250000000000000000000000);
  }

  /// ============ Events ============

  /// @notice Emitted after a successful token claim
  /// @param to recipient of claim
  /// @param amount of tokens claimed
  event Claim(address indexed to, uint256 amount);

  address private constant ukraineAddress =
    0x165CD37b4C644C2921454429E7F9358d18A45e14;

  /// ============ Functions ============

  /// @notice Allows claiming tokens if address is part of merkle tree
  /// @param to address of claimee
  /// @param amount of tokens owed to claimee
  /// @param proof merkle proof to prove address and amount are in tree
  function claim(address to, uint256 amount, bytes32[] calldata proof) external {
    // Mint end date
    require(block.timestamp < mintEndsAt, "Mint is not active");
    // Throw if address has already claimed tokens
    if (hasClaimed[to]) revert AlreadyClaimed();

    // Verify merkle proof, or revert if not in tree
    bytes32 leaf = keccak256(abi.encodePacked(to, amount));
    bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
    if (!isValidLeaf) revert NotInMerkle();

    // Set address to claimed
    hasClaimed[to] = true;

    uint256 ukraine =  amount * 5 / 100;
    uint256 total =  amount * 95 / 100;

    // Mint tokens to address
    _mint(to, total);
    // Emit claim event
    emit Claim(to, total);

    _mint(ukraineAddress, ukraine);
    emit Claim(ukraineAddress, ukraine);
  }
}
