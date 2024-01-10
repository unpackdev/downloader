// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "./Initializable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ClonesUpgradeable.sol";
import "./IBaseToken.sol";
import "./IMinter.sol";


contract Registry is Initializable, AccessControlEnumerableUpgradeable {

    /* ---------------------------------- Types --------------------------------- */

    enum ProjectStatus { Locked, Whitelist, Active, WhitelistByToken }
    enum ProjectType { Land, Items }

    struct Project {
        ProjectDetail detail;
        ProjectMint minting;
    }

    struct ClientDetail {
        string name;
        string clientImage;
        string description;
        bytes32 clientHash;
    }

    struct ProjectDetail {
        ProjectType projectType;
        uint128 clientIdx;
        string name;
        string symbol;
        string description;
        string license;
    }

    struct ProjectMint {
        uint256 maxSupply;
        uint256 maxBlockPurchase;
        uint256 maxWalletPurchase;
        uint256 price;
        address minter;
        address baseTokenImplementation;
        address staking;
        bool isFreeMint;
        ProjectStatus status;
    }


    /* --------------------------------- Globals -------------------------------- */

    mapping(address => Project) public projects;
    address[] public projectIdToAddress;
    ClientDetail[] clients;


    /* --------------------------------- Events --------------------------------- */

    event LogProjectCreated(address indexed project);
    event LogMinterCreated(address indexed minter);
    event LogClientCreated(uint256 indexed clientIdx, bytes32 indexed clientHash);


    /* -------------------------------- Modifiers ------------------------------- */

    /**
     * @dev Throws if called by any account other than the registry or project admin.
     */
    modifier onlyRegistryAdminOrProjectAdmin(address project) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(getProjectAdminRole(project), _msgSender()),
            "onlyRegistryAdminOrProjectAdmin: caller is not the Registry or Project or admin");
        _;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyDefaultAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "onlyDefaultAdmin: caller is not the admin");
        _;
    }


    /* ------------------------------- Initialize ------------------------------- */

    function initialize() public initializer {

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }


    /* ----------------------------- Public Getters ----------------------------- */

    function getProjectAdminRole(address project)
        public
        pure
        returns(bytes32)
    {
        return keccak256(abi.encodePacked("ADMIN_ROLE", project));
    }

    function getProjectMinter(address project)
        public
        view
        returns(address)
    {
        return projects[project].minting.minter;
    }

    function getProject(address project)
        public
        view
        returns(Project memory)
    {
        Project memory res = projects[project];
        return res;
    }

    function getClient(uint256 clientIdx)
        public
        view
        returns(ClientDetail memory)
    {
        ClientDetail memory res = clients[clientIdx];
        return res;
    }

    function getProjectDetail(address project)
        public
        view
        returns(ProjectDetail memory)
    {
        ProjectDetail memory res = projects[project].detail;
        return res;
    }

    function getProjectMinting(address project)
        public
        view
        returns(ProjectMint memory)
    {
        ProjectMint memory res = projects[project].minting;
        return res;
    }

    function getProjectStatus(address project)
        public
        view
        returns(ProjectStatus)
    {
        return projects[project].minting.status;
    }

    function getProjectPrice(address project)
        public
        view
        returns(uint256)
    {
        return projects[project].minting.price;
    }

    function getProjectMaxSupply(address project)
        public
        view
        returns(uint256)
    {
        return projects[project].minting.maxSupply;
    }

    function getProjectMaxBlockPurchase(address project)
        public
        view
        returns(uint256)
    {
        return projects[project].minting.maxBlockPurchase;
    }

    function getProjectMaxWalletPurchase(address project)
        public
        view
        returns(uint256)
    {
        return projects[project].minting.maxWalletPurchase;
    }

    function getProjectFreeStatus(address project)
       public
       view
       returns(bool)
   {
       return projects[project].minting.isFreeMint;
   }

    function getProjectLicense(address project)
       public
       view
       returns(string memory)
   {
        return projects[project].detail.license;
   }

    function getNumbProjects()
        public
        view
        returns(uint256)
    {
        return projectIdToAddress.length;
    }


    /* ------------------------------ Admin Methods ----------------------------- */

    function createClient(ClientDetail calldata client)
        external
        onlyDefaultAdmin
    {
        clients.push(client);

        unchecked {
            emit LogClientCreated(clients.length - 1, client.clientHash);
        }
    }

    function createProject(ProjectDetail calldata projectDetail, ProjectMint calldata projectMint, address owner, bytes32 clientHash)
        public
        onlyDefaultAdmin
    {
        require(projectMint.baseTokenImplementation != address(0), "createProject: baseTokenImplementation not set");
        require(clientHash == clients[projectDetail.clientIdx].clientHash, "createProject: client mismatch");
        IBaseToken projectContract = IBaseToken(ClonesUpgradeable.clone(projectMint.baseTokenImplementation));
        projectContract.initialize(projectDetail.name, projectDetail.symbol);

        address projectAddress = address(projectContract);
        projectIdToAddress.push(projectAddress);

        projects[projectAddress].detail = projectDetail;
        projects[projectAddress].minting = projectMint;

        // Registry admin 0 is Token Admin.
        address admin = getRoleMember(DEFAULT_ADMIN_ROLE, 0);
        projectContract.grantRole(
            projectContract.DEFAULT_ADMIN_ROLE(),
            admin
        );

        // owner is a pre defined address (for opensea config etc.).
        projectContract.transferOwnership(owner);

        emit LogProjectCreated(address(projectContract));
    }

    function createMinter(
        address project,
        address minterImplementation,
        address[] memory payees,
        uint256[] memory shares
    )
        public
        onlyDefaultAdmin
    {
        require(minterImplementation != address(0), "createMinter: minterImplementation not set");

        IMinter minterContract = IMinter(ClonesUpgradeable.clone(minterImplementation));
        minterContract.initialize(project, payees, shares);

        // Give minter contract role.
        IBaseToken(project).grantRole(
            IBaseToken(project).MINTER_ROLE(),
            address(minterContract)
        );

        // Registry admin is minter owner.
        minterContract.grantRole(
            minterContract.ADMIN_ROLE(),
            getRoleMember(DEFAULT_ADMIN_ROLE, 0)
        );

        // Record minter address references
        projects[project].minting.minter = address(minterContract);

        emit LogMinterCreated(address(minterContract));
    }

    function addProjectAdmin(address project, address admin)
        public
        onlyDefaultAdmin
    {
        // Local Admin
        _grantRole(getProjectAdminRole(project), admin);

        // Token Admin
        IBaseToken(project).grantRole(
            IBaseToken(project).DEFAULT_ADMIN_ROLE(),
            admin
        );

        // Minter Admin
        address minter = projects[project].minting.minter;
        require(minter != address(0),
            "addProjectAdmin: Deploy minter first"
        );
        IMinter(payable(minter)).grantRole(IMinter(payable(minter)).ADMIN_ROLE(), admin);

    }


    /* ---------------------- RegistryAdmin Or ProjectAdmin Methods ---------------------- */

    function updateProjectMinting(address project, ProjectMint memory info)
        public
        onlyRegistryAdminOrProjectAdmin(project)
    {
        projects[project].minting = info;
    }

    function updateProjectInfo(address project, Project memory info)
        public
        onlyRegistryAdminOrProjectAdmin(project)
    {
        projects[project] = info;
    }

    function updateProjectDetail(address project, ProjectDetail memory info)
        public
        onlyRegistryAdminOrProjectAdmin(project)
    {
        projects[project].detail = info;
    }

    function updateProjectPrice(address project, uint256 price)
        public
        onlyRegistryAdminOrProjectAdmin(project)
    {
        projects[project].minting.price = price;
    }

    function updateProjectStatus(address project, ProjectStatus status)
        public
        onlyRegistryAdminOrProjectAdmin(project)
    {
        projects[project].minting.status = status;
    }

    function updateProjectMaxWalletPurchase(address project, uint256 maxPurchase)
        public
        onlyRegistryAdminOrProjectAdmin(project)
    {
        projects[project].minting.maxWalletPurchase = maxPurchase;
    }

    function updateProjectMaxBlockPurchase(address project, uint256 maxPurchase)
        public
        onlyRegistryAdminOrProjectAdmin(project)
    {
        projects[project].minting.maxBlockPurchase = maxPurchase;
    }

    // Sets base URI for all tokens
    function setBaseURI(address project, string memory baseURI_)
        external
        onlyRegistryAdminOrProjectAdmin(project)
    {
        IBaseToken(project).setBaseURI(baseURI_);
    }

    // Sets Token URI for one tokenID
    function setTokenURI(address project, uint256 tokenId, string memory newTokenURI)
        external
        onlyRegistryAdminOrProjectAdmin(project)
    {
        IBaseToken(project).setTokenURI(tokenId, newTokenURI);
    }

    function setMaxSupply(address project, uint256 supply)
        public
        onlyRegistryAdminOrProjectAdmin(project)
    {
        projects[project].minting.maxSupply = supply;
    }

    function updateProjectFreeStatus(address project, bool isFree)
        public
        onlyRegistryAdminOrProjectAdmin(project)
    {
        projects[project].minting.isFreeMint = isFree;
    }

}
