pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract DopeDinos is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _reserved = 200;
    uint256 private _price = 0.01 ether;
    bool public _paused = false;
    bool public baseURIFinal = false;
    uint[] topTokenIds;

    // withdraw addresses
    address t1 = 0x6696360e0C3794Ce1f7Cfff40C9ECc8aA6F84e39;
    address t2 = 0x5F1Efa0BD8f936402c744Fd508DD15324f15ca89;

    constructor(string memory baseURI) ERC721("DopeDinos", "DOPE")  {
        setBaseURI(baseURI);

        // team gets the first 2 dinos
        _safeMint( t1, 0);
        _safeMint( t2, 1);
    }

    function rescue(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( !_paused,                              "Sale paused" );
        require( num < 21,                              "You can rescue a maximum of 20 Dinos" );
        require( supply + num < 10000 - _reserved,      "Exceeds maximum Dinos supply" );
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
    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        require(!baseURIFinal, "Base URL is unchangeable");
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function giveAway(address _to, uint256 _amount) internal {
        require( _amount <= _reserved, "Exceeds reserved Dino supply" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        _reserved -= _amount;
    }

    function airdrop(address[] memory addresses, uint[] memory amounts) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            giveAway(addresses[i], amounts[i]);
        }
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }
    function setTopScores(uint[] memory _topTokenIds) public onlyOwner {
        topTokenIds = _topTokenIds;
    }

    function getTopScores() public view returns (uint[] memory) {
        return topTokenIds;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function finalizeBaseURI() external onlyOwner {
        baseURIFinal = true;
    }
}
