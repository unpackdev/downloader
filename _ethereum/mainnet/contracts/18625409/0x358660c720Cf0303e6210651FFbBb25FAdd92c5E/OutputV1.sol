// Thunderhead: https://github.com/thunderhead-labs


// Author(s)
// Addison Spiegel: https://addison.is
// Pierre Spiegel: https://pierre.wtf

pragma solidity 0.8.20;

import "./IERC20.sol";
import "./stFlip.sol";
import "./BurnerV1.sol";
import "./RebaserV1.sol";
import "./StateChainGateway.sol";
import "./Ownership.sol";
import "./Initializable.sol";
import "./ProxyAdmin.sol";
import "./SafeCast.sol";

/**
 * @title Output contract for stFLIP
 * @notice Will hold all unstaked FLIP. Can stake/unstake to
 * whitelisted validators.
 */
contract OutputV1 is Initializable, Ownership {

    StateChainGateway public stateChainGateway; // StateChainGateway where FLIP goes for staking and comes from during unstaking
    BurnerV1 public wrappedBurnerProxy;
    RebaserV1 public wrappedRebaserProxy;
    IERC20 public flip;

    struct Validator {
        uint8 operatorId;          // the operator id of this validator
        bool whitelisted;          // determines whether staking to this address is allowed
        bool trackBalance;         // determines whether the rebaser should count this validator in balance calculations
    }

    struct ValidatorInfo {         // used for efficiency when rebaser queries validator info
        uint8 operatorId;
        bool trackBalance;
    }

    struct Operator {
        uint96 staked;             // cumulative amount of FLIP staked to this operator
        uint96 unstaked;           // cumulative amount of FLIP unstaked from this operator
        uint16 serviceFeeBps;      // percentage of rewards generated that go to the service
        uint16 validatorFeeBps;    // percentage of rewards generated that go to the operator
        bool whitelisted;          // whether or not this operator is whitelisted
        uint8 validatorAllowance;  // the number of validators this operator can add
        address manager;           // the operator controlled address that can add validators
        address feeRecipient;      // the address that receives the validator fee. This can be the manager - it is just for additional granularity.
        string name;               // the operators name 
    }   

    mapping (bytes32 => Validator) public validators;  
    bytes32[] public validatorAddresses;
    bytes32 public validatorAddressHash;
    Operator[] public operators;

    constructor () {
        _disableInitializers();
    }

    event ValidatorsAdded(uint256 indexed count, uint256 indexed operatorId);
    event ValidatorsWhitelistUpdated(uint256 indexed count, bool indexed status);
    event ValidatorsTrackBalanceUpdated(uint256 indexed count, bool indexed status);
    event ValidatorsStatusUpdated(uint256 indexed count, bool indexed whitelist, bool indexed trackBalance);
    event OperatorAdded(string indexed name, uint256 indexed serviceFeeBps, uint256 indexed validatorFeeBps, uint256 validatorAllowance, address manager);
    event ValidatorAllowanceUpdated(uint256 indexed newAllowance, uint256 indexed operatorId);
    event ValidatorsFunded(uint256 indexed count, uint256 indexed amount);
    event ValidatorsRedeemed(uint256 indexed count, uint256 indexed amount);
    event OperatorFeeUpdated(uint256 indexed serviceFeeBps, uint256 indexed validatorFeeBps, uint256 indexed operatorId);
    event OperatorWhitelistUpdated(uint256 indexed operatorId, bool indexed whitelist);

    error InsufficientOutputBalance();
    error NotManagerOfOperator();
    error OperatorNotWhitelisted();
    error CannotAddToNullOperator();
    error ValidatorAlreadyAdded();
    error ValidatorNotWhitelisted();
    error FeesExceedMax();
    error InputLengthsMustMatch();

    /**
     * 
     * @param flip_ The FLIP token address
     * @param burnerProxy_ Burner proxy address
     * @param gov_ The gov address
     * @param manager_ The manager address
     * @param stateChainGateway_ Statechain gateway address 
     * @param rebaser_ Rebaser contract address
     */
    function initialize(address flip_, address burnerProxy_, address gov_,  address manager_, address stateChainGateway_,address rebaser_) initializer public {
        flip = IERC20(flip_);

        __AccessControlDefaultAdminRules_init(0, gov_);
        _grantRole(MANAGER_ROLE, gov_);
        _grantRole(MANAGER_ROLE, manager_);

        stateChainGateway = StateChainGateway(stateChainGateway_);

        wrappedBurnerProxy = BurnerV1(burnerProxy_);
        wrappedRebaserProxy = RebaserV1(rebaser_);

        flip.approve(address(rebaser_), type(uint256).max);
        flip.approve(address(burnerProxy_), type(uint256).max);
        flip.approve(address(stateChainGateway), type(uint256).max);

        Operator memory operator = Operator(0, 0, 0, 0,false, 0, gov_, gov_,"null");
        operators.push(operator);
    }

    /** Adds validators so that they can be staked to
     * @param addresses The list of addresses to add to the map
     * @param operatorId the operator they should be added for
     * @dev Operators can add addresses to their list of validators
     * from their manager address. These addresses will not be stakeable initially.
     */
    function addValidators(bytes32[] calldata addresses, uint256 operatorId) external {
        if (operators[operatorId].manager != msg.sender) revert NotManagerOfOperator();
        if (operators[operatorId].whitelisted != true) revert OperatorNotWhitelisted();
        if (operatorId == 0) revert CannotAddToNullOperator();

        uint256 addressesLength = addresses.length;
        operators[operatorId].validatorAllowance -= SafeCast.toUint8(addressesLength);
        for (uint256 i; i < addressesLength; ++i) {
            if (validators[addresses[i]].operatorId != 0) revert ValidatorAlreadyAdded();

            validators[addresses[i]].operatorId = SafeCast.toUint8(operatorId);
            validators[addresses[i]].whitelisted = false;
            validatorAddresses.push(addresses[i]);
        }

        validatorAddressHash = keccak256(abi.encodePacked(validatorAddresses));

        emit ValidatorsAdded(addressesLength, operatorId);
    }

    /**
     * Whitelists specified validator addresses
     * @param addresses The list of addresses to whitelist
     * @param whitelist The whitelist status to set
     * @param trackBalance Whether or not to track the balance of the validator in rebase calculation
     * @dev We don't automatically whitelist validators when operators add
     * them. After they have been added, governance ensures that the withdrawal
     * address for those addresses has been locked to this output contract. Once
     * that has been confirmed then they can be whitelisted. Both `whitelist`
     * and `trackBalance` should be set to true for new validators. This function
     * exists for the case those values are not true and granular control is needed.
     * It is possible that a validator is no longer whitelisted but still has FLIP 
     * that needs to be counted. 
     */
    function setValidatorsStatus(bytes32[] calldata addresses, bool whitelist, bool trackBalance) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 addressesLength = addresses.length;
        for (uint256 i; i < addressesLength; ++i) {
            validators[addresses[i]].whitelisted = whitelist;
            validators[addresses[i]].trackBalance = trackBalance;
        }

        emit ValidatorsStatusUpdated(addressesLength, whitelist, trackBalance);
    }

    /**
     * Whitelists specified validator addresses
     * @param addresses The list of addresses to whitelist
     * @param whitelist The whitelist status to set
     */
    function setValidatorsWhitelist(bytes32[] calldata addresses, bool whitelist) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 addressesLength = addresses.length;
        for (uint256 i; i < addressesLength; ++i) {
            validators[addresses[i]].whitelisted = whitelist;
        }

        emit ValidatorsWhitelistUpdated(addressesLength, whitelist);

    }

    /**
     * Sets whether or not to track the balance of the validator in rebase calculation
     * @param addresses The list of addresses to set
     * @param trackBalance Whether or not to track the balance of the validator in rebase calculation
     * @dev We should never have to use this function.  
     */
    function setValidatorsTrackBalance(bytes32[] calldata addresses, bool trackBalance) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 addressesLength = addresses.length;
        for (uint256 i; i < addressesLength; ++i) {
            validators[addresses[i]].trackBalance = trackBalance;
        }

        emit ValidatorsTrackBalanceUpdated(addressesLength, trackBalance);
    }

    /**
     * Adds an operator to the list of operators
     * @param manager The manager address
     * @param name The operator name
     * @param serviceFeeBps The percentage of rewards generated that will go to the service
     * @param validatorFeeBps The percentage of the rewards generated that will go to the validator
     * @param validatorAllowance The number of validators this operator can add
     * @dev Initially this will just be Thunderhead team-ran validators, after we get going we will
     * put other operators through an onboarding process similar to Lido's. After vetting and identifying
     * the best operators governance can whitelist them. We have a validator allowance to ensure the 
     * address list does not become bloated
     */
    function addOperator(address manager, string calldata name, uint256 serviceFeeBps, uint256 validatorFeeBps, uint256 validatorAllowance) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (serviceFeeBps + validatorFeeBps > 10000) revert FeesExceedMax();

        Operator memory operator = Operator(0, 0, SafeCast.toUint16(serviceFeeBps), SafeCast.toUint16(validatorFeeBps),true, SafeCast.toUint8(validatorAllowance), manager, manager,name);
        operators.push(operator);

        emit OperatorAdded(name, serviceFeeBps, validatorFeeBps, validatorAllowance, manager);
    }

    /**
     * Sets validator allowance
     * @param allowance amount of validators to allow the operator to add
     * @param operatorId id of relevant operator
     */
    function setOperatorValidatorAllowance(uint256 allowance, uint256 operatorId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        operators[operatorId].validatorAllowance = SafeCast.toUint8(allowance);

        emit ValidatorAllowanceUpdated(allowance, operatorId);
    }

    /** Funds state chain accounts 
     * @param addresses The list of Chainflip validator addresses to fund (hex version)
     * @param amounts The list of amounts to fund each address with
     * @dev Only addresses in the `validators` map can be funded. An offchain service known
     * as the fund manager handles this. Chainflip's staking mechanics are complicated because
     * there is a fixed 150 validators and the set is determined via a staking auction. Each
     * auction cycle (every 30 days), we ensure that the FLIP is distributed across as many
     * validators as possible.
     */
    function fundValidators(bytes32[] calldata addresses, uint256[] calldata amounts) external onlyRole(MANAGER_ROLE) {
        uint256 addressesLength = addresses.length;
        if (addressesLength != amounts.length) revert InputLengthsMustMatch();

        Validator memory validator;
        uint8 operatorId_;
        uint256 total;
        for (uint i; i < addressesLength; ++i) {
            validator = validators[addresses[i]];
            operatorId_ = validator.operatorId;

            if (validator.whitelisted != true) revert ValidatorNotWhitelisted();
            if (operators[operatorId_].whitelisted != true) revert OperatorNotWhitelisted();

            operators[operatorId_].staked += SafeCast.toUint96(amounts[i]);
            stateChainGateway.fundStateChainAccount(addresses[i], amounts[i]);
            total += amounts[i];
        }

        emit ValidatorsFunded(addressesLength, total);

        if (flip.balanceOf(address(this)) < wrappedBurnerProxy.totalPendingBurns() + wrappedRebaserProxy.totalOperatorPendingFee() + wrappedRebaserProxy.servicePendingFee()) {
            revert InsufficientOutputBalance();
        }

    }

    /** Redeems funds from state chain accounts
     * @param addresses The list of Chainflip validator to redeem
     * @dev The redemptions must be first generated by the validators
     * on the Chainflip side, ensuring that a redemption executor address was specified.
     * After this, the chainflip network will call registerRedemption on the StateChainGateway 
     * to make the redemption eligible to be claimed. Only the output contract will be able to
     * execute the redemption
     */
    function redeemValidators(bytes32[] calldata addresses) external onlyRole(MANAGER_ROLE) {
        uint256 amount;
        uint256 addressesLength = addresses.length;
        uint256 total;
        for (uint i; i < addressesLength; ++i) {
            (,amount) = stateChainGateway.executeRedemption(addresses[i]);
            operators[validators[addresses[i]].operatorId].unstaked += SafeCast.toUint96(amount);
            total += amount;
        }

        emit ValidatorsRedeemed(addressesLength, total);
    }

    /**
     * Set operator fees
     * @param serviceFeeBps reward fee to the service
     * @param validatorFeeBps reward fee to the operator
     */
    function setOperatorFee(uint256 serviceFeeBps, uint256 validatorFeeBps, uint256 operatorId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (serviceFeeBps + validatorFeeBps > 10000) revert FeesExceedMax();
        
        operators[operatorId].serviceFeeBps = SafeCast.toUint16(serviceFeeBps);
        operators[operatorId].validatorFeeBps = SafeCast.toUint16(validatorFeeBps);

        emit OperatorFeeUpdated(serviceFeeBps, validatorFeeBps, operatorId);
    }

    /**
     * Set operator whitelist status
     * @param operatorId Operatorid of relevant operator
     * @param whitelist Whitelist status to set
     */
    function setOperatorWhitelist(uint256 operatorId, bool whitelist) external onlyRole(DEFAULT_ADMIN_ROLE) {
        operators[operatorId].whitelisted = whitelist;

        emit OperatorWhitelistUpdated(operatorId, whitelist);
    }

    /**
     * Return all validator addresses
     */
    function getValidators() external view returns (bytes32[] memory) {
        return validatorAddresses;
    }

    /**
     * Helper to hash the addresses offchain
     * @param addresses Validator addresses to hash
     */
    function computeValidatorHash(bytes32[] calldata addresses) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(addresses));
    }

    /**
     * Get number of all operators
     */
    function getOperatorCount() external view returns (uint256) {
        return operators.length;
    }

    /**
     * Returns relevant operator information
     * @param id ID of relevant operator
     * @return Operator staked counter
     * @return Operator unstaked counter
     * @return Operator service fee 
     * @return Operator validator fee
     * @dev Used for gas efficiency by the Rebaser contract since
     * the other information in the Operator struct is not relevant
     */
    function getOperatorInfo(uint256 id) external view returns (uint96, uint96, uint16, uint16) {
        return (operators[id].staked, operators[id].unstaked, operators[id].serviceFeeBps, operators[id].validatorFeeBps);
    }

    function getOperatorAddresses(uint256 id) external view returns (address, address) {
        return (operators[id].manager, operators[id].feeRecipient);
    }

    /**
     * Gets validator information
     * @param addresses Addresses of relevant validators
     * @return Operator ids of all the inputted addresses
     * @return Number of operators
     * @return Current validatorAddressHash
     * @dev Returns all this data in one call for gas efficiency
     * during the rebase calculation
     */
    function getValidatorInfo(bytes32[] calldata addresses) external view returns (ValidatorInfo[] memory, uint256, bool) {
        uint256 addressesLength = addresses.length;
        ValidatorInfo[] memory validatorInfo = new ValidatorInfo[](addressesLength);
        for (uint256 i; i < addressesLength; ++i) {
            validatorInfo[i].operatorId = validators[addresses[i]].operatorId;
            validatorInfo[i].trackBalance = validators[addresses[i]].trackBalance;
        }
        
        bool addressesEqual = validatorAddressHash == keccak256(abi.encodePacked(addresses));

        return (validatorInfo, operators.length, addressesEqual);
    }
    
    /**
     * Retrieves all validators that have `trackBalance == true`
     */
    function getCountableValidators() external view returns (bytes32[] memory) {
        bytes32 validatorToCheck;
        uint256 length = validatorAddresses.length;
        uint256 count;
        bytes32[] memory countableAddresses_ = new bytes32[](length);

        for (uint i; i < length; ++i) {
            validatorToCheck = validatorAddresses[i];
            if (validators[validatorToCheck].trackBalance == true) {
                countableAddresses_[count++] = validatorToCheck;
            }
        }

        bytes32[] memory countableAddresses = new bytes32[](count);

        for (uint i; i < count; ++i) {
            countableAddresses[i] = countableAddresses_[i];
        }

        return countableAddresses;
    }

}

