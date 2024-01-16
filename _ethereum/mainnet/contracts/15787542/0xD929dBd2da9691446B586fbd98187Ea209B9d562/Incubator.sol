// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./SignatureCheckerUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./IERC20Mint.sol";
import "./IERC1155Mint.sol";
import "./IIncubator.sol";

contract Incubator is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    IIncubator
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    IERC20Mint public token;
    IERC721Upgradeable public tengoku;
    IERC1155Mint public props;
    address public validator;

    mapping(address => mapping(uint256 => bool)) public holderClaimNonces;
    mapping(address => EnumerableSetUpgradeable.UintSet) private tokens;
    mapping(bytes32 => bool) private _claimHashes;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IERC20Mint _token,
        address _validator,
        IERC721Upgradeable _tengoku
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        token = _token;
        validator = _validator;
        tengoku = _tengoku;
    }

    function setNewValidator(address _validator)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        validator = _validator;
    }

    function setNewProps(IERC1155Mint _props)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        props = _props;
    }

    function tokenIds(address owner) public view returns (uint256[] memory) {
        return tokens[owner].values();
    }

    function addTengoku(uint256[] memory tokenIds)
        public
        override
        whenNotPaused
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            tengoku.transferFrom(msg.sender, address(this), tokenId);
            tokens[msg.sender].add(tokenId);
            emit AddTengoku(msg.sender, tokenId);
        }
    }

    function addAllTengoku() public whenNotPaused {
        uint256 bal = tengoku.balanceOf(msg.sender);
        require(bal > 0, "Incubator: Tengoku bal must be positive");
        uint256[] memory tokenIds = new uint256[](bal);
        for (uint256 i = 0; i < bal; i++) {
            uint256 tokenId = IERC721EnumerableUpgradeable(address(tengoku))
                .tokenOfOwnerByIndex(msg.sender, i);
            tokenIds[i] = tokenId;
        }

        addTengoku(tokenIds);
    }

    function removeTengoku(uint256[] memory tokenIds)
        public
        override
        whenNotPaused
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                tokens[msg.sender].contains(tokenId),
                "Incubator: Not owned"
            );
            tengoku.transferFrom(address(this), msg.sender, tokenId);
            tokens[msg.sender].remove(tokenId);
            emit RemoveTengoku(msg.sender, tokenId);
        }
    }

    function hashMessage(ClaimParams memory claimParams)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(block.chainid, address(this), claimParams));
    }

    /**
     * @notice Trusts the tengoku server, no need to check if the tokenid exists.
     */
    function claim(ClaimParams memory params, bytes memory signature)
        public
        override
        nonReentrant
        whenNotPaused
    {
        require(
            !holderClaimNonces[params.holder][params.nonce],
            "Incubator: Already claimed"
        );
        bytes32 hash = ECDSAUpgradeable.toEthSignedMessageHash(
            hashMessage(params)
        );
        require(!_claimHashes[hash], "Incubator: hash used");
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                validator,
                hash,
                signature
            ),
            "Incubator: Invalid signature"
        );
        if (params.claimAmount > 0) {
            token.mint(params.holder, params.claimAmount);
        }
        holderClaimNonces[params.holder][params.nonce] = true;
        _claimHashes[hash] = true;
        emit ClaimToken(params);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    event ClaimToken(ClaimParams);
    event AddTengoku(address indexed holder, uint256 tokenId);
    event RemoveTengoku(address indexed holder, uint256 tokenId);
}