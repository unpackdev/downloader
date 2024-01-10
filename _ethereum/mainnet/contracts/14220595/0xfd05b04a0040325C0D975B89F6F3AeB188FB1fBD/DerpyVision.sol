// SPDX-License-Identifier: GPL-3.0

/** DerpyVision BY DAIN MYRICK BLODORN KIM

 ▄▀▀█▄▄   ▄▀▀█▄▄▄▄  ▄▀▀▄▀▀▀▄  ▄▀▀▄▀▀▀▄  ▄▀▀▄ ▀▀▄       
█ ▄▀   █ ▐  ▄▀   ▐ █   █   █ █   █   █ █   ▀▄ ▄▀       
▐ █    █   █▄▄▄▄▄  ▐  █▀▀█▀  ▐  █▀▀▀▀  ▐     █         
  █    █   █    ▌   ▄▀    █     █            █         
 ▄▀▄▄▄▄▀  ▄▀▄▄▄▄   █     █    ▄▀           ▄▀          
█     ▐   █    ▐   ▐     ▐   █             █           
▐         ▐                  ▐             ▐           
 ▄▀▀▄ ▄▀▀▄  ▄▀▀█▀▄   ▄▀▀▀▀▄  ▄▀▀█▀▄   ▄▀▀▀▀▄   ▄▀▀▄ ▀▄ 
█   █    █ █   █  █ █ █   ▐ █   █  █ █      █ █  █ █ █ 
▐  █    █  ▐   █  ▐    ▀▄   ▐   █  ▐ █      █ ▐  █  ▀█ 
   █   ▄▀      █    ▀▄   █      █    ▀▄    ▄▀   █   █  
    ▀▄▀     ▄▀▀▀▀▀▄  █▀▀▀    ▄▀▀▀▀▀▄   ▀▀▀▀   ▄▀   █   
           █       █ ▐      █       █         █    ▐   
           ▐       ▐        ▐       ▐         ▐        

**/ 

pragma solidity 0.8.9;

import "./ERC721Base.sol";
import "./ERC721Delegated.sol";

import "./CountersUpgradeable.sol";

contract DerpyVision is ERC721Delegated {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public atId;
    
    mapping(uint256 => string) private myUris;

    string public contractURI = 'https://gateway.pinata.cloud/ipfs/QmaFLAyDC3mT46PXnZmBWoksT6vd55xbfeUiFn9gAGiRTn';

    constructor(
        IBaseERC721Interface baseFactory
    )
        ERC721Delegated(
          baseFactory,
          "Derpy~Vision",
          "DERPYVISION",
          ConfigSettings({
            royaltyBps: 1000,
            uriBase: "",
            uriExtension: "",
            hasTransferHook: false
          })
      )
    {}

    function mint(string memory uri) external onlyOwner {
        myUris[atId.current()] = uri;        
        _mint(msg.sender, atId.current());
        atId.increment();
    }

    function tokenURI(uint256 id) external view returns (string memory) {
        return myUris[id];
    }

    function burn(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId));
        _burn(tokenId);
    }

    function updateContractURI(string memory _contractURI) external onlyOwner {
      contractURI = _contractURI;
    }
}
