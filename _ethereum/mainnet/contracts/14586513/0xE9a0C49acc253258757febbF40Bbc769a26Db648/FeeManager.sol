// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EternalStorage.sol";


contract FeeManager is EternalStorage {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() public view returns (address) {
        return addressStorage[keccak256(abi.encode("owner"))];
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function _transferOwnership(address newOwner) internal {
        address oldOwner = owner();
        addressStorage[keccak256(abi.encode("owner"))] = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function serviceFee() public returns (uint256) {
        if(msg.sender == owner()) return 0;
        return uintStorage[keccak256(abi.encode("serviceFee"))];
    }

    function setServiceFee (uint256 fee) public onlyOwner {
        uintStorage[keccak256(abi.encode("serviceFee"))] = fee;
    }

    function subscribtionFee() public returns (uint256) {
        return uintStorage[keccak256(abi.encode("subscribtionFee"))];
    }

    function setSubscribtionFee (uint256 _subscribtionFee) public onlyOwner {
        uintStorage[keccak256(abi.encode("subscribtionFee"))] = _subscribtionFee;
    }

    function isSubscribed (address _addr) public view returns (bool) {
        return _addr == owner() || boolStorage[keccak256(abi.encode("subscribers", _addr))];
    }

    function _setSubscriber (address _addr, bool value) internal {
        boolStorage[keccak256(abi.encode("subscribers", _addr))] = value;
    }

    function setFees (uint256 _serviceFee, uint256 _subscribtionFee) public onlyOwner {
        setServiceFee(_serviceFee);
        setSubscribtionFee(_subscribtionFee);
    }

    function initialize (uint256 _serviceFee, uint256 _subscribtionFee) public {
        require(owner() == address(0), "");
        _transferOwnership(msg.sender);
        setFees(_serviceFee, _subscribtionFee);
    }
    
    modifier onlySubscriber () {
        require(isSubscribed(msg.sender), "Message sender is not subscribed");
        _;
    }

    function subscribe () public payable {
        require(msg.value >= subscribtionFee(), "Insufficient amount");
        _setSubscriber(msg.sender, true);
    }

    function unsubscribe () public {
        _setSubscriber(msg.sender, false);
    }

    function giftSubscribtion (address to) public payable {
        require(msg.value >= subscribtionFee(), "Insufficient amount");
        _setSubscriber(to, true);
    }

    function ownerGiftSubscribtion (address to) public onlyOwner {
        _setSubscriber(to, true);
    }

}