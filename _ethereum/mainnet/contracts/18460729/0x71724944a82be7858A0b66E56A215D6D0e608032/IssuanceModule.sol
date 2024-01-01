// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./ModuleBase.sol";
import "./IOwnable.sol";
import "./SafeERC20.sol";

import "./Invoke.sol";
import "./IIssuanceModule.sol";

contract IssuanceModule is ModuleBase, IIssuanceModule, Initializable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
	using Invoke for IVault;
	using SafeERC20 for IERC20;
	modifier onlyOwner() {
		require(
			msg.sender == IOwnable(diamond).owner(),
			"TradeModule:only owner"
		);
		_;
	}
	
	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
		_disableInitializers();
	}
	
	function initialize(address _diamond) public initializer {
		__UUPSUpgradeable_init();
		diamond = _diamond;
	}
	
	function _authorizeUpgrade(
		address newImplementation
	) internal override onlyOwner {}
	

	function issue(address _vault, address _from, address[] memory _assets, uint256[] memory _positionType, uint256[] memory _amounts) external nonReentrant onlyVault(_vault) {
		IPlatformFacet platformFacet=IPlatformFacet(diamond);
		if(platformFacet.getIsVault(_from)){
			IVaultFacet vaultFacet= IVaultFacet(diamond);
          	require(!vaultFacet.getVaultLock(_from),"IssuanceModule:vault is locked");  
		}
		for (uint256 i; i < _assets.length; i++) {
			//check asset
			validAsset(_vault, _assets[i], _positionType[i]);
			//transferForm
			if (_assets[i] !=platformFacet.getEth()) {
				IVault(_vault).invokeTransferFrom(_assets[i], _from, _vault, _amounts[i]);
			}
			//update Postion
			updatePosition(_vault, _assets[i], _positionType[i], 0);
		}
		emit Issue(_vault,_from, _assets, _positionType, _amounts);
	}

    function issue(address _vault, address[] memory _assets, uint256[] memory _positionType, uint256[] memory _amounts) external nonReentrant onlyVault(_vault) {
		address owner=IVault(_vault).owner();
        IPlatformFacet platformFacet=IPlatformFacet(diamond);
		if(platformFacet.getIsVault(owner)){
			IVaultFacet vaultFacet= IVaultFacet(diamond);
          	require(!vaultFacet.getVaultLock(owner),"IssuanceModule:vault is locked");  
		}
		for (uint256 i; i < _assets.length; i++) {
			//check asset
			validAsset(_vault, _assets[i], _positionType[i]);
			//transferForm
			if (_assets[i] != platformFacet.getEth()) {
				IERC20(_assets[i]).safeTransferFrom(owner,_vault, _amounts[i]);
			}
			//update Postion
			updatePosition(_vault, _assets[i], _positionType[i], 0);
		}
		emit Issue(_vault,owner, _assets, _positionType, _amounts);
	}
	
	function issueFromVault(address _vault, address _from, address[] memory _assets, uint256[] memory _positionType, uint256[] memory _amounts) external nonReentrant onlyVault(_vault) {
		require(IVault(_vault).owner() == IVault(_from).owner(), "IssuanceModule:only same owner vault");
		//check vault lock
		IVaultFacet vaultFacet= IVaultFacet(diamond);
		require(!vaultFacet.getVaultLock(_from),"IssuanceModule:vault is locked");  
		for (uint256 i; i < _assets.length; i++) {
			//check asset
			validAsset(_vault, _assets[i], _positionType[i]);
			//transferForm
			if (_assets[i] != IPlatformFacet(diamond).getEth()) {
				IVault(_from).invokeTransfer(_assets[i], _vault,  _amounts[i]);
			}
			//update Postion
			updatePosition(_vault, _assets[i], _positionType[i], 0);
			updatePosition(_from, _assets[i], _positionType[i], 0);
		}
		emit IssueFromVault(_vault,_from, _assets, _positionType, _amounts);
	}
	
	function redeem(address _vault, address payable _to, address[] memory _assets, uint256[] memory _positionType, uint256[] memory _amounts) external nonReentrant onlyVault(_vault) {
	    IPlatformFacet platformFacet=IPlatformFacet(diamond);
		for (uint256 i; i < _assets.length; i++) {
			uint256 amount = _amounts[i];
			//check asset
			validAsset(_vault, _assets[i], _positionType[i]);
			//transfer to metamask
			if (_assets[i] !=platformFacet.getEth()) {
				if (amount == 0) {
					amount = IERC20(_assets[i]).balanceOf(_vault);
				}
				IVault(_vault).invokeTransfer(_assets[i], _to, amount);
			} else {
				if (amount == 0) {
					amount = _vault.balance;
				}
				IVault(_vault).invokeTransferEth(_to, amount);
			}
			//update Postion
			updatePosition(_vault, _assets[i], _positionType[i], 0);
			if(platformFacet.getIsVault(_to)){
               	updatePosition(_to, _assets[i], _positionType[i], 0);    
			}
		}
		emit Redeem(_vault, _assets, _positionType, _amounts);
	}
	
	
	function validAsset(address _vault, address _asset, uint256 _debtType) internal view {
		IVaultFacet vaultFacet = IVaultFacet(diamond);
		IPlatformFacet platformFacet = IPlatformFacet(diamond);
		//check asset in platform
		uint256 assetType = platformFacet.getTokenType(_asset);
		require(assetType != 0 && assetType == _debtType, "IssuanceModule:asset must be platform allowed");
		//check asset in vault
		assetType = vaultFacet.getVaultTokenType(_vault, _asset);
		require(assetType != 0 && assetType == _debtType, "IssuanceModule:asset must be vault allowed");
	}	
}