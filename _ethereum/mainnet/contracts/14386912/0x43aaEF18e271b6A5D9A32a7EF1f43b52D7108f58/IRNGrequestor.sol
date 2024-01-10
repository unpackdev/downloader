pragma solidity ^0.8.7;

interface IRNGrequestor {
    function process(uint256 rand, bytes32 requestId) external;
}
