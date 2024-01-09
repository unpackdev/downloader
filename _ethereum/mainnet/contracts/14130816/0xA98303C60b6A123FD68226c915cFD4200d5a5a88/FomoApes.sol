// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract FomoApesV2 is ERC721, Ownable {
    //Imports
    using Strings for uint256;
    using Counters for Counters.Counter;

    //Token count 
    Counters.Counter private _tokenSupply;
    //0.02 eth token count 
    Counters.Counter private _tokenSupplyRefund;

    //Token URI generation
    string baseURI;
    string public baseExtension = ".json";

    //Admin mint
    uint256 public adminMintSize = 30;
    bool public adminMintCompleted = false;

    //Supply code
    uint256 public constant MAX_SUPPLY = 4900;

    //Pausing functionality
    bool public paused = true;

    //Old mint
    IERC721 public oldContract = IERC721(0x87B6b300c4e3D270984414c39db7921C47847907);
    address burn = 0x000000000000000000000000000000000000dEaD;

    //reserving functionality
    uint256 reserved = 0;
    uint256 refundReservedStart = 0;

    //--------------------------------------constructor--------------------------------------

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        uint256 _minted
    ) ERC721 (_name, _symbol){
        //Set base uri
        baseURI = _initBaseURI;
        
        //Create 1 nft so that the collection gets listed on opensea
        _safeMint(msg.sender, MintIndex());
        _tokenSupply.increment();


        //calc num tokens to reserve
        reserved = _minted + _minted - 200;
        refundReservedStart = _minted;
    }

    //=========================================PUBLIC=========================================================
    //------------------------------------------count functions---------------------------
    //Index for the png's
    function MintIndex() public view returns(uint256 index){
        return _tokenSupply.current() + 1 + reserved; // Start IDs at 1 and include reserved
    }

    // How many left
    function remainingSupply() public view returns (uint256) {
        return MAX_SUPPLY - tokenSupply();
    }

    // How many minted
    function tokenSupply() public view returns (uint256) {
        return _tokenSupply.current() + reserved;
    }

    //-----------------------------------------Price and amount functions--------------------------------------
    function Price() public pure returns (uint256 _cost){
        return 0.01 ether;
    } 

    function MaxMintAmount() public pure returns (uint256 _maxMintAmount){
        return 20;
    } 

    //-----------------------------------------V2 transfer functions-----------------------------------------------

    function v1FomosOwned() public view returns (uint256 count){
        return oldContract.balanceOf(msg.sender);
    }

    // --------------------------------------------------Minting functions---------------------------------------------------
    function MintFomoApes(uint256 _mintAmount) public payable {

        uint256 mintIndex = MintIndex();

        require(!paused, "FomoApes are paused!");
        require(_mintAmount > 0, "Cant order negative number");
        require(mintIndex + _mintAmount <= MAX_SUPPLY, "This order would exceed the max supply");

        require(_mintAmount <= MaxMintAmount(), "This order exceeds max mint amount for the current stage");
        require(msg.value >= Price() * _mintAmount, "This order doesn't meet the price requirement for the current stage");


        for (uint256 i = 0; i < _mintAmount; i++){
            _safeMint(msg.sender, mintIndex + i);
            _tokenSupply.increment();
        }
    }   

    //Claim v1 fomo apes
    function ClaimFomoApes(uint256[] calldata tokens ) public {  

        uint256 numToClaim =  tokens.length;

        for(uint256 i=0; i < numToClaim; i++){
            ClaimApe(msg.sender, tokens[i]);
        }
    }
    

    //Staff access 30 (must get before sold out)
    function adminMint() public onlyOwner {
        uint256 mintIndex = MintIndex();

        require(!adminMintCompleted, "Staff order has already been fuffiled"); 
        require(remainingSupply() > adminMintSize, "Not enough tokens remain");

        for (uint256 i = 0; i < adminMintSize; i++) { 
            _safeMint(msg.sender, mintIndex + i);
            _tokenSupply.increment();
        }
        adminMintCompleted = true;
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

    function reservedMintIndex() private view returns(uint256 index){
        return _tokenSupplyRefund.current() + refundReservedStart + 1; //again index's start from 1 (counters start from 0)
    }

    //---------------------------------------------------V2 transfer functions---------------------------------------
    function ownsOwnsOldToken(address sender, uint256 tokenId) internal view returns (bool owns){
        try oldContract.ownerOf(tokenId) returns (address tokenOwner){
            return sender == tokenOwner;
        } catch Error(string memory /*reason*/){
            return false;
        }
    }

    function ClaimApe(address sender, uint256 tokenId) internal {
        require(ownsOwnsOldToken(sender, tokenId), "You are not the owner of the token you are trying to claim!");
        oldContract.safeTransferFrom(sender, burn, tokenId);
        _safeMint(sender, tokenId); 

        //if token id < 200
        if(tokenId >= 200){
            //give free token
            _safeMint(sender, reservedMintIndex());
            _tokenSupplyRefund.increment();
        }

    }


    //-------------------------------------------------------Only Owner-----------------------------------------------------
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