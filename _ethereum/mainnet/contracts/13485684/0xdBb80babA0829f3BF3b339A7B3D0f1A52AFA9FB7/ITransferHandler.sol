pragma solidity ^0.6.0;

interface ITransferHandler {
    function varifyTransferApproval(        
        address sender, 
        address recipient
    ) external returns (bool approvalStatus);
}