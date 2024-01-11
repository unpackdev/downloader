// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

error PublicNotActive();
error PresaleNotActive();
error MintLimitExceeded();
error MintSupplyExceeded();
error IncorrectPrice();
error WrongMerkleProof();

contract RISE is ERC721A, Ownable, ReentrancyGuard {
    using MerkleProof for bytes32[];

    uint256 public constant teamAmt = 75;
    uint256 public teamMinted = 0;
    uint256 public constant collectionSize = 1000;
    string private _baseTokenURI;
    address public immutable proxyRegistryAddress;
    bool public proxyToggle = true;

    struct SaleConfig {
        uint48 presaleStartTime;
        uint48 publicStartTime;
        uint64 mintPrice;
        uint64 mintLimit;
        bytes32 merkleRoot;
    }

    SaleConfig public saleConfig;

    constructor(address _proxyRegistryAddress, bytes32 _merkleRoot) ERC721A('RISE Pass', 'RISEPASS') {
        proxyRegistryAddress = _proxyRegistryAddress;
        saleConfig = SaleConfig(1652118300, 1652140800, .1999 ether, 1, _merkleRoot);
    }

    function presaleMint(bytes32[] calldata proof) external payable {
        if (!isPresaleLive() || isPublicLive()) revert PresaleNotActive();
        if (_totalMinted() - teamMinted + 1 > collectionSize) revert MintSupplyExceeded();
        if (_getAux(msg.sender) + 1 > saleConfig.mintLimit) revert MintLimitExceeded();
        if (!isWhitelisted(proof, msg.sender)) revert WrongMerkleProof();

        _setAux(msg.sender, _getAux(msg.sender) + 1); //presale minted counter
        _safeMint(msg.sender, 1);
        refundIfOver(saleConfig.mintPrice);
    }

    function publicMint() external payable {
        uint256 publicMinted = _numberMinted(msg.sender) - _getAux(msg.sender);

        if (!isPublicLive()) revert PublicNotActive();
        if (_totalMinted() - teamMinted + 1 > collectionSize) revert MintSupplyExceeded();
        if (publicMinted + 1 > saleConfig.mintLimit) revert MintLimitExceeded();

        _safeMint(msg.sender, 1);
        refundIfOver(saleConfig.mintPrice);
    }

    // For team, partnerships, giveaways, etc.
    function devMint(uint256 quantity, address account) external onlyOwner {
        if (_numberMinted(account) + quantity + teamMinted > teamAmt) revert MintLimitExceeded();
        teamMinted += quantity;
        _safeMint(msg.sender, quantity);
    }

    function refundIfOver(uint256 price) internal {
        if (msg.value < price) revert IncorrectPrice();
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function setSaleConfig(
        uint32 _presaleStartTime,
        uint32 _publicStartTime,
        uint64 _mintPrice,
        uint64 _mintLimit,
        bytes32 _merkleRoot
    ) external onlyOwner {
        saleConfig = SaleConfig(_presaleStartTime, _publicStartTime, _mintPrice, _mintLimit, _merkleRoot);
    }

    function setStartTimes(uint32 _presaleStartTime, uint32 _publicStartTime) external onlyOwner {
        saleConfig.presaleStartTime = _presaleStartTime;
        saleConfig.publicStartTime = _publicStartTime;
    }

    function isPublicLive() public view returns (bool) {
        uint256 _publicStartTime = uint256(saleConfig.publicStartTime);
        return _publicStartTime != 0 && block.timestamp >= _publicStartTime;
    }

    function isPresaleLive() public view returns (bool) {
        uint256 _presaleStartTime = uint256(saleConfig.presaleStartTime);
        return _presaleStartTime != 0 && block.timestamp >= _presaleStartTime;
    }

    function isWhitelisted(bytes32[] calldata proof, address account) internal view returns (bool) {
        return MerkleProof.verify(proof, saleConfig.merkleRoot, keccak256(abi.encodePacked(account)));
    }

    function numberPublicMinted(address addr) public view returns (uint256) {
        return _numberMinted(addr) - _getAux(addr);
    }

    function numberWhitelistMinted(address addr) public view returns (uint256) {
        return _getAux(addr);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        saleConfig.merkleRoot = _merkleRoot;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _baseURI();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        uint256 bal = address(this).balance;
        payable(0x61BD98F11E950401A5194F2FbcCDcA74580BA520).transfer((bal / 100) * 3);
        payable(0x94f2d00AE73D9887BfE68Bfc85769cDFfEBA9Cf5).transfer((bal / 100) * 12);
        payable(0xb777f1b979d7E400F66f646C44B93ABA86533Dd5).transfer((bal / 100) * 25); 
        payable(0x7a73ba4117769F718a12C2859796B82e1B17ea08).transfer(address(this).balance);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

    function setProxyToggle() external onlyOwner {
        proxyToggle = !proxyToggle;
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (proxyToggle && address(proxyRegistry.proxies(_owner)) == operator) return true;
        return super.isApprovedForAll(_owner, operator);
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
