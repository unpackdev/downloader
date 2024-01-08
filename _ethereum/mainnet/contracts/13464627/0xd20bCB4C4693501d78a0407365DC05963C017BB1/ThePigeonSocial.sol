// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";

contract ThePigeonSocial is ERC721Enumerable, Ownable, PaymentSplitter {

    using Strings for uint256;

    uint256 private _price = 0.08 ether;

    string private extension = '.json';

    string public _baseTokenURI = '';
    
    string public PIGEON_PROVENANCE = '';

    uint256 public MAX_TOKENS_PER_TRANSACTION = 20;

    uint256 public MAX_SUPPLY = 10000;

    uint256 public _presaleStartTime = 1635238800; // Tuesday Oct 26 @ 10am CET
    uint256 public _presaleEndTime = 1635282000; // Tuesday Oct 26 @ 10pm CET
    uint256 public _startTime = 1635454800; // Thursday Oct 28 @ 10pm CET

    string public LICENSE_TEXT = ""; // IT IS WHAT IT SAYS

    bool licenseLocked = false; // TEAM CAN'T EDIT THE LICENSE AFTER THIS GETS TRUE

    bool public isMetadataRevealed = false;

    mapping(uint => string) private _owners;

    event licenseisLocked(string _licenseText);

    // Withdrawal addresses
    address t1 = 0x71996EE4ca39C7833BD12AD64C7792c3AE19f48B;
    address t2 = 0x0B2d070b8062F1B8694d245fF8FC41cb02557F6E;
    address t3 = 0xBB12075398553702a676C77f8e2FF016165e8a00;
    address t4 = 0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a;

    address[] addressList = [t1, t2, t3, t4];
    uint256[] shareList = [50, 425, 425, 100];

    constructor()
    ERC721("The Pigeon Social", "TPS")
    PaymentSplitter(addressList, shareList)  {}

    function tokenURI(uint256 tokenId) public override(ERC721) view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), extension)) : "";
    }

    function mint(uint256 _count) public payable {
        uint256 supply = totalSupply();
        uint256 tokenCount = balanceOf(msg.sender);
        
        require( block.timestamp >= _startTime || (block.timestamp >= _presaleStartTime && block.timestamp <= _presaleEndTime), "Presale has not started yet" );
        
        require( 
            block.timestamp >= _startTime ||
            (tokenCount < 1 && _count <= 1),
            "Public sale has not started yet" );

        require( _count <= MAX_TOKENS_PER_TRANSACTION, "You can mint a maximum of 20 Pigeons at once" );
        require( supply + _count <= MAX_SUPPLY,        "Exceeds max Pigeon supply" );
        require( msg.value >= _price * _count,         "Ether sent is not correct" );
        
        for(uint256 i = 1; i < _count; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function airdrop(address _wallet, uint256 _count) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _count <= MAX_SUPPLY, "Exceeds maximum Pigeon supply");
        
        for(uint256 i = 1; i < _count; i++){
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

    function setMaxSupply (uint256 _newMaxSupply) public onlyOwner { 
        MAX_SUPPLY = _newMaxSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        PIGEON_PROVENANCE = _provenanceHash;
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

    function setPresaleEndTime(uint256 _newEndTime) public onlyOwner {
        _presaleEndTime = _newEndTime;
    }
    
    function setStartTime(uint256 _newStartTime) public onlyOwner {
        _startTime = _newStartTime;
    }

    function setIsMetadataRevealed(bool _newState) public onlyOwner {
        isMetadataRevealed = _newState;
    }
}