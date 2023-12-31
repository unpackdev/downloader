//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BuyMeACoffee {
    //event to emit when a Memo is created
    event NewMemo(address indexed from, uint256 timestamp, string name, string message);

    //Memo struct
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    //List of all memos received
    Memo[] memos;

    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    /*
    * @dev Function to buy coffee for owner
    * @param _name Name of the person buying coffee
    * @param _message Message for the owner
    */
    function buyCoffee(string memory _name, string memory _message) public payable {
        require(msg.value >= 0.0001 ether, "Minimum 0.0001 ether required");
        //owner.transfer(msg.value);
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }
    /*
    * @dev send entire balance stored in this contract to owner
    */

    function withdrawTips() public {
        require(msg.sender == owner, "Only owner can withdraw");
        owner.transfer(address(this).balance);
    }

    /*
    * @dev retrieve all the memos received and stored on the blockchain
    */
    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }
}
