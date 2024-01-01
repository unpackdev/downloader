// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract InsuranceFund {
    address public admin;
    uint256 public fundBalance;

    event DepositedToFund(address indexed from, uint256 amount);
    event WithdrawnFromFund(address indexed to, uint256 amount);
    event ClaimPaid(address indexed to, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "InsuranceFund: Caller is not the admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function depositToFund(uint256 amount) external onlyAdmin {
        
        emit DepositedToFund(msg.sender, amount);
    }

    function withdrawFromFund(address to, uint256 amount) external onlyAdmin {
     
        emit WithdrawnFromFund(to, amount);
    }

    function payClaim(address to, uint256 amount) external onlyAdmin {
       
        emit ClaimPaid(to, amount);
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

    function getFundBalance() external view returns (uint256) {
        return fundBalance;
    }
}