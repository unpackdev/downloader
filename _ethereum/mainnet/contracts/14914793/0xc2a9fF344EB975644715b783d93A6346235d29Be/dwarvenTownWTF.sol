// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";

contract dwarventownNFT is ERC721A, Ownable, ReentrancyGuard {  
    using Strings for uint256;
    string public _weaponsURI;
    bool public create = false;
    uint256 public dwarves = 9999;
    uint256 public maxCreate = 1; 
    mapping (address => uint256) public howManyDwarves;

    constructor( ) ERC721A("dwarventown", "DWARF") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _weaponsURI;
    }

    function createDwarf() external nonReentrant() {
        require(create, "The Dwarves are not ready");
        require(totalSupply() + maxCreate <= dwarves, "We are all out of Dwarves");
        require(msg.sender == tx.origin);
        require(howManyDwarves[msg.sender] < maxCreate, "Aye don't be greedy, only 1 per Wallet");
        _safeMint( msg.sender, maxCreate);
        howManyDwarves[msg.sender] += maxCreate;
    } 

 	function enlistDwarves(address lord, uint256 _dwarves) public onlyOwner {
	    require(totalSupply() + _dwarves <= dwarves);
        _safeMint(lord, _dwarves);
    }    

    function giveDwarvesWeapons(string memory weapons) external onlyOwner {
        _weaponsURI = weapons;
    }

    function setCreateActive(bool val) external onlyOwner {
        create = val;
    }

    function setmaxCreate(uint256 _maxCreate) external onlyOwner {
        maxCreate = _maxCreate;
    }    

    function isthatGold() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}    
}