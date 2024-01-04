pragma solidity ^0.6.0;

abstract contract IMedianOracle {
    function read() external virtual view returns (uint256);
}
