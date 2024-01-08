// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import "./console.sol";
import "./ERC721.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Cyberlands is ERC721, Ownable {
    using SafeMath for uint256;
    uint public constant MAX_LANDS = 2042;
    uint256 public constant cyberlandPrice = 50000000000000000; //0.05 ETH
    uint public constant maxCyberlandPurchase = 20;
    bool public hasSaleStarted = false;
    
    string public METADATA_PROVENANCE_HASH = "";
    
    
    constructor() ERC721("Cyberlands of Polygonia","LANDS") public {
        _setBaseURI("https://api.cyberlands.co/");
        
        // Merwane
        _safeMint(address(0xa4722f1b4B552951828e6A334C5724b34B19A327), 0);
        _safeMint(address(0xa4722f1b4B552951828e6A334C5724b34B19A327), 1);
        _safeMint(address(0xa4722f1b4B552951828e6A334C5724b34B19A327), 2);

        // Rosco
        _safeMint(address(0xe126b3E5d052f1F575828f61fEBA4f4f2603652a), 3);
        _safeMint(address(0xe126b3E5d052f1F575828f61fEBA4f4f2603652a), 4);
        _safeMint(address(0xe126b3E5d052f1F575828f61fEBA4f4f2603652a), 5);

        // Suhail
        _safeMint(address(0xd19f4630136d2CE20aC33f230Cc947Ed688E951C), 6);
        _safeMint(address(0xd19f4630136d2CE20aC33f230Cc947Ed688E951C), 7);
        _safeMint(address(0xd19f4630136d2CE20aC33f230Cc947Ed688E951C), 8);
        
    }
   
    

    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    
   function conquerCyberland(uint256 numLands) public payable {
        require(totalSupply() < MAX_LANDS, "Sale has already ended");
        require(numLands > 0 && numLands <= maxCyberlandPurchase, "Maximum of 20 cyberlands per call");
        require(totalSupply().add(numLands) <= MAX_LANDS, "Exceeds MAX_LANDS");
        require(cyberlandPrice.mul(numLands) <= msg.value, "Ether value sent is below the price");

        for (uint i = 0; i < numLands; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }

    }
    
    // ONLYOWNER FUNCTIONS
    
    function setProvenanceHash(string memory _hash) public onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }
    
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }
    
    function startDrop() public onlyOwner {
        hasSaleStarted = true;
    }
    function pauseDrop() public onlyOwner {
        hasSaleStarted = false;
    }
    
    
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
    


}
