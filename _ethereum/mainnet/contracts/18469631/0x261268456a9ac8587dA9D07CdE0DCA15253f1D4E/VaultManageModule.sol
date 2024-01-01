// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./ModuleBase.sol";

import "./IVaultManageModule.sol";
import "./IOwnable.sol";
contract VaultManageModule is ModuleBase,IVaultManageModule,Initializable, UUPSUpgradeable {

    /// @custom:oz-upgrades-unsafe-allow constructor 
    constructor() {
        _disableInitializers();
    }
    function initialize(address _diamond) initializer public {
        __UUPSUpgradeable_init();
        diamond=_diamond;
    }
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
    modifier onlyOwner{
        require(msg.sender == IOwnable(diamond).owner(),"only owner");
        _;
    }
    function removeVault(address _vault) external onlyVault(_vault){
         address _wallet= IOwnable(_vault).owner();
         require(_wallet != address(0),"VaultManageModule:invalid vault");
         address[] memory vaults=new address[](1);
         vaults[0]=_vault;
         IPlatformFacet(diamond).removeWalletToVault(_wallet,vaults);
         emit RemoveVault(_wallet,_vault);
    }

    function validVaultModule(address _module,uint256 /** */,bytes memory func) external view{
        IVaultFacet vaultFacet= IVaultFacet(diamond);
        require(!IVaultFacet(diamond).getVaultLock(msg.sender),"VaultManageModule:vault is locked"); 
        require(func.length >= 4 || func.length == 0, "VaultManageModule:invalid func");
        bytes4 selector;
        assembly {
            selector := mload(add(func, 32))
        }
        if(vaultFacet.getVaultLock(msg.sender)){
            require( vaultFacet.getFuncWhiteList(msg.sender,selector),"VaultManageModule:vault is locked"); 
        }else{
            require(!vaultFacet.getFuncBlackList(msg.sender,selector),"VaultManageModule:func in balackList"); 
        }
        IPlatformFacet platformFacet=IPlatformFacet(diamond);
        require(platformFacet.getIsVault(msg.sender),"VaultManageModule:invalid vault");
        require(platformFacet.getModuleStatus(_module),"VaultManageModule:invalid module");
        if(_module != address(this)){      
           require(vaultFacet.getVaultModuleStatus(msg.sender,_module),"VaultManageModule:invalid module in vault");
        }
    }
    function registToPlatform(address _vault,uint256 _salt) external {
          require(_salt != 0,"VaultManageModule:_salt error");
          IVault vault= IVault(_vault);
          address imp=vault.getImplementation();      
          IPlatformFacet platformFacet =IPlatformFacet(diamond);
          address platformImp=platformFacet.getVaultImplementation();
          require(platformFacet.getProxyCodeHash(_vault),"VaultManageModule:vault mismatch condition");
          require(imp == platformImp,"VaultManageModule:vault implementation must be the same as the platform");
          address owner=vault.owner();
          require(msg.sender == owner,"VaultManageModule:caller must be vault owner");
          platformFacet.addWalletToVault(owner,_vault,_salt);  
          IVaultFacet(diamond).setSourceType(owner,2);     
          emit RegistToPlatform(_vault,_salt,2);                                                                                                                                                                                                                     
    }

 
    function setVaultMasterToken(address _vault,address _masterToken) external onlyVault(_vault){
          require(_masterToken != address(0),"VaultManageModule:invalid materToken");
          IVaultFacet(diamond).setVaultMasterToken(_vault,_masterToken);
    }
    function setVaultProtocol(address _vault,address[] memory _protocols,bool[] memory _status) external  onlyVault(_vault){
          IVaultFacet(diamond).setVaultProtocol(_vault,_protocols,_status);
    }
    function setVaultTokens(address _vault,address[] memory _tokens,uint256[] memory _types) external  onlyVault(_vault){
          IVaultFacet(diamond).setVaultTokens(_vault,_tokens,_types);
    }
    function setVaultModule(address _vault,address[] memory _modules,bool[] memory _status) external   onlyVault(_vault){
          IVaultFacet(diamond).setVaultModules(_vault,_modules,_status);
    }
    function setVaultType(address _vault,uint256 _vaultType) external onlyVault(_vault){
           require(IPlatformFacet(diamond).getVaultToSalt(_vault) != 0,"VaultManageModule:Main Vault not allow edit");    
           IVaultFacet(diamond).setVaultType(_vault,_vaultType);
    } 
}