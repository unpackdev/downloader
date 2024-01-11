//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./MerkleWhitelist.sol";
import "./Strings.sol";

contract St0rmEntertainment is Ownable, ERC721A, ReentrancyGuard{

    string public CONTRACT_URI = "ipfs://QmV2itKYvmM7C1W3ghQvcnqgtn1exZKUQXzBqSEtn1AgZx";   

    mapping(address => bool) public userToHasMinted;

    bool public REVEALED;
    string public UNREVEALED_URI = "ipfs://QmSycJZh9AP17Hj7Srij58LrQ28gZFCNcMRA55xNfzeSp6";
    string public BASE_URI;
    bool public isPublicMintEnabled = false;
    uint16 public COLLECTION_SIZE = 100;
    uint256 public MINT_PRICE = 0.0 ether;
    uint16 public MAX_BATCH_SIZE = 1;


    constructor() ERC721A("St0rmEntertainment", "ST0RM") {}

    function teamMint(uint256 quantity, address receiver) public onlyOwner {
        //Max supply
        require(
            totalSupply() + quantity <= COLLECTION_SIZE,
            "Max collection size reached!"
        );
        //Mint the quantity
        _safeMint(receiver, quantity);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function publicSaleMint(uint256 quantity)
        external
        payable
        callerIsUser
    {
        uint256 price = (MINT_PRICE) * quantity;
        require(isPublicMintEnabled == true, "public sale has not begun yet");
        require(!userToHasMinted[msg.sender], "Can only mint once!");   
        require(totalSupply() + quantity <= COLLECTION_SIZE, "Max Collection Size reached!");
        require(quantity <= MAX_BATCH_SIZE, "Tried to mint quanity over limit, retry with reduced quantity");
        require(msg.value >= price, "Must send enough eth for public mint");
        userToHasMinted[msg.sender] = true;
        _safeMint(msg.sender, quantity);
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setPublicMintEnabled(bool _isPublicMintEnabled) public onlyOwner {
        isPublicMintEnabled = _isPublicMintEnabled;
    }

    function setBaseURI(bool _revealed, string memory _baseURI) public onlyOwner {
        BASE_URI = _baseURI;
        REVEALED = _revealed;
    }

    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (REVEALED) {
            return
                string(abi.encodePacked(BASE_URI, Strings.toString(_tokenId)));
        } else {
            return UNREVEALED_URI;
        }
    }
}