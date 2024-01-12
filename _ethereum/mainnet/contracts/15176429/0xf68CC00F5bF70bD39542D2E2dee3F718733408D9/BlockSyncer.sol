// SPDX-License-Identifier: GPL-3.0

/**    BlockSyncer BY DAIN MYRICK BLODORN KIM
   ___  __         __    ____                     
  / _ )/ /__  ____/ /__ / __/_ _____  _______ ____
 / _  / / _ \/ __/  '_/_\ \/ // / _ \/ __/ -_) __/
/____/_/\___/\__/_/\_\/___/\_, /_//_/\__/\__/_/   
                          /___/    

**/

pragma solidity 0.8.9;

import "./ERC721Base.sol";
import "./ERC721Delegated.sol";

import "./CountersUpgradeable.sol";

contract BlockSyncer is ERC721Delegated {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public atId;
    
    mapping(uint256 => string) private myUris;

    string public contractURI = 'https://db13.mypinata.cloud/ipfs/QmQihEBAkMsBe47vW4iJTUU9ff4pRbpFmP1XDmbRy2xstw';

    constructor(
        IBaseERC721Interface baseFactory
    )
        ERC721Delegated(
          baseFactory,
          "BlockSyncer",
          "SYNC",
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
