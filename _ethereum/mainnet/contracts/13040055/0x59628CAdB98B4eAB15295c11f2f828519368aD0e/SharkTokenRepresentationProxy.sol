// SPDX-License-Identifier: None
pragma solidity ^0.8.6;

import "./TicketBooth.sol";
import "./ERC20.sol";
import "./console.sol";

contract SharkTokenRepresentationProxy is ERC20{

    ITicketBooth ticketBooth;
    uint256 projectId;

    constructor(address _ticketBooth, uint256 _projectId) ERC20("SharkDAOTokenProxy", "SHARKTANKPROXY"){
        ticketBooth = ITicketBooth(_ticketBooth);
        projectId = _projectId;
        
    }

    function totalSupply() public view virtual override returns (uint256) {
        return ticketBooth.totalSupplyOf(projectId);
    }

    function balanceOf(address _account) public view virtual override returns (uint256) {
        return ticketBooth.balanceOf(_account, projectId);
    }

}
