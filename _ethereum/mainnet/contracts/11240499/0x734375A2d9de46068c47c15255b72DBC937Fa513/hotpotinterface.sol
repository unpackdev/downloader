pragma solidity ^0.6.0;

interface IHotPot{
    function mint(address,uint256,uint8,string calldata) external;

    function update(uint256,uint8) external;

    function getGrade(uint256) external view returns(uint8);

    function getUseTime(uint256) external view returns(uint256);

    function setUse(uint256) external;

    function setUse(uint256,uint256) external;

    function getGradeCount(uint8) external view returns(uint256);
}