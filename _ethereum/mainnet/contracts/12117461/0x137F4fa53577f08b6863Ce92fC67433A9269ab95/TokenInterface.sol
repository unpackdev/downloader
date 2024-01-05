pragma solidity >=0.7.0 <=0.8.1;

interface TokenInterface {
    function name() external returns (string memory);
    function symbol() external returns (string memory);
    function decimals() external returns (uint);

    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint value) external;
    event Transfer(address indexed from, address indexed to, uint value);

    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address from, address to, uint value) external;
    function approve(address spender, uint value) external;
    event Approval(address indexed owner, address indexed spender, uint value);
}

