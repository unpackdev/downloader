// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "./ERC721A.sol";

contract Nfers is ERC721A {

    mapping (address => uint8) public ownerTokenMapping;

    string public baseURI = "https://www.nfers.xyz/api/metadata/";
    address private owner;
    uint public MINT_PRICE = 0.0069 ether;
    bool public PUBLIC_MINT = false;
    uint16 public FREE_SUPPLY = 2000;
    uint16 public MAX_SUPPLY = 5555;
    uint8 public MAX_PER_WALLET = 20;

    constructor() ERC721A("Nfers", "NFER") {
        owner = msg.sender;
    }


    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMintPrice(uint price) external onlyOwner {
        MINT_PRICE = price;
    }

    function setMaxTokensPerWallet(uint8 tokens) external onlyOwner {
        MAX_PER_WALLET = tokens;
    }

    function setPublicMint() external onlyOwner {
        PUBLIC_MINT = !PUBLIC_MINT;
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Not the owner!");
        _;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        string memory json = string(
                    abi.encodePacked(
                        baseURI,
                        '/',
                        Strings.toString(_tokenId),
                        '.json'
                    )
                );
        return json;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function mint(uint8 amount) external payable {
        require(PUBLIC_MINT, "Sale not active!");
        require(_currentIndex + amount <= MAX_SUPPLY + 1, "Not enough tokens to sell");
        require(amount <= MAX_PER_WALLET, "Max tokens exceeded");
        require(ownerTokenMapping[msg.sender] + amount <= MAX_PER_WALLET, "Max tokens exceeded");
        if(_currentIndex + amount > FREE_SUPPLY){
            require(msg.value == MINT_PRICE * amount, "Insufficient eth for mint");
        }
        _safeMint(msg.sender, amount);
        ownerTokenMapping[msg.sender] += amount;
    }
}