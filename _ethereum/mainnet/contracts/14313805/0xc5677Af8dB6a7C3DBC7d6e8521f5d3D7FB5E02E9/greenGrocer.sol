// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
Greengrocer     
*/
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract GreenGrocer is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string baseTokenUri;
    bool baseUriDefined = false;
    
    // Prices per Unit
    uint256 private _oneSVG = 0.03 ether; 
    
    bool public _openedGarden = false;

    // Team withdraw
    address coolGuy1 = 0xe03c018686E6E46Bb48A2722185d67f0eE6cee6b;
    address coolGuy2 = 0x667D02ae75D0d4F69392881B0caF980F4E77682B;
    address coolGuy3 = 0xf52B69d65C96794BAe7F6818e6bE7d1B482C510E;
    address coolGirl = 0x04E2D6F2d30b8927D54674b8795796cD368AC02E;
    
    /* Giveaway */
    uint256 _reserved = 200;
    uint256 MAX_SUPPLY = 5555;
    
    constructor(string memory baseURI) ERC721("GreenGrocer", "GG")  {
        setBaseURI(baseURI);
        
        // Team taste the first sweet vegetables :p
        _safeMint( coolGuy1, 1);
        _safeMint( coolGuy2, 2);
        _safeMint( coolGuy3, 3);
        _safeMint( coolGirl, 4);
    }
    
    /*************************************************
     * 
     *      METADATA PART
     * 
     * ***********************************************/
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    /*
    *   The setBaseURI function with a possibility to freeze it !
    */
    function setBaseURI(string memory baseURI) public onlyOwner() {
        require(!baseUriDefined, "Base URI has already been set");
        baseTokenUri = baseURI;
    }
    
    function lockMetadatas() public onlyOwner() {
        baseUriDefined = true;
    }
    
    /*************************************************
     * 
     *      SHARE <3
     * 
     * ***********************************************/

    function getReserved() public view onlyOwner() returns (uint256){
        return _reserved;
    }
     
    function bigGiveAway(address[] memory _addrs) external onlyOwner() {
        uint256 supply = totalSupply();
        uint256 amount = _addrs.length;
        require(amount <= _reserved, "Not enough reserved freshies");

        for(uint256 i = 0; i < amount; i++) {
            _safeMint( _addrs[i], supply + i + 1);
        }

        _reserved -= amount;
    }
    
    function giveAway(address _addrs, uint256 amount) external onlyOwner() {
        uint256 supply = totalSupply();
        require(amount <= _reserved, "Not enough reserved freshies");

        for(uint256 i = 1; i <= amount; i++) {
            _safeMint( _addrs, supply + i);
        }

        _reserved -= amount;
    }
    
    
    
    /*************************************************
     * 
     *      MINT 
     * 
     * ***********************************************/
    
    
    function collectFreshies(uint256 num) public payable {
        uint256 supply = totalSupply();

        require( _openedGarden,                          "Garden is closed !" );
        require( num > 0 && num <= 20,                   "You can collect 20 SVG maximum" );
        require( supply + num <= MAX_SUPPLY - _reserved, "Exceeds maximum svg supply" );
        require( msg.value >= getPrice(num),             "Ether sent is not correct" );

        for(uint256 i = 1; i <= num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function getPrice(uint256 num) internal view returns (uint256){
        uint256 discount = 100;
        if(num >= 5 && num < 10) {
            discount = 95;
        } else if (num >= 10 && num < 15) {
            discount = 90;
        } else if (num >= 15) {
            discount = 85;
        }
        return num * _oneSVG * discount / 100;
    }
    
    function manageGarden() public onlyOwner {
        _openedGarden = !_openedGarden;
    }
    
    function updatePriceOfSVG(uint256 price) public onlyOwner() {
       _oneSVG = price;
    }
    
    function getPriceOfSVG() public view returns (uint256){
        return _oneSVG;
    }
    
    function SVGOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _each = address(this).balance / 4;
        require(payable(coolGuy1).send(_each));
        require(payable(coolGuy2).send(_each));
        require(payable(coolGuy3).send(_each));
        require(payable(coolGirl).send(_each));
    }

}