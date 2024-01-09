pragma solidity >=0.5.0;

interface IFujiCallee {
    function fujiCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
