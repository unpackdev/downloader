// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

// To dev on Etherem or not, that is no longer a question
contract Shakespeare is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _reserved = 100;
    uint256 private _price = 0.03 ether;
    bool public _paused = true;
    mapping (address => uint) public early_addresses;

    // wallet address
    address t1 = 0xeE7392be3D672FF0114FA3B483d05F42A5001b4A;

    constructor(string memory baseURI) ERC721("9858 by Shakespeare", "9858")  {
        setBaseURI(baseURI);
    }

    function mint(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( !_paused,                              "Sale paused" );
        require( num < 11,                              "You can mint a maximum of 10 at once" );
        require( supply + num < 9858 - _reserved,       "Exceeds maximum supply" );
        require( msg.value >= _price * num,             "Ether sent is not correct" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    // first 1,000 tokens are free of charge
    function earlyfolks(uint256 num) public {
        uint256 supply = totalSupply();
        require(early_addresses[msg.sender] == 0,       "You can be early only once.");
        require(num < 11,                               "Don't be too greedy!" );
        require(totalSupply() + num < 1001,             "The earlier hath been better.");

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }

        early_addresses[msg.sender] = 1;
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
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _reserved, "Exceeds reserved supply" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        _reserved -= _amount;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(t1).send(address(this).balance));
    }
}