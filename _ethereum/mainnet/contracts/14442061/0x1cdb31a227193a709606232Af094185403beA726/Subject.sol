// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./ISubject.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./ERC721PresetMinterPauserAutoId.sol";
import "./SubjectGeneGenerator.sol";
import "./DAOControlled.sol";
import "./ValidAddress.sol";
import "./ERC2981Royalties.sol";

abstract contract Subject is
    ISubject,
    ERC721PresetMinterPauserAutoId,
    ReentrancyGuard,
    ERC2981Royalties,
    DAOControlled,
    ValidAddress
{
    using SafeMath for uint256;

    using Counters for Counters.Counter;
    using SubjectGeneGenerator for SubjectGeneGenerator.Gene;

    SubjectGeneGenerator.Gene internal geneGenerator;
    mapping(uint256 => uint256) internal _genes;
    mapping(uint256 => uint256) internal _bossTokens;
    uint256[7] internal _rareTraitsChances;
    uint256 public maxSupply;
    string public arweaveAssetsJSON;

    uint256 public immutable royaltyFeeBps = 500;

    event TokenMorphed(
        uint256 indexed tokenId,
        uint256 oldGene,
        uint256 newGene,
        uint256 price,
        SubjectEventType eventType
    );
    event TokenMinted(uint256 indexed tokenId, uint256 newGene);
    event BossCharactersGenerated(uint256[] bossCharactersGenes);
    event RareTraitsChancesChanged(uint256[] rareTraitsChances);
    event DaoAddressChanged(address newDaoAddress);
    event BaseURIChanged(string baseURI);
    event ArweaveAssetsJSONChanged(string arweaveAssetsJSON);

    enum SubjectEventType {
        MINT,
        MORPH,
        TRANSFER
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address payable _daoAddress,
        uint256 _maxSupply,
        string memory _arweaveAssetsJSON
    )
        DAOControlled(_daoAddress)
        ERC721PresetMinterPauserAutoId(name, symbol, baseURI)
    {
        maxSupply = _maxSupply;
        arweaveAssetsJSON = _arweaveAssetsJSON;
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

    function lastTokenId() public view override returns (uint256 tokenId) {
        return _tokenIdTracker.current();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721PresetMinterPauserAutoId) {
        ERC721PresetMinterPauserAutoId._beforeTokenTransfer(from, to, tokenId);
        emit TokenMorphed(
            tokenId,
            _genes[tokenId],
            _genes[tokenId],
            0,
            SubjectEventType.TRANSFER
        );
    }

    function setRareTraitsChances(uint256[] calldata entries)
        public
        virtual
        override
        onlyDAO
    {
        require(entries.length == 7, "Entries number should match traits number!");

        for (uint256 i = 0; i < entries.length; i++) {
            _rareTraitsChances[i] = entries[i];
        }
    }

    function setDaoAddress(address payable _daoAddress)
        public
        virtual
        override
        onlyDAO
        isValidAddress(_daoAddress)
    {
        daoAddress = _daoAddress;

        DAOControlled(daoAddress);

        emit DaoAddressChanged(_daoAddress);
    }

    function setBaseURI(string memory _baseURI)
        public
        virtual
        override
        onlyDAO
    {
        _setBaseURI(_baseURI);

        emit BaseURIChanged(_baseURI);
    }

    function setArweaveAssetsJSON(string memory _arweaveAssetsJSON)
        public
        virtual
        override
        onlyDAO
    {
        arweaveAssetsJSON = _arweaveAssetsJSON;

        emit ArweaveAssetsJSONChanged(_arweaveAssetsJSON);
    }

    function isTokenBoss(uint256 tokenId)
        public
        view
        returns (bool, uint256)
    {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        bool isBoss;
        uint256 gene;
        if (_bossTokens[tokenId] != 0) {
            isBoss = true;
            gene = _bossTokens[tokenId];
        }
        return (isBoss, gene);
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

}
