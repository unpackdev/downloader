// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
interface IVaultManageModule{
   event RemoveVault(address _wallet,address _vault);
   event RegistToPlatform(address _vault,uint256 _salt,uint256 _sourceType);
    function validVaultModule(address _module,uint256 _value,bytes memory func) external view;
   function registToPlatform(address _vault,uint256 _salt) external;
   function setVaultMasterToken(address _vault,address _masterToken) external;
   function setVaultProtocol(address _vault,address[] memory _protocols,bool[] memory _status) external;
   function setVaultTokens(address _vault,address[] memory _tokens,uint256[] memory _types) external;
   function setVaultModule(address _vault,address[] memory _modules,bool[] memory _status) external;
   function removeVault(address _vault) external;
   function setVaultType(address _vault,uint256 _vaultType) external;
}