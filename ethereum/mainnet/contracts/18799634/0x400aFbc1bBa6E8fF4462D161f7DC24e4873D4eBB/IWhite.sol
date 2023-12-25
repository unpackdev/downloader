pragma solidity 0.8.19;

interface IWhite {
    function mint(address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function burn(uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferOwnership(address) external;
}