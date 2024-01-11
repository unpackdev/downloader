pragma solidity ^0.8.6;

import "./Pausable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";


contract GloryGirl is ERC721AQueryable, Ownable {
    using Strings for uint256;
    uint256 public constant MAX_PER_ADDRESS = 20;
    uint256 public constant MAX_SUPPLY = 2000;

    string private _baseTokenURI;
    uint256 public price = 0.01 ether;

    constructor(string memory baseURI_) ERC721A("GloryGirl", "GloryGirl") {
        _baseTokenURI = baseURI_;
    }

    function fanMint(uint256 amount) public onlyOwner{
         _safeMint(msg.sender, amount);
    }

    function setPrice(uint256 price_) public onlyOwner{
        price = price_;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function baseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function mint(uint256 amount) external payable{
        require(msg.value >= amount * price, "Not enough ETH");
        require(balanceOf(msg.sender) + amount <= MAX_PER_ADDRESS, "Exceed max buy per address");
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceed max token supply");
        _safeMint(msg.sender, amount);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function withdraw(address to,uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
    }
}