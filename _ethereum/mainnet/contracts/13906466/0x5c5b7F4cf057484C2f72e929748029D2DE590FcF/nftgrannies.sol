// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract NFTGrannies is ERC721, ERC721Enumerable, Ownable {
    
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    string public constant PROVENANCE_HASH = "dbeac68106c396e9ffe91d8e21c943c813320b2de3977b7569beb5e61c49d3bd";
    uint256 public constant MAX_TOKENS = 10000;
    uint256 public constant MAX_TOKENS_PER_PURCHASE = 20;
    
    string public baseURI = "https://ipfs.io/ipfs/QmSY6x7k5DwtHf5ZGP3wHn2pvm1LqUm4YVH8xrxSr1jD4L/";
    uint256 public basePrice = 15000000000000000; // (wei) = 0.015 Ether
    bool public isSaleActive = false;
    
    mapping(uint256 => bool) private cashedOutTokens;



    //////////////////////////////////////////////////////////////////////////////////
    //  CONSTRUCTOR                                                                 //
    //////////////////////////////////////////////////////////////////////////////////
    
    constructor() ERC721("NFT Grannies", "GRANNY") {}
    
    

    //////////////////////////////////////////////////////////////////////////////////
    //  EXTERNAL                                                                    //
    //////////////////////////////////////////////////////////////////////////////////
    
    // Show amount of tokens hold by a specific owner
    function tokensByOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
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



    //////////////////////////////////////////////////////////////////////////////////
    //  PUBLIC                                                                      //
    //////////////////////////////////////////////////////////////////////////////////
    
    // --- PUBLIC - ALL - CHARGEABLE -----------------------------------------------//
    
    // Minting tokens with minting fee and gas fee
    function mint(uint256 _amount) public payable {
        
        uint256 price = getExactPrice(_amount);
        
        require(isSaleActive, "Error: Sale is not active" );
        require(_tokenIdCounter.current() + _amount < MAX_TOKENS + 1, "Error: Entered amount exceeds maximum of available tokens");
        require(msg.value >= price, "Error: Not enough Ether sent");

        for(uint256 i = 0; i < _amount; i++){
            _safeMint(msg.sender, _tokenIdCounter.current() + 1);
            _tokenIdCounter.increment();
        }
    }
    
    
    // --- PUBLIC - ALL - FREE -----------------------------------------------------//
    
    // Returns price for a specific amount of tokens
    function getExactPrice(uint256 _amount) public view returns (uint256) {
        uint256 exactPrice;
        
        if (_amount >= 1 && _amount < 10) {
            // 1 to 9 tokens 
            exactPrice = basePrice * _amount;
        } else if (_amount >= 10 && _amount < 20) {
            // 10 to 19 tokens -> 50% discount
            exactPrice = (basePrice / 2) * _amount;
        } else if (_amount >= 20 && _amount <= MAX_TOKENS_PER_PURCHASE) {
            // 20 tokens -> 60% discount
            exactPrice = ((basePrice / 10) * 4) * _amount;
        } else {
            require(false, "Error: Invalid amount of tokens" );
        }

        return exactPrice;
    }
    
    
    // Have all tokens been minted?
    function areAllMinted() public view returns (bool) {
        return _tokenIdCounter.current() >= MAX_TOKENS ? true : false;
    }
    
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    
    // --- PUBLIC - ONLY OWNER - CHARGEABLE ----------------------------------------//
    
    // Update base URI to API that contains metadata
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
    
    // Set basePrice for minting one new token
    function setBasePrice(uint256 _newBasePrice) public onlyOwner {
        basePrice = _newBasePrice;
    }
    
    
    // Allow or denie public minting
    function toggleSaleStatus() public onlyOwner {
        isSaleActive = !isSaleActive;
    }
    

    // Minting tokens without minting fee (gas fee still applies)
    function mintNoFee(address _to, uint256 _amount) public onlyOwner {
        require(_tokenIdCounter.current() + _amount < MAX_TOKENS + 1, "Error: Entered amount exceeds maximum of available tokens");

        for(uint256 i = 0; i < _amount; i++) {
            _safeMint(_to, _tokenIdCounter.current() + 1);
            _tokenIdCounter.increment();
        }
    }
    
    
    // Send 1 ETH to owner of token with specific id
    function cashOut(uint256 _tokenId) public onlyOwner {
        
        // Check if enough ETH available
        require(address(this).balance > 1 ether, "Error: Not enough ETH available");
        
        // Check if all tokens are minted
        require(areAllMinted(), "Error: There are still tokens to mint");
        
        // Check if cashout for this token already took place
        require(cashedOutTokens[_tokenId] == false, "Error: Already cashed out");
        
        // Get owners address
        address tokenOwner = ownerOf(_tokenId);
        
        // Send 1 ETH to token owner
        payable(tokenOwner).transfer(1 ether);
        
        // Add token id to mapping of cashed out tokens
        cashedOutTokens[_tokenId] = true;
    }
    
    
    // Sends all funds to contract owner
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Error: Balance is 0");
        payable(owner()).transfer(address(this).balance);
    }
    


    //////////////////////////////////////////////////////////////////////////////////
    //  INTERNAL                                                                    //
    //////////////////////////////////////////////////////////////////////////////////
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


}