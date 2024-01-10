//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//Written by mcarriga
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721A.sol";

contract AIWorld is ERC721A, Ownable {
    using SafeMath for uint256;

    uint public sale_startTime = 1646334000;
    
    uint public MAX_SUPPLY;
    bool public pause_sale = false;

    uint public price = 0.05 ether;
    uint public constant MAX_PER_MINT = 10;
    uint public constant MAX_PER_ACCOUNT = 10;
    
    string public baseTokenURI;
    
    constructor(string memory baseURI, uint _supply) ERC721A("Lucid A.I.", "LAI") {
        baseTokenURI = baseURI;
        MAX_SUPPLY = _supply;
    }
    function addSupply(uint _count) public onlyOwner {
        MAX_SUPPLY = MAX_SUPPLY + _count;
    }
    function reserveNFTs(uint _count) public onlyOwner {
        require(totalSupply().add(_count) <= MAX_SUPPLY, "Not enough NFTs left to reserve");
        _safeMint(msg.sender, _count);
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }
    function tokensOfOwner(address _owner) external view returns (uint[] memory) {

        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
    function mintNFTs(uint _count) public payable {
        require(totalSupply().add(_count) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(balanceOf(msg.sender).add(_count) <= MAX_PER_ACCOUNT, "Can only Mint 10 Tickets total");
        require(msg.value >= price.mul(_count), "Not enough ether");
        require(block.timestamp >= sale_startTime,"Minting not started yet");
        require(pause_sale == false, "Sale Paused.");
        _safeMint(msg.sender, _count);
    }
    function set_start_time(uint _time) external onlyOwner{
        sale_startTime = _time;
    }
    function set_mint_price(uint256 _cost) external onlyOwner{
       price = _cost;
    }
    function setPauseSale(bool temp) external onlyOwner {
        pause_sale = temp;
    }
}