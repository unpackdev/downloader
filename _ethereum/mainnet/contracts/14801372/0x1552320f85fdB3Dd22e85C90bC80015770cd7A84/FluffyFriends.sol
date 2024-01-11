// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract FluffyFriends is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;
    uint256 public immutable maxPerTx;

    constructor(uint256 maxBatchSize_, uint256 collectionSize_)
        ERC721A("FluffyFriends", "FF", maxBatchSize_, collectionSize_)
    {
        maxPerTx = maxBatchSize_;
    }

    uint256 public constant PRICE = 0.025 ether;
    uint256 public constant MAX_PER_WALLET = 90;
    uint256 public devPoolRemaining = 210;

    modifier noContracts() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier reduceDevPool(uint256 n) {
        require(n <= devPoolRemaining, "Dev pool exhausted");
        devPoolRemaining -= n;
        _;
    }

    function mint(uint256 quantity) external payable noContracts {
        require(mintEnabled, "Minting has not started yet");
        require(
            totalSupply() + quantity <= collectionSize,
            "No more friends to adopt"
        );
        require(
            numberMinted(msg.sender) + quantity <= MAX_PER_WALLET,
            "Address cannot hold this many tokens"
        );
        require(quantity <= maxPerTx, "Max per TX reached.");
        require(msg.value == quantity * PRICE, "Please send the exact amount.");
        _safeMint(msg.sender, quantity);
    }

    function freeHugsMint(uint256 quantity) external noContracts {
        require(mintEnabled, "Minting has not started yet");
        require(
            totalSupply() + quantity <= collectionSize,
            "No more friends to adopt"
        );
        require(
            numberMinted(msg.sender) + quantity <= MAX_PER_WALLET,
            "Address cannot hold this many tokens"
        );
        require(quantity <= maxPerTx, "Max per TX reached");
        require(quantity <= freeHugs, "Not enough free hugs left");

        freeHugs -= quantity;
        _safeMint(msg.sender, quantity);
    }

    /**
    @dev Allow dev team to set total number of free hugs (free mints)
     */

    uint256 public freeHugs = 1000;

    function setFreeHugs(uint256 _freeHugs) external onlyOwner {
        freeHugs = _freeHugs;
    }

    /**
    @notice Whether minting is currently allowed.
    @dev If false then minting is disabled
     */
    bool public mintEnabled = false;

    function openMinting(bool open) external onlyOwner {
        mintEnabled = open;
    }

    /**
    @notice Allow for a dev mint
    @dev These are not reserved so will need to be minted before supply is up
     */
    function devMint(uint256 quantity)
        external
        onlyOwner
        reduceDevPool(quantity)
    {
        require(
            quantity % maxBatchSize == 0,
            "can only mint a multiple of the maxBatchSize"
        );
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
    }

    // metadata URI
    string private _baseTokenURI;

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
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    // Other/Util
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}
