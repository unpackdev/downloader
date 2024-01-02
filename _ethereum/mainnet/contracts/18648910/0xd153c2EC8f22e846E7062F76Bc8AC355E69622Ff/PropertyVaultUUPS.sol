// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./IPropertyVaultUUPS.sol";

contract PropertyVaultUUPS is AccessControlUpgradeable, UUPSUpgradeable, IPropertyVaultUUPS {
  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
  bytes32 private _merkleRoot;
  bytes private _contractSignature; // unusued
  address[] private _trustedIntermediaries; // unusued
  address private _trusted;
  IRealtMediator private _bridge;
  IComplianceRegistry private _complianceRegistry;
  mapping(address => mapping(address => uint256)) private _cumulativeClaimedPerToken;

  uint8 public constant VERSION = 2;
  bytes4 private constant UPDATE_USER = IComplianceRegistry.updateUserAttributes.selector;
  bytes4 private constant REGISTER_USER = IComplianceRegistry.registerUser.selector;
  
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
      _disableInitializers();
  }

  /// @notice the initialize function to execute only once during the contract deployment
  function initialize(IRealtMediator bridge_) external onlyRole(DEFAULT_ADMIN_ROLE) reinitializer(VERSION) {
    _contractSignature = "";
    _trustedIntermediaries = new address[](0);
    _bridge = bridge_;
  }

  function computeSignature() private view returns (bytes memory s) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
        s := mload(0x40)
        mstore(0x40, add(s, 0x61))
        mstore(s, 0x41)
        mstore(add(s, 0x20), address())
        mstore(add(s, 0x41), 0x01)
    }
  }

  /// @notice The admin (with upgrader role) uses this function to update the contract
  /// @dev This function is always needed in future implementation contract versions, otherwise, the contract will not be upgradeable
  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address /* newImplementation */) internal override onlyRole(UPGRADER_ROLE) {}

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
      unchecked { ++i; }
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
    (address[] memory _tokens, uint256[] memory _amounts) = _verifyMerkleTree(account, tokens, cumulativeAmounts, expectedMerkleRoot, merkleProof);
    // Whitelist account
    _whitelist(account, _tokens);
    require(_bridge.batchTransferFromVault(_tokens, _amounts, account), "CMD: Transfer failed");
    emit Claimed(account, tokens, cumulativeAmounts);
  }

  /// @notice allows users to claim their token (verifed by merkle tree)
  /// @param account user address
  /// @param tokens array of tokens in the user balance
  /// @param cumulativeAmounts array of cumulative amount for each token (2 arrays must have the same length)
  /// @param expectedMerkleRoot merkle root (need to update each week to update user balance)
  /// @param merkleProof merkle proof to be provided for verification of user balance 
  function claimAndBridge(
    address account,
    address[] calldata tokens,
    uint256[] calldata cumulativeAmounts,
    bytes32 expectedMerkleRoot,
    bytes32[] calldata merkleProof
  ) external override {
    (address[] memory _tokens, uint256[] memory _amounts) = _verifyMerkleTree(account, tokens, cumulativeAmounts, expectedMerkleRoot, merkleProof);
    require(_bridge.batchBridgeFromVault(_tokens, _amounts, account), "CMD: Transfer failed");
    emit ClaimedBridge(account, tokens, cumulativeAmounts);
  }

  function _verifyMerkleTree(
      address account,
      address[] calldata tokens,
      uint256[] calldata cumulativeAmounts,
      bytes32 expectedMerkleRoot,
      bytes32[] calldata merkleProof
    ) private returns (address[] memory, uint256[] memory) {
    uint256 tokenLength = tokens.length;
    // Verify the merkle root
    require(_merkleRoot == expectedMerkleRoot, "CMD: Merkle root was updated");
    // Verify that tokens and cumulativeAmounts have the same length
    require(tokenLength == cumulativeAmounts.length, "CMD: Length of Tokens != amounts");
    // Verify the merkle proof
    bytes32 leaf = keccak256(abi.encode(account, tokens, cumulativeAmounts));
    require(_verifyAsm(merkleProof, expectedMerkleRoot, leaf), "CMD: Invalid proof");
    return formatValues(account, tokens, cumulativeAmounts);
  }

  function formatValues(address account, address[] calldata tokens, uint256[] calldata cumulativeAmounts) private returns (address[] memory, uint256[] memory) {
      // Iterate through the tokens array 
      address[] memory _tokens = new address[](tokens.length);
      uint256[] memory _amounts = new uint256[](tokens.length);
      uint256 j = 0;
      uint256 cumulativeAmount;
      uint256 preclaimed;
      for (uint256 i = 0; i < tokens.length;) {
        cumulativeAmount = cumulativeAmounts[i];
        // Check if the user has something to claim for each token
        preclaimed = _cumulativeClaimedPerToken[tokens[i]][account];
        if (preclaimed != cumulativeAmount) { // If nothing to claim continue
          require(preclaimed < cumulativeAmount, "CMD: Please contact support");
          // Mark it claimed in the mapping _cumulativeClaimedPerToken
          _cumulativeClaimedPerToken[tokens[i]][account] = cumulativeAmount;
          _tokens[j] = tokens[i];
          unchecked { _amounts[j] = cumulativeAmount - preclaimed; }
          unchecked { ++j; }
        }
        unchecked { ++i; }
      }
      require(j > 0, "CMD: Nothing to claim");
      // solhint-disable-next-line no-inline-assembly
      assembly {
        mstore(_tokens, j)
        mstore(_amounts, j)
      }
      return (_tokens, _amounts);
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
      mstore(0x40, add(0x40, mem1))
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

  function _getTokenIds(address[] memory tokens, uint256 length) private view returns (uint256[] memory, uint256[] memory) {
    uint256[] memory tokenIds = new uint256[](length);
    uint256[] memory attributeValues = new uint256[](length);
    uint256 ruleNumber;
    uint256 tokenId;
    for (uint256 i = 0; i < length;) { 
      (ruleNumber, tokenId) = IBridgeToken(tokens[i]).rule(0); // token address => tokenId (attributeKeys)
      // Rule 11: User Attribute Valid Rule
      // https://github.com/MtPelerin/bridge-v2/blob/master/docs/RuleEngine.md#rules-index
      require(ruleNumber == 11, "PV17");
      (tokenIds[i], attributeValues[i]) = (tokenId, 1);
      unchecked { ++i; }
    }
    return (tokenIds, attributeValues);
  }

  /// @param account user address
  /// @param tokens tokens addresses to whitelist
  function _whitelist(address account, address[] memory tokens) internal {
    address trusted = _trusted;
    address[] memory intermediaries = new address[](1);
    intermediaries[0] = trusted;
    IComplianceRegistry compliance = _complianceRegistry;
    // Check if the user is already registered
    (uint256 userId,) = compliance.userId(intermediaries, account);
    uint256 length = tokens.length;
    (uint256[] memory tokenIds, uint256[] memory attributeValues) = _getTokenIds(tokens, length);
    // If the user is not registered, register the user with tokenIds and attributeValues
    if (userId == 0) {
      _staticRegisterUser(account, tokenIds, attributeValues, trusted, address(compliance));
    } else {
      uint256[] memory isWhitelistedValues = compliance.attributes(trusted, userId, tokenIds);
      for (uint256 i = 0; i < length;) {
        if (isWhitelistedValues[i] == 0) {
          _staticUpdateUserAttributes(userId, tokenIds, attributeValues, trusted, address(compliance));
          return;
        }
        unchecked { ++i; }
      }
    }
  }

  function _staticUpdateUserAttributes(
    uint256 _userId, 
    uint256[] memory _attributeKeys, 
    uint256[] memory _attributeValues,
    address trusted,
    address compliance
  ) private {
    bytes memory encodedUpdateUserSelector = abi.encodeWithSelector(UPDATE_USER, _userId, _attributeKeys, _attributeValues);
    _execTransaction(IGnosisSafe(trusted),compliance,0,encodedUpdateUserSelector,Enum.Operation.Call,0,0,0,address(0),payable(address(0)),computeSignature());
  }

  function _staticRegisterUser(
    address _address,
    uint256[] memory _attributeKeys,
    uint256[] memory _attributeValues,
    address trusted,
    address compliance
  ) private {
    bytes memory encodedRegisterSelector = abi.encodeWithSelector(REGISTER_USER, _address, _attributeKeys, _attributeValues);
    _execTransaction(IGnosisSafe(trusted),compliance,0,encodedRegisterSelector,Enum.Operation.Call,0,0,0,address(0),payable(address(0)),computeSignature());
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

  /// @param trusted new address of trustedIntermediary in case of modifying KYC operator
  function setTrustedIntermediary(address trusted) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    emit TrustedIntermediaryUpdated(trusted);
    _trusted = trusted;
  }

  /// @return _trustedIntermediary the address of GnosisSafe wallet which is the KYC operator
  function trustedIntermediary() external override view returns (address) {
    return _trusted;
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

   /// @param bridge_ new address of realtMediator
  function setRealtMediator(IRealtMediator bridge_) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    emit MediatorUpdated(_bridge, bridge_);
    _bridge = bridge_;
  }

  /// @return _realtMediator mediator contract 
  function realtMediator() external override view returns (IRealtMediator) {
    return _bridge;
  }


  /// @return contractSignature which is the signature of the contract to sign execTransaction 
  function contractSignature() external override view returns (bytes memory) {
    return computeSignature();
  }
  uint256[43] private __gap;
}