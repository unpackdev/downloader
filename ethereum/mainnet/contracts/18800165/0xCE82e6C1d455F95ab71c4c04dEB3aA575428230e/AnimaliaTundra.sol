// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// aaaaaaaaaaaaaaaaaaaaaaam maaaaaaaaaaaaaaaaaaaaaaa
// aaaaaaaaaaaaaaaaaaaaaaa   maaaaaaaaaaaaaaaaaaaaaa
// aaaaaaaaaaaaaaaaaaaaaai   iaaaaaaaaaaaaaaaaaaaaaa
// aaaaaaaaaaaaaaaaaaaaai     iaaaaaaaaaaaaaaaaaaaaa
// aaaaaaaaaaaaaaaaaaaan       laaaaaaaaaaaaaaaaaaaa
// aaaaaaaaaaaaaaaaaaam         maaaaaaaaaaaaaaaaaaa
// aaaaaaaaaaaaaaaaaam   i   i   maaaaaaaaaaaaaaaaaa
// aaaaaaaaaaaaaaaaaai   m   m   iaaaaaaaaaaaaaaaaaa
// aaaaaaaaaaaaaaaaai   ma   am   iaaaaaaaaaaaaaaaaa
// aaaaaaaaaaaaaaaai   naa   aan   iaaaaaaaaaaaaaaaa
// aaaaaaaaaaaaaaan   iaaa   aaai   naaaaaaaaaaaaaaa
// aaaaaaaaaaaaaam   iaaaa   aaaai   maaaaaaaaaaaaaa
// aaaaaaaaaaaaaa    aami     imaai   maaaaaaaaaaaaa
// aaaaaaaaaaaaai   mni         inm   iaaaaaaaaaaaaa
// aaaaaaaaaaaai   i    la   aii   i   iaaaaaaaaaaaa
// aaaaaaaaaaan      imaaa   aaami      naaaaaaaaaaa
// aaaaaaaaaam     imaaaaa   aaaaaai     maaaaaaaaaa
// aaaaaaaaam    naaaaaaaa   aaaaaaaani   maaaaaaaaa
// aaaaaaaaai   maaaaaaaaa   aaaaaaaaam    aaaaaaaaa
// aaaaaaaai   maaaaaaaaaa   aaaaaaaaaam   iaaaaaaaa
// aaaaaaal   laaaaaaaaali   ilaaaaaaaaan   iaaaaaaa
// aaaaaam   iaaaaaaami         imaaaaaaai   naaaaaa
// aaaaam   iaaaaaani   im   mi   inaaaaaai   maaaaa
// aaaaa    aaaami   inaaa   aaani   imaaaai   maaaa
// aaaai   maani   imaaaaa   aaaaami   inaam   iaaaa
// aaai   nmi   inaaaaaaaa   aaaaaaaani   imn   iaaa
// aan   ii   imaaaaaaaaaa   aaaaaaaaaami   ii   naa
// am      ilaaaaaaaaaaaaa   aaaaaaaaaaaaani      ma
// m       iiiiiiiiiiiiiii   iiiiiiiiiiiiiii       m
// i                                               i
// aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
// aaaaaaaaaaaaa  ANIMALIA TUNDRA NFT  aaaaaaaaaaaaa
// aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

import "./ERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Royalty.sol";

