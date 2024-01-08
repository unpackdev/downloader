/*
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,#&@&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&@&#,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,@(((@*,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*@(((@,,,,,,,,,,,,,,,,
,,,,,,,,,*@@#,,,,%#((((@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@((((#%,,,,#@@*,,,,,,,,
,,,,,,,,,@((((&@,,@(((((@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@(((((@,,@@((((@,,,,,,,,
,,,,,,,,,@((((((((@&(((((@#@@@%################&@@@@@(,@(((((&@((((((((@,,,,,,,,
,,,,,,,,,@(((((((((((@@#################################%@@((((((((((((@,,,,,,,,
,,,,,,,,,,@((((((@@##########################################@@(((((((@,,,,,,,,,
,,,,,,,,,,,*@(#@################################################@@((@*,,,,,,,,,,
,,,,,,,,,,,,,@#######@,@&@&##@%##################@@@##############@,,,,,,,,,,,,,
,,,,,,,,,%,,@###################@@##############&%@@@&#############@,,,@,,,,,,,,
,,,,,,,,,#&#@######################################################@##&/,,,,,,,,
,,,,,,,,,,,,&@#####################################################@/,,,,,,,,,,,
,,,,,,,,,@%%%%@########################@%#%@######################@###%&,,,,,,,,
,,,,,,,,,,,,/@@@#########################%######################%@%*,,,,,,,,,,,,
,,,,,,,,,,,,,,,&#@%###########################################&@#&,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,@#@,@@%#####################################%@@,@#&,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,@,,%#&#,@@#############################%@&*@##/,@(,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,@@,,,,,,,,,,#@@@@@&##########&@@@/,,,,,,,@@,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

The King of Crabs has begun a campaign to make it known by all how cool
crabs are. Together with 9,999 crabgrammatically generated crabrades
the King is ready to fight for crabkind. Join us at https://crabrades.com/
to join the fight for the liberation of the crustacean nation! 
Crabkind will one day have their time in the sun again.

*/

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Crabrades is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _teamSpecials = 7;
    uint256 private _maxReserved = 35;
    uint256 private _reserved = _maxReserved - _teamSpecials;
    uint256 private _price = 0.02 ether;
    uint256 private _maxSupply = 9999;
    bool public _paused = true;
   
    constructor(string memory baseURI) ERC721("Crabrades", "CRAB")  {
        setBaseURI(baseURI);
        // Team and associates gets the first 7 crabrades
        for(uint256 i; i < _teamSpecials; i++){
            _safeMint (owner(), i );
        }
    }

    function adopt(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( !_paused,                              "Sale paused" );
        require( num < 51,                              "You can adopt a maximum of 50 Crabrades at a time" );
        require( supply + num < (_maxSupply+1) - _reserved,      "Exceeds maximum Crabrades supply" );
        require( msg.value >= _price * num,             "Ether sent is not correct" );

        for(uint256 i; i < num; i++){
            // First 35 Crabrades are reserved for team for giveaways
            _safeMint( msg.sender, supply + _reserved + i );
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

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
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

    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _reserved, "Exceeds reserved Crabrades supply" );
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, _maxReserved - _reserved + i );
        }
        _reserved -= _amount;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(owner()).send(address(this).balance));
    }
}
