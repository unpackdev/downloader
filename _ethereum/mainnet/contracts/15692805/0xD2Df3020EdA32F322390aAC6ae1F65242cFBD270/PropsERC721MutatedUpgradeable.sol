// SPDX-License-Identifier: Apache 2.0
//TODO: ensure that direct mints start at tokenID 10001
pragma solidity ^0.8.4;

//  ==========  External imports    ==========

import "./ERC721EnumerableUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./MulticallUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./IERC721.sol";
import "./IERC20Upgradeable.sol";
import "./ERC2981.sol";

import "./ERC2771ContextUpgradeable.sol";
import "./IOwnable.sol";
import "./MerkleProof.sol";

//  ==========  Internal imports    ==========

import "./IAllowlist.sol";
import "./IConfig.sol";
import "./IPropsContract.sol";
import "./IPropsAccessRegistry.sol";
import "./IRedeemableContract.sol";
import "./IERC20StakingToken.sol";

contract PropsERC721MutatedUpgradeable is
    Initializable,
    IOwnable,
    IAllowlist,
    IConfig,
    IPropsContract,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC2981
{
    using StringsUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using ECDSAUpgradeable for bytes32;

    //////////////////////////////////////////////
    // State Vars
    /////////////////////////////////////////////

    bytes32 private constant MODULE_TYPE = bytes32("Props721MutatedU");
    uint256 private constant VERSION = 6;

    uint256 private nextTokenId;
    mapping(address => uint256) public minted;
    mapping(address => mapping(uint256 => uint256)) public mintedByAllowlist;
    mapping(uint256 => uint256) public mutatedByToken;

    bytes32 private constant CONTRACT_ADMIN_ROLE =
        keccak256("CONTRACT_ADMIN_ROLE");
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant PRODUCER_ROLE = keccak256("PRODUCER_ROLE");
    // @dev reserving space for  more roles
    bytes32[32] private __gap;

    string private baseURI_;
    string public contractURI;
    address private _owner;
    address private accessRegistry;
    address public project;
    address public receivingWallet;
    address public rWallet;
    address public redeemableContract;
    address public stakingERC20Address;
    address public parentHolderContract;
    address[] private trustedForwarders;
    bool public isMutationEnabled;

    Allowlists public allowlists;
    Config public config;

    //////////////////////////////////////////////
    // Errors
    /////////////////////////////////////////////

    error AllowlistInactive();
    error MintQuantityInvalid();
    error MerkleProofInvalid();
    error MintClosed();
    error MintZeroQuantity();
    error InsufficientFunds();

    //////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////

    event Minted(address indexed account, string tokens);
    event Mutated(address indexed account, string tokens);
    event Upgraded(address indexed account, string tokens);

    //////////////////////////////////////////////
    // Init
    /////////////////////////////////////////////

    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address[] memory _trustedForwarders,
        address _receivingWallet,
        address _accessRegistry
    ) public initializer {
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarders);
        __ERC721_init(_name, _symbol);

        receivingWallet = _receivingWallet;
        _owner = _defaultAdmin;
        accessRegistry = _accessRegistry;
        baseURI_ = _baseURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setRoleAdmin(CONTRACT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PRODUCER_ROLE, CONTRACT_ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, PRODUCER_ROLE);

        nextTokenId = 10000;
        isMutationEnabled = false;

        // add default admin entry to registry
        IPropsAccessRegistry(accessRegistry).add(_defaultAdmin, address(this));
    }

    /*///////////////////////////////////////////////////////////////
                      Generic contract logic
  //////////////////////////////////////////////////////////////*/

    /// @dev Returns the type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    /*///////////////////////////////////////////////////////////////
                      ERC 165 / 721 logic
  //////////////////////////////////////////////////////////////*/

    /**
     * @dev see {IERC721Metadata}
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI_, _tokenId.toString(), ".json"));
    }

    /**
     * @dev see {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            AccessControlEnumerableUpgradeable,
            ERC721EnumerableUpgradeable,
            ERC2981
        )
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

    function mutate(
        uint256 tokenID,
        uint256 serumID
    ) public nonReentrant {
        require(!paused(), "Paused");
        require(isMutationEnabled, "Mutation is not enabled");
        IRedeemableContract(redeemableContract).burnFromRedeem(
            msg.sender,
            serumID
        );

        require(mutatedByToken[tokenID] < 1, "Already mutated");
            require(
                IERC721(parentHolderContract).ownerOf(tokenID) == msg.sender,
                "User Unauthorized"
            );
            mutatedByToken[tokenID] = 1;
            _safeMint(msg.sender, tokenID);
            emit Mutated(
                msg.sender,
                string(
                    abi.encodePacked(
                        tokenID.toString(),
                        ",",
                        serumID.toString()
                    )
                )
            );
    } 

    function upgrade(
        uint256 tokenID,
        uint256 serumID,
        bytes memory signature
    ) public nonReentrant {
        require(!paused(), "Paused");
        require(isMutationEnabled, "Mutation is not enabled");
        IRedeemableContract(redeemableContract).burnFromRedeem(
            msg.sender,
            serumID
        );

        require(
            IERC721(address(this)).ownerOf(tokenID) == msg.sender,
            "User Unauthorized"
        );
        require(
            ECDSAUpgradeable.recover(
                keccak256(abi.encodePacked(tokenID, serumID))
                    .toEthSignedMessageHash(),
                signature
            ) ==
                IERC20StakingToken(stakingERC20Address)
                    .getSignatureVerifier(),
            "Upgrade not allowed"
        );

        emit Upgraded(
            msg.sender,
            string(
                abi.encodePacked(
                    tokenID.toString(),
                    ",",
                    serumID.toString()
                )
            )
        );
        
    }

    function mint(
        uint256[] calldata _quantities,
        bytes32[][] calldata _proofs,
        uint256[] calldata _allotments,
        uint256[] calldata _allowlistIds
    ) external payable nonReentrant {
        require(isUniqueArray(_allowlistIds), "boo");
        uint256 _cost = 0;
        uint256 _quantity = 0;

        for (uint256 i = 0; i < _quantities.length; i++) {
            _quantity += _quantities[i];

            revertOnInactiveList(_allowlistIds[i]);
            revertOnAllocationCheckFailure(
                msg.sender,
                _allowlistIds[i],
                mintedByAllowlist[msg.sender][_allowlistIds[i]],
                _quantities[i],
                _allotments[i],
                _proofs[i]
            );
            _cost += allowlists.lists[_allowlistIds[i]].price * _quantities[i];
        }

        require(
            nextTokenId + _quantity - 1 <= config.mintConfig.maxSupply,
            "Exceeded max supply."
        );

        if (_cost > msg.value) revert InsufficientFunds();
        payable(receivingWallet).transfer(msg.value);

        string memory tokensMinted = "";
        unchecked {
            for (uint256 i = 0; i < _quantities.length; i++) {
                mintedByAllowlist[address(msg.sender)][
                    _allowlistIds[i]
                ] += _quantities[i];
                for (uint256 j = 0; j < _quantities[i]; j++) {
                    tokensMinted = string(
                        abi.encodePacked(
                            tokensMinted,
                            nextTokenId.toString(),
                            ","
                        )
                    );

                    _safeMint(msg.sender, nextTokenId);
                    nextTokenId++;
                }
            }
        }
        emit Minted(msg.sender, tokensMinted);
    }

    function revertOnInactiveList(uint256 _allowlistId) internal view {
        if (
            paused() ||
            block.timestamp < allowlists.lists[_allowlistId].startTime ||
            block.timestamp > allowlists.lists[_allowlistId].endTime ||
            !allowlists.lists[_allowlistId].isActive
        ) revert AllowlistInactive();
    }

    // @dev +~0.695kb
    function revertOnAllocationCheckFailure(
        address _address,
        uint256 _allowlistId,
        uint256 _minted,
        uint256 _quantity,
        uint256 _alloted,
        bytes32[] calldata _proof
    ) internal view {
        if (_quantity == 0) revert MintZeroQuantity();
        Allowlist storage allowlist = allowlists.lists[_allowlistId];
        if (_quantity + _minted > allowlist.maxMintPerWallet)
            revert MintQuantityInvalid();
        if (allowlist.typedata != bytes32(0)) {
            if (_quantity > _alloted || ((_quantity + _minted) > _alloted))
                revert MintQuantityInvalid();
            (bool validMerkleProof, ) = MerkleProof.verify(
                _proof,
                allowlist.typedata,
                keccak256(abi.encodePacked(_address, _alloted))
            );
            if (!validMerkleProof) revert MerkleProofInvalid();
        }
    }

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                      Allowlist Logic
  //////////////////////////////////////////////////////////////*/

    function setAllowlists(Allowlist[] calldata _allowlists)
        external
        minRole(PRODUCER_ROLE)
    {
        allowlists.count = _allowlists.length;
        for (uint256 i = 0; i < _allowlists.length; i++) {
            allowlists.lists[i] = _allowlists[i];
        }
    }

    function updateAllowlistByIndex(Allowlist calldata _allowlist, uint256 i)
        external
        minRole(PRODUCER_ROLE)
    {
        allowlists.lists[i] = _allowlist;
    }

    function addAllowlist(Allowlist calldata _allowlist)
        external
        minRole(PRODUCER_ROLE)
    {
        allowlists.lists[allowlists.count] = _allowlist;
        allowlists.count++;
    }

    /*///////////////////////////////////////////////////////////////
                      Getters
  //////////////////////////////////////////////////////////////*/

    /// @dev Returns the allowlist at the given uid.
    function getAllowlistById(uint256 _allowlistId)
        external
        view
        returns (Allowlist memory allowlist)
    {
        allowlist = allowlists.lists[_allowlistId];
    }

    /// @dev Returns the number of minted tokens for sender by allowlist.
    function getMintedByAllowlist(uint256 _allowlistId)
        external
        view
        returns (uint256 minted_)
    {
        minted_ = mintedByAllowlist[msg.sender][_allowlistId];
    }

    /*///////////////////////////////////////////////////////////////
                      Setters
  //////////////////////////////////////////////////////////////*/

    function setNextId(uint256 _id) external minRole(CONTRACT_ADMIN_ROLE) {
        nextTokenId = _id;
    }

    function setRoyalty(uint96 _royalty) external minRole(PRODUCER_ROLE) {
        _setDefaultRoyalty(rWallet, _royalty);
    }

    function setReceivingWallet(address _address)
      external
      minRole(CONTRACT_ADMIN_ROLE)
    {
        receivingWallet = _address;
    }

     function setRoyaltyWallet(address _address)
      external
      minRole(CONTRACT_ADMIN_ROLE)
    {
        rWallet = _address;
    }

    function setRedeemableContract(address _address)
        external
        minRole(CONTRACT_ADMIN_ROLE)
    {
        redeemableContract = _address;
    }

    function setParentHolderContract(address _address)
        external
        minRole(CONTRACT_ADMIN_ROLE)
    {
        parentHolderContract = _address;
    }

     function setStakingERC20Contract(address _address)
        external
        minRole(CONTRACT_ADMIN_ROLE)
    {
        stakingERC20Address = _address;
    }

    function toggleMutationState(bool _isMutationEnabled)
        external
        minRole(CONTRACT_ADMIN_ROLE)
    {
        isMutationEnabled = _isMutationEnabled;
    }

    function setInternals(
        address _receivingWallet,
        address _rWallet,
        address _stakingERC20Address,
        address _redeemableContract,
        address _parentHolderContract
    ) external minRole(CONTRACT_ADMIN_ROLE) {
        receivingWallet = _receivingWallet;
        rWallet = _rWallet;
        stakingERC20Address = _stakingERC20Address;
        redeemableContract = _redeemableContract;
        parentHolderContract = _parentHolderContract;
    }

    function setConfig(Config calldata _config)
        external
        minRole(PRODUCER_ROLE)
    {
        config = _config;
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function setOwner(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "!ADMIN");
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri)
        external
        minRole(CONTRACT_ADMIN_ROLE)
    {
        contractURI = _uri;
    }

    /// @dev Lets a contract admin set the URI for the baseURI.
    function setBaseURI(string calldata _baseURI)
        external
        minRole(CONTRACT_ADMIN_ROLE)
    {
        baseURI_ = _baseURI;
    }

    /// @dev Lets a contract admin set the address for the access registry.
    function setAccessRegistry(address _accessRegistry)
        external
        minRole(CONTRACT_ADMIN_ROLE)
    {
        accessRegistry = _accessRegistry;
    }

    /// @dev Lets a contract admin set the address for the parent project.
    function setProject(address _project) external minRole(PRODUCER_ROLE) {
        project = _project;
    }

    /*///////////////////////////////////////////////////////////////
                      Miscellaneous / Overrides
  //////////////////////////////////////////////////////////////*/

    function togglePause(bool _isPaused) external minRole(MINTER_ROLE) {
        _isPaused ? _pause() : _unpause();
    }

    function grantRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, IAccessControlUpgradeable)
        minRole(CONTRACT_ADMIN_ROLE)
    {
        if (!hasRole(role, account)) {
            super._grantRole(role, account);
            IPropsAccessRegistry(accessRegistry).add(account, address(this));
        }
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, IAccessControlUpgradeable)
        minRole(CONTRACT_ADMIN_ROLE)
    {
        if (hasRole(role, account)) {
            // @dev ya'll can't take your own admin role, fool.
            if (role == DEFAULT_ADMIN_ROLE && account == owner()) revert();
            // #TODO check if it still adds roles (enumerable)!
            super._revokeRole(role, account);
            IPropsAccessRegistry(accessRegistry).remove(account, address(this));
        }
    }

    function isUniqueArray(uint256[] calldata _array)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < _array.length; i++) {
            for (uint256 j = 0; j < _array.length; j++) {
                if (_array[i] == _array[j] && i != j) return false;
            }
        }
        return true;
    }

    /**
     * @dev Check if minimum role for function is required.
     */
    modifier minRole(bytes32 _role) {
        require(_hasMinRole(_role), "Not authorized");
        _;
    }

    function hasMinRole(bytes32 _role) public view virtual returns (bool) {
        return _hasMinRole(_role);
    }

    function _hasMinRole(bytes32 _role) internal view returns (bool) {
        // @dev does account have role?
        if (hasRole(_role, _msgSender())) return true;
        // @dev are we checking against default admin?
        if (_role == DEFAULT_ADMIN_ROLE) return false;
        // @dev walk up tree to check if user has role admin role
        return _hasMinRole(getRoleAdmin(_role));
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from != address(0x0)) {
            //IERC20StakingToken(stakingERC20Address).claimPoints(from, tokenId);
            uint256[] memory t = new uint256[](1);
            t[0] = tokenId;
            IERC20StakingToken(stakingERC20Address).bridgeUnstake(from, t);
        }
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    uint256[49] private ___gap;
}
