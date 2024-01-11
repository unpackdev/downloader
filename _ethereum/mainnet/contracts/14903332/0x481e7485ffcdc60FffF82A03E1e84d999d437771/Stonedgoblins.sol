//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract Stonedgoblins is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public stonersBaseURI;

    // This much stoners yes yes
    uint256 public freeStonerSupply = 1000;
    uint256 public almostFreeStonerSupply = 3200;

    // very expensive price for remaining hmmm
    uint256 public spliffCost = 0.0069 ether;

    uint256 public maxStonersPerWallet = 10;

    bool public hotbox = false;


    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721A(_name, _symbol) {
        setStonersBaseURI(_initBaseURI);
    }
    
    function spawnfreestoners(uint256 _amount) external nonReentrant {
        uint256 totalStoners = totalSupply();
        require(hotbox, "we are still grinding our weed.. come back later man");
        require(_numberMinted(msg.sender) + _amount <= maxStonersPerWallet, "u cant mint more greedy bitch");
        require(totalStoners + _amount <= freeStonerSupply, "you missed out on the free ones, ngmi");
        _safeMint(msg.sender, _amount);
    }

    function spawnstoners(uint256 _amount) external payable nonReentrant {
        uint256 totalStoners = totalSupply();
        require(hotbox, "we are still grinding our weed.. come back later man");
        require(_numberMinted(msg.sender) + _amount <= maxStonersPerWallet, "u cant mint more greedy bitch");
        require(totalStoners + _amount >= freeStonerSupply, "you can still mint for free, how many joints have you smoked??!");
        require(totalStoners + _amount <= freeStonerSupply + almostFreeStonerSupply, "maan you even missed the non free ones, u really ngmi");
        require(msg.value >= spliffCost * _amount, "you thought that was unchecked? naaah u gotta pay");
        _safeMint(msg.sender, _amount);
    }

    function enableHotBox() public onlyOwner {
        hotbox = true;
    }

    function disableHotBox() public onlyOwner {
        hotbox = false;
    }

    function setStonersBaseURI(string memory _newBaseURI) public onlyOwner {
        stonersBaseURI = _newBaseURI;
    }
    
    function getStonersBaseURI() public view returns (string memory) {
        return stonersBaseURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "This stoner doesnt exist, huh");

        string memory baseURI = getStonersBaseURI();
        string memory json = ".json";
        
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(stonersBaseURI, tokenId.toString(), json))
            : "";
    }

    function redeemweedprofits() public payable onlyOwner {
	    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
	    require(success);
	}
}