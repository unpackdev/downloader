// SPDX-License-Identifier: MIT
/*
     _ _____                      _     
    | |  __ \                    (_)    
  __| | |  \/ ___ _ __   ___  ___ _ ___ 
 / _` | | __ / _ \ '_ \ / _ \/ __| / __|
| (_| | |_\ \  __/ | | |  __/\__ \ \__ \
 \__,_|\____/\___|_| |_|\___||___/_|___/
                                        
                                        
       ______     _                     
       | ___ \   (_)                    
       | |_/ / __ _ _ __ ___   ___      
       |  __/ '__| | '_ ` _ \ / _ \     
       | |  | |  | | | | | | |  __/     
       \_|  |_|  |_|_| |_| |_|\___| 
*/
pragma solidity ^0.8.2;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
//debug
import "./console.sol";

contract dGenesisPrime is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    AccessControlUpgradeable,
    ERC721BurnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    bytes32 public constant PROJECTS_ADMIN = keccak256("PROJECTS_ADMIN");
    bytes32 public constant CLAIM_ROLE = keccak256("CLAIM_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /* ========== INITIALIZER ========== */
    function initialize() public initializer {
        __ERC721_init("dGenesis Prime", "DGNP");
        __ERC721Enumerable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        _setupRole(WITHDRAW_ROLE, msg.sender);
        _setupRole(PROJECTS_ADMIN, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(CLAIM_ROLE, msg.sender);
        nextProjectId = 1;
        contractURIString = "https://dgenesis.io/prime/metadata/contract";
        PROJECTS_RESERVED_BLOCK = 1000000;
    }

    /* ========== STATE VARIABLES ========== */

    struct Project {
        string name;
        uint256 pricePerTokenInWei;
        string projectBaseURI;
        CountersUpgradeable.Counter currentQuantity;
        CountersUpgradeable.Counter totalPurchased;
        uint256 maxQuantity;
        uint256 maxTotalPurchaseable;
        uint256 activeBlock;
        uint256 maxPurchaseQuantityPerTX;
        bool paused;
    }

    string public contractURIString;
    uint256 public nextProjectId;
    uint256 public PROJECTS_RESERVED_BLOCK;
    mapping(uint256 => Project) projects;

    /* ========== VIEWS ========== */
    function getProjectName(uint256 _projectId)
        public
        view
        returns (string memory)
    {
        return projects[_projectId].name;
    }

    function getProjectPrice(uint256 _projectId) public view returns (uint256) {
        return projects[_projectId].pricePerTokenInWei;
    }

    function getProjectBaseURI(uint256 _projectId)
        public
        view
        returns (string memory)
    {
        return projects[_projectId].projectBaseURI;
    }

    function getProjectMaxQuantity(uint256 _projectId)
        public
        view
        returns (uint256)
    {
        return projects[_projectId].maxQuantity;
    }

    function getProjectmaxTotalPurchaseable(uint256 _projectId)
        public
        view
        returns (uint256)
    {
        return projects[_projectId].maxTotalPurchaseable;
    }

    function getProjectMaxPurchaseQuantityPerTX(uint256 _projectId)
        public
        view
        returns (uint256)
    {
        return projects[_projectId].maxPurchaseQuantityPerTX;
    }

    function getProjectTotalPurchased(uint256 _projectId)
        public
        view
        returns (uint256)
    {
        return projects[_projectId].totalPurchased.current();
    }

    function getProjectCurrentQuantity(uint256 _projectId)
        public
        view
        returns (uint256)
    {
        return projects[_projectId].currentQuantity.current();
    }

    function getProjectActiveBlock(uint256 _projectId)
        public
        view
        returns (uint256)
    {
        return projects[_projectId].activeBlock;
    }

    function isPaused(uint256 _projectId) public view returns (bool) {
        return projects[_projectId].paused;
    }

    function contractURI() public view returns (string memory) {
        return contractURIString;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(
                projects[uint256(tokenId) / uint256(PROJECTS_RESERVED_BLOCK)]
                    .projectBaseURI
            ).length > 0
                ? string(
                    abi.encodePacked(
                        projects[
                            uint256(tokenId) / uint256(PROJECTS_RESERVED_BLOCK)
                        ].projectBaseURI,
                        StringsUpgradeable.toString(tokenId)
                    )
                )
                : "";
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function claimMint(
        uint256 _projectId,        
        uint256 _numberOfTokens,
        address _claimer
    ) public onlyRole(CLAIM_ROLE) {
        require(block.number >= projects[_projectId].activeBlock, "Inactive");
        require(
            projects[_projectId].currentQuantity.current().add(_numberOfTokens) <=
                projects[_projectId].maxQuantity,
            "Claim would exceed max supply of tokens"
        );

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            
            if (
                projects[_projectId].currentQuantity.current() <
                projects[_projectId].maxQuantity
            ) {
                _safeMint(
                    _claimer,
                    (uint256(PROJECTS_RESERVED_BLOCK).mul(_projectId)).add(
                        projects[_projectId].currentQuantity.current())
                );
                projects[_projectId].currentQuantity.increment();
            }
        }
    }

    function mint(uint256 _projectId, uint256 _numberOfTokens) public payable {
        require(block.number >= projects[_projectId].activeBlock, "Inactive");

        require(!projects[_projectId].paused, "Project Paused");

        require(
            _numberOfTokens <= projects[_projectId].maxPurchaseQuantityPerTX,
            "Exceeded max per TX purchase amount"
        );
        require(
            _numberOfTokens.add( projects[_projectId].totalPurchased.current()) <=
                projects[_projectId].maxTotalPurchaseable,
            "Exceeded max purchaseable amount"
        );
        require(
            projects[_projectId].currentQuantity.current().add( _numberOfTokens) <=
                projects[_projectId].maxQuantity,
            "Purchase would exceed max supply of tokens"
        );
        require(
            projects[_projectId].pricePerTokenInWei.mul( _numberOfTokens) <=
                msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            if (
                projects[_projectId].currentQuantity.current() <
                projects[_projectId].maxQuantity
            ) {
                _safeMint(
                    msg.sender,
                    (uint256(PROJECTS_RESERVED_BLOCK).mul(_projectId)).add(
                        projects[_projectId].currentQuantity.current())
                );
                projects[_projectId].currentQuantity.increment();
                projects[_projectId].totalPurchased.increment();
            }
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    function createProject(
        string memory _name,
        uint256 _pricePerTokenInWei,
        string memory _projectBaseURI,
        uint256 _maxPurchaseQuantityPerTX,
        uint256 _maxTotalPurchaseable,
        uint256 _maxQuantity,
        uint256 _activeBlock
    ) public onlyRole(PROJECTS_ADMIN) {
        uint256 projectId = nextProjectId;

        projects[projectId].name = _name;

        projects[projectId].pricePerTokenInWei = _pricePerTokenInWei;
        projects[projectId].projectBaseURI = _projectBaseURI;
        projects[projectId]
            .maxPurchaseQuantityPerTX = _maxPurchaseQuantityPerTX;
        projects[projectId].maxQuantity = _maxQuantity;
        projects[projectId].maxTotalPurchaseable = _maxTotalPurchaseable;
        projects[projectId].activeBlock = _activeBlock;
        projects[projectId].paused = false;
        nextProjectId = nextProjectId + 1;
    }

    function modifyProject(
        uint256 _projectId,
        string memory _name,
        uint256 _pricePerTokenInWei,
        string memory _projectBaseURI,
        uint256 _maxPurchaseQuantityPerTX,
        uint256 _maxTotalPurchaseable,
        uint256 _maxQuantity,
        uint256 _activeBlock
    ) public onlyRole(PROJECTS_ADMIN) {
        projects[_projectId].name = _name;
        projects[_projectId].pricePerTokenInWei = _pricePerTokenInWei;
        projects[_projectId].projectBaseURI = _projectBaseURI;
        projects[_projectId]
            .maxPurchaseQuantityPerTX = _maxPurchaseQuantityPerTX;
        projects[_projectId].maxQuantity = _maxQuantity;
        projects[_projectId].maxTotalPurchaseable = _maxTotalPurchaseable;
        projects[_projectId].activeBlock = _activeBlock;
    }

    function setProjectPrice(uint256 _projectId, uint256 _pricePerTokenInWei)
        public
        onlyRole(PROJECTS_ADMIN)
    {
        projects[_projectId].pricePerTokenInWei = _pricePerTokenInWei;
    }

    function setProjectActiveBlock(uint256 _projectId, uint256 _activeBlock)
        public
        onlyRole(PROJECTS_ADMIN)
    {
        projects[_projectId].activeBlock = _activeBlock;
    }

    function setprojectBaseURI(uint256 _projectId, string memory _projectBaseURI)
        public
        onlyRole(PROJECTS_ADMIN)
    {
        projects[_projectId].projectBaseURI = _projectBaseURI;
    }

    function setcontractURI(string memory _contractURIString)
        public
        onlyRole(PROJECTS_ADMIN)
    {
        contractURIString = _contractURIString;
    }

    function pauseProject(uint256 projectId) public onlyRole(PAUSER_ROLE) {
        projects[projectId].paused = true;
    }

    function unpauseProject(uint256 projectId) public onlyRole(PAUSER_ROLE) {
        projects[projectId].paused = false;
    }

    function reserveMint(
        uint256 _projectId,
        uint256 _numberOfTokens,
        address _to
    ) public onlyRole(MINTER_ROLE) {
        require(
            projects[_projectId].currentQuantity.current() + _numberOfTokens <=
                projects[_projectId].maxQuantity,
            "Mint would exceed max supply of tokens"
        );

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            _safeMint(
                _to,
                (uint256(PROJECTS_RESERVED_BLOCK).mul(_projectId)) +
                    projects[_projectId].currentQuantity.current()
            );
            projects[_projectId].currentQuantity.increment();
        }
    }

    function withdraw(address payable recipient, uint256 amount)
        public
        onlyRole(WITHDRAW_ROLE)
    {
        recipient.transfer(amount);
    }

   

    /* ========== OVERRIDES ========== */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721EnumerableUpgradeable, ERC721Upgradeable) {
        require(
            !projects[uint256(tokenId) / uint256(PROJECTS_RESERVED_BLOCK)]
                .paused,
            "Project Paused"
        );
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
