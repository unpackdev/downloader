// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// @owner:      Kian Pauwels
// @title:      Poshera Genesis
// @url:        https://poshera.io

// __________________    _________ ___ ________________________    _____
// \______   \_____  \  /   _____//   |   \_   _____/\______   \  /  _  \
//  |     ___//   |   \ \_____  \/    ~    \    __)_  |       _/ /  /_\  \
//  |    |   /    |    \/        \    Y    /        \ |    |   \/    |    \
//  |____|   \_______  /_______  /\___|_  /_______  / |____|_  /\____|__  /
//                   \/        \/       \/        \/         \/         \/

import "./ERC721A.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./MerkleProof.sol";

contract PosheraGenesis is
    ERC721A,
    AccessControl,
    Ownable,
    IERC2981,
    ReentrancyGuard
{
    using Address for address payable;

    // --<>-- Events --<>--

    event Nested(uint256 indexed tokenId);
    event Unnested(uint256 indexed tokenId);

    // --<>-- Supply --<>--

    uint256 public maxSupply = 555;
    uint256 public maxMintPerWallet = 1;
    mapping(address => uint256) public addressToPublicMintCount;

    // --<>-- Cost ・--<>--

    uint256 public price = 0.19 ether;

    // --<>-- Sale Status --<>--

    struct SaleStatus {
        bool poshList;
        bool reserveList;
        bool publicSale;
    }
    SaleStatus public saleStatus =
        SaleStatus({poshList: false, reserveList: false, publicSale: false});

    // --<>-- General --<>--

    string public baseTokenURI;
    uint256 private royaltyDivisor = 20;

    // --<>-- Merkle Root --<>--

    bytes32 public poshListMerkleRoot;
    bytes32 public reserveListMerkleRoot;

    // --<>-- Withdraw Addresses --<>--

    address t1 = 0x65B5Cb285d9813D5aA1DCDc6D56e98303D119D0F;

    // --<>-- Metadata Proxy --<>--

    address metadataAddress;

    // --<>-- Nesting --<>--

    mapping(uint256 => bool) public nested;
    bytes32 NEST_CONTROLLER = keccak256("NEST_CONTROLLER");

    // --<>-- Contract --<>--

    constructor(
        string memory _baseTokenURI,
        bytes32 _poshListMerkleRoot,
        bytes32 _reserveListMerkleRoot,
        uint256 _maxSupply
    ) ERC721A("Poshera Genesis", "POSHERAGENESIS") {
        baseTokenURI = _baseTokenURI;
        poshListMerkleRoot = _poshListMerkleRoot;
        reserveListMerkleRoot = _reserveListMerkleRoot;
        maxSupply = _maxSupply;

        _safeMint(msg.sender, 1);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // --<>-- Mint --<>--
    function mintPoshList(
        uint256 _amount,
        uint256 _maxAmount,
        bytes32[] calldata _proof
    ) external payable nonReentrant {
        require(saleStatus.poshList, "Sale inactive");
        require(totalSupply() + _amount <= maxSupply, "Sold out!");
        require(
            msg.value >= price * _amount,
            "Amount of ETH sent is incorrect"
        );
        require(
            _numberMinted(msg.sender) + _amount <= _maxAmount,
            "Amount must be less than or equal to whitelist allowance"
        );
        require(
            MerkleProof.verify(
                _proof,
                poshListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, _maxAmount))
            ),
            "Proof is not valid"
        );

        _mintPrivate(msg.sender, _amount);
    }

    function mintReserveList(
        uint256 _amount,
        uint256 _maxAmount,
        bytes32[] calldata _proof
    ) external payable nonReentrant {
        require(saleStatus.reserveList, "Sale inactive");
        require(totalSupply() + _amount <= maxSupply, "Sold out!");
        require(
            msg.value >= price * _amount,
            "Amount of ETH sent is incorrect"
        );
        require(
            _numberMinted(msg.sender) + _amount <= _maxAmount,
            "Amount must be less than or equal to reserve list allowance"
        );
        require(
            MerkleProof.verify(
                _proof,
                reserveListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, _maxAmount))
            ),
            "Proof is not valid"
        );

        _mintPrivate(msg.sender, _amount);
    }

    function mintPublicSale(uint256 _amount) external payable nonReentrant {
        require(saleStatus.publicSale, "Sale inactive");
        require(totalSupply() + _amount <= maxSupply, "Sold out!");
        require(
            msg.value >= price * _amount,
            "Amount of ETH sent is incorrect"
        );
        require(
            addressToPublicMintCount[msg.sender] + _amount <= maxMintPerWallet,
            "Amount must be less than or equal to public sale allowance"
        );

        addressToPublicMintCount[msg.sender] += _amount;
        _mintPrivate(msg.sender, _amount);
    }

    function mintRemaining(address _to, uint256 _amount) external onlyOwner {
        require(
            !saleStatus.poshList &&
                !saleStatus.reserveList &&
                !saleStatus.publicSale,
            "Can only mint reserves when sale is inactive"
        );
        require(totalSupply() + _amount <= maxSupply, "Sold out!");

        _mintPrivate(_to, _amount);
    }

    function _mintPrivate(address _to, uint256 _amount) internal {
        _safeMint(_to, _amount);
    }

    // --<>-- Setters --<>--

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setPoshListMerkleRoot(bytes32 _poshListMerkleRoot)
        external
        onlyOwner
    {
        poshListMerkleRoot = _poshListMerkleRoot;
    }

    function setReserveListMerkleRoot(bytes32 _reserveListMerkleRoot)
        external
        onlyOwner
    {
        reserveListMerkleRoot = _reserveListMerkleRoot;
    }

    function setMaxMintPerWallet(uint256 _maxMintPerWallet) external onlyOwner {
        maxMintPerWallet = _maxMintPerWallet;
    }

    function setSaleStatus(SaleStatus memory _saleStatus) external onlyOwner {
        saleStatus = _saleStatus;
    }

    function setRoyaltyDivisor(uint256 _divisor) external onlyOwner {
        royaltyDivisor = _divisor;
    }

    // --<>-- Getters --<>--

    function addressToPresaleMintCount(address _owner)
        external
        view
        returns (uint256)
    {
        return _numberMinted(_owner);
    }

    function checkPoshListMerkle(
        address _minter,
        uint256 _maxAmount,
        bytes32[] calldata _proof
    ) external view onlyOwner returns (bool) {
        return
            MerkleProof.verify(
                _proof,
                poshListMerkleRoot,
                keccak256(abi.encodePacked(_minter, _maxAmount))
            );
    }

    function checkReserveListMerkle(
        address _minter,
        uint256 _maxAmount,
        bytes32[] calldata _proof
    ) external view onlyOwner returns (bool) {
        return
            MerkleProof.verify(
                _proof,
                reserveListMerkleRoot,
                keccak256(abi.encodePacked(_minter, _maxAmount))
            );
    }

    // --<>-- Withdraw --<>--

    function withdraw() public onlyOwner {
        require(address(this).balance != 0, "Balance is zero");

        payable(t1).sendValue(address(this).balance);
    }

    // --<>-- Metadata Proxy --<>--

    function setMetadataAddress(address _metadataAddress) external onlyOwner {
        metadataAddress = _metadataAddress;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (address(metadataAddress) != address(0)) {
            return IERC721Metadata(metadataAddress).tokenURI(tokenId);
        }
        return super.tokenURI(tokenId);
    }

    // --<>-- Nesting --<>--

    function toggleNesting(uint256 tokenId) external onlyRole(NEST_CONTROLLER) {
        require(_exists(tokenId), "Nonexistent token");
        nested[tokenId] = !nested[tokenId];

        if (nested[tokenId]) emit Nested(tokenId);
        else emit Unnested(tokenId);
    }

    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            require(!nested[tokenId], "Nesting");
        }
    }

    // --<>-- Misc --<>--

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (address(t1), salePrice / royaltyDivisor);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
