//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC721A.sol";
                                                                                        
//                      ....                                                               
//                     ~J??7?YJ77:                                                         
//                     ~?!J557.   .:^~^~!!~:.                                              
//                     ^?PY^   .~~::^:~55?~~7!^.                                           
//                     !7:   ^5#Y!~~7^!PP57~!~!!!!7^                                       
//                     ~   ~G5?7::^!7J:7J7!~~~~~!!!J!                                      
//                       :JJ5!::~~~^^!~~~~~!!!!!!!!Y~                                      
//                      :P#!7~^?!~!!~~~!!!!!!!!!!77J~.                                     
//                     .?7!!~77!!7~~!!!!!!!!!7?J5Y?5BG?!5GP~                               
//                      ^7~~?~?7~~!!!!7!!!7J55GBBY7J5PBBBB##7                              
//                      :~!!^7^J7!!!!!!7JYY5GGPYPB&&@#PYYY5G&Y                             
//                      ..~^!^J!!!!!!7Y5G#B?J5JJ&@@@7?G#&&#B5&&!                           
//                        ~~~J!!!!~7J5?JGY5#&B5PB#@&J@@@@@@@&&@@B:                         
//                         7?!77!~JYP#5?5&@@&@@#PPG#&&&&&&&&&&BBBP!~                       
//                          .:^^~Y?5#JY&@@#P5P&@@BPPB&@&#55Y?7!!!!7.                       
//                              ~Y???G@@B&#YY5PGP&@GYJ5Y?^~!!!!!7?~:..                     
//                              :#P?#@&P5!Y#G?: ~B#P?7!!!!!!7JY55PPP55YJYYY                
//                              5B?&@GPP7JJ7#?!GB7!!!!!!7JY5PP55YYY555PGBBB^               
//                              JJ~###PJP5J&&&GY7~!!!7J5PPP5Y?JJY555PBBBBBGJ               
//                               .!GPJP&5B@&BJ!!!!!?YPPP5YJ7?5PPPPP5Y5P555GB.              
//                             ^G&#G5!.&@@#Y!!!!!?5PPP5J77?5PP5555YJ5555PYG#J              
//                          .JB&&P7.   !&G?!!!!75PP5Y7!?JY?7YJJJJYJPPPPP5YJPP              
//                        !G##P7.       ~?~!!~JPP5Y77JYYYY7?YYYYYY?7YYYJJ5PPP^             
//                     ^5##P7:          !.  .YPPY?77YYYYJ!?YYYYYY?7JYYYYJ5Y7~.             
//                  .JB#G?:                  55J??!?YYJ77!?JYJ??77YYYY7~.                  
//                !G#BJ^                    .Y77!7??7!77??7~!77??777^     .:~!             
//             :5#BY^                       :77!????~7?????~????7^    .~JPGJJP             
//          .7GBY^                           ~~~??7!~!7?7!~~7?7:   .!?J5GY?7!?.            
//        ~PB5~                                 ..:~!!!~~!77!.   .?PGP?!~~!7?J:            
//  .:^.^P5~.                                         ..:^~~    !55GY~^!??????^            
// ~Y5J!^.                                                     ^Y!?7^7J???????~            
// :77?!                                                            .:^~!77??J7            
//                                                                         ..:^                                                                                  
contract Umiverse is ERC721A, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for string;

    uint256 public constant tokenPrice = 0.05 ether;
    uint256 public constant purchaseLimit = 20;
    uint256 public constant maxSupply = 1000;

    bool public saleIsActive = false;
    bool public revealed = false;
    string public provenanceHash = '';

    string private _baseTokenURI;
    string public preRevealUri;

    constructor() ERC721A("Umiverse", "UMI") {}

    function mintNFT(uint256 numberOfTokens) external payable whenSaleIsActive {
        require(
            tx.origin == msg.sender,
            "Transaction from another contract not allowed"
        );
        require(
            numberOfTokens <= purchaseLimit,
            "Number of tokens exceeds purchase limit"
        );
        require(
            totalSupply().add(numberOfTokens) <= maxSupply,
            "Not enough tokens to complete transaction"
        );
        require(
            tokenPrice.mul(numberOfTokens) <= msg.value,
            "Insufficient amount sent"
        );

        _safeMint(msg.sender, numberOfTokens);
    }

    modifier whenSaleIsActive() {
        require(saleIsActive);
        _;
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenanceHash = _provenanceHash;
    }

    function setPreRevealURI(string memory _preRevealUri) public onlyOwner {
        preRevealUri = _preRevealUri;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        _baseTokenURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return preRevealUri;
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return
            bytes(_tokenURI).length > 0
                ? string(abi.encodePacked(_tokenURI, ".json"))
                : "";
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
