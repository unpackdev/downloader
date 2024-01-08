// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";

                                                                                                                               
//                                                                                                                               
//█████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████  
//                                                                                                                               
//                                                                                                                               
//                                                                                                                               
//                                                                                                                               
//███████ ██      ███████ ███████ ██████  ██      ███████ ███████ ███████     ███    ██ ██  ██████  ██   ██ ████████ ███████     
//██      ██      ██      ██      ██   ██ ██      ██      ██      ██          ████   ██ ██ ██       ██   ██    ██    ██          
//███████ ██      █████   █████   ██████  ██      █████   ███████ ███████     ██ ██  ██ ██ ██   ███ ███████    ██    ███████     
//     ██ ██      ██      ██      ██      ██      ██           ██      ██     ██  ██ ██ ██ ██    ██ ██   ██    ██         ██     
//███████ ███████ ███████ ███████ ██      ███████ ███████ ███████ ███████     ██   ████ ██  ██████  ██   ██    ██    ███████     
//                                                                                                                               
//                                                                                                                               
//                                                                                                                               
//                                                                                                                               
//█████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████ █████  
                                                                                                                               
     

contract SleeplessNightsNFT is ERC721Enumerable, Ownable, Pausable {
    using SafeMath for uint256;
    
    uint public constant NFT_PRICE = 30000000000000000; // 0.03 ETH
    uint public constant MAX_NFT_PURCHASE = 5;
    uint public MAX_SUPPLY = 10000;
    uint public ACTUAL_SUPPLY = 1700;
    string private base;
    
    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        setBaseURI(baseURI);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        base = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return base;
    }
    
    function setMaxTokenSupply(uint256 newSupply) public onlyOwner {
        require(newSupply <= MAX_SUPPLY, "Max supply reached");
        ACTUAL_SUPPLY = newSupply;
    }

    function mint(uint numberOfTokensMax5) public payable whenNotPaused {
        require(numberOfTokensMax5 > 0, "Number of tokens can not be less than or equal to 0");
        require(totalSupply().add(numberOfTokensMax5) <= ACTUAL_SUPPLY, "Purchase would exceed max supply");
        require(numberOfTokensMax5 <= MAX_NFT_PURCHASE,"Can only mint up to 10 per purchase");
        require(NFT_PRICE.mul(numberOfTokensMax5) == msg.value, "Sent ether value is incorrect");

        for (uint i = 0; i < numberOfTokensMax5; i++) {
             uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function magicMint(uint256 numTokens) external  onlyOwner {
        require(SafeMath.add(totalSupply(), numTokens) <= ACTUAL_SUPPLY, "Exceeds maximum token supply.");
        require(numTokens > 0 && numTokens <= 100, "Machine can dispense a minimum of 1, maximum of 100 tokens");

        for (uint i = 0; i < numTokens; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }
}