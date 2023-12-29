pragma solidity ^0.8.13;

interface IT2BRequest {
    struct T2BRequest {
        uint256 amount;
        address recipient;
        uint256 toChainId;
        address token;
    }
}
