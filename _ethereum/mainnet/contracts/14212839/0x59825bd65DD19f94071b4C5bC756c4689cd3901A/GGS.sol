// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract GGS is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _reserved = 0;
    uint256 private _price = 0.08 ether;
    bool public _paused = true;
      string public baseExtension = ".json";

    mapping(string => address) private walletAddress;
    address w1;
    address w2;
    address w3;

    constructor() ERC721("Greed God Society", "GGS")  {
    }
    function viewSupply() public view returns(uint256 num) {
        return totalSupply();
    }
    function buy(uint256 num) public payable{
        uint256 supply = totalSupply();
        require( !_paused,                              "Sales have been haulted" );
        require( num < 6,                              "You cannot mint more than 5 at a time" );
        require( supply + num < 7654  - _reserved,      "Quantity is over maximum token supply" );
        require( msg.value >= _price * num,             "Etherium quantity is incorrect" );
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

    // This will most likely never be used. Unless etherium price goes to zero.
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

    // function giveAway(address _to, uint256 _amount) external public onlyOwner() {
    //     require( _amount <= _reserved, "Exceeds reserved token supply" );

    //     uint256 supply = totalSupply();
    //     for(uint256 i; i < _amount; i++){
    //         _safeMint( _to, supply + i );
    //     }
    //     _reserved -= _amount;
    // }
    function pause(bool val) public onlyOwner {
        _paused = val;
    }
    function viewPause() public view returns(bool pauseStatus) {
        return _paused;
    }
    function setWalletAddress(string memory _name, address _wallet) public onlyOwner {
        walletAddress[_name] = _wallet;
    }
    function withdrawAllTo(address _wallet) public payable onlyOwner {
        require(payable(_wallet).send(address(this).balance));
    }
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
    }
    // function withdrawSplit(address _wallet1, address _wallet2) public payable onlyOwner {
    //     uint256 _each = address(this).balance/2;
    //     require(payable(_wallet1).send(_each));
    //     require(payable(_wallet2).send(_each));
    // }
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
}
