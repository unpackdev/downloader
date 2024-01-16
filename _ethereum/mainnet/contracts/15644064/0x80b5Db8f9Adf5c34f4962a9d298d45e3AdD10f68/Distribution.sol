// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;


import "./IERC20.sol";

contract Distribution {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: caller is not a owner");
        _;
    }

    struct TransferData {
        address to;
        uint256 amount;
    }

    function batchTransfer(address tokenAddress, address from, TransferData[] memory transferData) external onlyOwner returns(bool) {
        for(uint8 i = 0; i < transferData.length; i++) {
            IERC20(tokenAddress).transferFrom(from, transferData[i].to, transferData[i].amount);
        }
        return true;
    }

    function transferOwnership(address newOwner) external onlyOwner returns(bool) {
        require(newOwner != address(0), "newOwner is zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }
}