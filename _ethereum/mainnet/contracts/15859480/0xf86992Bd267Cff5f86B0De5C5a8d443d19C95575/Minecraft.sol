// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract Minecraft is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint;

    string private _baseTokenURI;
    uint public whitelistMintStartTime;
    uint public whitelistMintEndTime;
    uint public publicMintStartTime;
    uint public publicMintEndTime;
    bool public isRevealed;
    bytes32 public whitelistMerkleRoot;

    constructor(uint collectionSize_, string memory uri_)
        ERC721A("Minecraft", "MINECRAFT", 2000, collectionSize_)
    {
        _baseTokenURI = uri_;
        isRevealed = false;
    }

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "Minecraft: The caller is another contract"
        );
        _;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function reveal(string memory uri_) external onlyOwner {
        isRevealed = true;
        _baseTokenURI = uri_;
    }

    function setMintingSchedule(
        uint whitelistMintStartTime_,
        uint whitelistMintEndTime_,
        uint publicMintStartTime_,
        uint publicMintEndTime_
    ) external onlyOwner {
        whitelistMintStartTime = whitelistMintStartTime_;
        whitelistMintEndTime = whitelistMintEndTime_;
        publicMintStartTime = publicMintStartTime_;
        publicMintEndTime = publicMintEndTime_;
    }

    function isWhitelistMintActive() public view returns (bool) {
        return
            whitelistMintStartTime <= block.timestamp &&
            whitelistMintEndTime >= block.timestamp;
    }

    function isPublicMintActive() public view returns (bool) {
        return
            publicMintStartTime <= block.timestamp &&
            publicMintEndTime >= block.timestamp;
    }

    function devMint(address to_, uint256 quantity) external onlyOwner {
        require(to_ != address(0), "Minecraft: Invalid address");
        require(
            totalSupply() + quantity <= collectionSize,
            "Minecraft: reached max supply"
        );

        _safeMint(to_, quantity);
    }

    function mint(bytes32[] calldata merkleProof, uint256 quantity)
        external
        callerIsUser
    {
        uint allowMintNum = 0;

        if (isWhitelistMintActive()) {
            require(
                MerkleProof.verify(
                    merkleProof,
                    whitelistMerkleRoot,
                    keccak256(abi.encodePacked(msg.sender))
                ),
                "Minecraft: address not in list"
            );
            allowMintNum = 1 - numberMinted(msg.sender);
        } else {
            require(
                isPublicMintActive(),
                "Minecraft: public mint is not active"
            );
            allowMintNum = 1 - numberMinted(msg.sender);
        }

        require(
            totalSupply() + quantity <= collectionSize,
            "Minecraft: reached max supply"
        );
        require(quantity <= allowMintNum, "Minecraft: can not mint this many");

        _safeMint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
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

        if (!isRevealed) {
            return string(abi.encodePacked(_baseURI(), "notRevealed.json"));
        }

        return
            string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Minecraft: Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getCollectionSize() public view returns (uint256) {
        return collectionSize;
    }

    fallback() external payable {}

    receive() external payable {}
}
