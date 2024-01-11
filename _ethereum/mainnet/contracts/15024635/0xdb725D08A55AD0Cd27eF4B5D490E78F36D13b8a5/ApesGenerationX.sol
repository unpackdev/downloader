// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

error ExceedMaxMint(); /// @notice Thrown when user attempts to exceed the mint limit per wallet.
error ExceedMaxSupply(); /// @notice Thrown when mint operation exceeds ApesGenerationX max supply.
error AntiBot(); /// @notice Thrown when called by a contract.
error ValueTooLow(); /// @notice Thrown when users sends wrong ETH value.
error NotTokenOwner(); /// @notice Thrown when user operates an NFT from someone else.
error NotWhitelisted(); /// @notice Thrown when user is not whitelisted.
error SaleNotStartedOrEnded(); /// @notice Thrown if the the sale has not started or have already ended.

interface IApesGenerationXToken {
    function onTokenTransfer(address from, address to) external;
}

contract ApesGenerationX is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkelRoot;

    IApesGenerationXToken public apesGenerationXToken;

    uint256 public maxSupply = 8887; //first index is 0
    uint256 public preSalePrice = 0.0 ether;
    uint256 public mintPrice = 0.0 ether;

    bool public revealed = false;

    string public baseURI;
    string public unrevealedURI;

    uint256 public preSaleStartTime;
    uint256 public saleStartTime;
    uint256 public revealStartTime;

    constructor() ERC721A("ApesGenerationX", "APE") {
        _safeMint(msg.sender, 1);
    }

    function mintPreSale(uint256 tokenAmt, bytes32[] calldata proof)
        external
        payable
    {
        if (msg.sender != tx.origin) revert AntiBot(); // Anti-bot measure

        if (msg.value < tokenAmt * preSalePrice) revert ValueTooLow();

        uint256 currentTime = block.timestamp;
        if (currentTime < preSaleStartTime || currentTime > saleStartTime)
            revert SaleNotStartedOrEnded();

        if (!isWhitelisted(msg.sender, proof)) revert NotWhitelisted();

        if (tokenAmt > 10) revert ExceedMaxMint();

        if (totalSupply() + tokenAmt > maxSupply) revert ExceedMaxSupply();

        _safeMint(msg.sender, tokenAmt);
    }

    function mint(uint256 tokenAmt) external payable {
        if (msg.sender != tx.origin) revert AntiBot(); // Anti-bot measure

        if (msg.value < tokenAmt * mintPrice) revert ValueTooLow();

        uint256 currentTime = block.timestamp;
        if (saleStartTime == 0 || currentTime < saleStartTime)
            revert SaleNotStartedOrEnded();

        if (tokenAmt > 10) revert ExceedMaxMint();

        if (totalSupply() + tokenAmt > maxSupply) revert ExceedMaxSupply();

        _safeMint(msg.sender, tokenAmt);
    }

    function burnApesGenerationX(uint256 tokenId) public {
        if (msg.sender != ownerOf(tokenId)) revert NotTokenOwner();
        _burn(tokenId);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (address(apesGenerationXToken).code.length != 0)
            apesGenerationXToken.onTokenTransfer(from, to);
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setTimeConfig(
        uint256 _preSaleStartTime,
        uint256 _saleStartTime,
        uint256 _revealStartTime
    ) external onlyOwner {
        preSaleStartTime = _preSaleStartTime;
        saleStartTime = _saleStartTime;
        revealStartTime = _revealStartTime;
    }

    function setPreSaleMintPrice(uint256 _price) external onlyOwner {
        preSalePrice = _price;
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function setMerkelRoot(bytes32 _merkelRoot) external onlyOwner {
        merkelRoot = _merkelRoot;
    }

    function setApesGenerationXToken(address _apesGenerationX)
        public
        onlyOwner
    {
        apesGenerationXToken = IApesGenerationXToken(_apesGenerationX);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setUnrevealedURI(string memory newUnrevealedURI) public onlyOwner {
        unrevealedURI = newUnrevealedURI;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        uint256 currentTime = block.timestamp;
        if (
            revealStartTime == 0 ||
            currentTime < revealStartTime ||
            bytes(baseURI).length == 0
        ) return unrevealedURI;
        else return string(abi.encodePacked(baseURI, id.toString(), ".json"));
    }

    function isWhitelisted(address user, bytes32[] calldata proof)
        public
        view
        returns (bool)
    {
        bytes32 sender = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(proof, merkelRoot, sender);
    }
}
