pragma solidity ^0.8.0;

interface IRNGrequestorV2 {
    function process(uint256 rand, uint256 requestId) external;
}
