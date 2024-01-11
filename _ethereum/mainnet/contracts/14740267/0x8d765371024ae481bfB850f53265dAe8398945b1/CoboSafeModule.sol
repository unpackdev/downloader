// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;

import "EnumerableSet.sol";
import "GnosisSafe.sol";
import "Ownable.sol";

/// Interface of Protector
interface Protector {
    function check(bytes32 _role, bytes calldata data) external returns (bool);
}

/// @title A GnosisSafe module that implements Cobo's role based access control policy
/// @author Cobo Safe Dev Team (safe_devs@cobo.com)
/// @notice Use this module to access Gnosis Safe with role based access control policy
/// @dev This contract implements the core data structure and its related features.
contract CoboSafeModule is Ownable {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant NAME = "Cobo Safe Module";
    string public constant VERSION = "0.3.0";

    // Below are predefined roles: ROLE_HARVESTER
    //
    // Gnosis safe owners need to call to `grantRole(ROLE_XXX, delegate)` to grant permission to a delegate.

    // 'harvesters\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
    bytes32 public constant ROLE_HARVESTER =
        0x6861727665737465727300000000000000000000000000000000000000000000;

    /// @notice Event fired when a delegate is added
    /// @dev Event fired when a delegate is added via `grantRole` method
    /// @param delegate the delegate being added
    /// @param sender the owner who added the delegate
    event DelegateAdded(address indexed delegate, address indexed sender);

    /// @notice Event fired when a delegate is removed
    /// @dev Event fired when a delegate is remove via `revokeRole` method
    /// @param delegate the delegate being removed
    /// @param sender the owner who removed the delegate
    event DelegateRemoved(address indexed delegate, address indexed sender);

    /// @notice Event fired when a role is added
    /// @dev Event fired when a role is being added via `addRole` method
    /// @param role the role being added
    /// @param sender the owner who added the role
    event RoleAdded(bytes32 indexed role, address indexed sender);

    /// @notice Event fired when a role is grant to a delegate
    /// @dev Event fired when a role is grant to a delegate via `grantRole`
    /// @param role the role being granted
    /// @param delegate the delegate being granted the given role
    /// @param sender the owner who granted the role to the given delegate
    event RoleGranted(
        bytes32 indexed role,
        address indexed delegate,
        address indexed sender
    );

    /// @notice Event fired when a role is revoked from a delegate
    /// @dev Event fired when a role is revoked from a delegate via `revokeRole`
    /// @param role the role being revoked
    /// @param delegate the delegate being revoked the given role
    /// @param sender the owner who revoked the role from the given delegate
    event RoleRevoked(
        bytes32 indexed role,
        address indexed delegate,
        address indexed sender
    );

    /// @notice Event fired after a transaction is successfully executed by a delegate
    /// @dev Event fired after a transaction is successfully executed by a delegate via `execTransaction` method
    /// @param to the targate contract to execute the transaction
    /// @param value the ether value to be sent to the target contract when executing the transaction
    /// @param operation use `call` or `delegatecall` to execute the transaction on the contract
    /// @param data input data to execute the transaction on the given contract
    /// @param sender the delegate who execute the transaction
    event ExecTransaction(
        address indexed to,
        uint256 value,
        Enum.Operation operation,
        bytes data,
        address indexed sender
    );

    /// @notice Event fired when a role is associated with a contract and its function list
    /// @dev Event fired when a role is associated with a contract and its function list via `assocRoleWithContractFuncs`
    /// @param role the role to be associated with the given contract and function list
    /// @param _contract the target contract to be associated with the role
    /// @param funcList a list of function signatures of the given contract to be associated with the role
    /// @param sender the owner who associated the role with the contract and its function list
    event AssocContractFuncs(
        bytes32 indexed role,
        address indexed _contract,
        string[] funcList,
        address indexed sender
    );

    /// @notice Event fired when a role is disassociate from a contract and its function list
    /// @dev Event fired when a role is disassociate from a contract and its function list via `dissocRoleFromContractFuncs`
    /// @param role the role to be disassociated from the given contract and function list
    /// @param _contract the target contract to be disassociated from the role
    /// @param funcList a list of function signatures of the given contract to be disassociated from the role
    /// @param sender the owner who disassociated the role from the contract and its function list
    event DissocContractFuncs(
        bytes32 indexed role,
        address indexed _contract,
        string[] funcList,
        address indexed sender
    );

    /// @notice Event fired when a protector is installed to protect a contract
    /// @dev Event fired when a protector is installed to protect a contract via `installAclForContract`
    /// @param _contract the target contract to be protected
    /// @param _protector the contract to protect the target contract
    /// @param sender the owner who install the protector to the target contract
    event AclInstalled(
        address indexed _contract,
        address indexed _protector,
        address indexed sender
    );

    /// @notice Event fired when a protector is uninstalled from a contract
    /// @dev Event fired when the old protector is uninstalled from a contract
    ///      when install new protector via `installAclForContract`
    /// @param _contract the target contract to be uninstalled the protector
    /// @param _protector the contract to be uninstalled
    /// @param sender the owner who uninstall the protector from the target contract
    event AclUninstalled(
        address indexed _contract,
        address indexed _protector,
        address indexed sender
    );

    /// @notice Event fired when a call is checked by a protector
    /// @dev Event fired when the a call is checked via `_hasPermission`
    /// @param _contract the target contract to be execute
    /// @param _contractFunc the target contract function to be execute
    /// @param _protector the contract to check the access control
    /// @param _role the role to check the access control
    /// @param _data the original call data
    /// @param _success the result of access control checking
    /// @param sender the user who trigger the execution
    event AclChecked(
        address indexed _contract,
        bytes4 _contractFunc,
        address indexed _protector,
        bytes32 _role,
        bytes _data,
        bool _success,
        address indexed sender
    );

    /// @dev Tracks the set of granted delegates. The set is dynamically added
    ///      to or removed from by  `grantRole` and `rokeRole`.  `isDelegate`
    ///      also uses it to test if a caller is a valid delegate or not
    EnumerableSet.AddressSet delegateSet;

    /// @dev Tracks what roles each delegate owns. The mapping is dynamically
    ///      added to or removed from by  `grantRole` and `rokeRole`. `hasRole`
    ///      also uses it to test if a delegate is granted a given role or not
    mapping(address => EnumerableSet.Bytes32Set) delegateToRoles;

    /// @dev Tracks the set of roles. The set keeps track of all defined roles.
    ///      It is updated by `addRole`, and possibly by `removeRole` if to be
    ///      supported. All role based access policy checks against the set for
    ///      role validity.
    EnumerableSet.Bytes32Set roleSet;

    /// @dev Tracks the set of contract address. The set keeps track of contracts
    ///      which have been associated with a role. It is updated by
    ///      `assocRoleWithContractFuncs` and `dissocRoleFromContractFuncs`
    EnumerableSet.AddressSet contractSet;

    /// @dev mapping from `contract address` => `function selectors`
    mapping(address => EnumerableSet.Bytes32Set) contractToFuncs;

    /// @dev mapping from `contract address` => `function selectors` => `list of roles`
    mapping(address => mapping(bytes32 => EnumerableSet.Bytes32Set)) funcToRoles;

    /// @dev mapping from `contract address` => `protector contract address`
    mapping(address => address) public contractToProtector;

    /// @dev modifier to assert only delegate is allow to proceed
    modifier onlyDelegate() {
        require(isDelegate(_msgSender()), "must be delegate");
        _;
    }

    /// @dev modifier to assert the given role must be predefined
    /// @param role the role to be checked
    modifier roleDefined(bytes32 role) {
        require(roleSet.contains(role), "unrecognized role");
        _;
    }

    /// @notice Contructor function for CoboSafeModule
    /// @dev When this module is deployed, its ownership will be automatically
    ///      transferred to the given Gnosis safe instance. The instance is
    ///      supposed to call `enableModule` on the constructed module instance
    ///      in order for it to function properly.
    /// @param _safe the Gnosis Safe (GnosisSafeProxy) instance's address
    constructor(address payable _safe) {
        require(_safe != address(0), "invalid safe address");

        // Add default role. Use `addRole` to make sure `RoleAdded` event is fired
        addRole(ROLE_HARVESTER);

        // make the given safe the owner of the current module.
        _transferOwnership(_safe);
    }

    /// @notice Checks if an address is a permitted delegate
    /// @dev the address must have been granted role via `grantRole` in order to become a delegate
    /// @param delegate the address to be checked
    /// @return true|false
    function isDelegate(address delegate) public view returns (bool) {
        return delegateSet.contains(delegate);
    }

    /// @notice Grant a role to a delegate
    /// @dev Granting a role to a delegate will give delegate permission to call
    ///      contract functions associated with the role. Only owner can grant
    ///      role and the must be predefined and not granted to the delegate
    ///      already. on success, `RoleGranted` event would be fired and
    ///      possibly `DelegateAdded` as well if this is the first role being
    ///      granted to the delegate.
    /// @param role the role to be granted
    /// @param delegate the delegate to be granted role
    function grantRole(bytes32 role, address delegate)
        external
        onlyOwner
        roleDefined(role)
    {
        require(!_hasRole(role, delegate), "role already granted");

        delegateToRoles[delegate].add(role);

        // We need to emit `DelegateAdded` before `RoleGranted` to allow
        // subgraph event handler to process in sensible order.
        if (delegateSet.add(delegate)) {
            emit DelegateAdded(delegate, _msgSender());
        }

        emit RoleGranted(role, delegate, _msgSender());
    }

    /// @notice Revoke a role from a delegate
    /// @dev Revoking a role from a delegate will remove the permission the
    ///      delegate has to call contract functions associated with the role.
    ///      Only owner can revoke the role.  The role has to be predefined and
    ///      granted to the delegate before revoking, otherwise the function
    ///      will be reverted. `RoleRevoked` event would be fired and possibly
    ///      `DelegateRemoved` as well if this is the last role the delegate
    ///      owns.
    /// @param role the role to be granted
    /// @param delegate the delegate to be granted role
    function revokeRole(bytes32 role, address delegate)
        external
        onlyOwner
        roleDefined(role)
    {
        require(_hasRole(role, delegate), "role has not been granted");

        delegateToRoles[delegate].remove(role);

        // We need to make sure `RoleRevoked` is fired before `DelegateRemoved`
        // to make sure the event handlers in subgraphs are triggered in the
        // right order.
        emit RoleRevoked(role, delegate, _msgSender());

        if (delegateToRoles[delegate].length() == 0) {
            delegateSet.remove(delegate);
            emit DelegateRemoved(delegate, _msgSender());
        }
    }

    /// @notice Test if a delegate has a role
    /// @dev The role has be predefined or the function will be reverted.
    /// @param role the role to be checked
    /// @param delegate the delegate to be checked
    /// @return true|false
    function hasRole(bytes32 role, address delegate)
        external
        view
        roleDefined(role)
        returns (bool)
    {
        return _hasRole(role, delegate);
    }

    /// @notice Test if a delegate has a role (internal version)
    /// @dev This does the same check as hasRole, but avoid the checks on if the
    ///      role is defined. Internal functions can call this to save gas consumptions
    /// @param role the role to be checked
    /// @param delegate the delegate to be checked
    /// @return true|false
    function _hasRole(bytes32 role, address delegate)
        internal
        view
        returns (bool)
    {
        return delegateToRoles[delegate].contains(role);
    }

    /// @notice Add a new role
    /// @dev only owner can call this function, the role has to be a new role.
    ///      On success, `RoleAdded` event will be fired
    /// @param role the role to be added
    function addRole(bytes32 role) public onlyOwner {
        require(!roleSet.contains(role), "role exists");

        roleSet.add(role);

        emit RoleAdded(role, _msgSender());
    }

    /// @notice Call Gnosis Safe to execute a transaction
    /// @dev Delegates can call this method to invoke gnosis safe to forward to
    ///      transaction to target contract method `to`::`func`, where `func`
    ///      is the function selector contained in first 4 bytes of `data`.
    ///      The function can only be called by delegates.
    /// @param to The target contract to be called by Gnosis Safe
    /// @param data The input data to be called by Gnosis Safe
    ///
    /// TODO: implement EIP712 signature.
    function execTransaction(address to, bytes calldata data)
        external
        onlyDelegate
    {
        _execTransaction(to, data);
    }

    /// @notice Batch execute multiple transaction via Gnosis Safe
    /// @dev This is batch version of the `execTransaction` function to allow
    ///      the delegates to bundle multiple calls into a single transaction and
    ///      sign only once. Batch execute the transactions, one failure cause the
    ///      batch reverted. Only delegates are allowed to call this.
    /// @param toList list of contract addresses to be called
    /// @param dataList list of input data associated with each contract call
    function batchExecTransactions(
        address[] calldata toList,
        bytes[] calldata dataList
    ) external onlyDelegate {
        require(
            toList.length > 0 && toList.length == dataList.length,
            "invalid inputs"
        );

        for (uint256 i = 0; i < toList.length; i++) {
            _execTransaction(toList[i], dataList[i]);
        }
    }

    /// @dev The internal implementation of `execTransaction` and
    ///      `batchExecTransactions`, that invokes gnosis safe to forward to
    ///      transaction to target contract method `to`::`func`, where `func` is
    ///      the function selector contained in first 4 bytes of `data`.  The
    ///      function checks if the calling delegate has the required permission
    ///      to call the designated contract function before invoking Gnosis
    ///      Safe.
    /// @param to The target contract to be called by Gnosis Safe
    /// @param data The input data to be called by Gnosis Safe
    function _execTransaction(address to, bytes calldata data) internal {
        require(_hasPermission(_msgSender(), to, data), "permission denied");

        // execute the transaction from Gnosis Safe, note this call will bypass
        // safe owners confirmation.
        require(
            GnosisSafe(payable(owner())).execTransactionFromModule(
                to,
                0,
                data,
                Enum.Operation.Call
            ),
            "failed in execution in safe"
        );

        emit ExecTransaction(to, 0, Enum.Operation.Call, data, _msgSender());
    }

    /// @dev Internal function to check if a delegate has the permission to call a given contract function
    /// @param delegate the delegate to be checked
    /// @param to the target contract
    /// @param data the calldata to check the parameter
    /// @return true|false
    function _hasPermission(
        address delegate,
        address to,
        bytes calldata data
    ) internal returns (bool) {
        bytes32[] memory roles = getRolesByDelegate(delegate);

        bytes4 selector;
        assembly {
            selector := calldataload(data.offset)
        }

        EnumerableSet.Bytes32Set storage funcRoles = funcToRoles[to][selector];
        address protector = contractToProtector[to];
        for (uint256 index = 0; index < roles.length; index++) {
            if (funcRoles.contains(roles[index])) {
                if (protector != address(0)) {
                    bool success = Protector(protector).check(
                        roles[index],
                        data
                    );
                    emit AclChecked(
                        to,
                        selector,
                        protector,
                        roles[index],
                        data,
                        success,
                        _msgSender()
                    );
                    if (success) {
                        return true;
                    }
                } else {
                    return true;
                }
            }
        }
        return false;
    }

    /// @notice Associate a role with given contract funcs
    /// @dev only owners are allowed to call this function, the given role has
    ///      to be predefined. On success, the role will be associated with the
    ///      given contract function, `AssocContractFuncs` event will be fired.
    /// @param role the role to be associated
    /// @param _contract the contract address to be associated with the role
    /// @param funcList the list of contract functions to be associated with the role
    function assocRoleWithContractFuncs(
        bytes32 role,
        address _contract,
        string[] calldata funcList
    ) external onlyOwner roleDefined(role) {
        require(funcList.length > 0, "empty funcList");

        for (uint256 index = 0; index < funcList.length; index++) {
            bytes4 funcSelector = bytes4(keccak256(bytes(funcList[index])));
            bytes32 funcSelector32 = bytes32(funcSelector);
            funcToRoles[_contract][funcSelector32].add(role);
            contractToFuncs[_contract].add(funcSelector32);
        }

        contractSet.add(_contract);

        emit AssocContractFuncs(role, _contract, funcList, _msgSender());
    }

    /// @notice Dissociate a role from given contract funcs
    /// @dev only owners are allowed to call this function, the given role has
    ///      to be predefined. On success, the role will be disassociated from
    ///      the given contract function, `DissocContractFuncs` event will be
    ///      fired.
    /// @param role the role to be disassociated
    /// @param _contract the contract address to be disassociated from the role
    /// @param funcList the list of contract functions to be disassociated from the role
    function dissocRoleFromContractFuncs(
        bytes32 role,
        address _contract,
        string[] calldata funcList
    ) external onlyOwner roleDefined(role) {
        require(funcList.length > 0, "empty funcList");

        for (uint256 index = 0; index < funcList.length; index++) {
            bytes4 funcSelector = bytes4(keccak256(bytes(funcList[index])));
            bytes32 funcSelector32 = bytes32(funcSelector);
            funcToRoles[_contract][funcSelector32].remove(role);

            if (funcToRoles[_contract][funcSelector32].length() <= 0) {
                contractToFuncs[_contract].remove(funcSelector32);
            }
        }

        if (contractToFuncs[_contract].length() <= 0) {
            contractSet.remove(_contract);
        }

        emit DissocContractFuncs(role, _contract, funcList, _msgSender());
    }

    /// @notice Install acl contract for given contract
    /// @dev only owners are allowed to call this function. On success, the contract will
    ///      protector with the selector mapping, `AclInstalled` event will be fired,
    ///      `AclUninstalled` event may be fired when old protector existed.
    /// @param _contract the contract to be protected
    /// @param _protector the acl contract
    function installAclForContract(address _contract, address _protector)
        external
        onlyOwner
    {
        address oldProtector = contractToProtector[_contract];
        if (oldProtector != address(0)) {
            delete contractToProtector[_contract];
            emit AclUninstalled(_contract, oldProtector, _msgSender());
        }

        if (_protector != address(0)) {
            contractToProtector[_contract] = _protector;
            emit AclInstalled(_contract, _protector, _msgSender());
        }
    }

    /// @notice Get all the delegates who are currently granted any role
    /// @return list of delegate addresses
    function getAllDelegates() public view returns (address[] memory) {
        bytes32[] memory store = delegateSet._inner._values;
        address[] memory result;
        assembly {
            result := store
        }
        return result;
    }

    /// @notice Given a delegate, return all the roles granted to the delegate
    /// @return list of roles
    function getRolesByDelegate(address delegate)
        public
        view
        returns (bytes32[] memory)
    {
        return delegateToRoles[delegate]._inner._values;
    }

    /// @notice Get all the roles defined in the module
    /// @return list of roles
    function getAllRoles() external view returns (bytes32[] memory) {
        return roleSet._inner._values;
    }

    /// @notice Get all the contracts ever associated with any role
    /// @return list of contract addresses
    function getAllContracts() public view returns (address[] memory) {
        bytes32[] memory store = contractSet._inner._values;
        address[] memory result;
        assembly {
            result := store
        }
        return result;
    }

    /// @notice Given a contract, list all the function selectors of this contract associated with a role
    /// @param _contract the contract
    /// @return list of function selectors in the contract ever associated with a role
    function getFuncsByContract(address _contract)
        public
        view
        returns (bytes4[] memory)
    {
        bytes32[] memory store = contractToFuncs[_contract]._inner._values;
        bytes4[] memory result;
        assembly {
            result := store
        }
        return result;
    }

    /// @notice Given a function, list all the roles that have permission to access to them
    /// @param _contract the contract address
    /// @param funcSelector the function selector
    /// @return list of roles
    function getRolesByContractFunction(address _contract, bytes4 funcSelector)
        public
        view
        returns (bytes32[] memory)
    {
        return funcToRoles[_contract][funcSelector]._inner._values;
    }
}
