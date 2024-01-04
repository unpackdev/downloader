pragma solidity 0.6.12;


abstract contract ERC677 {
    function transfer(address to, uint256 value) public virtual returns (bool);
    function transferAndCall(address to, uint value, bytes memory data) public virtual returns (bool success);

    // event Transfer(address indexed from, address indexed to, uint value, bytes data);
}
