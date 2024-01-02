// SPDX-License-Identifier: MIT

//          █████╗ ██████╗ ██╗   ██╗████████╗ █████╗     ███████╗ ██████╗ ██╗   ██╗██████╗
//         ██╔══██╗██╔══██╗██║   ██║╚══██╔══╝██╔══██╗    ██╔════╝██╔═══██╗██║   ██║██╔══██╗
//         ███████║██████╔╝██║   ██║   ██║   ███████║    ███████╗██║   ██║██║   ██║██████╔╝
//         ██╔══██║██╔══██╗██║   ██║   ██║   ██╔══██║    ╚════██║██║   ██║██║   ██║██╔═══╝
//         ██║  ██║██║  ██║╚██████╔╝   ██║   ██║  ██║    ███████║╚██████╔╝╚██████╔╝██║
//         ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝    ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝
//
//                                             ██╗  ██╗
//                                             ╚██╗██╔╝
//                                              ╚███╔╝
//                                              ██╔██╗
//                                             ██╔╝ ██╗
//                                             ╚═╝  ╚═╝
//
//  █████╗ ██╗██████╗     ███████╗███╗   ███╗ ██████╗ ██╗  ██╗███████╗    ███████╗███████╗██████╗  ██████╗
// ██╔══██╗██║██╔══██╗    ██╔════╝████╗ ████║██╔═══██╗██║ ██╔╝██╔════╝    ╚══███╔╝██╔════╝██╔══██╗██╔═══██╗
// ███████║██║██████╔╝    ███████╗██╔████╔██║██║   ██║█████╔╝ █████╗        ███╔╝ █████╗  ██████╔╝██║   ██║
// ██╔══██║██║██╔══██╗    ╚════██║██║╚██╔╝██║██║   ██║██╔═██╗ ██╔══╝       ███╔╝  ██╔══╝  ██╔══██╗██║   ██║
// ██║  ██║██║██║  ██║    ███████║██║ ╚═╝ ██║╚██████╔╝██║  ██╗███████╗    ███████╗███████╗██║  ██║╚██████╔╝
// ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝    ╚══════╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝    ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝

pragma solidity ^0.8.13;

import "./ERC721AQueryableUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./RevokableDefaultOperatorFiltererUpgradeable.sol";
import "./RevokableOperatorFiltererUpgradeable.sol";
import "./IERC4906.sol";

contract Aruta_Soup_ASZ is
    IERC4906,
    Initializable,
    UUPSUpgradeable,
    ERC721AQueryableUpgradeable,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    ReentrancyGuardUpgradeable,
    RevokableDefaultOperatorFiltererUpgradeable
{
    using StringsUpgradeable for uint256;

    string private _baseTokenURI;

    uint256 public maxSupply;
    uint256 public price;

    bytes32 private _merkleRoot;

    bool public isPreActive;

    mapping(address => uint256) private _amountMinted;

    event MintAmount(
        uint256 _mintAmountLeft,
        uint256 _totalSupply,
        address _minter
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            totalMinted() + _mintAmount <= maxSupply,
            "Must mint within max supply"
        );
        require(_mintAmount > 0, "Must mint at least 1");
        _;
    }

    modifier saleCompliance(uint256 _mintAmount, uint256 _maxMintableAmount) {
        require(isPreActive, "The sale is not Active yet");
        address _sender = _msgSender();
        require(
            _mintAmount <= _maxMintableAmount - _amountMinted[_sender],
            "Insufficient mints left"
        );
        require(
            msg.value == price * _mintAmount,
            "The mint price is not right"
        );
        _;
    }

    function initialize(
        uint256 _maxSupply,
        uint256 _price,
        string memory baseTokenURI_,
        bytes32 merkleRoot_
    ) public initializerERC721A initializer {
        __ERC721A_init("ASZ", "ASZ");
        __ERC721AQueryable_init();
        __ERC2981_init();
        __Ownable_init();
        __RevokableDefaultOperatorFilterer_init();
        __UUPSUpgradeable_init();
        setRoyaltyInfo(_msgSender(), 750); // 750 == 7.5%
        maxSupply = _maxSupply;
        price = _price;
        _baseTokenURI = baseTokenURI_;
        _merkleRoot = merkleRoot_;
    }

    receive() external payable {}

    function ownerMint(
        address _to,
        uint256 _mintAmount
    ) external onlyOwner mintCompliance(_mintAmount) {
        _safeMint(_to, _mintAmount);
    }

    function airdrop(
        address[] memory _toList,
        uint256[] memory _amountList
    ) external onlyOwner {
        require(_toList.length == _amountList.length, "Invalid array length");
        uint256 maxCount = _toList.length;
        for (uint256 i = 0; i < maxCount; ) {
            _safeMint(_toList[i], _amountList[i]);
            unchecked {
                ++i;
            }
        }
    }

    function preMint(
        uint256 _mintAmount,
        uint256 _maxMintableAmount,
        bytes32[] calldata _merkleProof
    )
        external
        payable
        mintCompliance(_mintAmount)
        saleCompliance(_mintAmount, _maxMintableAmount)
    {
        address to = _msgSender();
        require(
            _verify(to, _maxMintableAmount, _merkleProof),
            "Invalid Merkle Proof"
        );

        unchecked {
            _amountMinted[to] += _mintAmount;
        }

        _safeMint(to, _mintAmount);

        uint256 mintAmountLeft;
        unchecked {
            mintAmountLeft = _maxMintableAmount - _amountMinted[to];
        }
        emit MintAmount(mintAmountLeft, totalMinted(), to);
    }

    function burn(uint256 _tokenId) public nonReentrant {
        require(_msgSender() == ownerOf(_tokenId), "Invalid owner");
        _burn(_tokenId);
    }

    function togglePreActive() external onlyOwner {
        isPreActive = !isPreActive;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "withdraw is failed!!");
    }

    function mintableAmount(
        address _address,
        uint256 _maxMintableAmount,
        bytes32[] calldata _merkleProof
    ) external view returns (uint256) {
        if (
            _verify(_address, _maxMintableAmount, _merkleProof) &&
            _amountMinted[_address] < _maxMintableAmount
        ) return _maxMintableAmount - _amountMinted[_address];
        else return 0;
    }

    function amountMinted(address _address) external view returns (uint256) {
        return _amountMinted[_address];
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function owner()
        public
        view
        virtual
        override(OwnableUpgradeable, RevokableOperatorFiltererUpgradeable)
        returns (address)
    {
        return OwnableUpgradeable.owner();
    }

    function setBaseTokenURI(string memory _newTokenURI) public onlyOwner {
        _baseTokenURI = _newTokenURI;
        emit BatchMetadataUpdate(_startTokenId(), totalMinted());
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setMerkleProof(bytes32 _newMerkleRoot) public onlyOwner {
        _merkleRoot = _newMerkleRoot;
    }

    function setRoyaltyInfo(
        address _receiver,
        uint96 _royaltyFee
    ) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFee);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _authorizeUpgrade(
        address _newImplementation
    ) internal override onlyOwner {}

    function _verify(
        address _address,
        uint256 _maxMintableAmount,
        bytes32[] calldata _merkleProof
    ) private view returns (bool) {
        bytes32 leaf = keccak256(
            abi.encodePacked(_address, _maxMintableAmount.toString())
        );

        return MerkleProofUpgradeable.verify(_merkleProof, _merkleRoot, leaf);
    }
}
