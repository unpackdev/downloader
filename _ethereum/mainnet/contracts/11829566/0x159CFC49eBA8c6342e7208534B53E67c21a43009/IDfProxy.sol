pragma solidity ^0.5.16;

interface IDfProxy {
    function cast(address payable _to, bytes calldata _data) external payable;
    function withdrawEth(address payable _to) external;
}
