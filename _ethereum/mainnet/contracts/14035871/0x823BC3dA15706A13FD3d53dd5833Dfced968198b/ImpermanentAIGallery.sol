// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Counters.sol";

/*
                                                                                                                                                                                                   @*   
                                 @@@@@                                                                                                                                                         /@@@@@@@@
               @@               @@@@@@@                                                                    .@@@@@@@@@@@                                                 @@@@@@@@@@             @@@@@@@@@
     @@@@@@@@@ @@@@             @@@@@@@   @@@@@                      @@@@@@@@@@@@@@@@@@&    @@@    @@@@  @@@@@@*     @@@,        @@@@      @@@@@                       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@ .@@@@           @@@@@ ,@@@@@@@@@@@@@@@                @@@@@@@@@,@@   @@@@  @@@@   @@@@@              @@@@       @@@@@    @@@@@@@                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
    @@@@@@@@@@@    @@@@       @@@@@  (@@@@@(     @@@@@@                 @@@@@@@@      @@@% @@@@@ @@@ @@    @@@@@@@@@@@@@@       @@@@@@   @@@@@@                          @@@@@@@     @@@@@@@      @#    
     @@@@@@@        @@@@@@@@@@@@@@@   @@@@@@    %@@@@@@                  @@@@@@@@@@   @@@& @@@@@@@@  @@   .@@@@  @@@@@ @        @@@@@@  @@@@@                                        @@@@@              
       @@@@         @@@    @@@ @@@@    @@@@@@@@@@@@        @@@@@*        @@@@@ /@@@@ @@@@( @@ @@@@    @    @@@@ ,@@@@ ,@        @@ @@@@@@@  @@@@@@@@@@@@@@@      @@@@     &@@@@@@@   #@@@.              
        @@@,        @@@     @@ @@@(    @@@@      @@@@@@@@@@@@@@@@@@.    @@@@@@@  @@@@@@@   @. @@@@     @     @@@@@@   @@@@@@@@  @@ @@@@@@   @@@@@@    @@@@       @@@@@@@@@@@@@@@@@@  &@@@               
        @@@@      @@@@@@       @@@@    @@@@    @@@@@@@@@@@@@@@@@@@@  @@@@@@  @@@@         @@           @@@@*           @@@@@@   @@ .@@@@@,  @@@@@                @@@@@@@@@@@    @@@&  @@@@              
       @@@@@   @@@@@@@@@         @@@@  @@@@      @@@@@@               @@@@@  @@@@      /@@@@            @@@@@@@                ,@@  @@@@@    @@@@@@@              @@@@@@@   @@@@@@@   @@@@@             
      #@@@@    @@@@@@@@           @@@@  @@@       @@@@@    .#@@@@@@@@@       @@@@     @@@@@              %@@@@@                @@@          @@@@@@@@@@@@@@@        @@@@@@   @@@@@@   @@@@@@@@@@         
  @@@@@@@@@@                           @@@@@@     @@@@@@@@@@@@@@@@@@@@      @@@@@@@@%                                        @@@@,          &@@@                  @@@@@      @@@&   @@@@@@@@@@@@@       
 @@@@@@@@@@@@                       @@@@@@@@@@     @@@@@(  &@               @@@@@@@@@@@                                   @@@@@@@          @@@@@                 @@@@@      @@@@    #@@@@@@@@@@@@       
 @@@@@@@@@@@@                      @@@@@@@@@@@@    @@@@@ ,@@@@                @@@@@@@@@                                   @@@@@          @@@@@@@@@@@@@@@@@@@@@   @@@@@@     @@@@@@     @@@@@@@          
    @@@@@@                          %@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@                                                                   (@@@@@     .@@@@@@@@   @@@@@@     @@@@@@                      
                                       .@@@@       @@@@@@                                                                                                         @@@@@      @@@@@                      

*/

contract ImpermanentAIGallery is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 public maxTokenSupply;

    uint256 public mintPrice = 0.01 ether;

    bool public mintingIsActive = false;

    bool public isLocked = false;
    string public baseURI;
    string public provenance;

    event MintedToken(uint256 tokenId, string id);
    event EvolvedToken(uint256 tokenId, string id);

    constructor(string memory name, string memory symbol, uint256 maxSupply) ERC721(name, symbol) {
        maxTokenSupply = maxSupply;
    }

    function setMaxTokenSupply(uint256 maxSupply) public onlyOwner {
        maxTokenSupply = maxSupply;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function withdraw(uint256 amount) public onlyOwner {
        Address.sendValue(payable(msg.sender), amount);
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount, address mintAddress) public onlyOwner {        
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _tokenIdCounter.increment();
            _safeMint(mintAddress, _tokenIdCounter.current());
        }
    }

    /*
    * Pause minting if active, make active if paused.
    */
    function flipMintingState() public onlyOwner {
        mintingIsActive = !mintingIsActive;
    }

    /*
    * Lock provenance and base URI.
    */
    function lockProvenance() public onlyOwner {
        isLocked = true;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function mint(string memory id) public payable {
        require(mintingIsActive, "Minting not live");
        require(_tokenIdCounter.current() < maxTokenSupply, "Exceeds max supply");
        require(mintPrice <= msg.value, "Incorrect ether value");

        _tokenIdCounter.increment();
        _safeMint(msg.sender, _tokenIdCounter.current());
        emit MintedToken(_tokenIdCounter.current(), id);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        require(!isLocked, "Locked");
        baseURI = newBaseURI;
    }

    /*     
    * Set provenance once it's calculated.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        require(!isLocked, "Locked");
        provenance = provenanceHash;
    }
}
