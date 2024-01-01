pragma solidity ^0.8.0;

contract testContract {
    string public name;

    function setName(string memory nm) public {
        name = nm;
    }

    function getName() public view returns(string memory) {
        return name;
    }

}