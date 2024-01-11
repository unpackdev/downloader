pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Moondots is ERC721A, Ownable {
    string public baseURI = "https://ipfs.io/ipfs/QmbVdPNW8xWn3CXicpc6qGN8MYNouQf8c18pghb2CLLrQm/";
    uint256 public constant MAX_PER_ADDR = 10;
    uint256 public PRICE = 0.005 ether;
    uint256 public MAX_SUPPLY = 5555;
    bool public live = false;

    constructor() ERC721A("Moondots", "MOONDOT") {}

    function mint(uint256 _amount) external payable {
        require(live, "Not live!");
        require(
            _amount > 0 && _amount <= MAX_PER_ADDR,
            "Max per addr exceeded!"
        );
        require(totalSupply() + _amount <= MAX_SUPPLY, "Max supply exceeded!");
        require(
            _numberMinted(msg.sender) + _amount <= MAX_PER_ADDR,
            "Max per addr exceeded!"
        );
        require(msg.value >= PRICE * _amount, "Insufficient transaction value!");
        _safeMint(_msgSender(), _amount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setLive(bool _state) external onlyOwner {
        live = _state;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        PRICE = newPrice;
    }

    function reduceSupply(uint256 newSupply) external onlyOwner {
        require(
            newSupply > 0 && newSupply < MAX_SUPPLY,
            "New supply must be lower than existing max supply!"
        );
        MAX_SUPPLY = newSupply;
    }

    function getPrice() external view returns (uint256) {
        return PRICE;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "Failed to send");
    }

    function contractURI() public view returns (string memory) {
        return "https://ipfs.io/ipfs/QmVk58qXwMWdU4EtYx8dgekX9xvC3JvaaBaUxzDkqzSyzJ";
    }
}
