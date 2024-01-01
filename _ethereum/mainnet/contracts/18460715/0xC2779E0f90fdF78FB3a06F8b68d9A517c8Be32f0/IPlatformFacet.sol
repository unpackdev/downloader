// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
interface IPlatformFacet{
    struct ProtocolAndA{
        address addr;
        address module;
        string  protocol;      
    }
    event SetModules(address[]  _modules,bool[]  _status);
    event SetProtocols(address _module,string[]  _protocols,address[]  _protocolAddrs);
    event SetTokens(address[]  _tokens,uint256[]  _tokenTypes);
    event AddWalletToVault(address _wallet,address _vault,uint256 _salt);
    event RemoveWalletToVault(address _wallet,address[]  _vaults);
    event SetWeth(address _weth);
    event SetEth(address _eth);
    event SetVaultImplementation(address _implementation);
    event SetProxyCodeHash(address _proxy,bool _option);

    function setModules(address[] memory _modules,bool[] memory _status)  external;
    function getAllModules()  external view returns(address[] memory);
    function getModuleStatus(address _module) external view returns(bool);   


    function setProtocols(address _module,string[] memory _protocols,address[] memory _protocolAddrs) external;
    function getProtocols()  external view returns(ProtocolAndA[] memory);
    function getModuleToProtocolA(address _module,string memory _protocol) external view returns(address);


    function setTokens(address[] memory _tokens,uint256[] memory _tokenTypes)  external;
    function getTokens()  external view returns(address[] memory);  
    function getTokenType(address _token) external view returns(uint256);


    function addWalletToVault(address _wallet,address _vault,uint256 _salt) external;
    function removeWalletToVault(address _wallet,address[] memory _vaults) external;
    function getAllVaultByWallet(address _wallet) external view returns(address[] memory);
    function getVaultToSalt(address _vault) external view returns(uint256);
    function getIsVault(address _vault) external view returns(bool);

    function setWeth(address _weth) external;
    function getWeth() external view returns(address);

    function setEth(address _eth) external;
    function getEth() external view returns(address);

    function getVaultImplementation() external view returns(address);
    function setVaultImplementation(address _implementation) external; 
    function setProxyCodeHash(address _proxy,bool _option) external;  
    function getProxyCodeHash(address _proxy) external view returns(bool);
}