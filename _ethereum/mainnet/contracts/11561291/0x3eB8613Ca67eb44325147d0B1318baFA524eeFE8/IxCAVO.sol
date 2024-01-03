pragma solidity >=0.6.6;

interface IxCAVO {
    function excvEthPair() external view returns (address);
    function cavoEthPair() external view returns (address);
    function getEXCV() external view returns (address);
    function getCAVO() external view returns (address);
    
    function redeem(address recipient) external;
    function initialize(address _factory, address _EXCV) external;
    function registerPairCreation() external;
    function mint(uint price) external;
    function accumulatedMintableCAVOAmount() external view returns (uint);
}
