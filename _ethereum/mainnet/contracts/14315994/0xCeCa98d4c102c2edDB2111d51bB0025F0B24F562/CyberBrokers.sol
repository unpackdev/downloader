//SPDX-License-Identifier: UNLICENSED

/*

  /$$$$$$            /$$                           /$$$$$$$                      /$$                                    
 /$$__  $$          | $$                          | $$__  $$                    | $$                                    
| $$  \__/ /$$   /$$| $$$$$$$   /$$$$$$   /$$$$$$ | $$  \ $$  /$$$$$$   /$$$$$$ | $$   /$$  /$$$$$$   /$$$$$$   /$$$$$$$
| $$      | $$  | $$| $$__  $$ /$$__  $$ /$$__  $$| $$$$$$$  /$$__  $$ /$$__  $$| $$  /$$/ /$$__  $$ /$$__  $$ /$$_____/
| $$      | $$  | $$| $$  \ $$| $$$$$$$$| $$  \__/| $$__  $$| $$  \__/| $$  \ $$| $$$$$$/ | $$$$$$$$| $$  \__/|  $$$$$$ 
| $$    $$| $$  | $$| $$  | $$| $$_____/| $$      | $$  \ $$| $$      | $$  | $$| $$_  $$ | $$_____/| $$       \____  $$
|  $$$$$$/|  $$$$$$$| $$$$$$$/|  $$$$$$$| $$      | $$$$$$$/| $$      |  $$$$$$/| $$ \  $$|  $$$$$$$| $$       /$$$$$$$/
 \______/  \____  $$|_______/  \_______/|__/      |_______/ |__/       \______/ |__/  \__/ \_______/|__/      |_______/ 
           /$$  | $$                                                                                                    
          |  $$$$$$/                                                                                                    
           \______/                                                                                                     


 /$$                          /$$$$$                     /$$          
| $$                         |__  $$                    |__/          
| $$$$$$$  /$$   /$$            | $$  /$$$$$$   /$$$$$$$ /$$  /$$$$$$ 
| $$__  $$| $$  | $$            | $$ /$$__  $$ /$$_____/| $$ /$$__  $$
| $$  \ $$| $$  | $$       /$$  | $$| $$  \ $$|  $$$$$$ | $$| $$$$$$$$
| $$  | $$| $$  | $$      | $$  | $$| $$  | $$ \____  $$| $$| $$_____/
| $$$$$$$/|  $$$$$$$      |  $$$$$$/|  $$$$$$/ /$$$$$$$/| $$|  $$$$$$$
|_______/  \____  $$       \______/  \______/ |_______/ |__/ \_______/
           /$$  | $$                                                  
          |  $$$$$$/                                                  
           \______/                                                   

*/

pragma solidity ^0.8.4;

import "./Ownable.sol";

import "./ERC721A.sol";

contract CyberBrokers is ERC721A, Ownable {


    uint256 public constant PUBLIC_PRICE = 0.35 ether;
    uint256 public constant LIMIT = 10_000;

    bool public paused = true;

    string public preRevealUri = "https://gateway.pinata.cloud/ipfs/QmcWx8ZJd8w4c78bTbkdDPe6pTabwy9joy1DxmETpqEnAX";

    constructor() ERC721A("CyberBrokers by Josie", "CyberBrokers") {
    }

    function ownerMint(address _to, uint256 _howMany) public onlyOwner {
        _safeMint(_to, _howMany);
    }

    function mint(uint256 _howMany) public payable {
        require(!paused, "Paused");
        require(msg.value == _howMany * PUBLIC_PRICE, "Needs more ETH");

        // mint the NFTs
        _safeMint(msg.sender, _howMany);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Does not exist");
        return preRevealUri;
    }

    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function cyberItOut(uint256 _howMuch) external onlyOwner {
        payable(owner()).transfer(_howMuch);
    }
}

