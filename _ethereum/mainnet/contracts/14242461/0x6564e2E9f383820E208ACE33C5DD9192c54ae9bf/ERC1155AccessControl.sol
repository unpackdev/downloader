// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "./ERC165Checker.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IAccessControlPolicy.sol";
import "./EnumerableSet.sol";
import "./PerVaultGatekeeper.sol";

/// @notice Configure and validate user access to a particular vault using ERC1155 NFTs.
///  Admin users can configure an array of ERC1155 NFT contracts and associated token ids for an array of vaults, or set them as globally defaults.
///  The global defaults will be used if there are no configurations set for a given vault. Otherwise only the configurations for the vault will be used to determine access.
///  An owner of any of the NFTs will be able to access a vault if the NFTs are granted access to the vault.
///  The `vault` here can either be the vaults are defined in the `SingleAssetVault` smart contract, or the staking contract.
///  NOTE the NFT contract has to implement the ERC1155 standard and can pass the check using ERC165 standard. ERC721 standard is not supported.
contract ERC1155AccessControl is IAccessControlPolicy, PerVaultGatekeeper {
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableSet for EnumerableSet.AddressSet;
  using ERC165Checker for address;

  /// @notice Emitted when some NFT tokens are granted access to a vault. If it's set for global access, the value of `_vault` will be `address(1)`.
  /// @param _vault the vault id. Will be `address(1)` if it's for global access
  /// @param _nftContract the address of the ERC1155 contract
  /// @param _nftIds the array of nft ids that are granted access
  event VaultAccessGranted(address indexed _vault, address indexed _nftContract, uint256[] _nftIds);

  /// @notice Emitted when some NFT tokens are removed access to a vault. If it's set for global access, the value of `_vault` will be `address(1)`.
  /// @param _vault the vault id. Will be `address(1)` if it's for global access
  /// @param _nftContract the address of the ERC1155 contract
  /// @param _nftIds the array of nft ids that are removed access
  event VaultAccessRemoved(address indexed _vault, address indexed _nftContract, uint256[] _nftIds);

  // used as the vault id for global access
  address internal constant GLOBAL_CONFIG_ID = address(1);
  // used to store all the addresses of nft contracts to help with look up the mapping
  // using just one global set to save gas
  EnumerableSet.AddressSet internal allContracts;

  struct Config {
    // used to indicate if there is a config
    bool isSet;
    // nft contract => token ids
    mapping(address => EnumerableSet.UintSet) settings;
  }

  // store the mappings of vaults and nft tokens
  // vault => Config
  mapping(address => Config) private vaultNftMapping;

  constructor(address _governer) PerVaultGatekeeper(_governer) {}

  /// @notice Check if the given user address can address the given vault.
  ///  It will check if the user address owns any of the NFTs that are granted access to the vault, either at the vault level or globally.
  ///  If the user owns any of the NFTs, it will be granted access.
  /// @param _user the address of user to check
  /// @param _vault the address of the vault
  /// @return if the user has access to the vault
  function hasAccess(address _user, address _vault) external view returns (bool) {
    require(_vault != address(0), "!vault");
    require(_user != address(0), "!user");
    bool userHasAccess = false;
    address vaultId = _vault;
    if (!vaultNftMapping[_vault].isSet) {
      // no configuration set for the given vault, fallback to the global configuration
      vaultId = GLOBAL_CONFIG_ID;
    }
    for (uint256 i = 0; i < allContracts.length(); i++) {
      if (_hasAccess(vaultId, allContracts.at(i), _user)) {
        userHasAccess = true;
        break;
      }
    }
    return userHasAccess;
  }

  /// @notice Add ERC1155 NFTs that will have access to all the vaults by default. Can only be set by governance.
  ///  The length of `_nftContracts` should match the length of `_nftIds`.
  /// @param _nftContracts The address of NFT contracts. Can have duplicates. Each contract needs to implement the ERC1155 spec.
  /// @param _nftIds The nft ids that will be granted access. Each item is an array itself and it should contain the NFT token ids of the NFT contract that has the same index value in `_nftContracts`.
  function addGlobalNftAccess(address[] calldata _nftContracts, uint256[][] calldata _nftIds) external onlyGovernance {
    require(_nftContracts.length > 0, "!contracts");
    require(_nftContracts.length == _nftIds.length, "!input");
    for (uint256 i = 0; i < _nftContracts.length; i++) {
      require(_nftContracts[i].supportsInterface(type(IERC1155).interfaceId), "!ERC1155");
      allContracts.add(_nftContracts[i]);
      _addTokenIds(GLOBAL_CONFIG_ID, _nftContracts[i], _nftIds[i]);
      emit VaultAccessGranted(GLOBAL_CONFIG_ID, _nftContracts[i], _nftIds[i]);
    }
  }

  /// @notice Remove access of ERC1155 NFTs to all the vaults by default. Can only be set by governance.
  ///  The length of `_nftContracts` should match the length of `_nftIds`.
  /// @param _nftContracts The address of NFT contracts. Can have duplicates. Each contract needs to implement the ERC1155 spec.
  /// @param _nftIds The nft ids that will be granted access. Each item is an array itself and it should contain the NFT token ids of the NFT contract that has the same index value in `_nftContracts`.
  function removeGlobalNftAccess(address[] calldata _nftContracts, uint256[][] calldata _nftIds)
    external
    onlyGovernance
  {
    require(_nftContracts.length > 0, "!contracts");
    require(_nftContracts.length == _nftIds.length, "!input");
    for (uint256 i = 0; i < _nftContracts.length; i++) {
      _removeTokenIds(GLOBAL_CONFIG_ID, _nftContracts[i], _nftIds[i]);
      emit VaultAccessRemoved(GLOBAL_CONFIG_ID, _nftContracts[i], _nftIds[i]);
    }
  }

  /// @notice Grant owners of the given NFT tokens access to the given vaults. Can be called either by the governance, or gatekeeper of the vaults.
  ///  It takes three array parameters and the length of the parameters need to be the same.
  ///  For example, given vaults v1 and v2, nft contract c1 with ids 1,2 and contract c2 with ids 3, 4,
  ///  if we want all nfts to access v1, and only c2 nfts access v2, we can set the parameters as
  ///  _vaults = [v1, v1, v2], _nftContracts = [c1, c2, c2], _nftIds = [[1,2], [3,4], [3,4]]
  /// @param _vaults the address of vaults. Can have duplicates.
  /// @param _nftContracts the address of nft contracts. Each NFT contract needs to implement the ERC1155 spec.
  /// @param _nftIds ids of nft contracts
  function addNftAccessToVaults(
    address[] calldata _vaults,
    address[] calldata _nftContracts,
    uint256[][] calldata _nftIds
  ) external {
    require(_vaults.length > 0, "!vaults");
    require(_vaults.length == _nftContracts.length, "!input");
    require(_nftContracts.length == _nftIds.length, "!input");
    for (uint256 i = 0; i < _vaults.length; i++) {
      _onlyGovernanceOrGatekeeper(_vaults[i]);
      require(_nftContracts[i].supportsInterface(type(IERC1155).interfaceId), "!ERC1155");
      allContracts.add(_nftContracts[i]);
      vaultNftMapping[_vaults[i]].isSet = true;
      _addTokenIds(_vaults[i], _nftContracts[i], _nftIds[i]);
      emit VaultAccessGranted(_vaults[i], _nftContracts[i], _nftIds[i]);
    }
  }

  /// @notice Remove owners of the given NFT tokens access to the given vaults. Can be called either by the governance, or gatekeeper of the vaults.
  ///  See method {addNftAccessToVaults}.
  /// @param _vaults the address of vaults. Can have duplicates.
  /// @param _nftContracts the address of nft contracts. Each NFT contract needs to implement the ERC1155 spec.
  /// @param _nftIds ids of nft contracts
  function removeNftAccessToVaults(
    address[] calldata _vaults,
    address[] calldata _nftContracts,
    uint256[][] calldata _nftIds
  ) external {
    require(_vaults.length > 0, "!vaults");
    require(_vaults.length == _nftContracts.length, "!input");
    require(_nftContracts.length == _nftIds.length, "!input");
    for (uint256 i = 0; i < _vaults.length; i++) {
      _onlyGovernanceOrGatekeeper(_vaults[i]);
      _removeTokenIds(_vaults[i], _nftContracts[i], _nftIds[i]);
      emit VaultAccessRemoved(_vaults[i], _nftContracts[i], _nftIds[i]);
    }
  }

  /// @notice Check what token ids are granted access to all the vaults by default.
  /// @param _nftContract the address of the NFT contract to check
  /// @return the token ids of the NFT contract that are granted access
  function getGlobalNftAccess(address _nftContract) external view returns (uint256[] memory) {
    require(_nftContract != address(0), "!contract");
    return vaultNftMapping[GLOBAL_CONFIG_ID].settings[_nftContract].values();
  }

  /// @notice Check what token ids are granted access the vault specified
  /// @param _vault the address of the vault to check
  /// @param _nftContract the address of the NFT contract to check
  /// @return the token ids of the NFT contract that are granted access
  function getVaultNftAccess(address _vault, address _nftContract) external view returns (uint256[] memory) {
    require(_vault != address(0), "!vault");
    require(_nftContract != address(0), "!contract");
    return vaultNftMapping[_vault].settings[_nftContract].values();
  }

  function _addTokenIds(
    address _vault,
    address _nftContract,
    uint256[] memory _tokenIds
  ) internal {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      vaultNftMapping[_vault].settings[_nftContract].add(_tokenIds[i]);
    }
  }

  function _removeTokenIds(
    address _vault,
    address _nftContract,
    uint256[] memory _tokenIds
  ) internal {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      vaultNftMapping[_vault].settings[_nftContract].remove(_tokenIds[i]);
    }
  }

  function _hasAccess(
    address _vault,
    address _nftContract,
    address _user
  ) internal view returns (bool) {
    EnumerableSet.UintSet storage tokenIds = vaultNftMapping[_vault].settings[_nftContract];
    bool allow = false;
    for (uint256 i = 0; i < tokenIds.length(); i++) {
      if (IERC1155(_nftContract).balanceOf(_user, tokenIds.at(i)) > 0) {
        allow = true;
        break;
      }
    }
    return allow;
  }
}
