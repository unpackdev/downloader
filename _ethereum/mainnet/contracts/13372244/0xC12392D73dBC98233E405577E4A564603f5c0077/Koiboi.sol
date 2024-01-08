// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Pausable.sol";
import "./ERC721.sol";
import "./Strings.sol";
import "./SafeMath.sol";


contract KoiBoi is Ownable, ERC721Pausable{ 

    using SafeMath for uint256;
    uint256 private counter = 1; 
    
    bool private saleOn = false;
    uint16 private constant MAX_MINT = 20;
    uint16 private constant MAX_BOIS = 10000;
    uint256 public constant BOI_PRICE = 50000000000000000; //0.05 ETH
    string private _current_baseURI;
    bool public preSaleOn = false;

    // Structures for data storage 
    struct frozen_uri {
        string uri_value;
        uint isSet;
    }
  
    struct approvalReg{
        bool approved;
    }
  
    uint8 currentBestBoi = 0;
  
    // key lists
    mapping(uint256 => frozen_uri) private id_to_uri;
    mapping(uint256 => uint256) private id_to_dna;
    mapping(address => approvalReg) private _whiteList;

    // Fundamental functions
    constructor() ERC721("KoiBoi", "KOIBOIS"){
        setBaseURI("https://backend.koiboi.io/");
        
    }
    
    // Twigs, Snakes, PirateCheetah and Apejo were here
    
  // MINTING
  //#########
    function mint(address luckyOwner, uint256 num_purchased) public payable {
        require(msg.value == BOI_PRICE.mul(num_purchased), "Incorrect amount of ethereums");
        require(counter + num_purchased -1 <= MAX_BOIS, "all bois have been minted");
        require(num_purchased > 0, "You're trying to give us free money here!");
        require(num_purchased <= MAX_MINT, "You can't mint that many at once");
        require(saleOn, "settle down there goldfish, we haven't started selling yet");
        
        for(uint i = 0; i < num_purchased; i++){
            uint256 _dna = randKoi();
            id_to_dna[counter] = _dna;
            _safeMint(luckyOwner, counter);
            counter += 1;
        }
        payable(owner()).transfer(BOI_PRICE.mul(num_purchased)); //handled in the Ownable import
    }
    
    function switchSale() public onlyOwner {
        saleOn = !saleOn;
    }
  
    function isSaleOn() public view returns(bool) {
        return saleOn;
    }

    // Multi_mint_sale
    // ###################
    function multi_mint_to_others(address[] calldata luckyOwners) public onlyOwner payable {
        require(msg.value == BOI_PRICE.mul(luckyOwners.length), "Incorrect amount of ethereums");
        require(counter + luckyOwners.length -1 <= MAX_BOIS, "all bois have been minted");
        require(luckyOwners.length > 0, "You're trying to give us free money here!");
        require(preSaleOn, "settle down there goldfish, we haven't started selling yet");
        
        for(uint i = 0; i < luckyOwners.length; i++){
            uint256 _dna = randKoi();
            id_to_dna[counter] = _dna;
            _safeMint(luckyOwners[i], counter);
            counter += 1;
        }
        payable(owner()).transfer(BOI_PRICE.mul(luckyOwners.length)); //handled in the Ownable import
    }
    
    function switchPreSale() public onlyOwner {
        preSaleOn = !preSaleOn;
    }
  
    // GENERAL CONTRACT METHODS
    function setBaseURI(string memory _temp_baseURI) public onlyOwner {
        _current_baseURI = _temp_baseURI;
    }
  
    function randKoi() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, counter)));
    }

    // this is overriding an empty function in ERC721.sol
    // It is also internal. Use tokenURI for the public external 
    function _baseURI() internal view virtual override returns (string memory) {
        return _current_baseURI;
    }

    function printDNA(uint256 _tokenId) public view returns (uint256) {
        return id_to_dna[_tokenId];
    }

    function getTotal() public view returns (uint256) {
        return counter -1;
    }

    // / Need to finish implementing this function!!'
    function setPermanentURI(uint256 _counter, string calldata _uri) external onlyOwner{
        id_to_uri[_counter].uri_value = _uri;
        id_to_uri[_counter].isSet = 1;
    } 
    
    function setMultiplePermanentURI(uint256 _counter, string[] calldata _uri) external onlyOwner{
        for(uint i = 0; i < _uri.length; i++){
            id_to_uri[_counter + i].uri_value = _uri[i];
            id_to_uri[_counter + i].isSet = 1;
        }
    } 

    //Including override throws an error. Not sure...
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(id_to_uri[tokenId].isSet == 1) {
          return id_to_uri[tokenId].uri_value;
        }

        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, uint2str(tokenId))) ;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;
        (bool success, ) = msg.sender.call{value:amount}("");
        require(success, "Transfer failed.");
    }
    
    function pause() public onlyOwner {
        _pause();
    }
    
    function unpause() public onlyOwner {
        _unpause();
    }
    
}
