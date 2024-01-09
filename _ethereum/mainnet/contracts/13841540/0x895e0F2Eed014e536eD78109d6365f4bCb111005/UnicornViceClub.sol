// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./ERC721PresetMinterPauserAutoId.sol";
import "./IUnicornViceClub.sol";
import "./UnicornViceClubGeneGenerator.sol";
import "./ERC2981Royalties.sol";

contract UnicornViceClub is
    IUnicornViceClub,
    ERC721PresetMinterPauserAutoId,
    ReentrancyGuard,
    ERC2981Royalties
{
    using UnicornViceClubGeneGenerator for UnicornViceClubGeneGenerator.Gene;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter internal _tokenIdTracker;
    string private _baseTokenURI;

    UnicornViceClubGeneGenerator.Gene internal geneGenerator;

    address payable public daoAddress;
    uint256 public unicornViceClubPrice;
    uint256 public unicornViceClubPresalePrice;
    uint256 public maxSupply;
    uint256 public bulkBuyLimit;

    uint256 public immutable reservedNFTsCount = 50;
    uint256 public immutable uniquesCount = 20;
    uint256 public immutable royaltyFeeBps = 527;

    event TokenMinted(uint256 indexed tokenId, uint256 newGene);
    event UnicornViceClubPriceChanged(uint256 newUnicornViceClubPrice);
    event UnicornViceClubPresalePriceChanged(uint256 newUnicornViceClubPrice);
    event MaxSupplyChanged(uint256 newMaxSupply);
    event BulkBuyLimitChanged(uint256 newBulkBuyLimit);
    event BaseURIChanged(string baseURI);
    event PresaleStartChanged(uint256 time);
    event OfficialSaleStartChanged(uint256 time);

    // Optional mapping for token URIs
    mapping(uint256 => uint256) internal _genes;
    mapping(uint256 => uint256) internal _uniqueGenes;

    // Presale configs
    uint256 public presaleStart;
    uint256 public officialSaleStart;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address payable _daoAddress,
        uint256 _unicornViceClubPrice,
        uint256 _unicornViceClubPresalePrice,
        uint256 _maxSupply,
        uint256 _bulkBuyLimit,
        uint256 _presaleStart,
        uint256 _officialSaleStart
    ) ERC721PresetMinterPauserAutoId(name, symbol, baseURI) {
        daoAddress = _daoAddress;
        unicornViceClubPrice = _unicornViceClubPrice;
        unicornViceClubPresalePrice = _unicornViceClubPresalePrice;
        maxSupply = _maxSupply;
        bulkBuyLimit = _bulkBuyLimit;
        presaleStart = _presaleStart;
        officialSaleStart = _officialSaleStart;
        geneGenerator.random();
        generateUniques();
    }

    modifier onlyDAO() {
        require(_msgSender() == daoAddress, "Not called from the dao");
        _;
    }

    function generateUniques() internal virtual {
        for (uint256 i = 1; i <= uniquesCount; i++) {
            uint256 selectedToken = (geneGenerator.random() % (maxSupply - 1)) +
                1;
            _uniqueGenes[selectedToken] = i;
        }
    }

    function isPresale() public view returns (bool) {
        return (block.timestamp > presaleStart &&
            block.timestamp < officialSaleStart);
    }

    function isSale() public view returns (bool) {
        return (block.timestamp > officialSaleStart);
    }

    function isTokenUnique(uint256 tokenId)
        public
        view
        returns (bool, uint256)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        bool isUnique;
        uint256 index;
        if (_uniqueGenes[tokenId] != 0) {
            isUnique = true;
            index = _uniqueGenes[tokenId];
        }
        return (isUnique, index);
    }

    function setGene() internal returns (uint256) {
        return geneGenerator.random();
    }

    function geneOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256 gene)
    {
        return _genes[tokenId];
    }

    function reserveMint(uint256 amount) external override onlyDAO {
        require(
            _tokenIdTracker.current().add(amount) <= maxSupply,
            "Total supply reached"
        );
        require(
            balanceOf(_msgSender()).add(amount) <= reservedNFTsCount,
            "Mint limit exceeded"
        );
        require(isPresale(), "Presale not started/already finished");

        _mint(amount);
    }

    function mint() public payable override nonReentrant {
        require(_tokenIdTracker.current() < maxSupply, "Total supply reached");
        require(!isPresale() && isSale(), "Official sale not started");

        (bool transferToDaoStatus, ) = daoAddress.call{
            value: unicornViceClubPrice
        }("");
        require(
            transferToDaoStatus,
            "Address: unable to send value, recipient may have reverted"
        );

        uint256 excessAmount = msg.value.sub(unicornViceClubPrice);
        if (excessAmount > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{
                value: excessAmount
            }("");
            require(returnExcessStatus, "Failed to return excess.");
        }
        _mint(1);
    }

    function presaleMint(uint256 amount)
        external
        payable
        override
        nonReentrant
    {
        require(
            amount <= bulkBuyLimit,
            "Cannot bulk buy more than the preset limit"
        );
        require(
            _tokenIdTracker.current().add(amount) <= maxSupply,
            "Total supply reached"
        );
        require(isPresale(), "Presale not started/already finished");

        (bool transferToDaoStatus, ) = daoAddress.call{
            value: unicornViceClubPresalePrice.mul(amount)
        }("");
        require(
            transferToDaoStatus,
            "Address: unable to send value, recipient may have reverted"
        );

        uint256 excessAmount = msg.value.sub(
            unicornViceClubPresalePrice.mul(amount)
        );
        if (excessAmount > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{
                value: excessAmount
            }("");
            require(returnExcessStatus, "Failed to return excess.");
        }
        _mint(amount);
    }

    function bulkBuy(uint256 amount) external payable override nonReentrant {
        require(
            amount <= bulkBuyLimit,
            "Cannot bulk buy more than the preset limit"
        );
        require(
            _tokenIdTracker.current().add(amount) <= maxSupply,
            "Total supply reached"
        );
        require(!isPresale() && isSale(), "Official sale not started");

        (bool transferToDaoStatus, ) = daoAddress.call{
            value: unicornViceClubPrice.mul(amount)
        }("");
        require(
            transferToDaoStatus,
            "Address: unable to send value, recipient may have reverted"
        );

        uint256 excessAmount = msg.value.sub(unicornViceClubPrice.mul(amount));
        if (excessAmount > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{
                value: excessAmount
            }("");
            require(returnExcessStatus, "Failed to return excess.");
        }
        _mint(amount);
    }

    function lastTokenId() public view override returns (uint256 tokenId) {
        return _tokenIdTracker.current();
    }

    function mint(address to)
        public
        pure
        override(ERC721PresetMinterPauserAutoId)
    {
        revert("Should not use this one");
    }

    function _mint(uint256 amount) internal {
        for (uint256 i = 0; i < amount; i++) {
            _tokenIdTracker.increment();

            uint256 tokenId = _tokenIdTracker.current();
            _genes[tokenId] = setGene();
            _mint(_msgSender(), tokenId);
            _setTokenRoyalty(tokenId, daoAddress, royaltyFeeBps);

            emit TokenMinted(tokenId, _genes[tokenId]);
        }
    }

    function setUnicornViceClubPrice(uint256 _newUnicornViceClubPrice)
        external
        virtual
        override
        onlyDAO
    {
        unicornViceClubPrice = _newUnicornViceClubPrice;

        emit UnicornViceClubPriceChanged(_newUnicornViceClubPrice);
    }

    function setUnicornViceClubPresalePrice(
        uint256 _newUnicornViceClubPresalePrice
    ) external virtual override onlyDAO {
        unicornViceClubPresalePrice = _newUnicornViceClubPresalePrice;

        emit UnicornViceClubPresalePriceChanged(
            _newUnicornViceClubPresalePrice
        );
    }

    function setMaxSupply(uint256 _maxSupply)
        external
        virtual
        override
        onlyDAO
    {
        maxSupply = _maxSupply;

        emit MaxSupplyChanged(maxSupply);
    }

    function setBulkBuyLimit(uint256 _bulkBuyLimit)
        external
        virtual
        override
        onlyDAO
    {
        bulkBuyLimit = _bulkBuyLimit;

        emit BulkBuyLimitChanged(_bulkBuyLimit);
    }

    function setBaseURI(string memory _baseURI)
        external
        virtual
        override
        onlyDAO
    {
        _baseTokenURI = _baseURI;

        emit BaseURIChanged(_baseURI);
    }

    function setOfficialSaleStart(uint256 _newOfficialSaleStart)
        external
        virtual
        override
        onlyDAO
    {
        officialSaleStart = _newOfficialSaleStart;

        emit OfficialSaleStartChanged(_newOfficialSaleStart);
    }

    function setPresaleStart(uint256 _newPresaleStart)
        external
        virtual
        override
        onlyDAO
    {
        presaleStart = _newPresaleStart;

        emit PresaleStartChanged(_newPresaleStart);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721PresetMinterPauserAutoId, ERC165Storage, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable {
        mint();
    }
}
