// This should have been deployed to Remix
// We will be using Solidity version 0.5.3

// Importing OpenZeppelin's SafeMath Implementation
//https://opensea-creatures-api.herokuapp.com/api/creature

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Bunny is ERC721Enumerable, Ownable {
    uint public constant MAX_BUNNY = 10000;
	string _baseTokenURI = "https://api.bunnygameclub.com/api/assets/";
	bool public paused = true;
	uint256 public itemPrice;
    address address1;

    constructor() ERC721("Bunny Game Club", "BGC")  {
        address1=0xA44082A231aB4893b1Ec5d6064a8D029AF926307;
       itemPrice=20000000000000000; // 0.02 ETH
    }

    function mintBunny(address _to, uint _count) public payable {
        require(!paused, "Pause");
        require(_count <= 20, "Exceeds 20");
        require(msg.value >= price(_count), "Value below price");
        require(totalSupply() + _count <= MAX_BUNNY, "Max limit");
        require(totalSupply() < MAX_BUNNY, "Sale end");

        for(uint i = 0; i < _count; i++){
            _safeMint(_to, totalSupply());
        }
    }
    

    
    function price(uint _count) public view returns (uint256) {
        return _count * itemPrice;
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
    
    function pause(bool val) public onlyOwner {
        paused = val;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 address1_balance = address(this).balance;
        //uint256 address2_balance = address(this).balance / 100 * 60;
        require(payable(address1).send(address1_balance));
       // require(payable(address2).send(address2_balance));
    }
    function changeFundWallet(address _newWallet) external onlyOwner {
        address1 = _newWallet;
    }
}







