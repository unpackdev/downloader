//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IVaultCalculator.sol";
import "./IERC20.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";


contract Multiplier is AccessControlUpgradeSafe {
    using SafeMath for uint256;
    bytes32 public constant MODIFIER_ROLE = keccak256("MODIFIER_ROLE");

    // Stores the requirement range (balance >= r1 && balance < r2) and the corresponding ranges applied values
    struct Range {
        uint256 r1;
        uint256 r2;
        uint256 amount;
        bytes32 data;
    }

    struct SpendableInfo {
        uint256 amount;
        uint256 cost;
        bytes32 data;
    }

    struct ContractInfo {
        // Contract address -> Token used for global effect
        IERC20 globalEffectTokenForContract;
        // Global holding info per contract
        mapping(uint256 => Range) globalEffectInfos;
        uint256 globalEffectCount;
        // User -> Total Level (just total level bookkeeping);
        mapping(address => uint256) userTotalLevel;
        // User -> Token -> Level (Last purchased level for particular token in particular Contract
        mapping(address => mapping(address => uint256)) userLastLevelForTokenInContract;
        // Token -> Spendable amount, value and it's cost
        mapping(address => SpendableInfo[]) spendableInfos;
        // Tokens-array (what tokens are used in this particular contract)
        address[] spendableTokensPerContract;
        uint256 spendableTokenCountPerContract;
        // User -> Token -> AmountSpent (who much user has spent a particular token in this particular contract)
        mapping(address => mapping(address => uint256)) spentTokensPerContract;
        // User -> Value from spendables (total spendable multiplier for an user in a Contract)
        mapping(address => uint256) userValueFromSpending;
    }

    mapping(address => ContractInfo) public contracts;

    address[] public globalEffectUNITokens;
    IVaultCalculator VaultCalculator;

    /** @dev A regular initializer due proxy usage */
    function initialize(address _VaultCalculator) external initializer {
        require(_VaultCalculator != address(0), "!calc addr");
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        VaultCalculator = IVaultCalculator(_VaultCalculator);
    }

    /** @dev Set the contract and it's global effect token */
    function initializeGlobalEffect(address[] calldata _contracts, address _globalEffectToken) external onlyAdmin {
        for (uint256 i; i < _contracts.length; i++) {
            contracts[_contracts[i]].globalEffectTokenForContract = IERC20(_globalEffectToken);

            mapping(uint256 => Range) storage infoByIndex = contracts[_contracts[i]].globalEffectInfos;
            // Default values
            infoByIndex[1] = Range({r1: 5, r2: 15, amount: 50, data: ""});
            infoByIndex[2] = Range({r1: 15, r2: 30, amount: 100, data: ""});
            infoByIndex[3] = Range({r1: 30, r2: 60, amount: 250, data: ""});
            infoByIndex[4] = Range({r1: 60, r2: 2**256 - 1, amount: 500, data: ""});
            contracts[_contracts[i]].globalEffectCount = 4;
        }
    }

    /******************** FUNCIONALITY */
    /** @dev Keep track of user purchase amounts */
    function purchase(
        address _contract,
        address _user,
        address _token,
        uint256 _newLevel
    ) external onlyAuthorized {
        ContractInfo storage contractInfo = contracts[_contract];

        uint256 lastLevel = contractInfo.userLastLevelForTokenInContract[_user][_token];
        require(lastLevel < _newLevel, "new level must be greater than last");

        // Cost of the NEW level being purchased
        uint256 cost = getSpendableCostPerTokenForUser(_contract, _user, _token, _newLevel);
        require(cost > 0, "cost cannot be 0");

        // Get the old amount gained from spendables
        uint256 oldTotalValueFromSpending = contractInfo.userValueFromSpending[_user];

        uint256 lastLevelValueFromSpending = contractInfo.spendableInfos[_token][lastLevel].amount;
        // Add the new amount in cumulatively
        contractInfo.userValueFromSpending[_user] = contractInfo.spendableInfos[_token][_newLevel]
            .amount
            .sub(lastLevelValueFromSpending)
            .add(oldTotalValueFromSpending);

        // Add spent for this particular pool and token
        contractInfo.spentTokensPerContract[_user][_token] = contractInfo.spentTokensPerContract[_user][_token].add(
            cost
        );

        // Bookkeeping for total level
        contractInfo.userTotalLevel[_user] = contractInfo.userTotalLevel[_user].add(_newLevel.sub(lastLevel));
        contractInfo.userLastLevelForTokenInContract[_user][_token] = _newLevel;
    }

    /** @dev Adjust global values for a particular contract */
    function adjustGlobalEffectValues(address _contract, Range[] memory _ranges) external onlyAuthorized {
        ContractInfo storage contractInfo = contracts[_contract];
        for (uint256 i; i < _ranges.length; i++) {
            // Set index with an offset so it matches the level
            contractInfo.globalEffectInfos[i + 1] = _ranges[i];
        }
        contractInfo.globalEffectCount = _ranges.length;
    }

    /** @dev This function sets the tokens and their corresponding spendable amount info for a contract. */
    function addSpendableTokenForContract(
        address _contract,
        address _spendableToken,
        SpendableInfo[] memory _spendableInfos
    ) external onlyAuthorized {
        ContractInfo storage contractInfo = contracts[_contract];
        // Set the token if it does not exist
        if (contractInfo.spendableInfos[_spendableToken].length == 0) {
            contractInfo.spendableTokensPerContract.push(_spendableToken);
        }
        // Set the level prices
        uint256 length = _spendableInfos.length;
        for (uint256 i; i < length; i++) {
            contractInfo.spendableInfos[_spendableToken].push(_spendableInfos[i]);
        }
    }

    function removeSpendableTokenFromContract(address _contract, address _spendableToken) external onlyAuthorized {
        ContractInfo storage contractInfo = contracts[_contract];
        uint256 length = contractInfo.spendableTokensPerContract.length;
        for (uint256 i; i < length; i++) {
            if (contractInfo.spendableTokensPerContract[i] == _spendableToken) {
                contractInfo.spendableTokensPerContract[i] = contractInfo.spendableTokensPerContract[length - 1];
                contractInfo.spendableTokensPerContract.pop();
                break;
            }
        }
    }

    /******************** VIEWS */

    /** @dev Cheeck if the token supplied is actually used in the contract */
    function isSpendableTokenInContract(address _contract, address _token) external view returns (bool result) {
        ContractInfo memory contractInfo = contracts[_contract];
        uint256 length = contractInfo.spendableTokensPerContract.length;
        for (uint256 i; i < length; i++) {
            if (!result) {
                result = contractInfo.spendableTokensPerContract[i] == _token;
            } else break;
        }
    }

    /** @dev For ease of access supply a view for a particular tokens latest level for a particular user in a contract */
    function getLastTokenLevelForUser(
        address _contract,
        address _user,
        address _token
    ) external view returns (uint256) {
        return contracts[_contract].userLastLevelForTokenInContract[_user][_token];
    }

    /** @dev Return the sum of all spendable levels */
    function getTotalLevel(address _contract, address _user) external view returns (uint256) {
        return contracts[_contract].userTotalLevel[_user];
    }

    /** @dev Get particular tokens spent per particular contract and user */
    function getTokensSpentPerContract(
        address _contract,
        address _token,
        address _user
    ) external view returns (uint256) {
        return contracts[_contract].spentTokensPerContract[_user][_token];
    }

    /** @dev Get the level cost for particulart token in a particular contract */
    function getSpendableCostPerTokenForUser(
        address _contract,
        address _user,
        address _token,
        uint256 _level
    ) public view returns (uint256) {
        uint256 spent = contracts[_contract].spentTokensPerContract[_user][_token];
        uint256 cost = contracts[_contract].spendableInfos[_token][_level].cost;
        return cost.sub(spent);
    }

    /** @dev Get the total value for user in a pool, accounting for global */
    function getTotalValueForUser(address _contract, address _user) external view returns (uint256) {
        ContractInfo storage contractInfo = contracts[_contract];
        // Get underlying LP assets
        uint256 globalBalance = VaultCalculator.getUnderlyingToken(_user);

        // Values from spending
        uint256 spendingValue = contractInfo.userValueFromSpending[_user];

        // No need to calculate global balance if there is no tokens.
        if (globalBalance == 0) return spendingValue;

        // Get the decimals for the bonus token, RFI-derivates will most likely be 9 and uniswap lp tokens 18.
        uint8 decimals = contractInfo.globalEffectTokenForContract.decimals();
        uint256 multiplier = 1 * 10**uint256(decimals);

        // Convert the balance to match the values set in global
        uint256 globalBalanceEtherFormat = globalBalance.div(multiplier);
        uint256 globalValue;
        uint256 length = contractInfo.globalEffectCount;
        for (uint256 i = 1; i <= length; i++) {
            Range memory range = contractInfo.globalEffectInfos[i];
            if (globalBalanceEtherFormat >= range.r1 && globalBalanceEtherFormat < range.r2) {
                globalValue = range.amount;
            } else if (globalBalanceEtherFormat >= range.r2) {
                globalValue = range.amount;
            }
        }

        return spendingValue.add(globalValue);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "!admin");
        _;
    }

    modifier onlyAuthorized() {
        require(hasRole(MODIFIER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "!admin or !mod");
        _;
    }
}
