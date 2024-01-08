// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
  _____ __                                      ______           _____
  / ___// /__________ _____  ____ ____  _____   / ____/___ _____ /__  /
  \__ \/ __/ ___/ __ `/ __ \/ __ `/ _ \/ ___/  / __/ / __ `/ __ `/ / / 
 ___/ / /_/ /  / /_/ / / / / /_/ /  __/ /     / /___/ /_/ / /_/ / / /__
/____/\__/_/   \__,_/_/ /_/\__, /\___/_/     /_____/\__, /\__, / /____/
                          /____/                   /____//____/        
*/

/*
* Hi Mom !
* I dedicate this project to you ! If I've made it until here it's thank to you
* Thank you for all the things that you did for me, I know it has been really hard sometimes.
* Now you will be in the blockchain forever !
* I love you with all my heart <3
* MW
*/

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract StrangerEggZ is ERC721Enumerable, Ownable {


    string baseTokenUri;
    bool baseUriDefined = false;
    /*
    *   50 for early supporter
    *   1 for each meowbits owner ~70
    *   100 for CryptoBabyPunks owner
    *   100 for Boring Banana Company owner
    *   100 for Top Dog Beach Club owner
    *   180 for Giveaway, contests, marketing
    */
    uint256 private _reserved = 600;
    
    //EggZ pack unit price
    uint256 private unitPrice1EggPack = 0.06 ether; // 0.06 ether
    uint256 private unitPrice4EggPack = 0.05 ether; // 0.05 ether
    uint256 private unitPrice6EggPack = 0.045 ether; // 0.045 ether
    uint256 private unitPrice12EggPack = 0.035 ether; // 0.035 ether
    
    bool public canMint = false;
    bool public earlySupportersGiveawayDone = false;

    // withdraw addresses
    address artistAdr = 0xb23D2ca9b0CBDDac6DB8A3ACcd13eCb6726d4Ee7;
    address sc_dev = 0xda9d7C1c84c7954Ee7F5281cDCddaD359ee072e6;
    address website_dev = 0xe03c018686E6E46Bb48A2722185d67f0eE6cee6b;
    
    constructor(string memory baseURI) ERC721("Stranger EggZ", "SEZ")  {
        setBaseURI(baseURI);

        // The team want an egg too
        _safeMint( artistAdr, 0);
        _safeMint( sc_dev, 1);
        _safeMint( website_dev, 2);
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
    *   The setBaseURI is internal and can't be called
    *   It's called once in Contract constructor   
    */
    function setBaseURI(string memory baseURI) internal onlyOwner() {
        require(!baseUriDefined, "Base URI has already been set");
        
        baseTokenUri = baseURI;
        baseUriDefined = true;
    }
    
    /*************************************************
     * 
     *      MINT PART
     * 
     * ***********************************************/
    
    /*
    *   Mint one Egg
    */
    function summon1Egg() public payable {
        summonEggZFromSpace(1,unitPrice1EggPack);
    }
    
    /*
    *   Mint a 4 EggZ Pack
    */
    function summon4PackEggZ() public payable {
        summonEggZFromSpace(4,unitPrice4EggPack);
    }
    
    /*
    *   Mint a 6 EggZ Pack
    */
    function summon6PackEggZ() public payable {
        summonEggZFromSpace(6,unitPrice6EggPack);
    }
    
    /*
    *   Mint a 12 EggZ Pack
    */
    function summon12PackEggZ() public payable {
        summonEggZFromSpace(12,unitPrice12EggPack);
    }
    
    /*
    * The mint function
    */
    function summonEggZFromSpace(uint256 num, uint256 price) internal {
        uint256 supply = totalSupply();
        require( canMint,                              "Sale paused" );
        require( supply + num <= 10000 - _reserved,      "No EggZ left :'(" );
        require( msg.value >= price * num,             "Not enough ether sent" );
        require( earlySupportersGiveawayDone,           "You can't summon EggZ till early supporters and team haven't had their EggZ");

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }
    
    function switchMintStatus() public onlyOwner {
        canMint = !canMint;
    }
    
    
    /*************************************************
     * 
     *      GIVEAWAY PART
     * 
     * ***********************************************/
     
     
    /*
    *   Used to airdrop 1 egg to each _addrs
    *   I'm not using airdropToWallet in this function to avoid
    *   calling require _addrs.length amounts of time
    *
    */
    function airdropOneEggToWallets(address[] memory _addrs) external onlyOwner() {
        uint256 supply = totalSupply();
        uint256 amount = _addrs.length;
        require( earlySupportersGiveawayDone, "You can't summon EggZ till early supporters and team haven't had their EggZ");
        require( supply + amount <= _reserved, "Not enough reserved EggZ");


        for(uint256 i; i < amount; i++) {
            _safeMint( _addrs[i], supply + i);
        }

        _reserved -= amount;
    }

    /*
    *   Used to airdrop amount egg to addr
    *
    */
    function airdropToWallet(address addr, uint256 amount) external onlyOwner() {
        uint256 supply = totalSupply();
        require( earlySupportersGiveawayDone, "You can't summon EggZ till early supporters and team haven't had their EggZ");
        require( supply + amount <= _reserved, "Not enough reserved EggZ");

        for(uint256 i; i < amount; i++) {
            _safeMint( addr, supply + i);
        }
        
        _reserved -= amount;
    }
    
    /*
    *   Used to airdrop the 50 EggZ with early supporter custom trait
    *   Can only be called once
    */
    function earlySupportersGiveaway(address[] memory _addrs) external onlyOwner() {
        uint256 supply = totalSupply();
        require( !earlySupportersGiveawayDone, "Early supporters giveaway has already been done !");
        require( _addrs.length == 50,   "There should be 50 adresses to run the early supporters giveaway");
        
        for(uint256 i; i < _addrs.length; i++) {
            _safeMint( _addrs[i], supply + i );
        }
        
        earlySupportersGiveawayDone = true;
        _reserved -= 50;
        
    }
    
    /*************************************************
     * 
     *      UTILITY PART
     * 
     * ***********************************************/
    
    function listEggZOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _each = address(this).balance / 3;
        require(payable(artistAdr).send(_each));
        require(payable(sc_dev).send(_each));
        require(payable(website_dev).send(_each));
    }

}