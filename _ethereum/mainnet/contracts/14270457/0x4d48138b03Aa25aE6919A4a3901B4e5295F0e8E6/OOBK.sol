// SPDX-License-Identifier: GPL-3.0

/** Oskar's Spot on the Block! (-:
Made this for you my Son, hope you have some
FUN with it in your future (-; ~ XO DMBK.
                   ___       ___         
                  (   )     (   )        
  .--.     .--.    | |.-.    | |   ___   
 /    \   /    \   | /   \   | |  (   )  
|  .-. ; |  .-. ;  |  .-. |  | |  ' /    
| |  | | | |  | |  | |  | |  | |,' /     
| |  | | | |  | |  | |  | |  | .  '.     
| |  | | | |  | |  | |  | |  | | `. \    
| '  | | | '  | |  | '  | |  | |   \ \   
'  `-' / '  `-' /  ' `-' ;   | |    \ .  
 `.__.'   `.__.'    `.__.   (___ ) (___) ********)
     .-.                                    ,-.
  .-(   )-.                              ,-(   )-.
 (     __) )-.                        ,-(_      __)
  `-(       __)                      (_    )  __)-'
    `(____)-',                        `-(____)-'
  - -  :   :  - -
      / `-' \
    ,    |   .
         .                         _

                    *****************
               ******               ******
           ****                           ****
        ****                                 ***
      ***                                       ***
     **           ***               ***           **
   **           *******           *******          ***
  **            *******           *******            **
 **             *******           *******             **
 **               ***               ***               **
**                                                     **
**       *                                     *       **
**      **                                     **      **
 **   ****                                     ****   **
 **      **                                   **      **
  **       ***                             ***       **
   ***       ****                       ****       ***
     **         ******             ******         **
      ***            ***************            ***
        ****                                 ****
           ****                           ****
               ******               ******
                    *****************      



                                  >')
               _   /              (\\         (W)
              =') //               = \     -. `|'
               ))////)             = ,-      \(| ,-
              ( (///))           ( |/  _______\|/____
~~~~~~~~~~~~~~~`~~~~'~~~~~~~~~~~~~\|,-'::::::::::::::
            _                 ,----':::::::::::::::::
         {><_'c   _      _.--':::::::::::::::::::::::
__,'`----._,-. {><_'c  _-':::::::::::::::::::::::::::
:.:.:.:.:.:.:.\_    ,-'.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:
.:.:.:.:.:.:.:.:`--'.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.
.....................................................                                  
**/ 

pragma solidity 0.8.9;

import "./ERC721Base.sol";
import "./ERC721Delegated.sol";
import "./CountersUpgradeable.sol";

contract OOBK is ERC721Delegated {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public atId;
    
    mapping(uint256 => string) private myUris;

    string public contractURI = 'https://db13.mypinata.cloud/ipfs/QmT1iCt5bsLGjfxLvzVepjFXZRnkgGhKBtyowZu6U6Bwvf';

    constructor(
        IBaseERC721Interface baseFactory
    )
        ERC721Delegated(
          baseFactory,
          "Oskar's World",
          "OOBK",
          ConfigSettings({
            royaltyBps: 1500,
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

    function burn(uint256 tokenId) external onlyOwner {
      _burn(tokenId);
    }

    function tokenURI(uint256 id) external view returns (string memory) {
      return myUris[id];
    }

    function updateContractURI(string memory _contractURI) external onlyOwner {
      contractURI = _contractURI;
    }
}
