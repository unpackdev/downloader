/*
*                                                                                                                                                                                                                                                                           
*                     ##    ##  #######                            
*                      ##  ##  ##     ##                           
*                       ####   ##     ##                           
*                        ##    ##     ##                           
*                        ##    ##     ##                           
*                        ##    ##     ##                           
*                        ##     #######                            
*   ##    ## #### ######## ######## #### ########  ######          
*   ##   ##   ##     ##       ##     ##  ##       ##    ##         
*   ##  ##    ##     ##       ##     ##  ##       ##               
*   #####     ##     ##       ##     ##  ######    ######          
*   ##  ##    ##     ##       ##     ##  ##             ##         
*   ##   ##   ##     ##       ##     ##  ##       ##    ##         
*   ##    ## ####    ##       ##    #### ########  ######          
*
*         Feline frens joining the Dastardly Ducks
*             smol farm x Iron Chef Cat Cora
*            Contract by: existentialenso.eth                                                                                                                               
*/
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract YONEKO is ERC721A, Ownable, Pausable {
    uint256 public mintPrice = 0.015 ether;
    uint256 public constant maxTokens = 5000;

    string public constant baseURI = "ipfs://QmPEdkX3maugP74zD1BLBNgP8DDkU6Kp6rosaPSCguY11k/";

    constructor() ERC721A("Yo Kitties", "YONEKO") {
        _pause();
    }

    function mintCats(uint256 qty) public payable whenNotPaused {
        require(qty <= 25, 'MAX_QTY_EXCEEDED');
        unchecked { require(mintPrice * qty <= msg.value, 'LOW_ETHER'); }
        unchecked { require(totalSupply() + qty <= maxTokens, 'MAX_REACHED'); }
        _safeMint(msg.sender, qty);
    }

    // Mint the first 60 ducks to smol farm-held wallets
    function promoMint() public onlyOwner {
        unchecked { require(totalSupply() == 0, 'PROMO_ALREADY_RUN'); }

        _safeMint(0x8aa986eB2F0D3b5001C9C2093698A4e13d646D5b, 10);
        _safeMint(0x8f4612e9aAB90eaD61A1637436BCb9FD0b606652, 10);
        _safeMint(0x72CAa8687E5C63f8bA2a271212556dA5eD58f0b0, 40);

        _unpause();
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _baseURI() internal pure override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}