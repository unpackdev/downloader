// Sources flattened with hardhat v2.19.0 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/access/IAccessControl.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/IAccessControl.sol)

pragma solidity ^0.8.20;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
}


// File @openzeppelin/contracts/utils/Context.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/utils/introspection/IERC165.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/utils/introspection/ERC165.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File @openzeppelin/contracts/access/AccessControl.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/AccessControl.sol)

pragma solidity ^0.8.20;



/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    mapping(bytes32 role => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].hasRole[account];
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
     * is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
        if (!hasRole(role, account)) {
            _roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Attempts to revoke `role` to `account` and returns a boolean indicating if `role` was revoked.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {
        if (hasRole(role, account)) {
            _roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}


// File @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/utils/ReentrancyGuard.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}


// File contracts/ICannathaiMotherPlantMintV2.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;

interface ICannathaiMotherPlantMintV2 {
   function safeMint(address to, uint256 tokenId) external;
}


// File contracts/CannathaiNFTShopV2.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.23;




contract CannathaiNFTShopV2 is IERC721Receiver, ReentrancyGuard, AccessControl {
    event TreasuryAddressSet(address previous, address value);
    event EarlyPrivateSaleCostSet(uint256 previous, uint256 value);
    event PrivateSaleCostSet(uint256 previous, uint256 value);
    event PublicSaleCostSet(uint256 previous, uint256 value);
    event MaxMintPerTxSet(uint256 previous, uint256 value);
    event FreeMint(address indexed sender, uint256 quantity);
    event EarlyPrivateSaleMint(
        address indexed sender,
        uint256 quantity,
        uint256 cost
    );
    event PrivateSaleMint(
        address indexed sender,
        uint256 quantity,
        uint256 cost
    );
    event PublicSaleMint(
        address indexed sender,
        uint256 quantity,
        uint256 cost
    );
    event FreeMintNumberSet(address indexed user, uint256 quantity);
    event EarlyPrivateSaleNumberSet(address indexed user, uint256 quantity);
    event PrivateSaleNumberSet(address indexed user, uint256 quantity);
    event TokenIdCounterSet(uint256 previousTokenId, uint256 nextTokenId);
    event MaxTokenIdCounterSet(uint256 previousTokenId, uint256 nextTokenId);

    // base
    address public nftAddress;
    address payable public treasuryAddress;
    uint256 public maxMintPerTx = 20;

    // pause variable
    bool public pausedPublicSale;
    bool public pausedPrivateSale;
    bool public pausedEarlyPrivateSale;
    bool public pausedFreeMint;

    // cost
    uint256 public earlyPrivateSaleCost;
    uint256 public privateSaleCost;
    uint256 public publicSaleCost;

    // green list
    mapping(address => uint256) public freeMintNumberByAddress;
    mapping(address => uint256) public earlyPrivateSaleNumberByAddress;
    mapping(address => uint256) public privateSaleNumberByAddress;

    // token id
    uint256 public tokenIdCounter;
    uint256 public maxTokenIdCounter;

    constructor(
        address _nftAddress,
        address payable _treasuryAddress,
        uint256 _earlyPrivateSaleCost,
        uint256 _privateSaleCost,
        uint256 _publicSaleCost,
        uint256 _tokenIdCounter,
        uint256 _maxTokenIdCounter
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        nftAddress = _nftAddress;
        treasuryAddress = _treasuryAddress;
        earlyPrivateSaleCost = _earlyPrivateSaleCost;
        privateSaleCost = _privateSaleCost;
        publicSaleCost = _publicSaleCost;
        tokenIdCounter = _tokenIdCounter;
        maxTokenIdCounter = _maxTokenIdCounter;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice set token id counter
     * @param _tokenIdCounter: token id counter
     * @dev Only callable by owner.
     */
    function setTokenIdCounter(
       uint256 _tokenIdCounter 
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit TokenIdCounterSet(tokenIdCounter,_tokenIdCounter);
        tokenIdCounter = _tokenIdCounter;
    }

    /**
     * @notice set max token id counter
     * @param _maxTokenIdCounter: max token id counter
     * @dev Only callable by owner.
     */
    function setMaxTokenIdCounter(
       uint256 _maxTokenIdCounter 
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit MaxTokenIdCounterSet(maxTokenIdCounter,_maxTokenIdCounter);
        maxTokenIdCounter = _maxTokenIdCounter;
    }

    /**
     * @notice set treasury address
     * @param _value: new treasury address
     * @dev Only callable by owner.
     */
    function setTreasuryAddress(
        address payable _value
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_value != address(0), "cannot be zero");
        emit TreasuryAddressSet(treasuryAddress, _value);
        treasuryAddress = _value;
    }

    /**
     * @notice set max mint per transaction
     * @param _value: new value
     * @dev Only callable by owner.
     */
    function setMaxMintPerTx(
        uint256 _value
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_value != 0, "cannot be zero");
        emit MaxMintPerTxSet(maxMintPerTx, _value);
        maxMintPerTx = _value;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice set early private sale cost
     */
    function setEarlyPrivateSaleCost(
        uint256 _value
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_value > 0, "cannot be zero");
        emit EarlyPrivateSaleCostSet(earlyPrivateSaleCost, _value);
        earlyPrivateSaleCost = _value;
    }

    /**
     * @notice set private sale cost
     */
    function setPrivateSaleCost(
        uint256 _value
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_value > 0, "cannot be zero");
        emit PrivateSaleCostSet(privateSaleCost, _value);
        privateSaleCost = _value;
    }

    /**
     * @notice set public private sale cost
     */
    function setPublicSaleCost(
        uint256 _value
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_value > 0, "cannot be zero");
        emit PublicSaleCostSet(publicSaleCost, _value);
        publicSaleCost = _value;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice free mint
     */
    function freeMint(
        uint256 quantity
    ) external nonReentrant whenFreeMintNotPaused {
        require(quantity>0,"quantity");
        require(quantity <= maxMintPerTx, "limit per tx");
        require(
            freeMintNumberByAddress[msg.sender] >= quantity,
            "exceeded mint"
        );
        freeMintNumberByAddress[msg.sender] -= quantity;

        _mintTransfer(msg.sender,quantity);

        emit FreeMint(msg.sender, quantity);
    }

    /**
     * @notice mint early private sale
     */
    function mintEarlyPrivateSale(
        uint256 quantity
    ) external payable nonReentrant whenEarlyPrivateSaleNotPaused {
        require(quantity>0,"quantity");
        require(
            msg.value >= earlyPrivateSaleCost * quantity,
            "not enough coin"
        );
        require(quantity <= maxMintPerTx, "limit per tx");
        require(
            earlyPrivateSaleNumberByAddress[msg.sender] >= quantity,
            "exceeded mint"
        );
        earlyPrivateSaleNumberByAddress[msg.sender] -= quantity;

        // transfer
        _treansferEthToTreasury();
        _mintTransfer(msg.sender,quantity);

        emit EarlyPrivateSaleMint(msg.sender, quantity, msg.value);
    }

    /**
     * @notice mint private sale
     */
    function mintPrivateSaleSale(
        uint256 quantity
    ) external payable nonReentrant whenPrivateSaleNotPaused {
        require(quantity>0,"quantity");
        require(msg.value >= privateSaleCost * quantity, "not enough coin");
        require(quantity <= maxMintPerTx, "limit per tx");
        require(
            privateSaleNumberByAddress[msg.sender] >= quantity,
            "exceeded mint"
        );
        privateSaleNumberByAddress[msg.sender] -= quantity;

        // transfer
        _treansferEthToTreasury();
        _mintTransfer(msg.sender,quantity);

        emit PrivateSaleMint(msg.sender, quantity, msg.value);
    }

    /**
     * @notice mint public sale
     */
    function mintPublicSale(
        uint256 quantity
    ) external payable nonReentrant whenPublicSaleNotPaused {
        require(quantity>0,"quantity");
        require(msg.value >= publicSaleCost * quantity, "not enough coin");
        require(quantity <= maxMintPerTx, "limit per tx");

        // trenafer
        _treansferEthToTreasury();
        _mintTransfer(msg.sender,quantity);

        emit PublicSaleMint(msg.sender, quantity, msg.value);
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice deposit to trasury
     */
    function _treansferEthToTreasury() internal {
        (bool success, ) = treasuryAddress.call{value: msg.value}("");
        require(success, "Transfer to treasury failed");
    }

    /**
     * @notice mint transfer
     */
    function _mintTransfer(address toAddress,uint256 quantity) internal {
        for (uint256 i=0;i<quantity;i++) {
            require(tokenIdCounter<=maxTokenIdCounter,"max token id counter");
            ICannathaiMotherPlantMintV2(nftAddress).safeMint(toAddress,tokenIdCounter);
            tokenIdCounter++;
        }
    }

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice set free mint number by address
     */
    function setFreeMintNumberByAddress(
        address _user,
        uint256 _number
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        freeMintNumberByAddress[_user] = _number;
        emit FreeMintNumberSet(_user, _number);
    }

    /**
     * @notice set early private sale number by address
     */
    function setEarlyPrivateSaleNumberByAddress(
        address _user,
        uint256 _number
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        earlyPrivateSaleNumberByAddress[_user] = _number;
        emit EarlyPrivateSaleNumberSet(_user, _number);
    }

    /**
     * @notice set private sale number by address
     */
    function setPrivateSaleNumberByAddress(
        address _user,
        uint256 _number
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        privateSaleNumberByAddress[_user] = _number;
        emit PrivateSaleNumberSet(_user, _number);
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////

    function pausePublicSale()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenPublicSaleNotPaused
    {
        pausedPublicSale = true;
    }

    function unpausePublicSale()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenPublicSalePaused
    {
        pausedPublicSale = false;
    }

    function pausePrivateSale()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenPrivateSaleNotPaused
    {
        pausedPrivateSale = true;
    }

    function unpausePrivateSale()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenPrivateSalePaused
    {
        pausedPrivateSale = false;
    }

    function pauseEarlyPrivateSale()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenEarlyPrivateSaleNotPaused
    {
        pausedEarlyPrivateSale = true;
    }

    function unpauseEarlyPrivateSale()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenEarlyPrivateSalePaused
    {
        pausedEarlyPrivateSale = false;
    }

    function pauseFreeMint()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenFreeMintNotPaused
    {
        pausedFreeMint = true;
    }

    function unpauseFreeMint()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenFreeMintPaused
    {
        pausedFreeMint = false;
    }

    // modifier
    modifier whenFreeMintNotPaused() {
        require(!pausedFreeMint, "Free Mint Paused");
        _;
    }

    modifier whenFreeMintPaused() {
        require(pausedFreeMint, "Free Mint Not Paused");
        _;
    }

    modifier whenPublicSaleNotPaused() {
        require(!pausedPublicSale, "Public Sale Paused");
        _;
    }

    modifier whenPublicSalePaused() {
        require(pausedPublicSale, "Public Sale Not Paused");
        _;
    }

    modifier whenEarlyPrivateSaleNotPaused() {
        require(!pausedEarlyPrivateSale, "Early Private Sale Paused");
        _;
    }

    modifier whenEarlyPrivateSalePaused() {
        require(pausedEarlyPrivateSale, "Early Private Sale Not Paused");
        _;
    }

    modifier whenPrivateSaleNotPaused() {
        require(!pausedPrivateSale, "Private Sale Paused");
        _;
    }

    modifier whenPrivateSalePaused() {
        require(pausedPrivateSale, "Private Sale Not Paused");
        _;
    }
}