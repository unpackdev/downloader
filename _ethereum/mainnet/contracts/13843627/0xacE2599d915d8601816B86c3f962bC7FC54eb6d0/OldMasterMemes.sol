// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Frames.sol";

/**
 * @title OldMasterMemes contract
 */
contract OldMasterMemes is ERC721Enumerable, ERC721URIStorage, Ownable {
    string public provenanceHash = "";
    uint256 public maxOmm;
    uint256 public maxOmmPresale;
    bool public metadataFrozen;
    bool public provenanceFrozen;

    uint256 public mintIndex;

    string public baseUri;
    bool public burnIsActive;
    bool public saleIsActive;
    bool public presaleIsActive;
    uint256 public mintPricePresale;
    uint256 public mintPrice;
    uint256 public mintInterval;
    uint256 public maxPerMint;
    uint256 public maxPerUser;
    address public presaleSigner;

    bool public revealed;
    string public unrevealedTokenUri;

    mapping(address => uint256) public lastPurchase;
    mapping(bytes32 => bool) public usedLink;

    Frames public framesContract;

    event SetBaseUri(string indexed baseUri);

    modifier whenBurnIsActive() {
        require(burnIsActive, "OldMasterMemes: Burn is not active");
        _;
    }

    modifier whenSaleIsActive() {
        require(saleIsActive, "OldMasterMemes: Sale is not active");
        _;
    }

    modifier whenPresaleIsActive() {
        require(presaleIsActive, "OldMasterMemes: Presale is not active");
        _;
    }

    modifier whenMetadataIsNotFrozen() {
        require(!metadataFrozen, "OldMasterMemes: Metadata already frozen");
        _;
    }

    modifier whenProvenanceIsNotFrozen() {
        require(!provenanceFrozen, "OldMasterMemes: Provenance already frozen");
        _;
    }

    constructor() ERC721("Old Master Memes", "OMM") {
        burnIsActive = false;
        saleIsActive = false;
        presaleIsActive = false;
        maxOmm = 10000;
        maxOmmPresale = 6150;
        mintPricePresale = 69000000000000000; // 0.069 ETH
        mintPrice = 80000000000000000; // 0.08 ETH
        mintInterval = 172800;
        maxPerMint = 5;
        maxPerUser = 20;
        metadataFrozen = false;
        provenanceFrozen = false;
        revealed = false;
    }

    // ------------------
    // Explicit overrides
    // ------------------

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721URIStorage, ERC721) returns (string memory) {
        if (revealed) {
            return super.tokenURI(tokenId);
        } else {
            return unrevealedTokenUri;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    // ------------------
    // Public functions
    // ------------------

    function mintOMM(uint256 amount) external payable whenSaleIsActive {
        require(amount <= maxPerMint, "OldMasterMemes: Amount exceeds max per mint");
        require(mintIndex + amount <= maxOmm, "OldMasterMemes: Purchase would exceed cap");
        require(mintPrice * amount <= msg.value, "OldMasterMemes: Ether value sent is not correct");
        require(
            lastPurchase[msg.sender] < block.timestamp - mintInterval,
            "OldMasterMemes: relax and wait a little. It will be a little while before you can mint again"
        );

        for (uint256 i = 0; i < amount; i++) {
            mintIndex += 1;
            _safeMint(msg.sender, mintIndex);
        }
        lastPurchase[msg.sender] = block.timestamp;
    }

    function presaleMintOMM(
        address wallet,
        uint256 maxAmount,
        uint256 timestamp,
        bytes memory signature,
        uint256 amount
    ) external payable whenPresaleIsActive {
        require(balanceOf(msg.sender) + amount <= maxPerUser, "OldMasterMemes: Amount exceeds max presale amount per user");
        require(amount <= maxAmount, "OldMasterMemes: Amount exceeds max");
        require(mintIndex + amount <= maxOmmPresale, "OldMasterMemes: Purchase would exceed presale cap");
        require(mintPricePresale * amount <= msg.value, "OldMasterMemes: Ether value sent is not correct");
        require(msg.sender == wallet, "OldMasterMemes: Wallet from signature does not match message sender");
        require(_verifySignature(wallet, maxAmount, timestamp, signature), "OldMasterMemes: Invalid signature");
        bytes32 linkHash = keccak256(signature);
        require(!usedLink[linkHash], "OldMasterMemes: The presale link has already been used. Please request a new one");

        for (uint256 i = 0; i < amount; i++) {
            mintIndex += 1;
            _safeMint(msg.sender, mintIndex);
        }
        usedLink[linkHash] = true;
    }

    function burnForFrames(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "OldMasterMemes: Only the owner is allowed to burn his token");
        _burn(tokenId);
        framesContract.mintFrames(msg.sender);
    }

    function burn(uint256 tokenId) external whenBurnIsActive {
        require(ownerOf(tokenId) == msg.sender, "OldMasterMemes: Only the owner is allowed to burn his token");
        _burn(tokenId);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(owner, index);
            }
            return result;
        }
    }

    // ------------------
    // Owner functions
    // ------------------

    function setMaxPerMint(uint256 _maxPerMint) external onlyOwner {
        maxPerMint = _maxPerMint;
    }

    function setMintPricePresale(uint256 _mintPricePresale) external onlyOwner {
        mintPricePresale = _mintPricePresale;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMintInterval(uint256 _mintInterval) external onlyOwner {
        mintInterval = _mintInterval;
    }

    function setMaxPerUser(uint256 _maxPerUser) external onlyOwner {
        maxPerUser = _maxPerUser;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner whenMetadataIsNotFrozen {
        baseUri = _baseUri;
        emit SetBaseUri(baseUri);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner whenMetadataIsNotFrozen {
        super._setTokenURI(tokenId, _tokenURI);
    }

    function setPresaleSigner(address _presaleSigner) external onlyOwner {
        presaleSigner = _presaleSigner;
    }

    function mintForCommunity(address to, uint256 numberOfTokens) external onlyOwner {
        require(to != address(0), "OldMasterMemes: Cannot mint to zero address");
        require(mintIndex + numberOfTokens <= maxOmm, "OldMasterMemes: Minting would exceed cap");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            mintIndex += 1;
            _safeMint(to, mintIndex);
        }
    }

    function setProvenanceHash(string memory _provenanceHash) external onlyOwner whenProvenanceIsNotFrozen {
        provenanceHash = _provenanceHash;
    }

    function setFramesContract(Frames _framesContract) external onlyOwner {
        framesContract = _framesContract;
    }

    function setMaxOmmPresale(uint256 _maxOmmPresale) external onlyOwner {
        maxOmmPresale = _maxOmmPresale;
    }

    function setUnrevealedTokenUri(string memory _unrevealedTokenUri) external onlyOwner whenMetadataIsNotFrozen {
        unrevealedTokenUri = _unrevealedTokenUri;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function toggleBurnState() external onlyOwner {
        burnIsActive = !burnIsActive;
    }

    function toggleSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function togglePresaleState() external onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    function withdraw(
        address mainShareholder1,
        address mainShareholder2,
        address fivePercentShareholder1,
        address onePercentShareholder1,
        address onePercentShareholder2
    ) external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 fivePercentShare = (balance * 5) / 100;
        payable(fivePercentShareholder1).transfer(fivePercentShare);
        uint256 onePercentShare = balance / 100;
        payable(onePercentShareholder1).transfer(onePercentShare);
        payable(onePercentShareholder2).transfer(onePercentShare);
        uint256 restShare = (balance - fivePercentShare - 2 * onePercentShare) / 2;
        payable(mainShareholder1).transfer(restShare);
        payable(mainShareholder2).transfer(restShare);
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function emergencyRecoverTokens(
        IERC20 token,
        address receiver,
        uint256 amount
    ) external onlyOwner {
        require(receiver != address(0), "Cannot recover tokens to the 0 address");
        token.transfer(receiver, amount);
    }

    function freezeMetadata() external onlyOwner whenMetadataIsNotFrozen {
        metadataFrozen = true;
    }

    function freezeProvenance() external onlyOwner whenProvenanceIsNotFrozen {
        provenanceFrozen = true;
    }

    // ------------------
    // Internal functions
    // ------------------

    function _splitSignature(bytes memory signature)
        private
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
        assembly {
            sigR := mload(add(signature, 32))
            sigS := mload(add(signature, 64))
            sigV := byte(0, mload(add(signature, 96)))
        }
        return (sigV, sigR, sigS);
    }

    /**
     * Restores the signer of the signed message and checks if it was signed by the trusted signer and also
     * contains the parameters.
     */
    function _verifySignature(
        address wallet,
        uint256 maxAmount,
        uint256 timestamp,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
        (sigV, sigR, sigS) = _splitSignature(signature);
        bytes32 message = keccak256(abi.encodePacked(wallet, maxAmount, timestamp));
        return presaleSigner == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message)), sigV, sigR, sigS);
    }
}
