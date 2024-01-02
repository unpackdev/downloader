// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";

contract CardService is Initializable {


    address owner;
    address payable receiver;

    event SendTransfer(
        address fromAddress,
        uint256 value
    );


    /**
        @notice Initializes CardService, creates and grants {msg.sender} the admin role,
     */
    function __CardService_init(
    ) public initializer{

        owner = msg.sender;
        receiver = payable(msg.sender);

    }

    modifier onlyOwner() {
        require(msg.sender == owner,"must be owner");
        _;
    }
    
    function send() public payable{
        
        emit SendTransfer(msg.sender,msg.value);
        receiver.transfer(msg.value);   
    }

    /**
     * @dev setReceiver
     */
    function setReceiver(address payable _receiver) external onlyOwner {

        receiver = _receiver;
    }

    /**
     * @dev getReceiver
     */
    function getReceiver() external view returns(address){

       return receiver;
    }

    function setOwner(address onwerAddress) external onlyOwner{

        owner = onwerAddress;
    }

    function getOwner()external view returns(address){
       return owner;
    }
}
