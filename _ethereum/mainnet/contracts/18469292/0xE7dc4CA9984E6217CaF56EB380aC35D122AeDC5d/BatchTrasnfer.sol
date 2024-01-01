// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

abstract contract Context {
    constructor () { }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract BatchTransfer is Ownable {
    constructor() {}
    
    function batchTransfer(address tokenAddress, address[] calldata recipients, uint256[] calldata amounts) public onlyOwner returns (bool) {
        require(recipients.length == amounts.length);
        
        IERC20 erc20 = IERC20(tokenAddress);

        for (uint256 i = 0; i < recipients.length; i++) {
            erc20.transfer(recipients[i], amounts[i]);
        }

        return true;
    }

    function withdrawErc20(address tokenAddress, address beneficialAddress) public onlyOwner returns (bool) {
        IERC20(tokenAddress).transfer(
            beneficialAddress,
            IERC20(tokenAddress).balanceOf(address(this))
        );

        return true;
    }
}