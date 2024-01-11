pragma solidity ^0.8.6;

interface IToken  {
    function setTxOk(uint256 _id, bool _ok) external;
}
