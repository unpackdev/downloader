// SPDX-License-Identifier: MIT
/*                            
                                            ((((((((                                                
                                 &&&&&%,,,,,,,,,,,,,,,,,,,,%&&&&&&&                                 
                            %&&&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*&&&&                           
                         &&&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&&&                       
                       &&*,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&&.                   
                     &&*,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,(&&                 
                    &&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,/&&               
                   &&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&&              
                  &&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&&             
                  &#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&&            
                 ,&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,(&            
                 &&///////,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&/           
                 &&&&,,,,,,,,,,,,,,,,,,,,,,,/////////,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&&           
               &&,,#&&&&&,,,,&&&(,,,,/////&&&&&(,,,,,,,/&&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&            
             ,&(&&*,,,,,,,,,,,,,,*&&#/%&&,,,,,,,,,,,,,,,,,,,,,,,,&&/,,,,,,,,,,,,,,,,,,%&            
             &&%,,,,,,,,,,,,,,,,,,,,&&(,,,,,,,,,,,,,,,,,,,,,,,,,,,,*&&,,,,,,,,,,,,,,,,&&            
             &&,,,,,,,,,,,,,,,,,,,,,&%,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&&,,,,,,,,,,,,,,*&,            
              &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&/,,,,,,,,,&/,,,,,,,,,,,,,&&             
              /&     .&&&&&&        &&*         &&&&&&        .&&&&,,&&,,,,,,,,,,,,,,&/             
               &                   (&&&                           &&,,,,,,,,,,,,,,,,&&              
               &&                 &&/(&,                         (&,,,,,,,,,,,,,,,,,&&              
                 &&            *&&/////&&                       &&,,,,,,,,,,,,,,,,,/&               
                  //&&&&&&&&&&#////,/////&&&                &&&*,,,,,,,,,,,,,,,,,,,&&               
                  /&,,,//////*,,,,,,,,,,/////&&&&&&&&&&&&&&,,,,,,,,,,,,,,,,,,,,,,,,&&               
                  &&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&                
                &&&&.     /%&&&&&&&(*,,,,,,,**,(#%%#(*,,,,,,,,,,,,,,,,,,,,,,,,,,,,(&                
              &&                                         &&&,,,,,,,,,,,,,,,,,,,,,,%&                
             &/                                             &&*,,,,,,,,,,,,,,,,,,,%&                
            &&                                               ,&,,,,,,,,,,,,,,,,,,,#&                
             &              &&&&&&&&&&&&&&&&&&                &*,,,,,,,,,,,,,,,,,,%&                
             #&/                                             &&,,,,,,,,,,,,,,,,,,,&&                
               &&&                                         &&,,,,,,,,,,,,,,,,,,,,%&                 
                   &&&&/                              (&&&*,,,,,,,,,,,,,,,,,,,,,&&                  
                     &&,//&&&&&&&&&&&&&&&&&&&&&&&&&&(,,,,,,,,,,,,,,,,,,,,,,,,,&&                    
                       &&%,*,//////////////////////,,,,,,,,,,,,,,,,,,,,,,,/&&#                      
                          &&&,,/////////////,*,,,,,,,,,,,,,,,,,,,,,,,,&&&&                          
                              &&&&,//,,,,,,,,,,,,,,,,,,,,,,,,,,,*&&&&                               
                                   &&&&&&(,,,,,,,,,,,,,*%&&&&&&                                     
                                                                                                    
*/
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract BoredOutBro is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _reserved = 200; // Giveaway Campaign
    uint256 private _price = 0.05 ether;
    uint256 private _maxMintPerTxn = 21; // maximum number of mint per transaction
    uint256 private _maxSupply = 10000;
    bool public _saleActive = false;
    bool public _isreveal = false;

    // withdraw addresses
    address t1 = 0x687FA36CdC13e45284e81beD7b798b1D65435186; // Founder 
    address t2 = 0xD10580A7BD811a90caDb90064C6154aD7e5C64d0; // 
    address t3 = 0xDeB34F38Ba2d81685a3744c6a728EAF5C8bd07dE; // 
    address t4 = 0xeDb899751FA6272CaD1Ac23D8Dff0C4667928B6e; // 

    // 0-9999 BoreoutBro in total, First 10 generate bot is fix graphic that come from Event, From number 10 is randomly generate
    constructor(string memory baseURI) ERC721("BoredOutBro", "BOB")  {
        setBaseURI(baseURI);

        // First 10 reserve for Special
        _safeMint( t1, 0);
        _safeMint( t1, 1);
        _safeMint( t1, 2);
        _safeMint( t1, 3);
        _safeMint( t1, 4);
        _safeMint( t1, 5);
        _safeMint( t1, 6);
        _safeMint( t1, 7);
        _safeMint( t1, 8);
        _safeMint( t1, 9);
        // Transfer 4 Persons that minted at old address 0x56123F5d57BeeA02f0A2026578b9fFbbC69B9e0e
        _safeMint( 0x98488C8A8005E8cae743d571d2a0f87DB288Ea99, 10);
        _safeMint( 0x98488C8A8005E8cae743d571d2a0f87DB288Ea99, 11);
        _safeMint( 0x03d42ccC77e4f389C56cF912d61491Cade4aE789, 12);
        _safeMint( 0x6899081D7B7016cb77BDBbf883484e495854E143, 13);
    }
    
    modifier onlyManager() {
        require(msg.sender == t1 || msg.sender == owner());
        _;
    }

    function getRemainBoreout() public view returns(uint256) {
        uint256 supply = totalSupply();
        return _maxSupply - supply;
    } 

    function getRemainReserveBoreout() public onlyManager() view returns(uint256) {
        return _reserved;
    } 

    function mintBros(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( _saleActive,                           "Sale paused" );
        require( num < _maxMintPerTxn,                  "You can minted a maximum of 20 Bros" );
        require( supply + num < _maxSupply - _reserved, "Exceeds maximum BoredOutBro supply" );
        require( msg.value >= _price * num,             "Ether sent is not correct" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // Just in case Eth does some crazy stuff
    function setPrice(uint256 _newPrice) public onlyManager() {
        _price = _newPrice;
    }

    // Once Reveal, we cannot turn it back
    function toggleReveal() public onlyManager() {
        _isreveal = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function giveAway(address _to, uint256 _amount) external onlyManager() {
        require( _amount <= _reserved, "Exceeds reserved BoredoutBro" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        _reserved -= _amount;
    }

    function setSaleActive(bool val) public onlyManager {
        _saleActive = val;
    }

    function withdrawAll() public payable onlyManager {
        uint256 _each = address(this).balance / 10;
        require(payable(t1).send(_each*2));
        require(payable(t2).send(_each*3));
        require(payable(t3).send(_each*3));
        require(payable(t4).send(address(this).balance));
    }
}