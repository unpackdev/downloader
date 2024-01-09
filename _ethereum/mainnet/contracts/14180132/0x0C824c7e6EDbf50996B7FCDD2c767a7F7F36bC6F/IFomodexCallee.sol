pragma solidity >=0.5.0;

interface IFomodexCallee {
    function FomodexCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
