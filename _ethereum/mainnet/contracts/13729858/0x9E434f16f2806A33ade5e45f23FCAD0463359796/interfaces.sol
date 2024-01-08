// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct TokenInfo {
    address sourceToken;
    address targetToken;
    uint256 amount;
}
    
struct Position {
    TokenInfo[] supply;
    TokenInfo[] withdraw;
}

interface Interop {

    function submitAction(
        Position memory position,
        address sourceDsaSender,
        string memory actionId,
        uint64 targetDsaId,
        uint256 targetChainId,
        bytes memory metadata
    ) external ;
}
