// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract S16Presale is Ownable {
    address private admin; //address of the s16 owner

    mapping(address => bool) public regForPresaleMint;

    uint256 public preSaleRegisterPrice = 0.016 ether;
    uint256 private PRE_SALE_REG_TIME = 1643414400; // Presale Time till 28th JAN 2021 07: 00 PM
    address[] public preSaleRegisterUserList;

    fallback() external payable {
        require(admin != address(0x0), "S16Presale: zero address error");
        require(
            block.timestamp <= PRE_SALE_REG_TIME,
            "S16Presale: preSale registration times end"
        );
        require(msg.value >= preSaleRegisterPrice, "transfer ether error");
        require(regForPresaleMint[msg.sender] == false, "already registered for presale");
        payable(admin).transfer(msg.value);
        regForPresaleMint[msg.sender] = true;
        preSaleRegisterUserList.push(msg.sender);
    }

    function changePreSaleTime(uint256 _PRE_SALE_REG_TIME) external onlyOwner {
        require(_PRE_SALE_REG_TIME > 0, "S16Presale: time update error");
        PRE_SALE_REG_TIME = _PRE_SALE_REG_TIME;
    }

    function setOwnerAddress(address _admin) external onlyOwner {
        require(_admin != address(0x0), "S16Presale: zero address error");
        admin = _admin;
    }

    function isRegisterforPresale(address _wallet)
        external
        view
        returns (bool)
    {
        return regForPresaleMint[_wallet];
    }

    function getETHBalance(address _wallet) external view returns (uint256) {
        return _wallet.balance;
    }

    function getPresaleRegisterUserList()
        external
        view
        returns (address[] memory)
    {
        return preSaleRegisterUserList;
    }

    function getPresaleTime() external view returns (uint) {
        return PRE_SALE_REG_TIME;
    }
}
