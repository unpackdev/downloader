// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";

interface IJira {
    function burn(uint amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract JiraBridge is Ownable{
    IJira public Jira = IJira(0x517AB044bda9629E785657DbbCae95C40C8f452C);
    event MarketplaceDeposit(address indexed sender, uint amount);

    function setAddress(address _adr) external onlyOwner {
        Jira = IJira(_adr);
    }

    function deposit(uint amount) external {
        require(Jira.allowance(msg.sender, address(this)) >= amount, "Not enough allowances");
        require(Jira.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        Jira.burn(amount);
        emit MarketplaceDeposit(msg.sender, amount);
    }
}
