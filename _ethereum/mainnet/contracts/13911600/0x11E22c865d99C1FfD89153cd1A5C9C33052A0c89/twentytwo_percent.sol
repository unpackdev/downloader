// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract twentytwo_percent is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    uint256 public constant MAXHUMANS = 5000;
    uint256 public reservedHumans = 110;
    uint256 public maxHumansPurchase = 20;
    uint256 public _price = 0.033 ether;
    uint256 public tokenCounter;
    string public _baseTokenURI;
    bool public isSaleActive;

    mapping (uint256 => string) private _tokenURIs;

    constructor(string memory baseURI) ERC721("22PERCENT", "22PERCENT") {
        setBaseURI(baseURI);
        isSaleActive = false;
        tokenCounter = 0;
    }

    function mintNFT(uint256 numberOfHumans) public payable {
        require(isSaleActive, "Sale is not active!");
        require(numberOfHumans >= 0 && numberOfHumans <= maxHumansPurchase,
            "You can only mint 20 Humans at a time!");
        require(totalSupply().add(numberOfHumans) <= MAXHUMANS - reservedHumans,
            "Hold up! You would buy more Humans than available...");
        require(msg.value >= _price.mul(numberOfHumans),
            "Not enough ETH for this purchase!");

        for (uint256 i = 0; i < numberOfHumans; i++){
            //uint256 tokenNr = totalSupply();
            if (totalSupply() < MAXHUMANS - reservedHumans) {
                _safeMint(msg.sender, tokenCounter+1);
                tokenCounter++;
            }
        }
        uint256 extraMint = numberOfHumans / uint256(10);
        for (uint256 i = 0; i < extraMint; i++){
            if (totalSupply() < MAXHUMANS - reservedHumans) {
                _safeMint(msg.sender, tokenCounter + 1);
                tokenCounter++;
            }
        }   
    }

    function humansOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory tokensId = new uint256[](tokenCount);
            for (uint256 i = 0; i < tokenCount; i++){
                tokensId[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return tokensId;
        }
    }

    function setHumanPrice(uint256 newPrice) public onlyOwner {
        _price = newPrice;
    }

    function flipSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= reservedHumans, "Exceeds reserved Human supply" );
        require(totalSupply().add(_amount) <= MAXHUMANS,
            "Hold up! You would buy more Humans than available...");
        for(uint256 i = 0; i < _amount; i++){
            _safeMint(_to, tokenCounter + 1);
            tokenCounter++;
        }
        reservedHumans -= _amount;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(msg.sender).send(balance),
            "Withdraw did not work...");
    }

    function withdraw(uint256 _amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(_amount < balance, "Amount is larger than balance");
        require(payable(msg.sender).send(_amount),
            "Withdraw did not work...");
    }

    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        uint256 tokenId = 0;
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

}
