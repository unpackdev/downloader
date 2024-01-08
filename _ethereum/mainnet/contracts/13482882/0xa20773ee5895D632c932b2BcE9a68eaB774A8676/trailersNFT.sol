// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
// import "./Counters.sol";

contract trailersNFT is Ownable, ERC721{

    using SafeMath for uint256;
    
     // address private mainContract = "";
    
    bool public isURIFrozen = true;
    
    string public baseURI = "https://";
    
    uint256 public MAX_SUPPLY = 8500;
    
    uint256 constant public MINT_PRICE = 0.07 ether;
    
    bool public mintIsActive = false;
    
    uint256 public MAX_MINT = 10;
    
    uint256 private LOT_NO = 85;
    
    uint256 private VERIFIER;
    
    uint256 private lotSize = 100;
    
    uint256 public totalSupply = 0;
    
    mapping(uint256 => uint256) private lotTracker;
    
    uint256[] private mintableTokens;
    
    uint256[] private minted;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {
        for(uint i = 0; i < LOT_NO; i++) {
           mintableTokens.push(i*lotSize);
        }
    }

    function _baseURI() internal view override returns (string memory)  {
        return baseURI;
    }
    
    function toggleURI() external onlyOwner {
        isURIFrozen = !isURIFrozen;
    }
    
    function setBaseURI(string calldata newURI) external onlyOwner {
        require(!isURIFrozen, "URI is Frozen");
        baseURI = newURI;
    }
    
    function setVerifier( uint256 verifier) external onlyOwner {
        VERIFIER = verifier;
    }
    
    function reserveTrailers() public onlyOwner {        
        for (uint i = 0; i < 30; i++) {
            uint256 lot = (1634500097242 * (i+1)) % mintableTokens.length;
            
               lotTracker[lot] += 1; 
               uint256 mintID = mintableTokens[lot]+lotTracker[lot];
               minted.push(mintID);
               _safeMint(msg.sender, mintID);
               totalSupply++;
              
            
            if(lotTracker[lot] >= lotSize){
                mintableTokens[lot] = mintableTokens[mintableTokens.length - 1];
                lotTracker[lot] = lotTracker[mintableTokens.length - 1];
                mintableTokens.pop();
            }
        }
    }
    
    function mintTrailer(uint256 randomiser, uint256 tokenQuantity, uint256 verifier) external payable {
        
        require(totalSupply < MAX_SUPPLY, "Sold Out");
        require(mintIsActive, "Minting has not commenced or has ended");
        require(totalSupply + tokenQuantity <= MAX_SUPPLY, "Requested Quantity Less than Available");
        require(tokenQuantity <= MAX_MINT, "You can only mint 20");
        require(VERIFIER == verifier, "Illegal Mint Action");
        require(MINT_PRICE * tokenQuantity <= msg.value, "Insufficient Funds");
        
        
        for(uint i = 0; i < tokenQuantity; i++) {
            uint256 lot = (randomiser * (i+1)) % mintableTokens.length;
            
                lotTracker[lot] += 1; 
                uint256 mintID = mintableTokens[lot]+lotTracker[lot];
                minted.push(mintID);
               _safeMint(msg.sender, mintID);
               totalSupply++;
            
            if(lotTracker[lot] >= lotSize){
                mintableTokens[lot] = mintableTokens[mintableTokens.length - 1];
                lotTracker[lot] = lotTracker[mintableTokens.length - 1];
                mintableTokens.pop();
            }
        }
      
    }
    
    function burn(uint256 _tokenId) public {
        require(!mintIsActive, "Ongoing Sale");
        require(_exists(_tokenId), "Token Does Not Exist");
        require(msg.sender == ownerOf(_tokenId), "Not Owner");
        totalSupply -= 1;
        _burn(_tokenId);
    }
    
    function toggleMint() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function withdrawAll(address treasury) external payable onlyOwner {
        require(payable(treasury).send(address(this).balance));
    }
}

