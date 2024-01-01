// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IVault} from  "../interfaces/internal/IVault.sol";
import "./IPlatformFacet.sol";
import "./IVaultFacet.sol";
import "./IERC20.sol";
contract ModuleBase{ 
    address public diamond;
    modifier onlyVault(address _vault) {
        require(msg.sender==address(_vault),"ModuleBase:caller must be vault");
        require(IPlatformFacet(diamond).getIsVault(_vault),"ModuleBase:vault must in platform");

        _;
    }

    modifier onlyVaultManager(address _vault){
        require(msg.sender==IVault(_vault).owner(),"ModuleBase:caller must be vault manager");
        require(IPlatformFacet(diamond).getIsVault(_vault),"ModuleBase:vault must in platform");
        _; 
    }
    function updatePosition(address _vault,address _component,uint256 _positionType,uint16 _debtType) internal {
            uint256 balance;
            if(_component==IPlatformFacet(diamond).getEth()) {
              balance= _vault.balance;    
            }else{
              balance=  IERC20(_component).balanceOf(_vault);
            }      
            uint16 option=balance>0 ? 1 : 0;
            uint16[3] memory sendAssetAppend=[uint16(_positionType),_debtType,option];
            IVaultFacet(diamond).setVaultPosition(_vault,_component,sendAssetAppend);
    }
}