// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//        ______                 __           ____
//       / ____/______  ______  / /_____     / __ \_      ______ _______   _____  _____
//      / /   / ___/ / / / __ \/ __/ __ \   / / / / | /| / / __ `/ ___/ | / / _ \/ ___/
//      / /___/ /  / /_/ / /_/ / /_/ /_/ /  / /_/ /| |/ |/ / /_/ / /   | |/ /  __(__  )
//      \____/_/   \__, / .___/\__/\____/  /_____/ |__/|__/\__,_/_/    |___/\___/____/
//                /____/_/

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract CryptoDwarves is ERC721Enumerable, Ownable {

    using Strings for uint256;
    string _baseTokenURI;

    uint256 private _maximumSupply = 12441;
    uint256 private _reserved = 400;
    bool public mintActivated = false;

    // The dwarf unit price for each of our packs, the more you get the better !
    uint256 private _dwarfPriceFor1 = 0.035 ether;
    uint256 private _dwarfPriceFor3 = 0.030 ether;
    uint256 private _dwarfPriceFor6 = 0.025 ether;
    uint256 private _dwarfPriceFor12 = 0.02 ether;

    // Our team withdraw address
    address team1 = 0x8e7D967Ca9f9948Ec0dF00C787B57575D4CA828C;
    address team2 = 0xa6331Fc23Af5Bbe12035c4654f5F37fBAD40100b;
    address team3 = 0xDbF6a61Ad0FCD52a0232A4d7b958885B5dE25240;

    constructor(string memory baseURI) ERC721("Crypto Dwarves", "DWARVES")  {
        setBaseURI(baseURI);

        // God of dwarves has invoked his sons into the rock, now we can get one dwarf ! YAY !
        _safeMint( team1, 0);
        _safeMint( team2, 1);
        _safeMint( team3, 2);
    }

    /******************************************************
    *   Mint functions
    *******************************************************/

    function free1Dwarf() public payable {
        freeDwarves(1, _dwarfPriceFor1);
    }

    function free3Dwarves() public payable {
        freeDwarves(3, _dwarfPriceFor3);
    }

    function free6Dwarves() public payable {
        freeDwarves(6, _dwarfPriceFor6);
    }

    function free12Dwarves() public payable {
        freeDwarves(12, _dwarfPriceFor12);
    }

    /*
    * Hit the block with a pickaxe to mint the dwarves
    */
    function freeDwarves(uint256 num, uint256 price) internal {
        uint256 supply = totalSupply();
        require( mintActivated,                                 "Sale paused" );
        require( supply + num <= _maximumSupply - _reserved,    "There's no longer dwarves to free" );
        require( msg.value >= price * num,                      "Ether sent is not correct" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    /******************************************************
    *   Handle prices in cases of mad changes on Ethereum value
    *******************************************************/
    function updateDwarfPriceFor1(uint256 price) public onlyOwner() {
        _dwarfPriceFor1 = price;
    }

    function updateDwarfPriceFor3(uint256 price) public onlyOwner() {
        _dwarfPriceFor3 = price;
    }

    function updateDwarfPriceFor6(uint256 price) public onlyOwner() {
        _dwarfPriceFor6 = price;
    }

    function updateDwarfPriceFor12(uint256 price) public onlyOwner() {
        _dwarfPriceFor12 = price;
    }

    /******************************************************
    *   Utilities
    *******************************************************/

    function getDwarfPriceFor1() public view returns (uint256){
        return _dwarfPriceFor1;
    }

    function getDwarfPriceFor3() public view returns (uint256){
        return _dwarfPriceFor3;
    }

    function getDwarfPriceFor6() public view returns (uint256){
        return _dwarfPriceFor6;
    }

    function getDwarfPriceFor12() public view returns (uint256){
        return _dwarfPriceFor12;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _reserved, "Exceeds reserved dwarves supply" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        _reserved -= _amount;
    }

    function updateMintState(bool val) public onlyOwner {
        mintActivated = val;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _each = address(this).balance / 3;
        require(payable(team1).send(_each));
        require(payable(team2).send(_each));
        require(payable(team3).send(_each));
    }
}
