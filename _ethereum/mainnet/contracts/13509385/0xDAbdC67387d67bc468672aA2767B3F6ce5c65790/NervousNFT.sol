pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Counters.sol";
import "./SignatureChecker.sol";

//
//  ▄▄▄▄▄▄▄▄▄▄▄  ▄         ▄                                        
// ▐░░░░░░░░░░░▌▐░▌       ▐░▌                                       
// ▐░█▀▀▀▀▀▀▀█░▌▐░▌       ▐░▌                                       
// ▐░▌       ▐░▌▐░▌       ▐░▌                                       
// ▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄█░▌                                       
// ▐░▌       ▐░▌▐░░░░░░░░░░░▌                                       
// ▐░▌       ▐░▌▐░█▀▀▀▀▀▀▀█░▌                                       
// ▐░▌       ▐░▌▐░▌       ▐░▌                                       
// ▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌                                       
// ▐░░░░░░░░░░░▌▐░▌       ▐░▌                                       
//  ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀                                        
//                                                                 
//  ▄▄       ▄▄  ▄         ▄                                        
// ▐░░▌     ▐░░▌▐░▌       ▐░▌                                       
// ▐░▌░▌   ▐░▐░▌▐░▌       ▐░▌                                       
// ▐░▌▐░▌ ▐░▌▐░▌▐░▌       ▐░▌                                       
// ▐░▌ ▐░▐░▌ ▐░▌▐░█▄▄▄▄▄▄▄█░▌                                       
// ▐░▌  ▐░▌  ▐░▌▐░░░░░░░░░░░▌                                       
// ▐░▌   ▀   ▐░▌ ▀▀▀▀█░█▀▀▀▀                                        
// ▐░▌       ▐░▌     ▐░▌                                            
// ▐░▌       ▐░▌     ▐░▌                                            
// ▐░▌       ▐░▌     ▐░▌                                            
//  ▀         ▀       ▀                                             
//                                                                 
//  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄         ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄  
// ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░▌ 
// ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░▌       ▐░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌
// ▐░▌          ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌
// ▐░▌ ▄▄▄▄▄▄▄▄ ▐░▌       ▐░▌▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌
// ▐░▌▐░░░░░░░░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌
// ▐░▌ ▀▀▀▀▀▀█░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░█▀▀▀▀█░█▀▀ ▐░▌       ▐░▌
// ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌     ▐░▌  ▐░▌       ▐░▌
// ▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░▌      ▐░▌ ▐░█▄▄▄▄▄▄▄█░▌
// ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░▌ 
//  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀  ▀▀▀▀▀▀▀▀▀▀  
//
// by nervous.eth // work with us // dylan@nervous.net                                                                 

contract NervousNFT is ERC721, ERC721Enumerable, PaymentSplitter, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public MAX_TOKENS = 3000;
    bool public hasSaleStarted = false;
    string public baseURI;

    uint256 public tokenPrice = 0;

    uint256 public MAX_GIFTS = 2000;
    uint256 public numberOfGifts;

    uint256 public MAX_MINTS = 1;
    mapping(address => uint256) private OMGMints;

    

    string public constant R =
        "We are Nervous. Are you? Let us help you with your next NFT Project -> dylan@nervous.net";

    constructor(
        string memory name,
        string memory symbol,
        string memory _initBaseURI,
        uint256 _maxTokens,
        uint256 _maxGifts,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721(name, symbol) PaymentSplitter(payees, shares) {
        MAX_TOKENS = _maxTokens;
        MAX_GIFTS = _maxGifts;
        setBaseURI(_initBaseURI);
    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

     function calculatePrice() public view returns (uint256) {
        return tokenPrice; // 0.1 ETH
    }


    function mint(uint256 numTokens) public payable {
        require(hasSaleStarted == true, "Sale hasn't started");
        require(
            _tokenIds.current() + numTokens <= MAX_TOKENS,
            "Exceeds maximum token supply."
        );
        require(
            numTokens > 0 && numTokens <= 10,
            "Machine can dispense a minimum of 1, maximum of 10 tokens"
        );
  
             require(
            OMGMints[msg.sender] + numTokens  <= MAX_MINTS,
            "Exceeds maximum gourds."
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
            OMGMints[msg.sender] = OMGMints[msg.sender] + 1;
        }
    }

    /* Magic */

    function magicGift(address[] calldata receivers) external onlyOwner {
        require(
            _tokenIds.current() + receivers.length <= MAX_TOKENS,
            "Exceeds maximum token supply"
        );
        require(
            numberOfGifts + receivers.length <= MAX_GIFTS,
            "Exceeds maximum allowed gifts"
        );

        for (uint256 i = 0; i < receivers.length; i++) {
            numberOfGifts++;

            _safeMint(receivers[i], _tokenIds.current());
            _tokenIds.increment();
        }
    }

    function magicMint(uint256 numTokens) external onlyOwner {
        require(
            _tokenIds.current() + numTokens <= MAX_TOKENS,
            "Exceeds maximum token supply."
        );
        require(
            numTokens > 0 && numTokens <= 100,
            "Machine can dispense a minimum of 1, maximum of 100 tokens"
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
        }
    }

    /* URIs */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
