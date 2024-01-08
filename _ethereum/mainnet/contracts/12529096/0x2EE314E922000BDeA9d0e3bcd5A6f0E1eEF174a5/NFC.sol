//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./CountersUpgradeable.sol";

contract NFC is
    Initializable,
    ContextUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721PausableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct Project {
        address payable author;
        string codeCid;
        string parametersCid;
        string name;
        string description;
        string license;
        uint256 pricePerTokenInWei;
        uint256 maxNumEditions;
        bool isPaused;
    }

    CountersUpgradeable.Counter private _nextTokenId;
    string private _baseTokenUri;

    CountersUpgradeable.Counter private _nextProjectId;
    mapping(uint256 => Project) private _projectById;
    mapping(uint256 => uint256) private _projectIdByTokenId;
    mapping(uint256 => uint256[]) private _tokenIdsByProjectId;

    address payable private _treasury;
    uint256 private _feeInBp;

    event Minted(address indexed minter, uint256 indexed tokenId);
    event ProjectCreated(address indexed creator, uint256 indexed projectId);
    event ProjectPaused(address indexed pauser, uint256 indexed projectId);
    event ProjectUnpaused(address indexed unpauser, uint256 indexed projectId);
    event TreasuryUpdated(address indexed updater, address treasury);
    event FeeUpdated(address indexed updater, uint256 feeInBp);

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "NFC: Caller is not the admin"
        );
        _;
    }

    modifier onlyProjectAuthor(uint256 projectId) {
        require(
            _msgSender() == _projectById[projectId].author,
            "NFC: Caller is not the author of the project"
        );
        _;
    }

    modifier whenProjectNotPaused(uint256 projectId) {
        require(!_projectById[projectId].isPaused, "NFC: Project is paused");
        _;
    }

    modifier whenProjectPaused(uint256 projectId) {
        require(_projectById[projectId].isPaused, "NFC: Project is not paused");
        _;
    }

    function initialize(
        string memory name,
        string memory symbol,
        string memory baseTokenUri,
        address payable treasury,
        uint256 feeInBp
    ) public initializer {
        __ERC165_init_unchained();

        __Context_init_unchained();

        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();

        __ERC721_init_unchained(name, symbol);

        __ERC721URIStorage_init_unchained();

        __ERC721Burnable_init_unchained();

        __Pausable_init_unchained();
        __ERC721Pausable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _baseTokenUri = baseTokenUri;
        _treasury = treasury;
        _feeInBp = feeInBp;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenUri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function numProjects() public view returns (uint256) {
        return _nextProjectId.current();
    }

    function project(uint256 projectId) public view returns (Project memory) {
        return _projectById[projectId];
    }

    function projectIdByTokenId(uint256 tokenId) public view returns (uint256) {
        return _projectIdByTokenId[tokenId];
    }

    function tokenIdsByProjectId(uint256 projectId)
        public
        view
        returns (uint256[] memory)
    {
        return _tokenIdsByProjectId[projectId];
    }

    function treasury() public view returns (address) {
        return _treasury;
    }

    function feeInBp() public view returns (uint256) {
        return _feeInBp;
    }

    function mint(
        address to,
        uint256 projectId,
        string memory cid
    ) public payable returns (uint256) {
        require(
            msg.value >= _projectById[projectId].pricePerTokenInWei,
            "NFC: ETH sent is insufficient"
        );
        require(
            _projectById[projectId].author != address(0),
            "NFC: Project does not exist"
        );
        require(
            _tokenIdsByProjectId[projectId].length <
                _projectById[projectId].maxNumEditions,
            "NFC: Project has reached its edition limit"
        );

        uint256 newTokenId = _nextTokenId.current();
        _nextTokenId.increment();

        _projectIdByTokenId[newTokenId] = projectId;
        _tokenIdsByProjectId[projectId].push(newTokenId);

        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, cid);

        emit Minted(_msgSender(), newTokenId);

        uint256 treasuryAmount =
            (_projectById[projectId].pricePerTokenInWei * _feeInBp) / 10000;
        uint256 projectAuthorAmount =
            _projectById[projectId].pricePerTokenInWei - treasuryAmount;
        _treasury.transfer(treasuryAmount);
        _projectById[projectId].author.transfer(projectAuthorAmount);

        uint256 refund = msg.value - treasuryAmount - projectAuthorAmount;
        if (refund > 0) {
            payable(_msgSender()).transfer(refund);
        }

        return newTokenId;
    }

    function createProject(
        address payable author,
        string memory codeCid,
        string memory parametersCid,
        string memory name,
        string memory description,
        string memory license,
        uint256 pricePerTokenInWei,
        uint256 maxNumEditions,
        string memory firstMintCid
    ) public payable returns (uint256) {
        uint256 newProjectId = _nextProjectId.current();
        _nextProjectId.increment();

        _projectById[newProjectId] = Project({
            author: author,
            codeCid: codeCid,
            parametersCid: parametersCid,
            name: name,
            description: description,
            license: license,
            pricePerTokenInWei: pricePerTokenInWei,
            maxNumEditions: maxNumEditions,
            isPaused: false
        });

        emit ProjectCreated(_msgSender(), newProjectId);

        mint(_msgSender(), newProjectId, firstMintCid);

        return newProjectId;
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    function pauseProject(uint256 projectId)
        public
        onlyProjectAuthor(projectId)
        whenProjectNotPaused(projectId)
    {
        _projectById[projectId].isPaused = true;

        emit ProjectPaused(_msgSender(), projectId);
    }

    function unpauseProject(uint256 projectId)
        public
        onlyProjectAuthor(projectId)
        whenProjectPaused(projectId)
    {
        _projectById[projectId].isPaused = false;

        emit ProjectUnpaused(_msgSender(), projectId);
    }

    function setTreasury(address payable addr) public onlyAdmin {
        _treasury = addr;

        emit TreasuryUpdated(_msgSender(), addr);
    }

    function setFeeInBp(uint256 bp) public onlyAdmin {
        require(bp < 10000, "NFC: Fee BP must be smaller than 10000");

        _feeInBp = bp;

        emit FeeUpdated(_msgSender(), bp);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            ERC721PausableUpgradeable
        )
        whenProjectNotPaused(projectIdByTokenId(tokenId))
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            AccessControlEnumerableUpgradeable,
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
