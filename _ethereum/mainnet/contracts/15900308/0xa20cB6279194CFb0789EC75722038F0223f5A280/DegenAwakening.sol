// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./MerkleAllowlist.sol";
import "./Strings.sol";

contract DegenAwakening is Ownable, ERC721A, MerkleAllowlist, ReentrancyGuard, ERC721ABurnable {

    string public CONTRACT_URI = "ipfs://QmY8rzEg4789wbXGqQQ19nnh3W36ZWjnD1SFVcQcRbwDiV";
    mapping(address => bool) public userHasMintedPublicAL;
    bool public REVEALED;
    string public UNREVEALED_URI = "ipfs://QmeFKpkCFpu6pW9RKC6Gnsj2eev2kxSa7pJqG1WpaCiL2e";
    string public BASE_URI;
    bool public isPublicMintEnabled = false;
    uint public COLLECTION_SIZE = 700;
    uint public MINT_PRICE = 0.03 ether;
    uint public AL_MINT_PRICE = 0.01 ether;
    uint public MAX_BATCH_SIZE = 5;
    uint public MAX_AL_BATCH_SIZE = 5;

    constructor() ERC721A("DegenAwakening", "DA") {}

    function teamMint(uint256 quantity, address receiver) public onlyOwner {
        // Max supply
        require(
            totalSupply() + quantity <= COLLECTION_SIZE,
            "Max collection size reached!"
        );
        // Mint the quantity
        _safeMint(receiver, quantity);
    }

    function mintPublicAL(uint256 quantity, bytes32[] memory proof)
        public
        payable
        onlyPublicAllowlist(proof)
    {
        uint256 price = (AL_MINT_PRICE) * quantity;
        require(!userHasMintedPublicAL[msg.sender], "Can only mint once during public AL!");   
        require(totalSupply() + quantity <= COLLECTION_SIZE, "Max collection size reached!");
        require(quantity <= MAX_AL_BATCH_SIZE, "Cannot mint this quantity");
        require(msg.value >= price, "Must send enough eth for AL Mint");

        userHasMintedPublicAL[msg.sender] = true;

        // Mint them
        _safeMint(msg.sender, quantity);
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
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
        require(totalSupply() + quantity <= COLLECTION_SIZE, "Max collection size reached!");
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

    function setALMintPrice(uint256 _mintPrice) public onlyOwner {
        AL_MINT_PRICE = _mintPrice;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        MINT_PRICE = _mintPrice;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override (ERC721A, IERC721A)
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
