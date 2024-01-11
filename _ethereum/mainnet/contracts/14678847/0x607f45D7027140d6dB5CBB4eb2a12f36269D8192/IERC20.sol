pragma solidity ^0.8.12;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address tokenOwner) external view returns (uint balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function allowance(address owner, address spender) external returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
