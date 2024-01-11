// SPDX-License-Identifier: MIT

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@  @@@@    *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@# %@@@@@@@@@   @@ /@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@ /@/  @@@  @@@@@ @@@@@   @@@@@@@@@@@@@@@@
//@@@@@@@@@@* @@@@@@@@@@@@  @@ @@@@@@@@@@@@@@@%      @@@@@      ,@@@@  @@@#@@@@@%         #@@@@         @@@@@@@@@
//@@@@@@@@@@ /@@@@@@@@@@@@@      @  @@@    # @@@@@@@@@. @@ (@@@ @@@@@  @@@@  @@@@  @@@@@@  @@ &@@@@  @@@@@@@@@@@@
//@@@@@@@@@@  @@@@@@@@@@@@    @@@@@@@@@@@@@   @@@@@@@@@@ @/ @@@& @@@/ @@@@@  @@@@  @@@@@@@   .@@@@@@   @@@@@@@@@@
//@@@@@@@@@@@  .@@@@@.  ,@@@   @@@@@@@@@@@@   @@@@@@@@@  @@ .     @@@ @@@@@ @@@  @@@@@@@@ # @@@@@@@@  @@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@%  @@@@@@@@@@@@@  %@@@@@@@  @@@@ @@@@ @@@@ &@@@  @@  (@@@@@@@@/   @@@@@@    @@@@*@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@  @ ,@@@@@@@@@@@@@*@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@ %@@@@@@@  @@@@@@@@@@
//@@@@@@@@@@ %@@@@@@@@@@@@@@ *@  @@@@@@@  &@@( @@@@@@@@@@@@@%@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@@
//@@@@@@@@@@@@      .@@@@@@  @@@@       @@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@*   %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

// glulgulgulgullulgulululuglulgulguuglluggulgulAAAAAAAAAUUUUCCCHHHHHHglgulglulgulgugulgugulglBAAAAAACHluglugglug

pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./ERC721A.sol";

contract Garglins is ERC721A, Ownable{

    error AlGarglinsArGon();
    error YuGottaPayMor();

    uint256 public constant ooohowmanygarglinsrrther = 9999;
    uint256 public constant howmuchforaAAUCHHHgarglin = 0.09999 ether;
    uint256 public howmanygarglingrightNOWW = 0;
    string public werardegarglinsliving = "";

    constructor () ERC721A("garglins", "GARGLINS")
    {}

    
    function safeMint(address huaryou, uint256 howmanygarglinsyuwant) public payable {
        
        if(howmanygarglingrightNOWW + howmanygarglinsyuwant > ooohowmanygarglinsrrther){
            revert AlGarglinsArGon();
        }
        
        if(msg.value < howmanygarglinsyuwant * howmuchforaAAUCHHHgarglin){
            revert YuGottaPayMor();
        }

        howmanygarglingrightNOWW += howmanygarglinsyuwant;

        _safeMint(huaryou, howmanygarglinsyuwant);

    }
   
    function _baseURI() internal view override returns (string memory) {
        return werardegarglinsliving;
    }

    function setBaseURI(string memory newhousforgarglins) external onlyOwner {
        werardegarglinsliving = newhousforgarglins;
    }

    function withdraw() external onlyOwner {
        payable(Ownable.owner()).transfer(address(this).balance);
    }

    
    

    
}
