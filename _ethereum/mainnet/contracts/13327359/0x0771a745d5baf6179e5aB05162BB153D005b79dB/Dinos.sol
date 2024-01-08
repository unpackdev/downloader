// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract Dinos is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    uint256 public constant MAXDINOS = 10000;
    uint256 public constant MAXDINOS_PRESALE = 2000;
    uint256 public maxDinosPurchase = 10;
    uint256 public reservedDinosCustom = 10;
    uint256 public _price = 0.07 ether;
    uint256 public tokenCounter;
    string public _baseTokenURI;
    bool public isSaleActive;
    bool public isPreSaleActive;

    mapping (uint256 => string) private _tokenURIs;

    constructor(string memory baseURI) ERC721("Dino Squad Unleashed", "DINOS") {
        setBaseURI(baseURI);
        isSaleActive = false;
        isPreSaleActive = false;
        tokenCounter = 0;
    }

    function mintDino(uint256 numberOfDinos) public payable {
        require(isSaleActive, "Sale is not active!");
        require(numberOfDinos >= 0 && numberOfDinos <= maxDinosPurchase,
            "You can only mint 10 Dinos at a time!");
        require(totalSupply().add(numberOfDinos) <= MAXDINOS - reservedDinosCustom,
            "Hold up! You would buy more Dinos than available...");
        require(msg.value >= _price.mul(numberOfDinos),
            "Not enough ETH for this purchase!");

        for (uint256 i = 0; i < numberOfDinos; i++){
            //uint256 tokenNr = totalSupply();
            if (totalSupply() < MAXDINOS - reservedDinosCustom) {
                _safeMint(msg.sender, tokenCounter+1);
                tokenCounter++;
            }
        }
    }

    function preSaleMintDino(uint256 numberOfDinos) public payable {
        require(isPreSaleActive, "Presale is not active!");
        require(numberOfDinos >= 0 && numberOfDinos <= maxDinosPurchase,
            "You can only mint 10 Dinos in the presale!");
        require(totalSupply().add(numberOfDinos) <= MAXDINOS_PRESALE,
            "Hold up! You would buy more Dinos than available...");
        require(msg.value >= _price.mul(numberOfDinos),
            "Not enough ETH for this purchase!");

        uint256 extraMint = numberOfDinos / uint256(5);

        for (uint256 i = 0; i < numberOfDinos; i++){
            if (totalSupply() < MAXDINOS_PRESALE) {
                _safeMint(msg.sender, tokenCounter + 1);
                tokenCounter++;
            }
        }
        //Extra NFT for every fifth NFT minted.
        for (uint256 i = 0; i < extraMint; i++){
            _safeMint(msg.sender, tokenCounter + 1);
            tokenCounter++;
        }
    }

    function dinosOfOwner(address _owner) external view returns(uint256[] memory) {
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

    function setDinoPrice(uint256 newPrice) public onlyOwner {
        _price = newPrice;
    }

    function setMaxDinosPurchase(uint256 _maxDinosPurchase) public onlyOwner {
      maxDinosPurchase = _maxDinosPurchase;
    }

    function flipSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function flipPreSaleState() public onlyOwner {
        isPreSaleActive = !isPreSaleActive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        require(totalSupply().add(_amount) <= MAXDINOS - reservedDinosCustom,
            "Hold up! You would buy more Dinos than available...");

        for(uint256 i = 0; i < _amount; i++){
            if(totalSupply() < MAXDINOS - reservedDinosCustom)
            _safeMint(_to, tokenCounter + 1);
            tokenCounter++;
        }
    }

    function giveAwayCustom(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= reservedDinosCustom, "Exceeds reserved Dino supply" );
        require(totalSupply().add(_amount) <= MAXDINOS,
            "Hold up! You would buy more Dinos than available...");
        for(uint256 i = 0; i < _amount; i++){
            _safeMint(_to, MAXDINOS - reservedDinosCustom + 1 + i);
        }
        reservedDinosCustom -= _amount;
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
