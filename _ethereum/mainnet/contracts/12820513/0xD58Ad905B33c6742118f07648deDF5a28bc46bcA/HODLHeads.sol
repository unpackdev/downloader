// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract HODLHeads is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint public availableToken = 10000;
    uint256 public constant price = 0.03 ether;
    uint public constant maxPurchaseSize = 20;

    string _baseTokenURI;
    bool public paused = false;
    bool public revealed = false;
    bool public debugMode = false;
    address owner1;
    address owner2;

    constructor(string memory theBaseURI, address theOwner1, address theOwner2, uint numToken, bool debug) ERC721("HodlHead", "HODLHEAD")  {
        setBaseURI(theBaseURI);
        owner1 = theOwner1;
        owner2 = theOwner2;
        availableToken = numToken;
        debugMode = debug;
    }

    modifier saleIsOpen {
        require(totalSupply() < availableToken, "Sale has ended");
        _;
    }

    modifier notPaused {
        if(msg.sender != owner()){
            require(!paused, "Minting has beend paused");
        }
        _;
    }

    modifier notRevealed {
        require(!revealed, "You can't do this after the reveal");
        _;
    }

    modifier onlyInDebugMode {
        require(debugMode, "You can do this only in debug mode");
        _;
    }

    function mintHeads(uint _count) public payable saleIsOpen notPaused notRevealed {
        require(_count > 0, "You can't mint 0 HodlHeads");
        require(_count <= maxPurchaseSize, "Exceeds 20");
        require(totalSupply() + _count <= availableToken, "Not enough token left");

        uint256 orderPrice = price.mul(_count);
        require(msg.value >= orderPrice, "Value below price");

        for(uint i = 0; i < _count; i++){
            _safeMint(msg.sender, totalSupply());
        }

        payable(owner1).transfer(orderPrice.div(2));
        payable(owner2).transfer(orderPrice.div(2));
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public pure returns (string memory) {
        return "https://www.hodlheads.io/contract-info.json";
    }

    function pause(bool val) public onlyOwner {
        paused = val;
    }

    function reveal(string memory baseURI) public onlyOwner notRevealed {
        setBaseURI(baseURI);
        revealed = true;
    }

    function unreveal() public onlyOwner onlyInDebugMode {
        revealed = false;
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }
}