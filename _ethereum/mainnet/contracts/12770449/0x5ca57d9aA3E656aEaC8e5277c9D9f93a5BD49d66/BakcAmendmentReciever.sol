// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC2771Context.sol";
import "./Bakc.sol";

contract TestReceiver is ERC2771Context, Pausable, Ownable {	
    struct AmendmentMetadata {
        address amender;
        uint timestamp;
        bool isAmendable;
    }

    mapping (uint => AmendmentMetadata) private _amendmentsRequests;
    Bakc private bakc;

    constructor(address dependentContractAddress) 
        ERC2771Context() {
        bakc = Bakc(dependentContractAddress);
    }

    function initializeMetadata(uint[] memory ids) external onlyOwner {
        for(uint i = 0; i < ids.length; i++) {
            _amendmentsRequests[ids[i]] = AmendmentMetadata(address(0), 0, true);
        }
    }

    function amendmentRequested(uint tokenId) public view returns (bool) {
        return 
            _amendmentsRequests[tokenId].isAmendable && 
            _amendmentsRequests[tokenId].amender != address(0);        
    }

    function isAmendable(uint tokenId) public view returns (bool) {
        return _amendmentsRequests[tokenId].isAmendable;
    }

    function togglePausedState() public onlyOwner {
        paused() ? _unpause() : _pause();
    }
    
    function requestAmendment(uint tokenId) external whenNotPaused {
        require(_amendmentsRequests[tokenId].isAmendable, "Requested Token ID isn't amendable");
        require(!amendmentRequested(tokenId), "Can only request an amendment once");
        require(bakc.ownerOf(tokenId) == _msgSender(), "Token ID must be owned by amender");
        _amendmentsRequests[tokenId] = AmendmentMetadata(_msgSender(), block.timestamp, true);
    }

    function amendmentRequestDetails(uint tokenId) public view returns(address, uint) {        
        require(amendmentRequested(tokenId), "Token hasn't been amended");
        AmendmentMetadata memory amendment = _amendmentsRequests[tokenId];
        return (amendment.amender, amendment.timestamp);
    }
    
    function _msgSender() internal view override(Context, ERC2771Context)
        returns (address sender) {
        sender = ERC2771Context._msgSender();
    }    

    function _msgData() internal view override(Context, ERC2771Context)
        returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
