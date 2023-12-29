pragma solidity ^0.5.0;


interface IGasToken {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}


contract GasDiscountDeployer {
    IGasToken public constant gasToken = IGasToken(0x0000000000b3F879cb30FE243b4Dfee438691c04);
    
    function deploy(bytes memory data) public {
        uint256 gas_start = gasleft();
        assembly {
            pop(create(0, add(data, 32), mload(data)))
        }
        
        uint256 gasSpent = gas_start - gasleft();
        gasToken.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41130);
    }
}