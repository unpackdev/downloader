pragma solidity ^0.8.0;

contract setstringcontract123456{
    string public a;
    uint256 public b = 69420;
    
    function setString(string memory _a) public {
        a = _a;
    }

    function returnString() public view returns (string memory) {
        return a;
    }
}