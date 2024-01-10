// SPDX-License-Identifier: GPL-3.0

/** Nature:::

 _______          __                        
 \      \ _____ _/  |_ __ _________   ____  
 /   |   \\__  \\   __\  |  \_  __ \_/ __ \ 
/    |    \/ __ \|  | |  |  /|  | \/\  ___/ 
\____|__  (____  /__| |____/ |__|    \___  >
        \/     \/                        \/ 

     _.-""""`-._ 
   ,' _-""""`-_ `.
  / ,'.-'"""`-.`. \
 | / / ,'"""`. \ \ |
| | | | ,'"`. | | | |
| | | | |   | | | | |

        _    .  ,   .           .
    *  / \_ *  / \_      _  *        *   /\'__        *
      /    \  /    \,   ((        .    _/  /  \  *'.
 .   /\/\  /\/ :' __ \_  `          _^/  ^/    `--.
    /    \/  \  _/  \-'\      *    /.' ^_   \_   .'\  *
  /\  .-   `. \/     \ /==~=-=~=-=-;.  _/ \ -. `_/   \
 /  `-.__ ^   / .-'.--\ =-=~_=-=~=^/  _ `--./ .-'  `-

**/ 

pragma solidity 0.8.9;

import "./ERC721Base.sol";
import "./ERC721Delegated.sol";

import "./CountersUpgradeable.sol";

contract Nature is ERC721Delegated {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public atId;
    
    mapping(uint256 => string) private myUris;

    string public contractURI = 'https://gateway.pinata.cloud/ipfs/QmNZYAFgm1nf8fM6AFpfKaCf1cbrEPjPHERmuJaZ1niofe';

    constructor(
        IBaseERC721Interface baseFactory
    )
        ERC721Delegated(
          baseFactory,
          "Nature",
          "NATURE",
          ConfigSettings({
            royaltyBps: 1000,
            uriBase: "",
            uriExtension: "",
            hasTransferHook: false
          })
      )
    {}

    function burn(uint256 tokenId) external onlyOwner {
      _burn(tokenId);
    }

    function mint(string memory uri) external onlyOwner {
      myUris[atId.current()] = uri;        
      _mint(msg.sender, atId.current());
      atId.increment();
    }

    function tokenURI(uint256 id) external view returns (string memory) {
      return myUris[id];
    }

    function updateContractURI(string memory _contractURI) external onlyOwner {
      contractURI = _contractURI;
    }
}
