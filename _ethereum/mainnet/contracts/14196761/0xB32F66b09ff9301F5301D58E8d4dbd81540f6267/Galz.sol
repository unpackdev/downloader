// SPDX-License-Identifier: MIT

/*
╋╋╋╋╋╋╋┏┓╋╋╋╋╋╋╋╋╋╋╋╋┏┓
╋╋╋╋╋╋╋┃┃╋╋╋╋╋╋╋╋╋╋╋╋┃┃
┏━━┳┓╋┏┫┗━┳━━┳━┳━━┳━━┫┃┏━━━┓
┃┏━┫┃╋┃┃┏┓┃┃━┫┏┫┏┓┃┏┓┃┃┣━━┃┃
┃┗━┫┗━┛┃┗┛┃┃━┫┃┃┗┛┃┏┓┃┗┫┃━━┫
┗━━┻━┓┏┻━━┻━━┻┛┗━┓┣┛┗┻━┻━━━┛
╋╋╋┏━┛┃╋╋╋╋╋╋╋╋┏━┛┃
╋╋╋┗━━┛╋╋╋╋╋╋╋╋┗━━┛
*/

// CyberGalz Legal Overview [https://cybergalznft.com/legaloverview]

pragma solidity >=0.8.4;

import "./Counters.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721XX.sol";

abstract contract GalzRandomizer {
    function getTokenId(uint256 tokenId) public view virtual returns(uint256 resultId);
}

contract Galz is ERC721XX, OwnableUpgradeable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string private _baseURIextended;

    address randomizerAddress;
    address galzVendingMachineEthAddress;

    bool public contractLocked = false;

    event GalzRevealed(uint256 tokenId);
    event PaymentComplete(address indexed to, uint16 nonce, uint16 quantity);

    function initialize() initializer public {
        __ERC721XX_init("Galz", "GALZ", address(0x5FDCCA53617f4d2b9134B29090C87D01058e27e9));
    }

    function mintTransfer(address to) public returns(uint256, uint256) {
        require(msg.sender == galzVendingMachineEthAddress, "Not authorized");
        
        GalzRandomizer tokenAttribution = GalzRandomizer(randomizerAddress);
        
        uint256 realId1 = tokenAttribution.getTokenId(_tokenIdCounter.current());
        
        _safeMint(to, realId1);
        emit GalzRevealed(realId1);
        _tokenIdCounter.increment();

        uint256 realId2 = tokenAttribution.getTokenId(_tokenIdCounter.current());
        
        _safeMint(to, realId2);
        emit GalzRevealed(realId2);
        _tokenIdCounter.increment();

        return (realId1, realId2);
    }

    function isRevealed(uint256 id) public view returns(bool) {
        if (abi.encodePacked(ownerOf(id)).length == 20) {return true;} else {return false;}
    }
    
    function setGalzVendingMachineEthAddress(address newAddress) public onlyOwner { 
        galzVendingMachineEthAddress = newAddress;
    }

    function setRandomizerAddress(address newAddress) public onlyOwner {
        randomizerAddress = newAddress;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        require(contractLocked == false, "Contract has been locked and URI can't be changed");
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function lockContract() public onlyOwner {
        contractLocked = true;   
    }

}