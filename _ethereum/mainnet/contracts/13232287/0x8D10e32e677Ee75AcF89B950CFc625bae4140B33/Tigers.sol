
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract ShogunsTigerDojo is ERC721Enumerable, Ownable {
    address public tigeraccount=0xc4d99F9a528860077212756eaEc1D1AA9526b874;
    uint public constant maxTiger = 10000;
	bool public saleTigers = false;
    string _baseTokenURI = "https://stdapi.shogunstigerdojo.io/api/v1/metadata/";
    uint256 public priceTiger = 50000000000000000; // 0.05 ETH

    constructor() ERC721("Shoguns Tiger Dojo", "STD")  {
    }
    function mintTiger(address _to, uint _count) public payable {
        require(saleTigers, "No Sales Yet");
        require(_count <= 20, "Cannot be more than 20");
        require(msg.value >= price(_count), "Value below price");
        require(totalSupply() + _count <= maxTiger, "Max limit");
        require(totalSupply() < maxTiger, "Sale end");

        for(uint i = 0; i < _count; i++){
            _safeMint(_to, totalSupply());
        }
    }
    

    
    function price(uint _count) public view returns (uint256) {
        return _count * priceTiger;
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
    
    function saleControl(bool val) public onlyOwner {
        saleTigers = val;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 tigeraccount_balance = address(this).balance;
        require(payable(tigeraccount).send(tigeraccount_balance));
    }
    function changeWallet(address _accountchange) external onlyOwner {
        tigeraccount = _accountchange;
    }
}







