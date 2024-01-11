//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

///@title BigBrainKidsV2 NFT Contract

contract BigBrainKidsV2 is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public MAX_SUPPLY = 5000;
    uint256 public maxFreeSupply = 4000;
    uint256 public mintPrice = 0.02 ether;
    uint256 public maxMintAmount = 5;
    uint256 public wlMaxMintAmount = 2;
    bytes32 public merkleRoot;
    bool public publicActive = false;
    bool public claimActive = false;
    bool public wlActive = false;

    string private _baseTokenURI;

    mapping(address => uint256) public wlMinted;

    modifier callerIsUser() {
        require(tx.origin == msg.sender);
        _;
    }

    constructor(string memory _unrevealedURI)
        ERC721A("BigBrainKidsV2", "BBKv2")
    {
        _baseTokenURI = _unrevealedURI;
    }

    //External functions

    function wlMint(uint256 quantity, bytes32[] calldata proof)
        external
        callerIsUser
    {
        require(wlActive, "whitelist mint is not active!");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "mint amount exceeds max supply!"
        );
        require(
            wlMinted[msg.sender] + quantity <= wlMaxMintAmount,
            "Cannot mint more than 2"
        );
        require(
            MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "address not whitelisted!"
        );
        wlMinted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function claim(uint256 quantity) external callerIsUser {
        require(totalSupply() <= maxFreeSupply, "no more free mints left");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "mint amount exceeds max supply!"
        );
        require(claimActive, "Free mint is not active!");
        require(
            quantity <= maxMintAmount,
            "quantity exceeds allowed mint quantity!"
        );

        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable callerIsUser {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "mint amount exceeds max supply!"
        );
        require(publicActive, "Public mint is not active!");
        require(
            quantity <= maxMintAmount,
            "quantity exceeds allowed mint quantity!"
        );
        require(msg.value == mintPrice * quantity, "ETH amount invalid!");

        _safeMint(msg.sender, quantity);
    }

    function devMint(address to, uint256 quantity) public onlyOwner {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "mint exceeds MAX_SUPPLY"
        );
        _safeMint(to, quantity);
    }

    function setPublicActive(bool b) external onlyOwner {
        publicActive = b;
        claimActive = b;
    }

    function setWlActive(bool b) external onlyOwner {
        wlActive = b;
    }

    function setMaxMintAmount(uint256 amount) external onlyOwner {
        maxMintAmount = amount;
    }

    function setWlMaxMintAmount(uint256 amount) external onlyOwner {
        wlMaxMintAmount = amount;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(0xE66DFC56Da47145aa46DB81Da2274c75278260BB)
            .call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    //Public functions

    function walletOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    //Internal functions

    function airdrop(address[] calldata accounts) internal onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _safeMint(accounts[i], 2);
        }
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}
