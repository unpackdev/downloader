// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;                                               
import "./Ownable.sol";
import "./SafeMath.sol";

contract ProzacYouth is Ownable{
    using SafeMath for uint256;
    bool public paused = true;
    uint256 public maxSupply = 13;
    uint256 public count = 0;
    mapping(address => uint256) public addressList;
    mapping(uint256 => address) public orderedAddressList;

    constructor() {}

    function addToList(address _address) public {
        require(!paused);
        require(count < maxSupply, "No spots left");
        require(addressList[_address] == 0, "Already registered");
        addressList[_address] = 1;
        orderedAddressList[count] = _address;
        count++;
    }

    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setAddressList(uint256 index, address newAddress) public onlyOwner {
        require(index < count, "Invalid index");
        address oldVal = orderedAddressList[index];
        addressList[oldVal] = 0;
        orderedAddressList[index] = newAddress;
        addressList[newAddress] = 1;
    }

    function togglePause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function getAddresses(uint256 startIndex)  public view returns (address[] memory){
        require(startIndex < count, "Invalid startIndex");
        address[] memory ret = new address[]((count-startIndex));
        for (uint i = startIndex; i < count; i++) {
            ret[i] = orderedAddressList[i];
        }
        return ret;
    }

    function isRegistered(address addressToCheck) public view returns (bool) {
        return addressList[addressToCheck] != 0;
    }
}