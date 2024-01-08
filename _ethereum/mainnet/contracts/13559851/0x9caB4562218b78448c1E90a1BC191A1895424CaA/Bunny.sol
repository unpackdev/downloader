
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract CoolBunnies is ERC721Enumerable, Ownable {
    uint public constant maxbunny = 3333;
    uint256 public bunnyprice = 30000000000000000; // 0.03 ETH
	bool public saleControl = false;
    address public bunnyaddress=0x187904e9bEa1d622f7E5c1FD1D1cd135511E88ab;
    string _baseTokenURI = "https://api.coolbunnies.io/api/v2/data/";

    constructor() ERC721("Cool Bunnies", "CB")  {
    }
    function mintBunny(address _to, uint _count) public payable {
        require(saleControl, "No Sales Yet");
        require(_count <= 20, "Cannot be more than 20");
        require(msg.value >= price(_count), "Value below price");
        require(totalSupply() + _count <= maxbunny, "Max limit");
        require(totalSupply() < maxbunny, "Sale end");

        for(uint i = 0; i < _count; i++){
            _safeMint(_to, totalSupply());
        }
    }
    
    function price(uint _count) public view returns (uint256) {
        return _count * bunnyprice;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    
    function salefunc(bool val) public onlyOwner {
        saleControl = val;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 bunnyaddress_balance = address(this).balance;
        require(payable(bunnyaddress).send(bunnyaddress_balance));
    }
    function changeWallet(address _accountchange) external onlyOwner {
        bunnyaddress = _accountchange;
    }
}







