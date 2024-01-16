
/*


                                                                                           


                                                                                                                                                             


                                                                                                                                                                                            
                                                                                                                                                                                            
PPPPPPPPPPPPPPPPP        AAA               NNNNNNNN        NNNNNNNN     PPPPPPPPPPPPPPPPP        AAA               NNNNNNNN        NNNNNNNNDDDDDDDDDDDDD                  AAA               
P::::::::::::::::P      A:::A              N:::::::N       N::::::N     P::::::::::::::::P      A:::A              N:::::::N       N::::::ND::::::::::::DDD              A:::A              
P::::::PPPPPP:::::P    A:::::A             N::::::::N      N::::::N     P::::::PPPPPP:::::P    A:::::A             N::::::::N      N::::::ND:::::::::::::::DD           A:::::A             
PP:::::P     P:::::P  A:::::::A            N:::::::::N     N::::::N     PP:::::P     P:::::P  A:::::::A            N:::::::::N     N::::::NDDD:::::DDDDD:::::D         A:::::::A            
  P::::P     P:::::P A:::::::::A           N::::::::::N    N::::::N       P::::P     P:::::P A:::::::::A           N::::::::::N    N::::::N  D:::::D    D:::::D       A:::::::::A           
  P::::P     P:::::PA:::::A:::::A          N:::::::::::N   N::::::N       P::::P     P:::::PA:::::A:::::A          N:::::::::::N   N::::::N  D:::::D     D:::::D     A:::::A:::::A          
  P::::PPPPPP:::::PA:::::A A:::::A         N:::::::N::::N  N::::::N       P::::PPPPPP:::::PA:::::A A:::::A         N:::::::N::::N  N::::::N  D:::::D     D:::::D    A:::::A A:::::A         
  P:::::::::::::PPA:::::A   A:::::A        N::::::N N::::N N::::::N       P:::::::::::::PPA:::::A   A:::::A        N::::::N N::::N N::::::N  D:::::D     D:::::D   A:::::A   A:::::A        
  P::::PPPPPPPPP A:::::A     A:::::A       N::::::N  N::::N:::::::N       P::::PPPPPPPPP A:::::A     A:::::A       N::::::N  N::::N:::::::N  D:::::D     D:::::D  A:::::A     A:::::A       
  P::::P        A:::::AAAAAAAAA:::::A      N::::::N   N:::::::::::N       P::::P        A:::::AAAAAAAAA:::::A      N::::::N   N:::::::::::N  D:::::D     D:::::D A:::::AAAAAAAAA:::::A      
  P::::P       A:::::::::::::::::::::A     N::::::N    N::::::::::N       P::::P       A:::::::::::::::::::::A     N::::::N    N::::::::::N  D:::::D     D:::::DA:::::::::::::::::::::A     
  P::::P      A:::::AAAAAAAAAAAAA:::::A    N::::::N     N:::::::::N       P::::P      A:::::AAAAAAAAAAAAA:::::A    N::::::N     N:::::::::N  D:::::D    D:::::DA:::::AAAAAAAAAAAAA:::::A    
PP::::::PP   A:::::A             A:::::A   N::::::N      N::::::::N     PP::::::PP   A:::::A             A:::::A   N::::::N      N::::::::NDDD:::::DDDDD:::::DA:::::A             A:::::A   
P::::::::P  A:::::A               A:::::A  N::::::N       N:::::::N     P::::::::P  A:::::A               A:::::A  N::::::N       N:::::::ND:::::::::::::::DDA:::::A               A:::::A  
P::::::::P A:::::A                 A:::::A N::::::N        N::::::N     P::::::::P A:::::A                 A:::::A N::::::N        N::::::ND::::::::::::DDD A:::::A                 A:::::A 
PPPPPPPPPPAAAAAAA                   AAAAAAANNNNNNNN         NNNNNNN     PPPPPPPPPPAAAAAAA                   AAAAAAANNNNNNNN         NNNNNNNDDDDDDDDDDDDD   AAAAAAA                   AAAAAAA
                                                                                                                                                                                            
                                                                                                                                                                                            
                                                                                                                                                                                            
                                                                                                                                                                                            
                                                                                                                                                                                            
                                                                                                                                                                                            
                                                                                                                                                                                            
                                                                                                                                                             
                                                                                                                                                             


                                                                                                                                                                              

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./Base64.sol";
import "./ERC721A.sol";


contract PANPANDA is ERC721A, Ownable {
    enum SaleStatus{ PAUSED, PRESALE, PUBLIC }

    uint public constant COLLECTION_SIZE = 5000;
    uint public constant FIRSTXFREE = 1;
    uint public constant TOKENS_PER_TRAN_LIMIT = 100;
    uint public constant TOKENS_PER_PERSON_PUB_LIMIT = 1000;
    
    
    uint public MINT_PRICE = 0.005 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    
    string private _baseURL = "ipfs://bafybeifpfaoo6tcbltidpqtr6ahzoorpdiuptkhuhrvkcmmkzab3oqqv4a";
    
    mapping(address => uint) private _mintedCount;
    

    constructor() ERC721A("PAN PANDA", "PAN PANDA"){}
    
    
    
    
    
    
    /// @notice Set base metadata URL
    function setBaseURL(string calldata url) external onlyOwner {
        _baseURL = url;
    }

    /// @dev override base uri. It will be combined with token ID
    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice Update current sale stage
    function setSaleStatus(SaleStatus status) external onlyOwner {
        saleStatus = status;
    }

    /// @notice Update public mint price
    function setPublicMintPrice(uint price) external onlyOwner {
        MINT_PRICE = price;
    }

    /// @notice Withdraw contract balance
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No balance");
        payable(owner()).transfer(balance);
    }

    /// @notice Allows owner to mint tokens to a specified address
    function airdrop(address to, uint count) external onlyOwner {
        require(_totalMinted() + count <= COLLECTION_SIZE, "Request exceeds collection size");
        _safeMint(to, count);
    }

    /// @notice Get token URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI, "/", _toString(tokenId), ".json")) 
            : "";
    }
    
    function calcTotal(uint count) public view returns(uint) {
        require(saleStatus != SaleStatus.PAUSED, "SpaceCatsClub: Sales are off");

        
        require(msg.sender != address(0));
        uint totalMintedCount = _mintedCount[msg.sender];

        if(FIRSTXFREE > totalMintedCount) {
            uint freeLeft = FIRSTXFREE - totalMintedCount;
            if(count > freeLeft) {
                // just pay the difference
                count -= freeLeft;
            }
            else {
                count = 0;
            }
        }

        
        uint price = MINT_PRICE;

        return count * price;
    }
    
    
    
    /// @notice Mints specified amount of tokens
    /// @param count How many tokens to mint
    function mint(uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED, "SpaceCatsClub: Sales are off");
        require(_totalMinted() + count <= COLLECTION_SIZE, "SpaceCatsClub: Number of requested tokens will exceed collection size");
        require(count <= TOKENS_PER_TRAN_LIMIT, "SpaceCatsClub: Number of requested tokens exceeds allowance (100)");
        require(_mintedCount[msg.sender] + count <= TOKENS_PER_PERSON_PUB_LIMIT, "SpaceCatsClub: Number of requested tokens exceeds allowance (1000)");
        require(msg.value >= calcTotal(count), "SpaceCatsClub: Ether value sent is not sufficient");
        _mintedCount[msg.sender] += count;
        _safeMint(msg.sender, count);
    }
}
