// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract CoolPunks is ERC721, Ownable {
    //Imports
    using Strings for uint256;
    using Counters for Counters.Counter;

    //Token count 
    Counters.Counter private _tokenSupply;

    //Token URI generation
    string baseURI;
    string public baseExtension = ".json";

    //Supply code
    uint256 public constant MAX_SUPPLY = 4444;
    

    //Pausing functionality
    bool public paused = true;

    //--------------------------------------constructor--------------------------------------

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721 (_name, _symbol){
        //Set base uri
        baseURI = _initBaseURI;
        
        //Create 1 nft so that the collection gets listed on opensea
        _safeMint(msg.sender, MintIndex());
        _tokenSupply.increment();

    }

    //=========================================PUBLIC=========================================================
    //------------------------------------------count functions---------------------------
    //Index for the png's
    function MintIndex() public view returns(uint256 index){
        return _tokenSupply.current() + 1; // Start IDs at 1
    }

    // How many left
    function remainingSupply() public view returns (uint256) {
        return MAX_SUPPLY - tokenSupply();
    }

    // How many minted
    function tokenSupply() public view returns (uint256) {
        return _tokenSupply.current();
    }

    //-----------------------------------------Price and amount functions--------------------------------------
    function Price() public view returns (uint256 _cost){
        uint256 supply = tokenSupply();
        if(supply < 444){ 
            return 0 ether;
        }else{
            return 0.02 ether;
        }
    } 

    function MaxMintAmount() public pure returns (uint256 _maxMintAmount){
        return 10;
    } 

    // --------------------------------------------------Minting functions---------------------------------------------------
    function MintCoolPunks(uint256 _mintAmount) public payable {

        uint256 mintIndex = MintIndex();

        require(!paused, "CoolPunks are paused!");
        require(_mintAmount > 0, "Cant order negative number");
        require(mintIndex + _mintAmount <= MAX_SUPPLY, "This order would exceed the max supply");

        require(_mintAmount <= MaxMintAmount(), "This order exceeds max mint amount for the current stage");
        
        require(msg.value >= Price() * _mintAmount, "This order doesn't meet the price requirement for the current stage");


        for (uint256 i = 0; i < _mintAmount; i++){
            _safeMint(msg.sender, mintIndex + i);
            _tokenSupply.increment();
        }
    }

    //------------------------------------------------------------Metadata---------------------------------------
    //Generate uri for metadata
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

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    //=========================================================PRIVATE and OWNER=====================================
    //-------------------------------------------------------------------uri-------------------------------------------------------
    //returns the base uri for URI generation
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //Only Owner
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    //Pause the contract, if paused = true will not be able to mint
    function pause(bool _state) public onlyOwner{
        paused = _state;
    }

    //Withdraw money from minting
    function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}