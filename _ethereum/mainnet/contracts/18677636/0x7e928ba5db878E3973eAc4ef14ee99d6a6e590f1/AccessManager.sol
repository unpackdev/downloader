// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AccessControl.sol";
import "./IAuthorizationContract.sol";

/// @author Swarm Markets
/// @title Access Manager for AssetToken Contract
/// @notice Contract to manage the Asset Token contracts
abstract contract AccessManager is AccessControl {
    error AM_Blacklisted(address _blacklistedAddress);
    /// @notice Role to be able to deploy an Asset Token
    bytes32 public constant ASSET_DEPLOYER_ROLE = keccak256("ASSET_DEPLOYER_ROLE");

    /// @dev This is a WAD on DSMATH representing 1
    uint256 public constant DECIMALS = 10 ** 18;
    /// @dev This is a proportion of 1 representing 100%, equal to a WAD
    uint256 public constant HUNDRED_PERCENT = 10 ** 18;

    /// @notice Structure to hold the Token Data
    /// @notice guardian and issuer of the contract
    /// @notice isFrozen: boolean to store if the contract is frozen
    /// @notice isOnSafeguard: state of the contract: false is ACTIVE // true is SAFEGUARD
    /// @notice positiveInterest: if the interest will be a positvie or negative one
    /// @notice interestRate: the interest rate set in AssetTokenData.setInterestRate() (percent per seconds)
    /// @notice rate: the interest determined by the formula. Default is 10**18
    /// @notice lastUpdate: last block where the update function was called
    /// @notice blacklist: account => bool (if bool = true, account is blacklisted)
    /// @notice agents: agents => bool(true or false) (enabled/disabled agent)
    /// @notice safeguardTransferAllow: allow certain addresses to transfer even on safeguard
    /// @notice authorizationsPerAgent: list of contracts of each agent to authorize a user
    /// @notice array of addresses. Each one is a contract with the isTxAuthorized function
    struct TokenData {
        address issuer;
        address guardian;
        bool isFrozen;
        bool isOnSafeguard;
        bool positiveInterest;
        uint256 interestRate;
        uint256 rate;
        uint256 lastUpdate;
        mapping(address => bool) blacklist;
        mapping(address => bool) agents;
        mapping(address => bool) safeguardTransferAllow;
        mapping(address => address) authorizationsPerAgent;
        address[] authorizationContracts;
    }

    /// @notice mapping of TokenData, entered by token Address
    mapping(address => TokenData) public tokensData;

    /// @dev this is just to have an estimation of qty and prevent innecesary looping
    uint256 public maxQtyOfAuthorizationLists;

    /// @notice Emitted when changed max quantity
    event ChangedMaxQtyOfAuthorizationLists(address indexed changedBy, uint newQty);

    /// @notice Emitted when Issuer is transferred
    event IssuerTransferred(address indexed _tokenAddress, address indexed _caller, address indexed _newIssuer);
    /// @notice Emitted when Guardian is transferred
    event GuardianTransferred(address indexed _tokenAddress, address indexed _caller, address indexed _newGuardian);

    /// @notice Emitted when Agent is added to the contract
    event AgentAdded(address indexed _tokenAddress, address indexed _caller, address indexed _newAgent);
    /// @notice Emitted when Agent is removed from the contract
    event AgentRemoved(address indexed _tokenAddress, address indexed _caller, address indexed _agent);

    /// @notice Emitted when an Agent list is transferred to another Agent
    event AgentAuthorizationListTransferred(
        address indexed _tokenAddress,
        address _caller,
        address indexed _newAgent,
        address indexed _oldAgent
    );

    /// @notice Emitted when an account is added to the Asset Token Blacklist
    event AddedToBlacklist(address indexed _tokenAddress, address indexed _account, address indexed _from);
    /// @notice Emitted when an account is removed from the Asset Token Blacklist
    event RemovedFromBlacklist(address indexed _tokenAddress, address indexed _account, address indexed _from);

    /// @notice Emitted when a contract is added to the Asset Token Authorization list
    event AddedToAuthorizationContracts(
        address indexed _tokenAddress,
        address indexed _contractAddress,
        address indexed _from
    );
    /// @notice Emitted when a contract is removed from the Asset Token Authorization list
    event RemovedFromAuthorizationContracts(
        address indexed _tokenAddress,
        address indexed _contractAddress,
        address indexed _from
    );

    /// @notice Emitted when an account is granted with the right to transfer on safeguard state
    event AddedTransferOnSafeguardAccount(address indexed _tokenAddress, address indexed _account);
    /// @notice Emitted when an account is revoked the right to transfer on safeguard state
    event RemovedTransferOnSafeguardAccount(address indexed _tokenAddress, address indexed _account);

    /// @notice Emitted when a new Asset Token is deployed and registered
    event TokenRegistered(address indexed _tokenAddress, address _caller);
    /// @notice Emitted when an  Asset Token is deleted
    event TokenDeleted(address indexed _tokenAddress, address _caller);

    /// @notice Emitted when the contract changes to safeguard mode
    event ChangedToSafeGuard(address indexed _tokenAddress);

    /// @notice Emitted when the contract gets frozen
    event FrozenContract(address indexed _tokenAddress);
    /// @notice Emitted when the contract gets unfrozen
    event UnfrozenContract(address indexed _tokenAddress);

    /// @notice Allow TRANSFER on Safeguard
    /// @param _tokenAddress address of the current token being managed
    /// @param _account the account to grant the right to transfer on safeguard state
    function allowTransferOnSafeguard(address _tokenAddress, address _account) external {
        onlyStoredToken(_tokenAddress);
        onlyIssuerOrGuardian(_tokenAddress, _msgSender());

        emit AddedTransferOnSafeguardAccount(_tokenAddress, _account);
        tokensData[_tokenAddress].safeguardTransferAllow[_account] = true;
    }

    /// @notice Removed TRANSFER on Safeguard
    /// @param _tokenAddress address of the current token being managed
    /// @param _account the account to be revoked from the right to transfer on safeguard state
    function preventTransferOnSafeguard(address _tokenAddress, address _account) external {
        onlyStoredToken(_tokenAddress);
        onlyIssuerOrGuardian(_tokenAddress, _msgSender());

        emit RemovedTransferOnSafeguardAccount(_tokenAddress, _account);
        tokensData[_tokenAddress].safeguardTransferAllow[_account] = false;
    }

    function changeMaxQtyOfAuthorizationLists(uint newMaxQty) public onlyRole(DEFAULT_ADMIN_ROLE) {
        maxQtyOfAuthorizationLists = newMaxQty;

        emit ChangedMaxQtyOfAuthorizationLists(msg.sender, newMaxQty);
    }

    /**
     * @notice Checks if the user is authorized by the agent
     * @dev This function verifies if the `_from` and `_to` addresses are authorized to perform a given `_amount`
     * transaction on the asset token contract `_tokenAddress`.
     * @param _tokenAddress The address of the current token being managed
     * @param _from The address to be checked if it's authorized
     * @param _to The address to be checked if it's authorized
     * @param _amount The amount of the operation to be made
     * @return bool Returns true if `_from` and `_to` are authorized to perform the transaction
     */
    function mustBeAuthorizedHolders(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool) {
        onlyStoredToken(_tokenAddress);

        require(_msgSender() == _tokenAddress, "AccessManager: caller must be tokenAddress");
        // This line below should never happen. A registered asset token shouldn't call
        // to this function with both addresses (from - to) in ZERO
        require(!(_from == address(0) && _to == address(0)), "AccessManager: from and to are addresses 0");

        address[2] memory addresses = [_from, _to];
        uint256 response = 0;
        uint256 arrayLength = addresses.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            if (addresses[i] != address(0)) {
                if (tokensData[_tokenAddress].blacklist[addresses[i]]) {
                    revert AM_Blacklisted(addresses[i]);
                }

                /// @dev the caller (the asset token contract) is an authorized holder
                if (addresses[i] == _tokenAddress && addresses[i] == _msgSender()) {
                    response++;
                    // this is a resource to avoid validating this contract in other system
                    addresses[i] = address(0);
                }
                if (!tokensData[_tokenAddress].isOnSafeguard) {
                    /// @dev on active state, issuer and agents are authorized holder
                    if (
                        addresses[i] == tokensData[_tokenAddress].issuer ||
                        tokensData[_tokenAddress].agents[addresses[i]]
                    ) {
                        response++;
                        // this is a resource to avoid validating agent/issuer in other system
                        addresses[i] = address(0);
                    }
                } else {
                    /// @dev on safeguard state, guardian is authorized holder
                    if (addresses[i] == tokensData[_tokenAddress].guardian) {
                        response++;
                        // this is a resource to avoid validating guardian in other system
                        addresses[i] = address(0);
                    }
                }

                /// each of these if statements are mutually exclusive, so response cannot be more than 2
            }
        }

        /// if response is more than 0 none of the address are:
        /// the asset token contract itself, agents, issuer or guardian
        /// if response is 1 there is one address which is one of the above
        /// if response is 2 both addresses are one of the above, no need to iterate in external list
        if (response < 2) {
            require(
                tokensData[_tokenAddress].authorizationContracts.length > 0,
                "AccessManager: token authorizations list is empty"
            );
            IAuthorizationContract authorizationList;
            for (uint256 i = 0; i < tokensData[_tokenAddress].authorizationContracts.length; i++) {
                authorizationList = IAuthorizationContract(tokensData[_tokenAddress].authorizationContracts[i]);
                if (authorizationList.isTxAuthorized(_tokenAddress, addresses[0], addresses[1], _amount)) {
                    return true;
                }
            }
        } else {
            return true;
        }
        return false;
    }

    /// @notice Changes the ISSUER
    /// @param _tokenAddress address of the current token being managed
    /// @param _newIssuer to be assigned in the contract
    function transferIssuer(address _tokenAddress, address _newIssuer) external {
        onlyStoredToken(_tokenAddress);
        require(
            _msgSender() == tokensData[_tokenAddress].issuer || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "AccessManager: only issuer or DEFAULT_ADMIN"
        );
        emit IssuerTransferred(_tokenAddress, _msgSender(), _newIssuer);
        tokensData[_tokenAddress].issuer = _newIssuer;
    }

    /// @notice Changes the GUARDIAN
    /// @param _tokenAddress address of the current token being managed
    /// @param _newGuardian to be assigned in the contract
    function transferGuardian(address _tokenAddress, address _newGuardian) external {
        onlyStoredToken(_tokenAddress);
        require(
            _msgSender() == tokensData[_tokenAddress].guardian || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "AccessManager: only guardian or DEFAULT_ADMIN"
        );
        emit GuardianTransferred(_tokenAddress, _msgSender(), _newGuardian);
        tokensData[_tokenAddress].guardian = _newGuardian;
    }

    /// @notice Adds an AGENT
    /// @param _tokenAddress address of the current token being managed
    /// @param _newAgent to be added
    function addAgent(address _tokenAddress, address _newAgent) external {
        onlyStoredToken(_tokenAddress);
        onlyIssuerOrGuardian(_tokenAddress, _msgSender());
        require(!tokensData[_tokenAddress].agents[_newAgent], "AccessManager: agent already exists");
        emit AgentAdded(_tokenAddress, _msgSender(), _newAgent);
        tokensData[_tokenAddress].agents[_newAgent] = true;
    }

    /// @notice Deletes an AGENT
    /// @param _tokenAddress address of the current token being managed
    /// @param _agent to be removed
    function removeAgent(address _tokenAddress, address _agent) external {
        onlyStoredToken(_tokenAddress);
        onlyIssuerOrGuardian(_tokenAddress, _msgSender());
        require(tokensData[_tokenAddress].agents[_agent], "AccessManager: agent not found");

        require(!_agentHasContractsAssigned(_tokenAddress, _agent), "AccessManager: agent has contracts assigned");

        emit AgentRemoved(_tokenAddress, _msgSender(), _agent);
        delete tokensData[_tokenAddress].agents[_agent];
    }

    /// @notice Transfers the authorization contracts to a new Agent
    /// @param _tokenAddress address of the current token being managed
    /// @param _newAgent to link the authorization list
    /// @param _oldAgent to unlink the authrization list
    function transferAgentList(address _tokenAddress, address _newAgent, address _oldAgent) external {
        onlyStoredToken(_tokenAddress);
        if (!tokensData[_tokenAddress].isOnSafeguard) {
            require(
                _msgSender() == tokensData[_tokenAddress].issuer || tokensData[_tokenAddress].agents[_msgSender()],
                "AccessManager: only agent or issuer (onActive)"
            );
        } else {
            require(_msgSender() == tokensData[_tokenAddress].guardian, "AccessManager: only guardian (onSafeguard)");
        }
        require(
            tokensData[_tokenAddress].authorizationContracts.length > 0,
            "AccessManager: token authorization list is empty"
        );
        require(_newAgent != _oldAgent, "AccessManager: newAgent is oldAgent");
        require(tokensData[_tokenAddress].agents[_oldAgent], "AccessManager: oldAgent not found");

        if (_msgSender() != tokensData[_tokenAddress].issuer && _msgSender() != tokensData[_tokenAddress].guardian) {
            require(_oldAgent == _msgSender(), "AccessManager: list is not owned");
        }
        require(tokensData[_tokenAddress].agents[_newAgent], "AccessManager: newAgent not found");

        (bool executionOk, bool changed) = _changeAuthorizationOwnership(_tokenAddress, _newAgent, _oldAgent);
        // this 2 lines below should never happen. The change list owner should always be successfull
        // because of the requires validating the information before calling _changeAuthorizationOwnership
        require(executionOk, "AccessManager: authorization list ownership transfer failed");
        require(changed, "AccessManager: agent has no contracts");
        emit AgentAuthorizationListTransferred(_tokenAddress, _msgSender(), _newAgent, _oldAgent);
    }

    /// @notice Adds an address to the authorization list
    /// @param _tokenAddress address of the current token being managed
    /// @param _contractAddress the address to be added
    function addToAuthorizationList(address _tokenAddress, address _contractAddress) external {
        onlyStoredToken(_tokenAddress);
        onlyAgent(_tokenAddress, _msgSender());
        require(_isContract(_contractAddress), "AccessManager: contractAddress is not contract");
        require(
            tokensData[_tokenAddress].authorizationsPerAgent[_contractAddress] == address(0),
            "AccessManager: contractAddress belongs to agent"
        );
        emit AddedToAuthorizationContracts(_tokenAddress, _contractAddress, _msgSender());
        tokensData[_tokenAddress].authorizationContracts.push(_contractAddress);
        tokensData[_tokenAddress].authorizationsPerAgent[_contractAddress] = _msgSender();
    }

    /// @notice Removes an address from the authorization list
    /// @param _tokenAddress address of the current token being managed
    /// @param _contractAddress the address to be removed
    function removeFromAuthorizationList(address _tokenAddress, address _contractAddress) external {
        onlyStoredToken(_tokenAddress);
        onlyAgent(_tokenAddress, _msgSender());
        require(_isContract(_contractAddress), "AccessManager: contractAddress is not contract");
        require(
            tokensData[_tokenAddress].authorizationsPerAgent[_contractAddress] != address(0),
            "AccessManager: contractAddress not found"
        );
        require(
            tokensData[_tokenAddress].authorizationsPerAgent[_contractAddress] == _msgSender(),
            "AccessManager: contract not managed by caller"
        );

        emit RemovedFromAuthorizationContracts(_tokenAddress, _contractAddress, _msgSender());

        // this line below should never happen. The removal should always be successfull
        // because of the require validating the caller before _removeFromAuthorizationArray
        require(
            _removeFromAuthorizationArray(_tokenAddress, _contractAddress),
            "AccessManager: failed removing from auth array"
        );
        delete tokensData[_tokenAddress].authorizationsPerAgent[_contractAddress];
    }

    /// @notice Adds an address to the blacklist
    /// @param _tokenAddress address of the current token being managed
    /// @param _account the address to be blacklisted
    function addMemberToBlacklist(address _tokenAddress, address _account) external {
        onlyStoredToken(_tokenAddress);
        onlyIssuerOrGuardian(_tokenAddress, _msgSender());
        require(!tokensData[_tokenAddress].blacklist[_account], "AccessManager: account is already blacklisted");
        emit AddedToBlacklist(_tokenAddress, _account, _msgSender());
        tokensData[_tokenAddress].blacklist[_account] = true;
    }

    /// @notice Removes an address from the blacklist
    /// @param _tokenAddress address of the current token being managed
    /// @param _account the address to be removed from the blacklisted
    function removeMemberFromBlacklist(address _tokenAddress, address _account) external {
        onlyStoredToken(_tokenAddress);
        onlyIssuerOrGuardian(_tokenAddress, _msgSender());
        require(tokensData[_tokenAddress].blacklist[_account], "AccessManager: account is not blacklisted");
        emit RemovedFromBlacklist(_tokenAddress, _account, _msgSender());
        delete tokensData[_tokenAddress].blacklist[_account];
    }

    /// @notice Register the asset tokens and its rates in this contract
    /// @param _tokenAddress address of the current token being managed
    /// @param _issuer address of the contract issuer
    /// @param _guardian address of the contract guardian
    /// @return bool true if operation was successful
    function registerAssetToken(address _tokenAddress, address _issuer, address _guardian) external returns (bool) {
        require(_tokenAddress != address(0), "AccessManager: tokenAddress is address 0");
        require(_issuer != address(0), "AccessManager: issuer is address 0");
        require(_guardian != address(0), "AccessManager: guardian is address 0");
        // slither-disable-next-line incorrect-equality
        require(tokensData[_tokenAddress].issuer == address(0), "AccessManager: token already registered");
        require(_isContract(_tokenAddress), "AccessManager: tokenAddress must be contract");
        require(hasRole(ASSET_DEPLOYER_ROLE, _msgSender()), "AccessManager: only ASSET_DEPLOYER");

        emit TokenRegistered(_tokenAddress, _msgSender());

        TokenData storage newTokenData = tokensData[_tokenAddress];
        newTokenData.issuer = _issuer;
        newTokenData.guardian = _guardian;
        newTokenData.rate = DECIMALS;
        newTokenData.lastUpdate = block.timestamp;

        return true;
    }

    /// @notice Deletes the asset token from this contract
    /// @notice It has no real use (I think should be removed)
    /// @param _tokenAddress address of the current token being managed
    function deleteAssetToken(address _tokenAddress) external {
        onlyStoredToken(_tokenAddress);
        onlyUnfrozenContract(_tokenAddress);
        onlyIssuerOrGuardian(_tokenAddress, _msgSender());

        emit TokenDeleted(_tokenAddress, _msgSender());
        // slither-disable-next-line mapping-deletion
        delete tokensData[_tokenAddress];
    }

    /// @notice Set the contract into Safeguard)
    /// @param _tokenAddress address of the current token being managed
    /// @return bool true if operation was successful
    function setContractToSafeguard(address _tokenAddress) external returns (bool) {
        onlyStoredToken(_tokenAddress);
        onlyUnfrozenContract(_tokenAddress);
        onlyActiveContract(_tokenAddress);
        require(_msgSender() == _tokenAddress, "AccessManager: only tokenAddress");
        emit ChangedToSafeGuard(_tokenAddress);
        tokensData[_tokenAddress].isOnSafeguard = true;
        return true;
    }

    /// @notice Freeze the contract
    /// @param _tokenAddress address of the current token being managed
    /// @return bool true if operation was successful
    function freezeContract(address _tokenAddress) external returns (bool) {
        onlyStoredToken(_tokenAddress);
        require(_msgSender() == _tokenAddress, "AccessManager: only tokenAddress");

        emit FrozenContract(_tokenAddress);
        tokensData[_tokenAddress].isFrozen = true;
        return true;
    }

    /// @notice Unfreeze the contract
    /// @param _tokenAddress address of the current token being managed
    /// @return bool true if operation was successful
    function unfreezeContract(address _tokenAddress) external returns (bool) {
        onlyStoredToken(_tokenAddress);
        require(_msgSender() == _tokenAddress, "AccessManager: only tokenAddress");

        emit UnfrozenContract(_tokenAddress);
        tokensData[_tokenAddress].isFrozen = false;
        return true;
    }

    /// @notice Check if the token is valid
    /// @param _tokenAddress address of the current token being managed
    function onlyStoredToken(address _tokenAddress) public view {
        require(tokensData[_tokenAddress].issuer != address(0), "AccessManager: token address is address 0");
    }

    /// @notice Check if the token contract is Not frozen
    /// @param _tokenAddress address of the current token being managed
    function onlyUnfrozenContract(address _tokenAddress) public view {
        require(!tokensData[_tokenAddress].isFrozen, "AccessManager: token address frozen");
    }

    /// @notice Check if the token contract is Active
    /// @param _tokenAddress address of the current token being managed
    function onlyActiveContract(address _tokenAddress) public view {
        require(!tokensData[_tokenAddress].isOnSafeguard, "AccessManager: token address not active (onSafeguard)");
    }

    /// @notice Check if sender is the ISSUER
    /// @param _tokenAddress address of the current token being managed
    /// @param _functionCaller the caller of the function where this is used
    function onlyIssuer(address _tokenAddress, address _functionCaller) external view {
        // slither-disable-next-line incorrect-equality
        require(_functionCaller == tokensData[_tokenAddress].issuer, "AccessManager: only issuer");
    }

    /// @notice Check if sender is an AGENT
    /// @param _tokenAddress address of the current token being managed
    /// @param _functionCaller the caller of the function where this is used
    function onlyAgent(address _tokenAddress, address _functionCaller) public view {
        require(tokensData[_tokenAddress].agents[_functionCaller], "AccessManager: only agent");
    }

    /// @notice Check if sender is AGENT_or ISSUER
    /// @param _tokenAddress address of the current token being managed
    /// @param _functionCaller the caller of the function where this is used
    function onlyIssuerOrAgent(address _tokenAddress, address _functionCaller) external view {
        // slither-disable-next-line incorrect-equality
        require(
            _functionCaller == tokensData[_tokenAddress].issuer || tokensData[_tokenAddress].agents[_functionCaller],
            "AccessManager: only issuer or agent"
        );
    }

    /// @notice Check if sender is GUARDIAN or ISSUER
    /// @param _tokenAddress address of the current token being managed
    /// @param _functionCaller the caller of the function where this is used
    function onlyIssuerOrGuardian(address _tokenAddress, address _functionCaller) public view {
        if (tokensData[_tokenAddress].isOnSafeguard) {
            // slither-disable-next-line incorrect-equality
            require(
                _functionCaller == tokensData[_tokenAddress].guardian,
                "AccessManager: only Guardian (onSafeguard)"
            );
        } else {
            // slither-disable-next-line incorrect-equality
            require(_functionCaller == tokensData[_tokenAddress].issuer, "AccessManager: only Issuer (onActive)");
        }
    }

    /// @notice Return if the account can transfer on safeguard
    /// @param _tokenAddress address of the current token being managed
    /// @param _account the account to get info from
    /// @return bool true or false
    function isAllowedTransferOnSafeguard(address _tokenAddress, address _account) external view returns (bool) {
        onlyStoredToken(_tokenAddress);
        return tokensData[_tokenAddress].safeguardTransferAllow[_account];
    }

    /// @notice Get if the contract is on SafeGuard or not
    /// @param _tokenAddress address of the current token being managed
    /// @return bool true if the contract is on SafeGuard
    function isOnSafeguard(address _tokenAddress) external view returns (bool) {
        onlyStoredToken(_tokenAddress);
        return tokensData[_tokenAddress].isOnSafeguard;
    }

    /// @notice Get if the contract is frozen or not
    /// @param _tokenAddress address of the current token being managed
    /// @return bool true if the contract is frozen
    function isContractFrozen(address _tokenAddress) external view returns (bool) {
        onlyStoredToken(_tokenAddress);
        return tokensData[_tokenAddress].isFrozen;
    }

    /// @notice Get the issuer of the asset token
    /// @param _tokenAddress address of the current token being managed
    /// @return address the issuer address
    function getIssuer(address _tokenAddress) external view returns (address) {
        onlyStoredToken(_tokenAddress);
        return tokensData[_tokenAddress].issuer;
    }

    /// @notice Get the guardian of the asset token
    /// @param _tokenAddress address of the current token being managed
    /// @return address the guardian address
    function getGuardian(address _tokenAddress) external view returns (address) {
        onlyStoredToken(_tokenAddress);
        return tokensData[_tokenAddress].guardian;
    }

    /// @notice Get if the account is blacklisted for the asset token
    /// @param _tokenAddress address of the current token being managed
    /// @return bool true if the account is blacklisted
    function isBlacklisted(address _tokenAddress, address _account) external view returns (bool) {
        onlyStoredToken(_tokenAddress);
        return tokensData[_tokenAddress].blacklist[_account];
    }

    /// @notice Get if the account is an agent of the asset token
    /// @param _tokenAddress address of the current token being managed
    /// @return bool true if account is an agent
    function isAgent(address _tokenAddress, address _agentAddress) external view returns (bool) {
        onlyStoredToken(_tokenAddress);
        return tokensData[_tokenAddress].agents[_agentAddress];
    }

    /// @notice Get the agent address who was responsable of the validation contract (_contractAddress)
    /// @param _tokenAddress address of the current token being managed
    /// @return address of the agent
    function authorizationContractAddedBy(
        address _tokenAddress,
        address _contractAddress
    ) external view returns (address) {
        onlyStoredToken(_tokenAddress);
        return tokensData[_tokenAddress].authorizationsPerAgent[_contractAddress];
    }

    /// @notice Get the position (index) in the authorizationContracts array of the authorization contract
    /// @param _tokenAddress address of the current token being managed
    /// @return uint256 the index of the array
    function getIndexByAuthorizationAddress(
        address _tokenAddress,
        address _authorizationContractAddress
    ) external view returns (uint256) {
        onlyStoredToken(_tokenAddress);
        uint256 arrayLength = tokensData[_tokenAddress].authorizationContracts.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            // slither-disable-next-line incorrect-equality
            if (tokensData[_tokenAddress].authorizationContracts[i] == _authorizationContractAddress) {
                return i;
            }
        }
        /// @dev returning this when address is not found
        return maxQtyOfAuthorizationLists + 1;
    }

    /// @notice Get the authorization contract address given an index in authorizationContracts array
    /// @param _tokenAddress address of the current token being managed
    /// @return address the address of the authorization contract
    function getAuthorizationAddressByIndex(address _tokenAddress, uint256 _index) external view returns (address) {
        require(
            _index < tokensData[_tokenAddress].authorizationContracts.length,
            "AccessManager: index does not exist"
        );
        return tokensData[_tokenAddress].authorizationContracts[_index];
    }

    /* *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */

    /// @notice Returns true if `account` is a contract
    /// @param _contractAddress the address to be ckecked
    /// @return bool if `account` is a contract
    function _isContract(address _contractAddress) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(_contractAddress)
        }
        return size > 0;
    }

    /// @notice checks if the agent has a contract from the array list assigned
    /// @param _tokenAddress address of the current token being managed
    /// @param _agent agent to check
    /// @return bool if the agent has any contract assigned
    function _agentHasContractsAssigned(address _tokenAddress, address _agent) internal view returns (bool) {
        uint256 arrayLength = tokensData[_tokenAddress].authorizationContracts.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            if (
                // slither-disable-next-line incorrect-equality
                tokensData[_tokenAddress].authorizationsPerAgent[tokensData[_tokenAddress].authorizationContracts[i]] ==
                _agent
            ) {
                return true;
            }
        }
        return false;
    }

    /// @notice changes the owner of the contracts auth array
    /// @param _tokenAddress address of the current token being managed
    /// @param _newAgent target agent to link the contracts to
    /// @param _oldAgent source agent to unlink the contracts from
    /// @return bool true if there was no error
    /// @return bool true if authorization ownership has occurred
    function _changeAuthorizationOwnership(
        address _tokenAddress,
        address _newAgent,
        address _oldAgent
    ) internal returns (bool, bool) {
        bool changed = false;
        uint256 arrayLength = tokensData[_tokenAddress].authorizationContracts.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            if (
                // slither-disable-next-line incorrect-equality
                tokensData[_tokenAddress].authorizationsPerAgent[tokensData[_tokenAddress].authorizationContracts[i]] ==
                _oldAgent
            ) {
                tokensData[_tokenAddress].authorizationsPerAgent[
                    tokensData[_tokenAddress].authorizationContracts[i]
                ] = _newAgent;
                changed = true;
            }
        }
        return (true, changed);
    }

    /// @notice removes contract from auth array
    /// @param _tokenAddress address of the current token being managed
    /// @param _contractAddress to be removed
    /// @return bool if address was removed
    function _removeFromAuthorizationArray(address _tokenAddress, address _contractAddress) internal returns (bool) {
        uint256 arrayLength = tokensData[_tokenAddress].authorizationContracts.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            // slither-disable-next-line incorrect-equality
            if (tokensData[_tokenAddress].authorizationContracts[i] == _contractAddress) {
                tokensData[_tokenAddress].authorizationContracts[i] = tokensData[_tokenAddress].authorizationContracts[
                    arrayLength - 1
                ];
                tokensData[_tokenAddress].authorizationContracts.pop();
                return true;
            }
        }
        // This line below should never happen. Before calling this function,
        // it is known that the address exists in the array
        return false;
    }
}
