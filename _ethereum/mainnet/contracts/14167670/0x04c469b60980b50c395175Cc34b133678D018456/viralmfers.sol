// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/*

▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
██ ███ ██▄██ ▄▄▀█ ▄▄▀█ █████ ▄▀▄ █ ▄▄█ ▄▄█ ▄▄▀█ ▄▄
███ █ ███ ▄█ ▀▀▄█ ▀▀ █ █████ █ █ █ ▄██ ▄▄█ ▀▀▄█▄▄▀
███▄▀▄██▄▄▄█▄█▄▄█▄██▄█▄▄████ ███ █▄███▄▄▄█▄█▄▄█▄▄▄
▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
 ▄▀ █▄ █ ▄▀▄ ▀█▀   █▄ ▄█ ▄▀▄ █▀▄ ██▀   █ █▄ █   █   ▄▀▄ ██▄ ▀▄
 ▀▄ █ ▀█ ▀▄▀  █    █ ▀ █ █▀█ █▄▀ █▄▄   █ █ ▀█   █▄▄ █▀█ █▄█ ▄▀
   
*/

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract ViralMfers is ERC721, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;

    string private _baseTokenURI;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public MINT_COST = 0.0 ether;
 
    bool public saleIsActive;

    constructor() ERC721("Viral Mfers", "VM") {
        _nextTokenId.increment(); // Start Token IDs at 1
        saleIsActive = false;
    }

    function mint(uint256 _mintAmount) public payable {
        require(saleIsActive, "Viral Mfers are not on sale yet.");
        require(_mintAmount > 0, "Cannot mint zero!");
        require(_mintAmount <= maxMint(), "Save some for the rest of us, fren!");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Not enough Viral Mfers remaining.");
        require(msg.value >= MINT_COST * _mintAmount, "Not enough ETH to buy Viral Mfers, :-(");
  
        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 mintIndex = _nextTokenId.current(); // Get next ID to mint
            _nextTokenId.increment();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
        require(_mintAmount > 0, "Cannot mint zero!");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Not enough Viral Mfers remaining.");
  
        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 mintIndex = _nextTokenId.current(); // Get next ID to mint
            _nextTokenId.increment();
            _safeMint(_receiver, mintIndex);
        }
    }

    function remainingSupply() public view returns (uint256) {
        uint256 numberMinted = totalSupply();
        return MAX_SUPPLY - numberMinted;
    }

    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function toggleSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        MINT_COST = _newMintPrice;
    }

    function maxMint() public view returns (uint256) {

        uint256 totalMinted = totalSupply();

        if (totalMinted <= 2500) {
            return 15;

        } else if (totalMinted <= 5000) {
            return 10;

        } else {
            return 5;
        }
    }

    function withdrawBalance() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
}