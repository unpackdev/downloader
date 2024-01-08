// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Tag.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./BAYC.sol";
import "./MAYC.sol";

contract PapiNFT is ERC721, ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private tokenCounter;

    bool public saleStarted;
    string public baseURI;
    uint256 public maxTokenSupply;

    mapping(address => bool) addressClaimed;
    mapping(uint256 => bool) baycClaimed;
    mapping(uint256 => bool) maycClaimed;

    BAYC private immutable bayc;
    MAYC private immutable mayc;

    constructor() ERC721("PAPI", "PAPI") {
        tokenCounter.increment();
        bayc = BAYC(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D); 
        mayc = MAYC(0x60E4d786628Fea6478F785A6d7e704777c86a7c6); 
        maxTokenSupply = 500; 
    }

    modifier whenSaleStarted() {
        require(saleStarted,"Sale not active");
        _;
    }
  
    modifier whenSaleStopped() {
        require(saleStarted==false,"Sale already started");
        _;
    }

    function mint(uint256 numTokens) external whenSaleStarted {

        require(!addressClaimed[msg.sender],"Address already claimed");
        require(totalSupply().add(numTokens) <= maxTokenSupply, "Not enough tokens remaining");
        require(numTokens > 0, "Must request at least 1 token");
        require(numTokens <= 100, "Gas Limit protection");

        uint256 baycBalance = bayc.balanceOf(msg.sender);
        uint256 maycBalance = mayc.balanceOf(msg.sender);

        require(baycBalance > 0 || maycBalance > 0,"Claim requires at least one Bored Ape or Mutant Ape");

        uint256 baycClaimable = 0;
        uint256 maycClaimable = 0;

        uint256[] memory baycTokensId = new uint256[](baycBalance); 

        for(uint256 i; i < baycBalance; i++){

            uint256 tokenNumber = bayc.tokenOfOwnerByIndex(msg.sender, i);

            if(baycClaimed[tokenNumber] == false){
                baycTokensId[baycClaimable] = tokenNumber;
                baycClaimable++;
            }
        }
        
        uint256[] memory maycTokensId = new uint256[](maycBalance);

        for(uint256 i; i < maycBalance; i++){

            uint256 tokenNumber = mayc.tokenOfOwnerByIndex(msg.sender, i);

            if(maycClaimed[tokenNumber] == false){
                maycTokensId[maycClaimable] = tokenNumber;
                maycClaimable++;
            }
        }

        require(baycClaimable > 0 || maycClaimable > 0,"Tokens for BAYC and MAYC already claimed");
        require(numTokens <= (baycClaimable.add(maycClaimable)).mul(2), "Max 2 tickets per token");

        for (uint256 i; i < numTokens; i++) {
            _safeMint(msg.sender, tokenCounter.current());
            tokenCounter.increment();
        }

        addressClaimed[msg.sender] = true;

        for (uint256 i; i < baycClaimable; i++) {
            baycClaimed[baycTokensId[i]] = true;    
        }

        for (uint256 i; i < maycClaimable; i++) {
            maycClaimed[maycTokensId[i]] = true;    
        }
    }

    function reserveTokens(address _to, uint256 numTokens) external onlyOwner {
        require(numTokens > 0, "Must request at least 1 token");
        require(numTokens <= 100, "Gas Limit protection");
        require(totalSupply().add(numTokens) <= maxTokenSupply, "Not enough tokens remaining");
        for (uint256 i; i < numTokens; i++) {
            _safeMint( _to, tokenCounter.current());
            tokenCounter.increment();
        }
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }
        
    function startSale() external whenSaleStopped onlyOwner {
        saleStarted = true;
    }
  
    function stopSale() external whenSaleStarted onlyOwner {
        saleStarted = false;
    }

    function tokensInWallet(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
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
