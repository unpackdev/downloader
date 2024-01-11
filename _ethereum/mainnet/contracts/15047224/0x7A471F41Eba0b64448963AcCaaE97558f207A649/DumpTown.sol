//SPDX-License-Identifier: MIT
/*



  _____                          _______                  
 |  __ \                        |__   __|                 
 | |  | |_   _ _ __ ___  _ __      | | _____      ___ __  
 | |  | | | | | '_ ` _ \| '_ \     | |/ _ \ \ /\ / / '_ \ 
 | |__| | |_| | | | | | | |_) |    | | (_) \ V  V /| | | |
 |_____/ \__,_|_| |_| |_| .__/     |_|\___/ \_/\_/ |_| |_|
                        | |                               
                        |_|                               


*/
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";
import "./ReentrancyGuard.sol";

contract DumpTown is Ownable, ERC721Enumerable, ERC721Pausable, ReentrancyGuard {

    event TokenClaimed(uint256 _totalClaimed, address _owner, uint256 _numOfTokens, uint256[] _tokenIds);

    string public metadataBaseURL;
    bool public claimEnabled;
    uint public maxPerAddr;
    uint public maxPerTx;
    uint public maxTokens;
    
    constructor(string memory _metadataBaseURL) 
        ERC721("DumpTownDropouts", "DTD") {
            metadataBaseURL = _metadataBaseURL;
            claimEnabled = false;
            maxPerTx = 5;
            maxPerAddr = 20;
            maxTokens = 9500; // Public (9500) + Team (500) = Total supply (10,000)
        }

    function claim(uint numOfTokens) public nonReentrant {

        address _sender = _msgSender();
        uint _balance = balanceOf(_sender);
        uint _supply = totalSupply();
        
        require(_sender == tx.origin, "Cannot claim through contracts");
        require(claimEnabled, "Claim not enabled yet");
        require(numOfTokens > 0, "Cannot claim zero tokens");
        require(numOfTokens <= maxPerTx, "Cannot claim these many per tx");
        require(_balance < maxPerAddr, "Cannot claim these many per wallet");
        require(_supply + numOfTokens <= maxTokens, "Claim will exceed supply");
        
        uint[] memory ids = new uint[](numOfTokens);
        for(uint i=0; i<numOfTokens; i++) {
            uint256 _tokenid = _supply + 1;
            ids[i] = _tokenid;
            _supply++;
            _safeMint(msg.sender, _tokenid);
        }

        emit TokenClaimed(totalSupply(), _sender, numOfTokens, ids);
    }

    function mintToAddress(address to) public onlyOwner {
        uint _supply = totalSupply();
        require(_supply < maxTokens, "Claim will exceed supply");
        _safeMint(to, _supply + 1);
    }

    function reserve(uint num) public onlyOwner {
        uint i;
        for (i=0; i<num; i++)
            mintToAddress(msg.sender);
    }

    function setBaseURI(string memory baseURL) public onlyOwner {
        metadataBaseURL = baseURL;
    }

    function flipClaimEnabled() public onlyOwner {
        claimEnabled = !(claimEnabled);
    }

    function setSupply(uint _supply) public onlyOwner {
        maxTokens = _supply;
    }

    function setMaxPerTx(uint _max) public onlyOwner {
        maxPerTx = _max;
    }

    function setMaxPerAddr(uint _max) public onlyOwner {
        maxPerAddr = _max;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        address payable _sender = payable(_msgSender());
        _sender.transfer(_balance);
    }

    function pause() public virtual onlyOwner {
        _pause();
    }

    function unpause() public virtual onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from, 
        address to, 
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}