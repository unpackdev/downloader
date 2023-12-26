// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./AccessControl.sol";
import "./ISignVerifierRegistry.sol";
import "./ECDSA.sol";
import "./IERC165.sol";
import "./ReentrancyGuard.sol";

contract PudgyPenguinsMiami2023 is AccessControl, ReentrancyGuard {
  ///////////////////////////////////////////
  //////////        Errors     //////////////
  //////////////////////////////////////////
  error AssetNotEligible();
  error InsufficientStakeAmount();
  error ExpiredSignature();
  error InvalidSignature();
  error TransferFailed();

  ///////////////////////////////////////////
  /////       State Varibles     ///////////
  //////////////////////////////////////////
  // functions from the ECDSA library can be called directly on any bytes32 variable
  using ECDSA for bytes32;

  // Create a new role identifier for the ADMIN role
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  // Address of registry that resolves the signVerifier
  ISignVerifierRegistry public signVerifierRegistry;

  // bytes32 variable representing the ID of the sign verifier within the Sign Verifier Registry.
  bytes32 public signVerifierId;
  uint256 public minimumStakeIncrease = 10; // 10%
  address public currentStaker;
  uint256 public currentStake;

  mapping(address => bool) public eligibleAssets;
  mapping(address => uint256) public stakeNonces;

  ///////////////////////////////////////////
  ///////       Events           ///////////
  //////////////////////////////////////////
  event SignVerifierRegistryUpdated(address indexed signVerifierRegistry, address indexed oldSignVerifierRegistry);

  event SignVerifierIdUpdated(bytes32 indexed signVerifierId, bytes32 indexed oldSignVerifierId);

  event AssetEligibilityUpdated(address asset, bool isEligible);

  event Staked(address indexed staker, uint256 amount, address asset, uint256 tokenId);

  event StakeReturned(address indexed staker, uint256 amount);

  event MinimumStakeIncreased(uint256 indexed amount);

  ///////////////////////////////////////////
  //////////        Functions     //////////
  //////////////////////////////////////////
  constructor(address _signVerifierRegistry, bytes32 _signVerifierId) {
    // Grant admin role to the contract deployer
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    grantAdminRole(msg.sender);

    // Set up the signVerifierRegistry
    setSignVerifierRegistry(_signVerifierRegistry);
    setSignVerifierId(_signVerifierId);
  }

  ////////////////////////////////////////////////
  ///  Public and External Functions     ////////
  ///////////////////////////////////////////////
  /**
   * @notice Updates the ID of the sign verifier
   * @dev Requires the DEFAULT_ADMIN_ROLE to call
   * @param _signVerifierId The ID of the new sign verifier
   */
  function setSignVerifierId(bytes32 _signVerifierId) public onlyRole(ADMIN_ROLE) {
    require(_signVerifierId != bytes32(0), "_signVerifierId cannot be the zero ID");

    bytes32 oldSignVerifierId = signVerifierId;
    signVerifierId = _signVerifierId;
    emit SignVerifierIdUpdated(_signVerifierId, oldSignVerifierId);
  }

  /**
   * @notice Updates the sign verifier registry address
   * @param _signVerifierRegistry The address the new registry
   * @dev Requires the DEFAULT_ADMIN_ROLE to call
   */
  function setSignVerifierRegistry(address _signVerifierRegistry) public onlyRole(ADMIN_ROLE) {
    require(_signVerifierRegistry != address(0), "_signVerifierRegistry cannot be the zero address");
    require(
      IERC165(_signVerifierRegistry).supportsInterface(type(ISignVerifierRegistry).interfaceId),
      "_signVerifierRegistry does not implement ISignVerifierRegistry"
    );

    address oldSignVerifierRegistry = address(signVerifierRegistry);
    signVerifierRegistry = ISignVerifierRegistry(_signVerifierRegistry);

    emit SignVerifierRegistryUpdated(_signVerifierRegistry, oldSignVerifierRegistry);
  }

  /**
   * @notice Function to grant the ADMIN ROLE to an account
   * @dev this function can performed using  "grantRole" function which is available in this contract due to inheritance of Access Control Libarary
   * @dev so this function can removed to save deployment gas
   * @param _account address of the account to set ADMIN
   */
  function grantAdminRole(address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(ADMIN_ROLE, _account);
  }

  /**
   * @notice function to increase the Minimum Stake Increse
   * @dev function can only be called by the ADMIN
   * @param _newMinimum amount of new Minimum value
   */
  function setMinimumStakeIncrease(uint256 _newMinimum) public onlyRole(ADMIN_ROLE) {
    minimumStakeIncrease = _newMinimum;
    emit MinimumStakeIncreased(_newMinimum);
  }

  /**
   * @notice function to add/remove new NFT collection to stake
   * @param _collectionAddress address of the collection
   * @param _isEligible true -> added , false -> removal
   */
  function setAssetEligibility(address _collectionAddress, bool _isEligible) public onlyRole(ADMIN_ROLE) {
    eligibleAssets[_collectionAddress] = _isEligible;
    emit AssetEligibilityUpdated(_collectionAddress, _isEligible);
  }

  /**
   * @notice function to stake the amount on the particular NFT of NFT Collection
   * @param _selectedAsset address of the NFT collection
   * @param _selectedAssetTokenID Token ID of the collection
   * @param _sig signature to check the correct user
   */
  function stake(
    address _selectedAsset,
    uint256 _selectedAssetTokenID,
    uint256 _blockExpiry,
    bytes memory _sig
  ) public payable nonReentrant {
    if (!eligibleAssets[_selectedAsset]) {
      revert AssetNotEligible();
    }
    if (msg.value < currentStake + ((currentStake * minimumStakeIncrease) / 100)) {
      revert InsufficientStakeAmount();
    }
    if (block.number > _blockExpiry) {
      revert ExpiredSignature();
    }
    if (!(_verifySignature(msg.sender, _selectedAsset, _selectedAssetTokenID, _blockExpiry, _sig))) {
      revert InvalidSignature();
    }

    if (currentStaker != address(0)) {
      (bool sent, ) = currentStaker.call{value: currentStake}("");
      if (!sent) {
        revert TransferFailed();
      }
    }

    currentStaker = msg.sender;
    currentStake = msg.value;
    stakeNonces[msg.sender]++;

    emit Staked(msg.sender, msg.value, _selectedAsset, _selectedAssetTokenID);
  }

  /**
   * @notice function to return the currently staked amount to the current staker
   * @dev function can only be called by the ADMIN
   */
  function returnStake() public onlyRole(ADMIN_ROLE) {
    require(currentStaker != address(0), "No current staker");
    require(currentStake > 0, "No stake to return");

    (bool sent, ) = currentStaker.call{value: currentStake}("");
    if (!sent) {
      revert TransferFailed();
    }

    emit StakeReturned(currentStaker, currentStake);

    currentStaker = address(0);
    currentStake = 0;
  }

  ////////////////////////////////////////////////
  ///  Private and Internal Functions     ////////
  ///////////////////////////////////////////////

  /**
   * @notice function to check the correct user
   * @param _staker address of the staker
   * @param _asset address of the NFT Collection
   * @param _tokenId Token ID of the collection
   * @param _sig signature to check the correct user
   */
  function _verifySignature(
    address _staker,
    address _asset,
    uint256 _tokenId,
    uint256 _blockExpiry,
    bytes memory _sig
  ) private view returns (bool) {
    bytes32 message = getStakeSigningHash(_staker, _asset, _tokenId, _blockExpiry).toEthSignedMessageHash();
    require(ECDSA.recover(message, _sig) == getSignVerifier(), "Permission to call this function failed");
    return true;
  }

  //////////////////////////////////////////////////////
  ///////  Public & External VIEW Functions     ////////
  //////////////////////////////////////////////////////

  /**
   * @notice function to get the hash to be signed for staking
   * @param _staker address of the staker
   * @param _asset address of the NFT Collection
   * @param _tokenId Token ID of the collection
   */
  function getStakeSigningHash(
    address _staker,
    address _asset,
    uint256 _tokenId,
    uint256 _blockExpiry
  ) public view returns (bytes32) {
    return keccak256(abi.encodePacked(_staker, _asset, _tokenId, _blockExpiry, address(this), stakeNonces[_staker]));
  }

  /**
   * @notice Returns the address of the sign verifier
   */
  function getSignVerifier() public view returns (address) {
    // retrieve the address of a sign verifier associated with a specific ID.
    address signVerifier = signVerifierRegistry.get(signVerifierId);
    require(signVerifier != address(0), "cannot use zero address as sign verifier");
    return signVerifier;
  }

  /**
   * @notice Function to check whether the address is an ADMIN or not
   * @param _address address to check
   */
  function isAddressAdmin(address _address) public view returns (bool) {
    return hasRole(ADMIN_ROLE, _address);
  }
}
