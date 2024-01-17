//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";
import "./ClonesUpgradeable.sol";
import "./SettingStorage.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC721.sol";
import "./IVault.sol";
import "./ISettings.sol";
import "./DataTypes.sol";

contract VaultFactory is
    SettingStorage,
    OwnableUpgradeable,
    PausableUpgradeable
{
    /// @notice the number of ERC721 vaults
    uint256 public vaultCount;

    /// @notice the mapping of vault number to vault contract
    mapping(uint256 => address) public vaults;

    /// @notice  gap for reserve, minus 1 if use
    uint256[10] public __gapUint256;
    /// @notice  gap for reserve, minus 1 if use
    uint256[5] public __gapAddress;

    event Mint(
        address[] tokens,
        uint256[] ids,
        uint256 price,
        address vault,
        uint256 vaultId
    );

    constructor(address _settings) SettingStorage(_settings) {}

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
        // update data
    }

    /// @notice the function to mint a new vault
    /// @param _name the desired name of the vault
    /// @param _symbol the desired sumbol of the vault
    /// @param _tokens  list ERC721 token address fo the NFT
    /// @param _ids list the uint256 ID of the token
    /// @param _listPrice the initial price of the NFT
    /// @return the ID of the vault
    function mint(
        string memory _name,
        string memory _symbol,
        address[] memory _tokens,
        uint256[] memory _ids,
        uint256 _supply,
        uint256 _treasuryBalance,
        uint256 _listPrice,
        uint256 _exitLength
    ) external whenNotPaused returns (uint256) {
        require(_tokens.length == _ids.length, "invalids list tokens");
        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize((address,address[],uint256[],uint256,uint256,string,string,uint256,uint256))",
            DataTypes.TokenVaultInitializeParams({
                curator: msg.sender,
                listTokens: _tokens,
                ids: _ids,
                listPrice: _listPrice,
                exitLength: _exitLength,
                name: _name,
                symbol: _symbol,
                supply: _supply,
                treasuryBalance: _treasuryBalance
            })
        );

        address vault = ClonesUpgradeable.clone(ISettings(settings).vaultTpl());
        Address.functionCall(vault, _initializationCalldata);

        IVault(vault).initializeGovernorToken();

        for (uint i = 0; i < _tokens.length; i++) {
            IERC721(_tokens[i]).safeTransferFrom(msg.sender, vault, _ids[i]);
        }
        emit Mint(_tokens, _ids, _listPrice, vault, vaultCount);

        vaults[vaultCount] = vault;
        vaultCount++;

        return vaultCount - 1;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
