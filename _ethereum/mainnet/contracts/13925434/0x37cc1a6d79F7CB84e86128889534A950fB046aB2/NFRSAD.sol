/*

███    ██  ██████  ███    ██       ███████ ██    ██ ███    ██  ██████  ██ ██████  ██      ███████ 
████   ██ ██    ██ ████   ██       ██      ██    ██ ████   ██ ██       ██ ██   ██ ██      ██      
██ ██  ██ ██    ██ ██ ██  ██ █████ █████   ██    ██ ██ ██  ██ ██   ███ ██ ██████  ██      █████   
██  ██ ██ ██    ██ ██  ██ ██       ██      ██    ██ ██  ██ ██ ██    ██ ██ ██   ██ ██      ██      
██   ████  ██████  ██   ████       ██       ██████  ██   ████  ██████  ██ ██████  ███████ ███████ 
                                                                                                  
                                                                                                  
██████   █████  ██████  ██  ██████  ███████ ██   ██  █████   ██████ ██   ██                       
██   ██ ██   ██ ██   ██ ██ ██    ██ ██      ██   ██ ██   ██ ██      ██  ██                        
██████  ███████ ██   ██ ██ ██    ██ ███████ ███████ ███████ ██      █████                         
██   ██ ██   ██ ██   ██ ██ ██    ██      ██ ██   ██ ██   ██ ██      ██  ██                        
██   ██ ██   ██ ██████  ██  ██████  ███████ ██   ██ ██   ██  ██████ ██   ██                       
                                                                                                  
                                                                                                  
 █████  ██    ██ ████████ ██   ██  ██████  ██████  ██ ███████ ███████ ██████                      
██   ██ ██    ██    ██    ██   ██ ██    ██ ██   ██ ██    ███  ██      ██   ██                     
███████ ██    ██    ██    ███████ ██    ██ ██████  ██   ███   █████   ██   ██                     
██   ██ ██    ██    ██    ██   ██ ██    ██ ██   ██ ██  ███    ██      ██   ██                     
██   ██  ██████     ██    ██   ██  ██████  ██   ██ ██ ███████ ███████ ██████                      
                                                                                                  
                                                                                                  
██████  ███████  █████  ██      ███████ ██████  ███████                                           
██   ██ ██      ██   ██ ██      ██      ██   ██ ██                                                
██   ██ █████   ███████ ██      █████   ██████  ███████                                           
██   ██ ██      ██   ██ ██      ██      ██   ██      ██                                           
██████  ███████ ██   ██ ███████ ███████ ██   ██ ███████                                         
                                                            
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract NFRSAD is ERC721, Pausable, Ownable {
    using Strings for uint256;

    uint256 public shacksToReserve = 30;
    uint256 public shackPrice = .088 ether;
    uint256 public maxShacks = 353;

    string public baseURI =
        "ipfs://QmQ5x7FoMfKk4HGGz2T71P2LzzgRk9XvhQ5qqcxjPN3yyq/";

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Non-Fungible RadioShack Authorized Dealers", "RSAD") {
        transferOwnership(msg.sender);
        _tokenIdCounter.increment();
        // Reserve some shacks for the based devs
        for (uint256 i = 1; i <= shacksToReserve; i++) {
            _mint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function mintRSAD() public payable whenNotPaused {
        require(msg.value >= shackPrice, "LOW_ETHER");
        require(_tokenIdCounter.current() < maxShacks, "MAX_REACHED");
        _mint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current() - 1;
    }

    function remainingSupply() public view returns (string memory) {
        uint256 supply = maxShacks - totalSupply();
        return supply.toString();
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