/// @custom:security-contact security@animalia.games
contract AnimaliaTundra is
    ERC721,
    ERC721Enumerable,
    ERC721Royalty,
    Ownable,
    ReentrancyGuard
{
    uint256 private _nextTokenId;

    string private _name;
    string private _symbol;
    string private baseURI;

    mapping(address => uint256) public minted;
    uint256 public maxSupply;
    uint256 public whitelistMintFee;
    uint256 public publicMintFee;
    address public mintFeeReceiver;
    bytes32 public whitelistMerkleRoot;

    bool public whitelistMintActive;
    bool public publicMintActive;
    uint8 public mintCap = 2;

    function _canMint(uint256 quantity) internal view {
        require(totalSupply() <= maxSupply, "REACHED_MAX_SUPPLY");
        require(quantity > 0, "QUANTITY_LESS_THAN_ONE");
        require(
            totalSupply() + quantity <= maxSupply,
            "QUANTITY_EXCEEDED_MAX_SUPPLY"
        );
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address _mintFeeReceiver,
        uint256 _whitelistMintFee,
        uint256 _publicMintFee,
        uint256 _maxSupply,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        baseURI = baseURI_;
        mintFeeReceiver = _mintFeeReceiver;
        whitelistMintFee = _whitelistMintFee;
        publicMintFee = _publicMintFee;
        maxSupply = _maxSupply;
        _setDefaultRoyalty(royaltyReceiver, royaltyFeeNumerator);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setName(string memory name_) external onlyOwner {
        _name = name_;
    }

    function setSymbol(string memory symbol_) external onlyOwner {
        _symbol = symbol_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function batchMint(address to, uint256 quantity) internal {
        for (uint256 i = 0; i < quantity; i++) {
            // skip 0
            uint256 tokenId = ++_nextTokenId;
            _safeMint(to, tokenId);
        }
        minted[to] += quantity;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setWhitelistMintFee(uint256 _whitelistMintFee) external onlyOwner {
        whitelistMintFee = _whitelistMintFee;
    }

    function setPublicMintFee(uint256 _publicMintFee) external onlyOwner {
        publicMintFee = _publicMintFee;
    }

    function setMintFeeReceiver(address mintFeeReceiver_) external onlyOwner {
        mintFeeReceiver = mintFeeReceiver_;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function setWhitelistMintActive(
        bool _whitelistMintActive
    ) external onlyOwner {
        whitelistMintActive = _whitelistMintActive;
    }

    function setPublicMintActive(bool _publicMintActive) external onlyOwner {
        publicMintActive = _publicMintActive;
    }

    function setMintCap(uint8 _mintCap) external onlyOwner {
        mintCap = _mintCap;
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function renounceOwnership() public view override onlyOwner {
        revert("FUNCTION_DISABLED");
    }

    // Custom mints
    function mintReserved(uint16 quantity) external onlyOwner {
        require(quantity <= 250, "EXCEEDS_MINT_CAP_250");
        batchMint(msg.sender, quantity);
    }

    function mintWhitelist(
        bytes32[] calldata whitelistMerkleProof,
        uint8 quantity
    ) external payable nonReentrant {
        _canMint(quantity);
        require(whitelistMintActive, "WHITELIST_MINT_INACTIVE");
        require(
            MerkleProof.verify(
                whitelistMerkleProof,
                whitelistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "INVALID_MERKLE_PROOF"
        );
        require(minted[msg.sender] + quantity <= mintCap, "REACHED_MINT_CAP");

        uint256 fee = whitelistMintFee * quantity;

        _transferInETH(fee);
        _transferOutETH(mintFeeReceiver, fee);

        batchMint(msg.sender, quantity);
    }

    function mintPublic(uint8 quantity) external payable nonReentrant {
        _canMint(quantity);
        require(publicMintActive, "PUBLIC_MINT_INACTIVE");
        require(minted[msg.sender] + quantity <= mintCap, "REACHED_MINT_CAP");

        uint256 fee = publicMintFee * quantity;

        _transferInETH(fee);
        _transferOutETH(mintFeeReceiver, fee);

        batchMint(msg.sender, quantity);
    }

    // Custom helpers
    function _transferInETH(uint256 amount) internal {
        require(msg.value >= amount, "INSUFFICIENT_ETH_RECEIVED");
    }

    function _transferOutETH(address receiver, uint256 amount) internal {
        require(amount > 0, "INVALID_AMOUNT");
        require(address(this).balance >= amount, "INSUFFICIENT_ETH_BALANCE");

        Address.sendValue(payable(receiver), amount);
    }

    // Overrides
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
