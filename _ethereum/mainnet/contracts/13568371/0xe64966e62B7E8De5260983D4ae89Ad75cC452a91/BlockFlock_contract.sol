// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

pragma solidity ^0.8.0;

contract BlockFlock is ERC721, ERC721Enumerable, Ownable {
    
    using SafeMath for uint256;

    string private _baseURIextended;
    
    uint public price = 0.05 ether;
    uint public constant maxBirdsPurchase = 10;
    uint public mintChickStartDate = 1637254800; // Thursday, November 18, 2021 12:00:00 PM EST
    bool public presaleIsActive = false;
    bool public saleIsActive = false;

    uint16[] birds;
    uint public constant MAX_BIRDS = 4444;
    uint public constant MAX_CHICKS = 888;
    mapping(uint => bool) public birdsUsedForBreeding;
    uint public chickSupply = 0;

    uint public reserveAmount = 100; // Reserve - Giveaways etc...
    mapping(address => uint8) private _allowList;

    address public w1 = 0xEca3B7627DEef983A4D4EEE096B0B33A2D880429; // dev
    address public w2 = 0xE12744C41beC092b7b38d66eE68C14Cdb1366a08; // charity
    address public w3 = 0xd747D1c09c7c9A69C2d2bC407d3e91405D4698E2; // partner

    constructor() ERC721("Block Flock", "BLOCKFLOCK") {
        for(uint16 i = 1; i <= MAX_BIRDS; i++) {
            birds.push(i);
        }
    }
    
    function withdraw() public onlyOwner {
        uint w1Cut = address(this).balance * 5/100;
        uint w2Cut = address(this).balance * 5/100;
        uint w3Cut = address(this).balance * 45/100;
        uint ownerCut = address(this).balance * 45/100;
        require(payable(w1).send(w1Cut));
        require(payable(w2).send(w2Cut));
        require(payable(w3).send(w3Cut));
        require(payable(msg.sender).send(ownerCut));
    }
    
    function reserveBirds(address _to, uint _amount) public onlyOwner {        
        require(_amount > 0 && _amount <= birds.length && _amount <= reserveAmount, "Not enough reserve left for team");
        reserveAmount -= _amount;
        for (uint i = 0; i < _amount; i++) {
            uint randBird = getRandom(birds);
            _safeMint(_to, randBird);
        }
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPresaleState() public onlyOwner {
        presaleIsActive = !presaleIsActive;
    }
    
    function setChickStartDate(uint timestamp) public onlyOwner {
        mintChickStartDate = timestamp;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getRandom(uint16[] storage _arr) private returns (uint) {
        uint random = _getRandomNumber(_arr);
        uint tokenId = uint(_arr[random]);

        _arr[random] = _arr[_arr.length - 1];
        _arr.pop();

        return tokenId;
    }

    function _getRandomNumber(uint16[] storage _arr) private view returns (uint) {
        uint random = uint(
            keccak256(
                abi.encodePacked(
                    _arr.length,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender
                )
            )
        );

        return random % _arr.length;
    }
    
    function tokensOfOwner(address _owner) external view returns(uint[] memory ) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function getBirdsLeft() external view returns(uint) {
        return birds.length;
    }

    function mintBirds(uint numberOfTokens) public payable {
        if (presaleIsActive) {
            require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to mint");
        } else {
            require(saleIsActive, "Sale must be active to mint a bird");
        }
        require(numberOfTokens > 0 && numberOfTokens <= maxBirdsPurchase, "Can only mint 10 birds at a time");
        require(numberOfTokens <= birds.length, "Purchase would exceed max supply of birds");
        require(msg.value >= price.mul(numberOfTokens), "Ether value sent is not correct");

        if (presaleIsActive) {
            _allowList[msg.sender] -= uint8(numberOfTokens);
        }

        for (uint i = 0; i < numberOfTokens; i++) {
            uint randBird = getRandom(birds);
            _safeMint(msg.sender, randBird);
        }
    }

    function mintChick(uint birdA, uint birdB) public {
        require(block.timestamp >= mintChickStartDate, "Chicks are not available to mint yet");
        require(birdA != birdB, "Must be different birds");
        require(this.ownerOf(birdA) == msg.sender && this.ownerOf(birdB) == msg.sender, "Must own both birds");
        require(!birdsUsedForBreeding[birdA], "Already used birdA");
        require(!birdsUsedForBreeding[birdB], "Already used birdB");
        require(chickSupply < MAX_CHICKS, "No more chicks left to breed");

        bool canMint = false;
        if ((birdA >= 1 && birdA <= 120 && birdB >= 1 && birdB <= 600) || 
            (birdA >= 601 && birdA <= 700 && birdB >= 601 && birdB <= 1100) || 
            (birdA >= 1101 && birdA <= 1200 && birdB >= 1101 && birdB <= 1600) || 
            (birdA >= 1601 && birdA <= 1690 && birdB >= 1601 && birdB <= 2050) || 
            (birdA >= 2051 && birdA <= 2140 && birdB >= 2051 && birdB <= 2500) || 
            (birdA >= 2501 && birdA <= 2580 && birdB >= 2501 && birdB <= 2900) || 
            (birdA >= 2901 && birdA <= 2980 && birdB >= 2901 && birdB <= 3300) || 
            (birdA >= 3301 && birdA <= 3360 && birdB >= 3301 && birdB <= 3600) || 
            (birdA >= 3601 && birdA <= 3660 && birdB >= 3601 && birdB <= 3900) || 
            (birdA >= 3901 && birdA <= 3954 && birdB >= 3901 && birdB <= 4172) || 
            (birdA >= 4173 && birdA <= 4226 && birdB >= 4173 && birdB <= 4444)) {
            canMint = true;
        }
        require(canMint, "Birds are not a breed match");

        chickSupply += 1;
        birdsUsedForBreeding[birdA] = true;
        birdsUsedForBreeding[birdB] = true;
        _safeMint(msg.sender, MAX_BIRDS + chickSupply);
    }
    
}