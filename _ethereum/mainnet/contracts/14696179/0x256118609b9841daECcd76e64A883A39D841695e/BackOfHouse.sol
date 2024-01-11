//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./MerkleWhitelist.sol";
import "./Strings.sol";

contract BackOfHouse is Ownable, ERC721A, ReentrancyGuard{

    //Contract URI
    string public CONTRACT_URI =
        "ipfs://QmZUuZ2LmCVJXbr5YT7Am8uFueDQekAmNm9hAeJyAdeisE";   //should link to the contract.json file

    bool public REVEALED;
    string public UNREVEALED_URI = "ipfs://QmUEoNxtEhtPPDhnvwnJvHKhP2s51GcMag6rE48sgGUCyW";  
    string public BASE_URI;
    bool public isPublicMintEnabled = false;  //Note: this controls public mint, whitelist mint is controlled by setting root hash on Merkle tree
    uint16 public COLLECTION_SIZE = 100;
    uint256 public MINT_PRICE = 0.1 ether;
    uint16 public MAX_BATCH_SIZE = 8;


    constructor() ERC721A("BackOfHouse", "BOH") {}

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
        require(totalSupply() + quantity <= COLLECTION_SIZE, "Max Collection Size reached!");
        require(quantity <= MAX_BATCH_SIZE, "Tried to mint quanity over limit, retry with reduced quantity");
        require(msg.value >= price, "Must send enough eth for public mint");
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