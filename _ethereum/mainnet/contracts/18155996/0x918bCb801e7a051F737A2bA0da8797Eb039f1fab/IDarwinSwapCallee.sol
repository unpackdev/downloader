pragma solidity ^0.8.14;

interface IDarwinSwapCallee {
    function darwinSwapCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}