pragma solidity >=0.6.6;

interface ICAVO {
    function MAX_SUPPLY() external pure returns(uint);
    function CREATOR_SUPPLY() external pure returns(uint);
    function creator() external returns (address);
    function xCAVOToken() external view returns (address);
    function EXCVToken() external view returns (address);
    function mint(address to, uint value) external;
    function initialize(address _factory) external;
    function virtualBalanceOf(address account) external view returns (uint);
}   