// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IVaultFacet{
      struct Position{  
           uint16  positionType;  //1 normal 2 aave asset 3 compound asset 4gmx  asset  5 lido asset  6 nft asset
           uint16  debtType;   // 0 normal    1  debt           
           uint16 ableUse;   // 0 unused   1 used
           address component; 
           uint256 balance;
           bytes data; 
      }
     event SetVaultType(address _vault,uint256 _vaultType);
     event SetSourceType(address _vault,uint256 _sourceType);
     event SetVaultMasterToken(address _vault,address _masterToken);
     event SetVaultLock(address _vault,bool _lock);
     event SetVaultTime(address _vault,uint256 _time);
     event SetVaultModules(address _vault,address[]  _modules,bool[]  _status);
     event SetVaultTokens(address _vault,address[] _tokens,uint256[]  _types);
     event SetVaultProtocol(address _vault,address[]  _protocols,bool[]  _status);
     event SetVaultPosition(address _vault,address _component,uint16[3]  _append);
     event SetVaultPositionData(address _vault,address _component,uint256 _positionType,bytes  _data);
     event SetVaultPositionBalance(address _vault,address _component,uint256 _positionType,uint256 _balance);  
    
     event SetFuncWhiteList(address _vault,bytes4 _func,bool _type);
     event SetFuncBlackList(address _vault,bytes4 _func,bool _type);



     function setVaultType(address _vault,uint256 _vaultType) external;
     function getVaultType(address _vault) external view returns(uint256);
     function setSourceType(address _vault,uint256 _sourceType) external;
     function getSourceType(address _vault) external view returns(uint256);
     
     function setVaultMasterToken(address _vault,address _masterToken) external;
     function getVaultMasterToken(address _vault) external view returns(address);
     
     function setVaultLock(address _vault,bool _lock) external;
     function getVaultLock(address _vault) external view returns(bool);
     function setVaultTime(address _vault,uint256 _time) external;
     function getVaulTime(address _vault) external view returns(uint256);


     function setVaultModules(address _vault,address[] memory _modules,bool[] memory _status) external; 
     function getVaultAllModules(address _vault) external view returns(address[] memory);
     function getVaultModuleStatus(address _vault,address _module) external view returns(bool);

     function setVaultTokens(address _vault,address[] memory _tokens,uint256[] memory _status) external;
     function getVaultAllTokens(address _vault) external view returns(address[] memory);
     function getVaultTokenType(address _vault,address _token) external view returns(uint256);

     function setVaultProtocol(address _vault,address[] memory _protocols,bool[] memory _status) external;
     function getVaultAllProtocol(address _vault) external view returns(address[] memory);
     function getVaultProtocolStatus(address _vault,address  _protocol) external view returns(bool);

     function setVaultPosition(address _vault,address _component,uint16[3] memory _append) external;
     function setVaultPositionData(address _vault,address _component,uint256 _positionType,bytes memory _data) external;
     function getVaultAllPosition(address _vault,uint16[] memory _positionTypes) external view returns(Position[] memory positions);
     function getVaultProtocolPosition(address _vault,uint16 _positionType) external view returns(Position[] memory positions);
     function getVaultPosition(address _vault,address _component, uint256 _positionType) external view returns(Position memory position);
    
     function setFuncWhiteList(address _vault,bytes4 _func,bool _type) external;
     function getFuncWhiteList(address _vault,bytes4 _func) external view returns(bool);
     function setFuncBlackList(address _vault,bytes4 _func,bool _type) external;
     function getFuncBlackList(address _vault,bytes4 _func) external view returns(bool);
}