//SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0;

interface IRegistry {

    function fee(address localAddr) external view returns(uint256);
    function tokenRegistry(address localAddress, uint256 alienChainId) external view returns(address);
    function callRegistry(bytes32 callId) external view returns(bool);
    function registerToken(address localAddress, uint256 alienChainId, address alienAddress) external;
    function unregisterToken(address localAddress, uint256 alienChainId, address alienAddress) external;
    function setFee(address localAddr, uint256 _feeConst) external;


    event TokenRegistered(address indexed localAddress, uint256 indexed alienChainId, address indexed alienTokenAddress);
    event TokenUnregistered(address indexed localAddress, uint256 indexed alienChainId, address indexed alienTokenAddress);


    // event CallRegistered(uint256 indexed alienChainId_, address indexed alienChainContractAddr_, address indexed localChainContractAddr_, bytes4 callSig_);
    // event CallUnregistered(uint256 indexed alienChainId_, address indexed alienChainContractAddr_, address indexed localChainContractAddr_, bytes4 callSig_);

    event FeeChanged(address indexed localAddr, uint256 _feeConst);
}
