// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PVERC721.sol";
import "./PvSignedAllowlist.sol";

/*
* @author Niftydude
*/
contract BlootComic is PVERC721, PvSignedAllowlist {
    uint256 constant MAX_SUPPLY = 8008;

    uint256 public windowOpens;
    uint256 public windowCloses;

    constructor(
        string memory _name, 
        string memory _symbol,  
        string memory _uri,
        uint256 _windowOpens,
        uint256 _windowCloses  
    ) PVERC721(_name, _symbol, _uri) {
        windowOpens = _windowOpens;
        windowCloses = _windowCloses;

        _setSigner(0x2F403D19922343F15B6c455178FFEe9fB491CC8c);
        _setTicketSupply(MAX_SUPPLY); 
    }                  

    function editWindows(
        uint256 _windowOpens, 
        uint256 _windowCloses
    ) external onlyOwner {
        require(_windowOpens < _windowCloses, "open window must be before close window");

        windowOpens = _windowOpens;
        windowCloses = _windowCloses;
    }      

    function mint(
        bytes calldata _signature, 
        uint256 _ticketId,
        uint256 _amount
    ) external {
        require(totalSupply() + _amount <= MAX_SUPPLY, "Max supply reached");
        require (block.timestamp > windowOpens && block.timestamp < windowCloses, "Window closed");

        _verify(_signature, _ticketId, _amount);
        _invalidate(_ticketId);

        _mintMany(msg.sender, _amount);
    }       

    function invalidateTickets(
        uint256[] calldata _ticketIds
    ) external onlyOwner {
        for(uint256 i; i < _ticketIds.length; i++) {
             _invalidate(_ticketIds[i]);
        }
    }

    function setSigner(
        address _signer
    ) external onlyOwner {
        _setSigner(_signer);
    }

    function resetWithNewSupply(
        uint256 _supply
    ) external onlyOwner {
        _setTicketSupply(_supply);
    } 

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token. 
     */
    function tokenURI(uint256) public view override returns (string memory) {
        return uri;
    }             
}