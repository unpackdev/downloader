pragma solidity >=0.5.0;

interface IBonexV2Callee {
    function BonexV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
