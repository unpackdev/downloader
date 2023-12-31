// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract Ownable is Context {
    address private _Owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function Owner() public view virtual returns (address) {
        return _Owner;
    }
    modifier onlyOwner() {
        require(Owner() == _msgSender(), "Ownable: caller is not the Owner");
        _;
    }
}

contract Bf is Context, Ownable {
    event Subscribed(address indexed subscriber, address indexed subscribee, uint256 amount);

    uint256 public feeRation = 5;
    function setFeeRation(uint256 newFeeRation) external onlyOwner{
        feeRation = newFeeRation;
    }
    function subscribe(address payable to) external payable  {
        uint256 fee = msg.value * feeRation / 100;
        payable(to).transfer(msg.value - fee);
        emit Subscribed(msg.sender, to, msg.value);

    }
    function withdraw() external onlyOwner{
        payable(Owner()).transfer(address(this).balance);
    }
    receive() external payable{

    }
}