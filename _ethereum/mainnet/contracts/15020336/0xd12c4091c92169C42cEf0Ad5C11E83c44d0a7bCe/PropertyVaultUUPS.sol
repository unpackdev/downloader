// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./IPropertyVaultUUPS.sol";

contract PropertyVaultUUPS is AccessControlUpgradeable, UUPSUpgradeable, IPropertyVaultUUPS {
  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
  bytes32 private _merkleRoot;
  bytes private _contractSignature;
  address[] private _trustedIntermediaries;
  IGnosisSafe private _trustedIntermediary;
  IGnosisSafe private _distributor;
  IComplianceRegistry private _complianceRegistry;
  mapping(address => mapping(address => uint256)) private _cumulativeClaimedPerToken;

  bytes4 private constant UPDATE_USER = IComplianceRegistry.updateUserAttributes.selector;
  bytes4 private constant REGISTER_USER = IComplianceRegistry.registerUser.selector;
  bytes4 private constant TRANSFER_FROM = IBridgeToken.transferFrom.selector;

  /// @notice the initialize function to execute only once during the contract deployment
  /// @param admin address of the admin with unique responsibles: set the merkle root, upgrade the contract
  function initialize(
    address admin,
    IGnosisSafe trustedIntermediary_,
    IGnosisSafe distributor_,
    IComplianceRegistry complianceRegistry_
  ) external initializer {
    __AccessControl_init();
    __UUPSUpgradeable_init();
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(UPGRADER_ROLE, admin);
    _computeSignature();
    _distributor = distributor_;
    _trustedIntermediary = trustedIntermediary_;
    _complianceRegistry = complianceRegistry_;
    _trustedIntermediaries.push(address(trustedIntermediary_));
  }

  function _computeSignature() private {
    bytes memory s = new bytes(65);
    bytes memory contractAddress = abi.encodePacked(address(this));
    uint8 i = 0;
    uint8 j = 0;
    while (i < 44) {
      if (i != 12) s[i + j] = 0x00;
      else while (j < 20) {s[i + j] = contractAddress[j]; unchecked { ++j;}}
      unchecked { ++i; }
    }
    s[i + j] = 0x01;
    _contractSignature = s;
  }
  /// @notice The admin (with upgrader role) uses this function to update the contract
  /// @dev This function is always needed in future implementation contract versions, otherwise, the contract will not be upgradeable
  /// @param newImplementation is the address of the new implementation contract
  function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

  /// @notice query the total amount that the user claimed for a given token
  /// @param token_ token address 
  /// @param account_ user address
  /// @return the total amount of a token that the user already claimed
  function totalClaimedAmount(address token_, address account_) external override view returns (uint256) {
    return _cumulativeClaimedPerToken[token_][account_];
  }

  /// @notice query the total amount that the user claimed for a given token
  /// @param tokens_ token address 
  /// @param account_ user address
  /// @return amounts total amount of a token that the user already claimed
  function totalClaimedAmounts(address[] calldata tokens_, address account_) external override view returns (uint256[] memory) {
    uint256 length = tokens_.length;
    uint256[] memory amounts = new uint256[](length);
    for (uint256 i = 0; i < length;) {
      amounts[i] = _cumulativeClaimedPerToken[tokens_[i]][account_];
      ++i;
    }
    return amounts;
  }

  /// @notice allows users to claim their token (verifed by merkle tree)
  /// @param account user address
  /// @param tokens array of tokens in the user balance
  /// @param cumulativeAmounts array of cumulative amount for each token (2 arrays must have the same length)
  /// @param expectedMerkleRoot merkle root (need to update each week to update user balance)
  /// @param merkleProof merkle proof to be provided for verification of user balance 
  function claim(
    address account,
    address[] calldata tokens,
    uint256[] calldata cumulativeAmounts,
    bytes32 expectedMerkleRoot,
    bytes32[] calldata merkleProof
  ) external override {
    // Verify the merkle root
    require(_merkleRoot == expectedMerkleRoot, "CMD: Merkle root was updated");
    // Verify that tokens and cumulativeAmounts have the same length
    require(tokens.length == cumulativeAmounts.length, "CMD: Length of Tokens != amounts");
    // Verify the merkle proof
    bytes32 leaf = keccak256(abi.encodePacked(account, tokens, cumulativeAmounts));
    require(_verifyAsm(merkleProof, expectedMerkleRoot, leaf), "CMD: Invalid proof");
    // Whitelist account
    _whitelist(account, tokens);
    // Iterate through the tokens array 
    for (uint256 i = 0; i < tokens.length; i++) {
      // Check if the user has something to claim for each token
      uint256 preclaimed = _cumulativeClaimedPerToken[tokens[i]][account];
      if (preclaimed == cumulativeAmounts[i]) continue; // If nothing to claim continue
      require(preclaimed < cumulativeAmounts[i], "CMD: Please contact support");

      // Mark it claimed in the mapping _cumulativeClaimedPerToken
      _cumulativeClaimedPerToken[tokens[i]][account] = cumulativeAmounts[i];

      // Send the token
      uint256 amount = cumulativeAmounts[i] - preclaimed;
      address owner = IBridgeToken(tokens[i]).owner();
      _staticTransferFrom(owner, account, amount, tokens[i]);
    }
    emit Claimed(account, tokens, cumulativeAmounts);
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

  function _getTokenAttributes(address[] calldata tokens, uint256 length) private view returns (uint256[] memory, uint256[] memory) {
    // Get tokenId from token address
    // Create an array of [1,1,...,1] to whitelist
    uint256[] memory tokenIds = new uint256[](length);
    uint256[] memory attributeValues = new uint256[](length);
    for (uint256 i = 0; i < length;) { 
      (, uint256 tokenId) = (IBridgeToken(tokens[i]).rule(0)); // token address => tokenId (attributeKeys)
      tokenIds[i] = tokenId;
      attributeValues[i] = 1;
      unchecked { ++i; }
    }
    return (tokenIds, attributeValues);
  }

  /// @param account user address
  /// @param tokens tokens addresses to whitelist
  function _whitelist(address account, address[] calldata tokens) private {
    // Check if the user is already registered
    (uint256 userId, ) = _complianceRegistry.userId(_trustedIntermediaries, account);
    uint256 length = tokens.length;
    (uint256[] memory tokenIds, uint256[] memory attributeValues) = _getTokenAttributes(tokens, length);
    // If the user is not registered, register the user with tokenIds and attributeValues
    if (userId == 0) {
      _staticRegisterUser(account, tokenIds, attributeValues);
    } else {
      uint256[] memory isWhitelistedValues = _complianceRegistry.attributes(address(_trustedIntermediary), userId, tokenIds);
      for (uint256 i = 0; i < length;) {
        if (isWhitelistedValues[i] == 0) {
          _staticUpdateUserAttributes(userId, tokenIds, attributeValues);
          break;
        }
        unchecked { ++i; }
      }
    }
  }

  function _staticUpdateUserAttributes(
    uint256 _userId, 
    uint256[] memory _attributeKeys, 
    uint256[] memory _attributeValues
  ) private {
    bytes memory encodedUpdateUserSelector = abi.encodeWithSelector(UPDATE_USER, _userId, _attributeKeys, _attributeValues);
    _execTransaction(_trustedIntermediary, address(_complianceRegistry),0,encodedUpdateUserSelector,Enum.Operation.Call,0,0,0,address(0),payable(address(0)),_contractSignature);
  }

  function _staticRegisterUser(
    address _address,
    uint256[] memory _attributeKeys,
    uint256[] memory _attributeValues
  ) private {
    bytes memory encodedRegisterSelector = abi.encodeWithSelector(REGISTER_USER, _address, _attributeKeys, _attributeValues);
    _execTransaction(_trustedIntermediary, address(_complianceRegistry),0,encodedRegisterSelector,Enum.Operation.Call,0,0,0,address(0),payable(address(0)),_contractSignature);
  }

  function _staticTransferFrom(
    address _from,
    address _to,
    uint256 _value,
    address token
  ) private {
    bytes memory encodedTransferSelector = abi.encodeWithSelector(TRANSFER_FROM, _from, _to, _value);
    _execTransaction(_distributor, address(token),0,encodedTransferSelector,Enum.Operation.Call,0,0,0,address(0),payable(address(0)),_contractSignature);
  }

  function _execTransaction(
    IGnosisSafe target,
    address to,
    uint256 value,
    bytes memory data,
    Enum.Operation operation,
    uint256 safeTxGas,
    uint256 baseGas,
    uint256 gasPrice,
    address gasToken,
    address payable refundReceiver,
    bytes memory signatures
  ) private {
    require(target.execTransaction(
      to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, signatures
    ), "CMD: execTransaction failed");
  }

  /// @notice only the default admin role can call this function
  /// @dev update the merkle root to update user balance for multiple tokens
  /// @param merkleRoot_ The new merkle root to be updated in the contract
  function setMerkleRoot(bytes32 merkleRoot_) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    emit MerkelRootUpdated(_merkleRoot, merkleRoot_);
    _merkleRoot = merkleRoot_;
  }

  /// @notice getter function of the merkle root
  /// @return the current merkle root in the vault contract
  function merkleRoot() external override view returns (bytes32) {
    return _merkleRoot;
  }

  /// @param distributor_ new address of GnosisSafe wallet which is the token distributor
  function setDistributor(IGnosisSafe distributor_) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    emit DistributorUpdated(_distributor, distributor_);
    _distributor = distributor_;
  }

  /// @return _distributor the address of GnosisSafe wallet which is the token distributor
  function distributor() external override view returns (IGnosisSafe) {
    return _distributor;
  }

  /// @param trustedIntermediary_ new address of trustedIntermediary in case of modifying KYC operator
  function setTrustedIntermediary(IGnosisSafe trustedIntermediary_) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    emit TrustedIntermediaryUpdated(_trustedIntermediary, trustedIntermediary_);
    _trustedIntermediary = trustedIntermediary_;
    _trustedIntermediaries[0] = address(trustedIntermediary_);
  }

  /// @return _trustedIntermediary the address of GnosisSafe wallet which is the KYC operator
  function trustedIntermediary() external override view returns (IGnosisSafe) {
    return _trustedIntermediary;
  }

  /// @param complianceRegistry_ new address of complianceRegistry
  function setComplianceRegistry(IComplianceRegistry complianceRegistry_) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    emit ComplianceRegistryUpdated(_complianceRegistry, complianceRegistry_);
    _complianceRegistry = complianceRegistry_;
  }

  /// @return _complianceRegistry ComplianceRegistry contract 
  function complianceRegistry() external override view returns (IComplianceRegistry) {
    return _complianceRegistry;
  }

  /// @return contractSignature which is the signature of the contract to sign execTransaction 
  function contractSignature() external override view returns (bytes memory) {
    return _contractSignature;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[45] private __gap;
}