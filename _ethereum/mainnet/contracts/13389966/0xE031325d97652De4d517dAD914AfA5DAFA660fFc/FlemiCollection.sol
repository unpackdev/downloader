// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract FlemiCollection is ERC721Enumerable, Ownable {

    IERC721 public EtherCards = IERC721(0x97CA7FE0b0288f5EB85F386FeD876618FB9b8Ab8);    
    IERC721 public MasterBrews = IERC721(0x1EB4C9921C143e9926A2e592B828005A63529dA5);  
    IERC721 public WhelpsNFT = IERC721(0xa8934086a260F8Ece9166296967D18Bd9C8474A5);  


    uint256 public constant price = 50000000000000000; //0.05 ETH
    uint256 public constant maxBuy = 20;
    uint256 public constant maxSupply = 3375;
    uint256 public winId = maxSupply;
    bool public whitelistActive;
    bool public saleIsActive;
    string public provenance;
    string private baseURI_;


    constructor() ERC721("FlemiCollection", "FLEMI") { }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);                
    }

    /*     
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        provenance = provenanceHash;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseURI_ = baseURI;
    }

    function _baseURI() override internal view returns (string memory) {
        return baseURI_;
    }

    /*
    * Set random token ID to win
    */
    function setRandomId() external {
        require(totalSupply() == maxSupply, "Not all minted");
        require(winId == maxSupply, "Already set");
    
        uint randomHash = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        winId = randomHash % maxSupply;
    }

    /*
    * Pause sale if active, make active if paused
    */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /*
    * Pause whitelist if active, make active if paused
    */
    function flipWhitelistState() external onlyOwner {
        whitelistActive = !whitelistActive;
    }

    /*     
    Reserve 30 NFTs for giveaways
    */
    function reserveFlemi() external onlyOwner {
        for(uint i = 0; i < 30; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    /**
    * Mint Flemish Faces
    */
    function mintFlemi(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint");
        require(numberOfTokens <= maxBuy, "Can only mint 20 tokens at once");
        require((totalSupply() + (numberOfTokens)) <= maxSupply, "Purchase exceeds max supply");
        require(price*(numberOfTokens) <= msg.value, "Ether value sent isn't correct");
        
        if(whitelistActive) {
            if(numberOfTokens >= 2 && totalSupply() <= 1000 && (EtherCards.balanceOf(msg.sender) > 0 || MasterBrews.balanceOf(msg.sender) > 0 || WhelpsNFT.balanceOf(msg.sender) > 0)) {
                numberOfTokens=numberOfTokens + numberOfTokens/2;
            }
        }

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();   
            if (totalSupply() < maxSupply) {  
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
}