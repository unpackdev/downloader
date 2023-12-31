// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";

error CommunitySaleNotActive();
error WhitelistSaleNotActive();
error PublicSaleNotActive();
error InvalidSaleStateForCommunity();
error InvalidSaleStateForWhitelist();
error InvalidSaleStateForPublic();
error InvalidAmountForCommunitySale(uint256 amount);
error InvalidAmountForWhitelistSale(uint256 amount);
error InvalidAmountForPublicSale(uint256 amount);
error IncorrectEtherSent();
error NoMoreTokenForCommunitySale(uint256 amount);
error NoMoreTokenToMint(uint256 amount);
error InvalidMerkleProof();
error FailedToSendEther();

contract Animental is ERC2981, ERC721A, Ownable {
    string public baseURI;

    bool public isCommunitySaleActive = false;
    bool public isWhitelistSaleActive = false;
    bool public isPublicSaleActive = false;

    mapping(address => uint256) public communityMints;
    mapping(address => uint256) public whitelistMints;
    mapping(address => uint256) public publicMints;

    uint256 public whitelistMintPrice = 0.008 ether;
    uint256 public publicMintPrice = 0.01 ether;

    bytes32 public communityMerkleRoot;
    bytes32 public whitelistMerkleRoot;

    uint256 public maxCommunityMintPerAddress = 1;
    uint256 public maxWhitelistMintPerAddress = 3;
    uint256 public maxPublicMintPerAddress = 3;

    uint256 public communitySupply = 2000;
    uint256 public maxSupply = 8000;

    constructor(string memory _newBaseURI) ERC721A("ANIMENTALS", "ANIM") {
        baseURI = _newBaseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function toggleCommunitySale() public onlyOwner {
        if (isWhitelistSaleActive || isPublicSaleActive) {
            revert InvalidSaleStateForCommunity();
        }
        isCommunitySaleActive = !isCommunitySaleActive;
    }

    function toggleWhitelistSale() public onlyOwner {
        if (isCommunitySaleActive || isPublicSaleActive) {
            revert InvalidSaleStateForWhitelist();
        }
        isWhitelistSaleActive = !isWhitelistSaleActive;
    }

    function togglePublicSale() public onlyOwner {
        if (isCommunitySaleActive || isWhitelistSaleActive) {
            revert InvalidSaleStateForPublic();
        }
        isPublicSaleActive = !isPublicSaleActive;
    }

    function setWhitelistMintPrice(uint256 _newPrice) public onlyOwner {
        whitelistMintPrice = _newPrice;
    }

    function setPublicMintPrice(uint256 _newPrice) public onlyOwner {
        publicMintPrice = _newPrice;
    }

    function setCommunityMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        communityMerkleRoot = _merkleRoot;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function setMaxCommunityMintPerAddress(uint256 _newMax) public onlyOwner {
        maxCommunityMintPerAddress = _newMax;
    }

    function setMaxWhitelistMintPerAddress(uint256 _newMax) public onlyOwner {
        maxWhitelistMintPerAddress = _newMax;
    }

    function setMaxPublicMintPerAddress(uint256 _newMax) public onlyOwner {
        maxPublicMintPerAddress = _newMax;
    }

    function setCommunitySupply(uint256 _newSupply) public onlyOwner {
        communitySupply = _newSupply;
    }

    function setTotalSupply(uint256 _newSupply) public onlyOwner {
        maxSupply = _newSupply;
    }

    function _verifyProof(bytes32[] memory proof, bytes32 root) internal view returns (bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_msgSender()))));
        return MerkleProof.verify(proof, root, leaf);
    }

    function mintForCommunity(uint256 amount, bytes32[] calldata proof) external payable {
        if (!isCommunitySaleActive) {
            revert CommunitySaleNotActive();
        }
        if (communityMints[_msgSender()] + amount > maxCommunityMintPerAddress) {
            revert InvalidAmountForCommunitySale(amount);
        }
        if (totalSupply() + amount > communitySupply) {
            revert NoMoreTokenForCommunitySale(amount);
        }
        if (!_verifyProof(proof, communityMerkleRoot)) {
            revert InvalidMerkleProof();
        }

        _mint(_msgSender(), amount);
        communityMints[_msgSender()] += amount;
    }

    function mintForWhitelist(uint256 amount, bytes32[] calldata proof) external payable {
        if (!isWhitelistSaleActive) {
            revert WhitelistSaleNotActive();
        }
        if (whitelistMints[_msgSender()] + amount > maxWhitelistMintPerAddress) {
            revert InvalidAmountForWhitelistSale(amount);
        }
        if (totalSupply() + amount > maxSupply) {
            revert NoMoreTokenToMint(amount);
        }
        if (msg.value != whitelistMintPrice * amount) {
            revert IncorrectEtherSent();
        }
        if (!_verifyProof(proof, whitelistMerkleRoot)) {
            revert InvalidMerkleProof();
        }

        _mint(_msgSender(), amount);
        whitelistMints[_msgSender()] += amount;
    }

    function mintForPublic(uint256 amount) external payable {
        if (!isPublicSaleActive) {
            revert PublicSaleNotActive();
        }
        if (publicMints[_msgSender()] + amount > maxPublicMintPerAddress) {
            revert InvalidAmountForPublicSale(amount);
        }
        if (totalSupply() + amount > maxSupply) {
            revert NoMoreTokenToMint(amount);
        }
        if (msg.value != publicMintPrice * amount) {
            revert IncorrectEtherSent();
        }

        _mint(_msgSender(), amount);
        publicMints[_msgSender()] += amount;
    }

    function airdrop(address to, uint256 amount) external onlyOwner {
        if (totalSupply() + amount > maxSupply) {
            revert NoMoreTokenToMint(amount);
        }
        _mint(to, amount);
    }

    function withdraw(address payable _to) external onlyOwner {
        // Call returns a boolean value indicating success or failure.
        (bool sent, ) = _to.call{value: address(this).balance}("");
        if (!sent) {
            revert FailedToSendEther();
        }
    }

    // --------
    // EIP-2981
    // --------
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    // -------
    // EIP-165
    // -------
    // https://chiru-labs.github.io/ERC721A/#/migration?id=supportsinterface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}
