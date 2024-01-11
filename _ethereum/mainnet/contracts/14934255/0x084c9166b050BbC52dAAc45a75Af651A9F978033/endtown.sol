// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract endtownNFT is ERC721A, Ownable, ReentrancyGuard {  
    using Strings for uint256;
    string public _endtownlink;
    bool public hasTownEnded = false;
    uint256 public endtownnfts = 9999;
    uint256 public endtownspeed = 2; 
    mapping(address => uint256) public howmanyendtowns;
   
	constructor() ERC721A("endtown", "ENDTOWN") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _endtownlink;
    }

 	function joinendtown() external nonReentrant {
  	    uint256 totalendtownnfts = totalSupply();
        require(hasTownEnded);
        require(totalendtownnfts + endtownspeed <= endtownnfts);
        require(msg.sender == tx.origin);
    	require(howmanyendtowns[msg.sender] < endtownspeed);
        _safeMint(msg.sender, endtownspeed);
        howmanyendtowns[msg.sender] += endtownspeed;
    }

 	function enforceendtowns(address targets, uint256 _endtowns) public onlyOwner {
  	    uint256 totalendtownnfts = totalSupply();
	    require(totalendtownnfts + _endtowns <= endtownnfts);
        _safeMint(targets, _endtowns);
    }

    function endtownnow(bool _end) external onlyOwner {
        hasTownEnded = _end;
    }

    function endtownquickly(uint256 _speedup) external onlyOwner {
        endtownspeed = _speedup;
    }

    function endtownplease(string memory link) external onlyOwner {
        _endtownlink = link;
    }

    function justendit() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}
}