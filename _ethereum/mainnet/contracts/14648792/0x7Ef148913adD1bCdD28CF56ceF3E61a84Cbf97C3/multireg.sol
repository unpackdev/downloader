// SPDX-License-Identifier: MIT
// infant level solidity, be gentle.
// lcfr.eth && @lcfr_eth

pragma solidity ^0.8.7;

import "./ETHRegistrarController.sol";

contract ENSBulkRegister {

    event log_named_string       (string key, string val);

    address baseRegistrarAddr = 0x283Af0B28c62C092C9727F1Ee09c02CA627EB7F5;
    ETHRegistrarController controller = ETHRegistrarController(baseRegistrarAddr);

    struct CommitInfo {
        string  name; 
        address sender;
        bytes32 secret;
        uint256 timestamp;
    }
    
    CommitInfo[] private user_commitments;

    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function updateRegistrarAddr(address _newRegistrar) external onlyOwner {
        baseRegistrarAddr = _newRegistrar;
    }

    function updateOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function emergencyWithdraw(address _payee) external onlyOwner {
        (bool sent, bytes memory data) = _payee.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    // weak but doesnt matter much.
    function random(address _userAddress) internal view returns (bytes32) {
        return bytes32(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _userAddress)));
    }

    function doCommitloop(string[] memory _name) external {
        // we do this so people who have submitted commitments 
        // but didnt execute the register command will have stuck commitments. then the rentPrice calculation would be off later.
        // can be moved outside for "cheaper" gas - test inside vs outside.
        cleanCommitments();
        for ( uint i = 0; i < _name.length; ++i ) {
            bytes32 secret = random(msg.sender);
            bytes32 commitment = controller.makeCommitment(_name[i], msg.sender, secret); 
            controller.commit(commitment);
            user_commitments.push(CommitInfo(_name[i], msg.sender, secret, block.timestamp));
        }
    }

    function doRegisterloop(string[] memory _name, uint256 _duration) external payable { 
        uint256 totalPrice = rentPriceLoop(_name, _duration);

        require( msg.value >= totalPrice, "Not enough Ether sent.");
        
        for( uint i = 0; i < user_commitments.length; ++i ) {
            if( user_commitments[i].sender == msg.sender ) {
                uint price = controller.rentPrice(user_commitments[i].name, _duration);
                controller.register{value: price}(user_commitments[i].name, user_commitments[i].sender, _duration, user_commitments[i].secret);
                delete(user_commitments[i]); // consume the commitment.
                emit log_named_string("NameRegistered: ", user_commitments[i].name);
            }
        }
    }

    function cleanCommitments() internal {
        for( uint i = 0; i < user_commitments.length; ++i ) {
            if( user_commitments[i].sender == msg.sender ) {
                delete(user_commitments[i]);
            }
        }
    }

    function rentPriceLoop(string[] memory _name, uint256 _duration) public view returns(uint total) {
        uint256 total;
        for (uint i = 0; i < _name.length; i++) {
            total += controller.rentPrice(_name[i], _duration);
        }
        return total;
    }

}