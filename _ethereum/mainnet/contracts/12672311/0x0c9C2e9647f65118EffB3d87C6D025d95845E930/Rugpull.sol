// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Rugpull is ERC721Enumerable, Ownable {
    uint public constant MAX_RUGS = 10001;
	string _baseTokenURI;
	bool public paused = false;

    uint256 flyingRug = 99999;
    uint rugOrPull = 2;

    constructor(string memory baseURI) ERC721("Rugpull", "RUGS")  {
        setBaseURI(baseURI);
    }

    modifier saleIsOpen{
        require(totalSupply() < MAX_RUGS, "Sale end");
        _;
    }

    function mint(uint _count) public payable saleIsOpen {
        if(msg.sender != owner()){
            require(!paused, "Pause");
        }
        require(totalSupply() + _count <= MAX_RUGS, "Max limit");
        require(totalSupply() < MAX_RUGS, "Sale end");
        require(_count <= 50, "Exceeds 50");
        require(msg.value >= 2000000000000000 * _count, "Value below price");

        for(uint i = 0; i < _count; i++){
            _safeMint(msg.sender, totalSupply());
        }
    }


    function selectFlyingRug() public onlyOwner {

        require(flyingRug == 0, "Flying rug already minted");

        uint256 max = MAX_RUGS - 1;
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));

        flyingRug = randomHash % max;
    }

    function selectRugOrPull() public onlyOwner {

        require(rugOrPull == 2, "Already selected");

        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));

        rugOrPull = randomHash % 2 == 0 ? 0 : 1;
    }

    function isRugPull(uint tokenID) public view returns (bool){
        require(rugOrPull != 2, "Not selected");

        if(tokenID == getFlyingRug()) {
            return false;
        }
        return tokenID % 2 == rugOrPull ? true : false ;
    }

    function getFlyingRug() public view returns (uint256){
        return flyingRug;
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

    function withdraw() onlyOwner external {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}