pragma solidity >=0.6.6;

interface IEXCV {
    function MAX_SUPPLY() external pure returns(uint);
    function CREATOR_SUPPLY() external pure returns(uint);
    function xEXCVToken() external view returns (address);
    function factory() external view returns (address);

    function mint(address to, uint value) external;
    function initialize(address _factory) external;
}