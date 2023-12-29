pragma solidity ^0.8.0;

interface IL2GatewayRouter {
    
    function outboundTransfer(
        address _l1Token,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable returns (bytes memory);
}