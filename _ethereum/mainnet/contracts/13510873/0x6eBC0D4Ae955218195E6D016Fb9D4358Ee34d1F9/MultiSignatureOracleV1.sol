// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC20.sol";
import "./MyPausableUpgradeable.sol";
import "./console.sol";
import "./IMultiSignatureOracle.sol";

/**
 * @title MultiSignatureOracleV1
 * Provides signature and verification services for the cross-chain bridge to allow validation of deposits between networks
 */
contract MultiSignatureOracleV1 is MyPausableUpgradeable, IMultiSignatureOracle {
  // Roles
  bytes32 public constant MANAGE_ORACLES_ROLE = keccak256('MANAGE_ORACLES_ROLE');
  bytes32 public constant MULTISIG_THRESHOLD_ROLE = keccak256('MULTISIG_THRESHOLD_ROLE');

  // EIP712 Precomputed hashes:
  // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)")
  bytes32 constant EIP712DOMAINTYPE_HASH = 0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;
  bytes32 constant NAME_HASH = keccak256('Tixl Cross-Chain Bridge MultiSig');
  bytes32 constant VERSION_HASH = keccak256('1');
  bytes32 constant TXTYPE_HASH_ERC20 =
    keccak256(
      'ReleaseRequest(address receiverAddress,address sourceNetworkTokenAddress,uint256 amount,uint256 depositChainId,uint256 depositNumber)'
    );
  bytes32 constant TXTYPE_HASH_ERC721 =
    keccak256(
      'ReleaseRequest(address receiverAddress,address sourceNetworkCollectionAddress,uint256 tokenId,uint256 depositChainId,uint256 depositNumber)'
    );
  bytes32 public constant SALT = 0x251543af6a222378665a76fe38dbceae4871a070b7fdaf5c6c30cf758dc33cc0;

  event SignaturesCheckPassedERC20(
    address indexed tokenAddress,
    uint256 amount,
    address indexed receiverAddress,
    uint256 depositChainId,
    uint256 depositNumber
  );

  event SignaturesCheckPassedERC721(
    address indexed collectionAddress,
    uint256 tokenId,
    address indexed receiverAddress,
    uint256 depositChainId,
    uint256 depositNumber
  );

  event MultiSignatureThresholdChanged(uint256 oldValue, uint256 newValue, address indexed changedBy);

  event MultiSignatureOracleAdded(address indexed newOracleAddress, address indexed changedBy);

  event MultiSignatureOracleRemoved(address indexed removedOracleAddress, address indexed changedBy);

  // stores signature metadata
  bytes32 domainSeparator;

  /// stores the number of signatures needed to pass a verification
  uint256 public multiSignatureThreshold;

  /// mapping from address of the contract to true/false if permitted as an oracle
  mapping(address => bool) public permittedOracleAddresses;

  /**
   * @notice Initializer instead of constructor to have the contract upgradable
   * @dev can only be called once after deployment of the contract
   */
  function initialize() external initializer {
    // call parent initializers
    __MyPausableUpgradeable_init();

    // set up admin roles
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    // initialize required state variables
    domainSeparator = keccak256(
      abi.encode(EIP712DOMAINTYPE_HASH, NAME_HASH, VERSION_HASH, _getChainID(), address(this), SALT)
    );
    multiSignatureThreshold = 3;
  }

  /**
   * @notice Sets the signature verification threshold  (i.e. the amount of oracle verifications required to pass)
   *
   * @dev can only be called by MULTISIG_THRESHOLD_ROLE
   * @param threshold the amount of signatures required to pass verification
   * @dev emits event MultiSignatureThresholdChanged
   */
  function setMultiSignatureThreshold(uint256 threshold) external {
    require(
      hasRole(MULTISIG_THRESHOLD_ROLE, _msgSender()),
      'MultiSignatureOracleV1: must have MULTISIG_THRESHOLD_ROLE role to execute this function'
    );
    require(threshold > 0, 'MultiSignatureOracleV1: Invalid threshold value');
    emit MultiSignatureThresholdChanged(multiSignatureThreshold, threshold, _msgSender());
    multiSignatureThreshold = threshold;
  }

  /**
   * @notice Adds a new oracle to the list of oracles that are permitted to contribute to multisignature checks
   *
   * @dev can only be called by MANAGE_ORACLES_ROLE
   * @param oracleAddress the address of the oracle that should be added
   * @dev emits event MultiSignatureOracleAdded
   */
  function addMultiSignatureOracle(address oracleAddress) external {
    require(oracleAddress != address(0), 'MultiSignatureOracleV1: invalid oracle address provided');
    require(
      hasRole(MANAGE_ORACLES_ROLE, _msgSender()),
      'MultiSignatureOracleV1: must have MANAGE_ORACLES_ROLE role to execute this function'
    );
    permittedOracleAddresses[oracleAddress] = true;
    emit MultiSignatureOracleAdded(oracleAddress, _msgSender());
  }

  /**
   * @notice Verifies signatures for ERC20 deposits
   *
   * @param sigV Array of recovery Ids for the signature
   * @param sigR Array of R values of the signatures
   * @param sigS Array of S values of the signatures
   * @param receiverAddress The account to receive the tokens
   * @param tokenAddress The address of the token sent for deposit
   * @param amount The amount to be sent
   * @param depositChainId The chain ID of the network in which the deposit was made
   * @param depositNumber The number of the corresponding deposit
   * @return returns true if the signatures could be verified, otherwise false
   * @dev emits event SignaturesCheckPassedERC20
   */
  function signaturesCheckERC20(
    uint8[] memory sigV,
    bytes32[] memory sigR,
    bytes32[] memory sigS,
    address receiverAddress,
    address tokenAddress,
    uint256 amount,
    uint256 depositChainId,
    uint256 depositNumber
  ) external override returns (bool) {
    require(sigV.length >= multiSignatureThreshold, 'MultiSignatureOracleV1: Not enough signatures');
    require(
      sigR.length == sigS.length && sigR.length == sigV.length,
      'MultiSignatureOracleV1: Inconsistent signature input'
    );

    // produce transaction input hash from input parameters
    bytes32 txInputHash = keccak256(
      abi.encode(TXTYPE_HASH_ERC20, receiverAddress, tokenAddress, amount, depositChainId, depositNumber)
    );

    // verify oracle signatures
    bool verified = _verifySignatures(sigV, sigR, sigS, txInputHash);
    require(verified, 'MultiSignatureOracleV1: Release not permitted');

    // signatures verified - emit event
    emit SignaturesCheckPassedERC20(tokenAddress, amount, receiverAddress, depositChainId, depositNumber);

    return verified;
  }

  /**
   * @notice Verifies signatures for ERC721 deposits
   *
   * @param sigV Array of recovery Ids for the signature
   * @param sigR Array of R values of the signatures
   * @param sigS Array of S values of the signatures
   * @param receiverAddress The account to receive the tokens
   * @param collectionAddress The address of the token sent for deposit
   * @param tokenId The unique native ID of the ERC721 token
   * @param depositChainId The chain ID of the network in which the deposit was made
   * @param depositNumber The number of the corresponding deposit
   * @return returns true if the signatures could be verified, otherwise false
   * @dev emits event SignaturesCheckPassedERC721
   */
  function signaturesCheckERC721(
    uint8[] memory sigV,
    bytes32[] memory sigR,
    bytes32[] memory sigS,
    address receiverAddress,
    address collectionAddress,
    uint256 tokenId,
    uint256 depositChainId,
    uint256 depositNumber
  ) external override returns (bool) {
    require(sigV.length >= multiSignatureThreshold, 'MultiSignatureOracleV1: Not enough signatures');
    require(
      sigR.length == sigS.length && sigR.length == sigV.length,
      'MultiSignatureOracleV1: Inconsistent signature input'
    );

    // produce transaction input hash from input parameters
    bytes32 txInputHash = keccak256(
      abi.encode(TXTYPE_HASH_ERC721, receiverAddress, collectionAddress, tokenId, depositChainId, depositNumber)
    );

    // verify oracle signatures
    bool verified = _verifySignatures(sigV, sigR, sigS, txInputHash);
    require(verified, 'MultiSignatureOracleV1: Release not permitted');

    // signatures verified - emit event
    emit SignaturesCheckPassedERC721(collectionAddress, tokenId, receiverAddress, depositChainId, depositNumber);
    return verified;
  }

  function _verifySignatures(
    uint8[] memory sigV,
    bytes32[] memory sigR,
    bytes32[] memory sigS,
    bytes32 txInputHash
  ) private view whenNotPaused returns (bool) {
    bytes32 totalHash = keccak256(abi.encodePacked('\x19\x01', domainSeparator, txInputHash));

    uint256 verifiedSignatures = 0;
    address lastAdd = address(0); // cannot have address(0) as an owner
    for (uint256 i = 0; i < sigV.length; i++) {
      address recovered = ecrecover(totalHash, sigV[i], sigR[i], sigS[i]);
      require(recovered > lastAdd, 'MultiSignatureOracleV1: Oracles not sorted');

      // check if the computed address is included in the permitted oracles list
      if (permittedOracleAddresses[recovered]) {
        // address is a part of the permitted oracles list, increase verified signature counter
        verifiedSignatures = verifiedSignatures + 1;
        lastAdd = recovered;
      }
    }

    // return true if the amount of verified signatures is equal to or above multisig threshold
    return verifiedSignatures >= multiSignatureThreshold;
  }

  /**
   * @notice Removes an address from the list of oracles that are permitted to verify sighnatures
   *
   * @param oracleAddress the address of the oracle to be removed
   * @dev emits event MultiSignatureOracleRemoved
   */
  function removePermittedOracleAddress(address oracleAddress) external {
    require(
      hasRole(MANAGE_ORACLES_ROLE, _msgSender()),
      'MultiSignatureOracleV1: must have MANAGE_ORACLES_ROLE role to execute this function'
    );
    permittedOracleAddresses[oracleAddress] = false;
    emit MultiSignatureOracleRemoved(oracleAddress, _msgSender());
  }

  /**
   * @notice Returns the ID of the chain this contract is deployed to
   *
   * @return ID of the chain this contract was deployed to
   */
  function _getChainID() private view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }
}
