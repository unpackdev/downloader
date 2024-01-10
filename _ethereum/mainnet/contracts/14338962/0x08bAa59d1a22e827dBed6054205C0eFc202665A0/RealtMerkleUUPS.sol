// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma abicoder v1;

import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ICumulativeMerkleDrop.sol";

contract RealtMerkleUUPS is AccessControlUpgradeable, UUPSUpgradeable, ICumulativeMerkleDrop {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

  address public override token;
  bytes32 public override merkleRoot;
  
  mapping(address => uint256) private _cumulativeClaimed;

  /// @notice the initialize function to execute only once during the contract deployment
  /// @param token_ address of the token in the vault
  /// @param admin address of the admin with unique responsibles: set the merkle root, withdraw tokens, upgrade the contract
  function initialize(address token_, address admin) initializer external {
    __AccessControl_init();
    __UUPSUpgradeable_init();

    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(UPGRADER_ROLE, admin);
    token = token_;
  }

  /// @notice The admin (with upgrader role) uses this function to update the contract
  /// @dev This function is always needed in future implementation contract versions, otherwise, the contract will not be upgradeable
  /// @param newImplementation is the address of the new implementation contract
  function _authorizeUpgrade(address newImplementation) internal onlyRole(UPGRADER_ROLE) override {}

  /// @notice only the default admin role can call this function
  /// @dev update the merkle root to update user balance for multiple tokens
  /// @param merkleRoot_ The new merkle root to be updated in the contract
  function setMerkleRoot(bytes32 merkleRoot_) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    emit MerkelRootUpdated(merkleRoot, merkleRoot_);
    merkleRoot = merkleRoot_;
  }

  /// @notice query the total amount that the user claimed for a given token
  /// @param account user address
  /// @return the total amount that the user already claimed
  function totalClaimedAmount(address account) external override view returns (uint256) {
    return _cumulativeClaimed[account];
  }

  /// @notice allows users to claim their token (verifed by merkle tree)
  /// @param account user address
  /// @param cumulativeAmount array of cumulative amount for each token (2 arrays must have the same length)
  /// @param expectedMerkleRoot merkle root (need to update each week to update user balance)
  /// @param merkleProof merkle proof to be provided for verification of user balance 
  function claim(
    address account,
    uint256 cumulativeAmount,
    bytes32 expectedMerkleRoot,
    bytes32[] calldata merkleProof
  ) external override {
    // Verify the merkle root
    require(merkleRoot == expectedMerkleRoot, "CMD: Merkle root was updated");

    // Verify the merkle proof
    bytes32 leaf = keccak256(abi.encodePacked(account, cumulativeAmount));
    require(_verifyAsm(merkleProof, expectedMerkleRoot, leaf), "CMD: Invalid proof");

    // Mark it claimed
    uint256 preclaimed = _cumulativeClaimed[account];
    require(preclaimed < cumulativeAmount, "CMD: Nothing to claim");
    _cumulativeClaimed[account] = cumulativeAmount;

    // Send the token
    unchecked {
      uint256 amount = cumulativeAmount - preclaimed;
      IERC20Upgradeable(token).safeTransfer(account, amount);
      emit Claimed(account, amount);
    }
  }

  /// @notice The function allows the admin to withdraw token from the vault
  /// @dev uses admin wallet to call the function
  /// @param account address to which the admin want to withdraw tokens
  /// @param amount array of amounts to withdraw for each token
  function withdraw(address account, uint256 amount) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    IERC20Upgradeable(token).safeTransfer(account, amount);
    emit Withdrawed(account, amount);
  }

  /// @notice if a leaf belonging to the merkle tree with the given proof
  /// @param proof array of proof to be provided for merkle tree verification
  /// @param root merkle root of the merkle tree
  /// @param leaf leaf that coresponds to the user
  /// @return valid which is true if a leaf with the provided proof belongs to the merkle tree (root)
  function _verifyAsm(bytes32[] calldata proof, bytes32 root, bytes32 leaf) private pure returns (bool valid) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let mem1 := mload(0x40)
      let mem2 := add(mem1, 0x20)
      let ptr := proof.offset

      for { let end := add(ptr, mul(0x20, proof.length)) } lt(ptr, end) { ptr := add(ptr, 0x20) } {
        let node := calldataload(ptr)

        switch lt(leaf, node)
        case 1 {
          mstore(mem1, leaf)
          mstore(mem2, node)
          }
          default {
            mstore(mem1, node)
            mstore(mem2, leaf)
          }

          leaf := keccak256(mem1, 0x40)
      }

      valid := eq(root, leaf)
    }
  }

}