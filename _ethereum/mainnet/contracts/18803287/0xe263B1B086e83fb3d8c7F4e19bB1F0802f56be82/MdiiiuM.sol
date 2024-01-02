// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./MerkleProof.sol";
import "./ERC721AQueryable.sol";
import "./ERC721A.sol";
import "./ERC2981.sol";
import "./IERC4906.sol";
import "./AccessControl.sol";

enum TicketID {
    FreeMintBlackHolderSale,
    PrimeBlackHolderSale,
    NormalBlackHolderSale,
    YellowHolderSale,
    AllowList
}

error PreMaxExceed(uint256 _presaleMax);
error MaxSupplyOver();
error NotEnoughFunds(uint256 balance);
error NotMintable();
error InvalidMerkleProof();
error AlreadyClaimedMax();
error MintAmountOver();

contract MdiiiuM is ERC721A, IERC4906, ERC721AQueryable, AccessControl, ERC2981 {
    string private constant BASE_EXTENSION = ".json";
    address private constant FUND_ADDRESS = 0x37df2D6523265a68975e2429e74E841d524b6BB9;
    address private constant DEV_ADDRESS = 0x86c06d20aACFBad1912CF2Ac398cc44E8f77E53d;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PIE_ROLE = keccak256("PIE_ROLE");

    uint256 public maxSupply = 500;
    bool public publicSale = false;
    bool public mintable = true;
    bool public renounceOwnerMintFlag = false;

    uint256 public publicCost = 0.075 ether;
    string private baseURI = "https://arweave.net/5ITAVYFQeRMT53MvTAiicUobOc2xX-sSEA5PYOGgyQw/";

    mapping(TicketID => bool) public presalePhase;
    mapping(TicketID => uint256) public presaleCost;
    mapping(TicketID => bytes32) public merkleRoot;
    mapping(uint256 => string) private metadataURI;
    mapping(TicketID => mapping(address => uint256)) public whiteListClaimed;

    constructor() ERC721A("MdiiiuM", "MDIIIUM") {
        _setDefaultRoyalty(FUND_ADDRESS, 1000);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        presaleCost[TicketID.PrimeBlackHolderSale] = 0.0325 ether;
        presaleCost[TicketID.NormalBlackHolderSale] = 0.075 ether;
        presaleCost[TicketID.YellowHolderSale] = 0.075 ether;
        presaleCost[TicketID.AllowList] = 0.075 ether;
        presalePhase[TicketID.FreeMintBlackHolderSale] = true;
        presalePhase[TicketID.PrimeBlackHolderSale] = true;
        presalePhase[TicketID.NormalBlackHolderSale] = true;
        merkleRoot[TicketID.FreeMintBlackHolderSale] = 0xd7eb1599c7d5bd69d045946cf505441a07ef0989822b215292af170b010f7f26;
        merkleRoot[TicketID.PrimeBlackHolderSale] = 0x1e33b85f58741446ae2724692e316df9b5acce4d5c3c041c0d8a4478c2e761d2;
        merkleRoot[TicketID.NormalBlackHolderSale] = 0xc4fd9cbda0fdcfc075054513bc0f7d7b285cd169aa6422ecb97b4689ae06f524;
        merkleRoot[TicketID.YellowHolderSale] = 0xd2079d0cee116d1d0ee37d166d5e46f8b7aebeb42e6606c84aa2467cca75bef1;
        merkleRoot[TicketID.AllowList] = 0x02e5f8f5d895f0a51b1fea5feef2a3f7fa83cc31b2fc964d07b02c0cc51b0027;
    }

    modifier whenMintable() {
        if (mintable == false) revert NotMintable();
        _;
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (bytes(metadataURI[tokenId]).length == 0) {
            return string(abi.encodePacked(ERC721A.tokenURI(tokenId), BASE_EXTENSION));
        } else {
            return metadataURI[tokenId];
        }
    }

    function setTokenMetadataURI(uint256 tokenId, string memory metadata) external onlyRole(DEFAULT_ADMIN_ROLE) {
        metadataURI[tokenId] = metadata;
        emit MetadataUpdate(tokenId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRoot(bytes32 _merkleRoot, TicketID ticket) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRoot[ticket] = _merkleRoot;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxSupply = _maxSupply;
    }

    function publicMint(address _to, uint256 _mintAmount) external payable whenMintable {
        if (_totalMinted() + _mintAmount > maxSupply) revert MaxSupplyOver();
        if (msg.value < publicCost * _mintAmount) revert NotEnoughFunds(msg.value);
        if (!publicSale) revert NotMintable();

        _mint(_to, _mintAmount);
    }

    function preMint(uint256 _mintAmount, uint256 _presaleMax, bytes32[] calldata _merkleProof, TicketID ticket) external payable whenMintable {
        _preMint(_mintAmount, _presaleMax, _merkleProof, msg.sender, ticket);
    }

    function _preMint(uint256 _mintAmount, uint256 _presaleMax, bytes32[] calldata _merkleProof, address _recipient, TicketID ticket) internal {
        if (_totalMinted() + _mintAmount > maxSupply) revert MaxSupplyOver();
        if (msg.value < presaleCost[ticket] * _mintAmount) revert NotEnoughFunds(msg.value);
        if (!presalePhase[ticket]) revert NotMintable();
        bytes32 leaf = keccak256(abi.encodePacked(_recipient, _presaleMax));
        if (whiteListClaimed[ticket][_recipient] + _mintAmount > _presaleMax) revert AlreadyClaimedMax();
        if (!MerkleProof.verifyCalldata(_merkleProof, merkleRoot[ticket], leaf)) revert InvalidMerkleProof();

        _mint(_recipient, _mintAmount);
        whiteListClaimed[ticket][_recipient] += _mintAmount;
    }

    function mintPie(uint256 _mintAmount, uint256 _presaleMax, bytes32[] calldata _merkleProof, address _recipient, TicketID ticket) external payable whenMintable onlyRole(PIE_ROLE) {
        _preMint(_mintAmount, _presaleMax, _merkleProof, _recipient, ticket);
    }

    function ownerMint(address _address, uint256 count) external onlyRole(MINTER_ROLE) {
        require(!renounceOwnerMintFlag, "owner mint renounced");
        _safeMint(_address, count);
    }

    function setPresalePhase(bool _state, TicketID ticket) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presalePhase[ticket] = _state;
    }

    function setPresaleCost(uint256 _cost, TicketID ticket) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presaleCost[ticket] = _cost;
    }

    function setPublicCost(uint256 _publicCost) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicCost = _publicCost;
    }

    function setPublicPhase(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicSale = _state;
    }

    function setMintable(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintable = _state;
    }

    function setBaseURI(string memory _newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _newBaseURI;
        emit BatchMetadataUpdate(_startTokenId(), totalSupply());
    }

    function withdrawToDev(uint256 _amount) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(DEV_ADDRESS).transfer(_amount);
    }

    function withdraw() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(FUND_ADDRESS).transfer(address(this).balance);
    }

    function renounceOwnerMint() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        renounceOwnerMintFlag = true;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A, ERC2981, AccessControl) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}
