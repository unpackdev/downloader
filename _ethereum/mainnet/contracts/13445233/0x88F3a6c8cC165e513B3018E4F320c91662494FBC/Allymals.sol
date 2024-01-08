// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";

contract Allymals is ERC721Enumerable, Ownable, PaymentSplitter {

    using Strings for uint256;

    uint256 private _price = 0.03 ether;

    uint256 private _presalePrice = 0.02 ether;

    string private extension = '.json';

    string public _baseTokenURI = 'https://www.allymals.club/metadata/';
    
    string public ALLYMALS_PROVENANCE = '';

    uint256 public MAX_TOKENS_PER_TRANSACTION = 20;

    uint256 public MAX_SUPPLY = 3210;

    uint256 public PRESALE_SUPPLY = 500;

    uint256 public _presaleStartTime = 1634659200; 

    string public LICENSE_TEXT = ""; // IT IS WHAT IT SAYS

    bool licenseLocked = false; // TEAM CAN'T EDIT THE LICENSE AFTER THIS GETS TRUE

    mapping(uint => string) private _owners;

    event licenseisLocked(string _licenseText);

    // Withdrawal addresses
    address t1 = 0x43797B21e76f93adB2377376187ba44D4715A8De;
    address t2 = 0x1B822133c955cD52C6005129Eae10aEf80382594;
    address t3 = 0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a;

    address[] addressList = [t1, t2, t3];
    uint256[] shareList = [15,70,15];

    constructor()
    ERC721("Allymals Squiffy Collection", "ASC")
    PaymentSplitter(addressList, shareList)  {}

    function tokenURI(uint256 tokenId) public override(ERC721) view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), extension)) : "";
    }

    function mint(uint256 _count) public payable {
        uint256 supply = totalSupply();
        require( block.timestamp >= _presaleStartTime,                           "Sale has not started yet" );

        require( _count <= MAX_TOKENS_PER_TRANSACTION,          "You can mint a maximum of 20 Allymals at once" );

        require( supply + _count <= MAX_SUPPLY,                                  "Exceeds max Allymal supply" );
        
        if ( supply < PRESALE_SUPPLY ) { 
            require( msg.value >= _presalePrice * _count,                            "Ether sent is not correct" );
        } else { 
            require( msg.value >= _price * _count,                                   "Ether sent is not correct" );
        }
        
        for(uint256 i; i < _count; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function airdrop(address _wallet, uint256 _count) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _count <= MAX_SUPPLY, "Exceeds maximum Allymal supply");
        
        for(uint256 i; i < _count; i++){
            _safeMint(_wallet, supply + i );
        }
    }

    // Just in case Eth does some crazy stuff
    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function getPrice() public view returns (uint256){
            return _price;
    }

    function getPresalePrice() public view returns (uint256) {
        return _presalePrice;
    }

    function setPresalePrice(uint256 _newPresalePrice) public onlyOwner {
        _presalePrice = _newPresalePrice;
    }

    function setMaxSupply (uint256 _newMaxSupply) public onlyOwner { 
        MAX_SUPPLY = _newMaxSupply;
    }

    function setPresaleSupply (uint256 _newPresaleSupply) public onlyOwner { 
        PRESALE_SUPPLY = _newPresaleSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        ALLYMALS_PROVENANCE = _provenanceHash;
    }
    
    // Returns the license for tokens
    function tokenLicense(uint _id) public view returns(string memory) {
        require(_id < totalSupply(), "Invalid ID");
        return LICENSE_TEXT;
    }
    
    // Locks the license to prevent further changes 
    function lockLicense() public onlyOwner {
        licenseLocked =  true;
        emit licenseisLocked(LICENSE_TEXT);
    }
    
    // Change the license
    function changeLicense(string memory _license) public onlyOwner {
        require(licenseLocked == false, "License already locked");
        LICENSE_TEXT = _license;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setPresaleStartTime(uint256 _newStartTime) public onlyOwner {
        _presaleStartTime = _newStartTime;
    }
}