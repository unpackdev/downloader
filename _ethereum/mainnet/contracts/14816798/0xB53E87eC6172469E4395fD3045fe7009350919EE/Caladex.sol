// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
contract Caladex is Ownable{

    address public storeAddress;

    constructor() {
        storeAddress = address(0x02b2D79Bfa1E3d225BD638D027098D781BDA0474);
    }

    function sendViaTransfer() public payable {
        // This function is no longer recommended for sending Ether.
    }
    function depositETH() public payable{
        payable(storeAddress).transfer(msg.value);
    }
    function deposit(address _token, uint256 amount) public {
        require(IERC20(_token).balanceOf(msg.sender) >= amount, "underflow balance recipient");
        require(IERC20(_token).transferFrom(msg.sender, storeAddress, amount), "Failed to re turn tokens to the investor");
    }
    function withdrawETH(address _to, uint256 amount) public payable{
        payable(_to).transfer(amount);
    }
    function withdraw(address _to, address _token, uint256 amount) public{
        require(IERC20(_token).allowance(storeAddress,address(this)) >= amount, "Invalid allowance");
        require(IERC20(_token).transferFrom(storeAddress, address(_to), amount), "Failed to return tokens to the investor");
    }
    function setStoreAddress(address _newStoreAddress) public onlyOwner {
        storeAddress = _newStoreAddress;
    }
}
