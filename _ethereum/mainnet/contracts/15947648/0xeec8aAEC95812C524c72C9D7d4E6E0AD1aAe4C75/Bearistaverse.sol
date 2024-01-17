//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./MerkleAllowlist.sol";
import "./Strings.sol";
import "./ERC721ABurnable.sol";
import "./DefaultOperatorFilterer.sol";


contract Bearistaverse is Ownable, ERC721A, MerkleAllowlist, ReentrancyGuard, ERC721ABurnable, DefaultOperatorFilterer{

    //Contract URI
    string public CONTRACT_URI = "ipfs://QmTcJUrwPpEUwUG31DU2NkuCKhkdTp4Hjwyq2BfhhEs4GR";

    mapping(address => bool) public userHasMintedAL;
    bool public REVEALED;
    string public UNREVEALED_URI = "ipfs://QmUfwYL4MyPP4aneNwAwpwJYEPsKfuiDuDREsdKhh44qZn";
    string public BASE_URI;
    bool public isPublicMintEnabled = false;
    uint public COLLECTION_SIZE = 10000;
    uint public MINT_PRICE = 0.02 ether;
    uint public MAX_BATCH_SIZE = 50;
    uint public MAX_AL_BATCH_SIZE = 3;


    constructor() ERC721A("Bearistaverse", "BEARVERSE") {}

    function teamMint(uint256 quantity, address receiver) public onlyOwner {
        //Max supply
        require(
            totalSupply() + quantity <= COLLECTION_SIZE,
            "Max collection size reached!"
        );
        //Mint the quantity
        _safeMint(receiver, quantity);
    }

    function mintAL(uint256 quantity, bytes32[] memory proof)
        public
        payable
        onlyPublicAllowlist(proof)
    {
        uint256 price = (MINT_PRICE) * quantity;
        require(!userHasMintedAL[msg.sender], "Can only mint once during public AL!");   
        require(totalSupply() + quantity <= COLLECTION_SIZE, "Max Collection Size reached!");
        require(quantity <= MAX_AL_BATCH_SIZE, "Cannot mint this quantity");
        require(msg.value >= price, "Must send enough eth for AL Mint");

        userHasMintedAL[msg.sender] = true;

        //Mint them
        _safeMint(msg.sender, quantity);
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mint(uint256 quantity)
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

    function withdrawFunds() external onlyOwner nonReentrant {
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

    function transferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable
        override (ERC721A, IERC721A)
        onlyAllowedOperator
    {
        super.safeTransferFrom(from, to, tokenId, data);
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
