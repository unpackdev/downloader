//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

/*
    ▓█████▄ ▓█████   █████▒██▓    ▓█████  ▄████▄  ▄▄▄█████▓ ▒█████   ██▀███
    ▒██▀ ██▌▓█   ▀ ▓██   ▒▓██▒    ▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒▒██▒  ██▒▓██ ▒ ██▒
    ░██   █▌▒███   ▒████ ░▒██░    ▒███   ▒▓█    ▄ ▒ ▓██░ ▒░▒██░  ██▒▓██ ░▄█ ▒
    ░▓█▄   ▌▒▓█  ▄ ░▓█▒  ░▒██░    ▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ ▒██   ██░▒██▀▀█▄
    ░▒████▓ ░▒████▒░▒█░   ░██████▒░▒████▒▒ ▓███▀ ░  ▒██▒ ░ ░ ████▓▒░░██▓ ▒██▒
     ▒▒▓  ▒ ░░ ▒░ ░ ▒ ░   ░ ▒░▓  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   ░ ▒░▒░▒░ ░ ▒▓ ░▒▓░
     ░ ▒  ▒  ░ ░  ░ ░     ░ ░ ▒  ░ ░ ░  ░  ░  ▒       ░      ░ ▒ ▒░   ░▒ ░ ▒░
     ░ ░  ░    ░    ░ ░     ░ ░      ░   ░          ░      ░ ░ ░ ▒    ░░   ░
       ░       ░  ░           ░  ░   ░  ░░ ░                   ░ ░     ░
     ░                                   ░
*/

import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeMath.sol";


/** @dev This contract handles token effects on contracts.
 *  Default values set used for percentages should be divided by 1000.
 */

contract Deflector is AccessControlUpgradeSafe {
    using SafeMath for uint256;
    bytes32 public constant MODIFIER_ROLE = keccak256("MODIFIER_ROLE");

    mapping(address => IERC20) public globalEffectTokenForContract;

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

    // Global holding info per contract
    mapping(address => mapping(uint256 => Range)) public globalEffectInfos;
    mapping(address => uint256) public globalEffectCounts;

    // Contract -> User -> Total Level (just total level bookkeeping);
    mapping(address => mapping(address => uint256)) public userTotalLevel;

    // Contract -> User -> Token -> Level (Last purchased level for particular token in particular Contract
    mapping(address => mapping(address => mapping(address => uint256))) public userLastLevelForTokenInContract;

    // Contract -> Token -> Spendable amount, value and it's cost
    mapping(address => mapping(address => SpendableInfo[])) public spendableInfos;

    // Contract -> Tokens-array (what tokens are used in this particular contract)
    mapping(address => address[]) public spendableTokensPerContract;
    mapping(address => uint256) public spendableTokenCountPerContract;

    // Contract -> User -> Token -> AmountSpent (who much user has spent a particular token in this particular contract)
    mapping(address => mapping(address => mapping(address => uint256))) public spentTokensPerContract;

    // Contract -> User -> Value from spendables (total spendable multiplier for an user in a Contract)
    mapping(address => mapping(address => uint256)) public userValueFromSpending;

    function initialize() external initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function initializeGlobalEffect(address[] memory _contracts, address _globalEffectToken) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Slaps!");
        for (uint256 i; i < _contracts.length; i++) {
            globalEffectTokenForContract[_contracts[i]] = IERC20(_globalEffectToken);
            // Default values
            globalEffectInfos[_contracts[i]][1] = Range({r1: 25, r2: 125, amount: 20, data: ""});
            globalEffectInfos[_contracts[i]][2] = Range({r1: 125, r2: 250, amount: 100, data: ""});
            globalEffectInfos[_contracts[i]][3] = Range({r1: 250, r2: 500, amount: 250, data: ""});
            globalEffectInfos[_contracts[i]][4] = Range({r1: 500, r2: 2**256 - 1, amount: 500, data: ""});
            globalEffectCounts[_contracts[i]] = 4;
        }
    }

    /******************** FUNCIONALITY */
    /** @dev Keep track of user purchase amounts */
    function purchase(
        address _contract,
        address _user,
        address _token,
        uint256 _newLevel
    ) external {
        require(hasRole(MODIFIER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Slaps!");
        uint256 cost = getSpendableCostPerTokenForUser(_contract, _user, _token, _newLevel);

        uint256 oldTotalValueFromSpending = userValueFromSpending[_contract][_user];

        // Add cumulatively
        userValueFromSpending[_contract][_user] = spendableInfos[_contract][_token][_newLevel].amount.add(oldTotalValueFromSpending);

        // Add spent for this particular pool and token
        spentTokensPerContract[_contract][_user][_token] = spentTokensPerContract[_contract][_user][_token].add(cost);

        // Bookkeeping for total level
        uint256 lastLevel = userLastLevelForTokenInContract[_contract][_token][_user];
        userTotalLevel[_contract][_user] = userTotalLevel[_contract][_user].add(_newLevel.sub(lastLevel));
        userLastLevelForTokenInContract[_contract][_token][_user] = _newLevel;
    }

    /** @dev Set the global token for a contract. */
    function setGlobalEffectToken(address _contract, address _token) external {
        require(hasRole(MODIFIER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Slaps!");
        globalEffectTokenForContract[_contract] = IERC20(_token);
    }

    /** @dev Adjust global values for a particular contract */
    function adjustGlobalEffectValues(address _contract, Range[] memory _ranges) external {
        require(hasRole(MODIFIER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Slaps!");
        for (uint256 i; i < _ranges.length; i++) {
            globalEffectInfos[_contract][i + 1] = Range({r1: _ranges[i].r1, r2: _ranges[i].r2, amount: _ranges[i].amount, data: _ranges[i].data});
        }
        globalEffectCounts[_contract] = _ranges.length;
    }

    /** @dev This function sets the tokens and their corresponding spendable amount info for a pool. */
    function addSpendableTokenForContract(
        address _contract,
        address _spendableToken,
        SpendableInfo[] memory _spendableInfos,
        uint256 _tokenDecimals
    ) external {
        require(hasRole(MODIFIER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Slaps!");

        // Set the spendables used
        spendableTokensPerContract[_contract].push(_spendableToken);
        spendableTokenCountPerContract[_contract]++;

        delete spendableInfos[_contract][_spendableToken];
        uint256 multiplier = 1 * 10**_tokenDecimals;
        // Set the level prices
        for (uint256 i; i < _spendableInfos.length; i++) {
            spendableInfos[_contract][_spendableToken].push(SpendableInfo({amount: _spendableInfos[i].amount, cost: _spendableInfos[i].cost.mul(multiplier), data: _spendableInfos[i].data}));
        }
    }

    function removeSpendableTokenFromContract(address _contract, address _spendableToken) external {
        require(hasRole(MODIFIER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Slaps!");
        for (uint256 i; i < spendableTokensPerContract[_contract].length; i++) {
            if (spendableTokensPerContract[_contract][i] == _spendableToken) {
                delete spendableTokensPerContract[_contract][i];
            }
        }
        spendableTokenCountPerContract[_contract]--;
    }

    /******************** VIEWS */
    function isSpendableTokenInContract(address _contract, address _token) external view returns (bool) {
        bool result;
        for (uint256 i; i < spendableTokensPerContract[_contract].length; i++) {
            if (!result) {
                result = spendableTokensPerContract[_contract][i] == _token;
            } else break;
        }
        return result;
    }

    function getLastTokenLevelForUser(
        address _contract,
        address _user,
        address _token
    ) external view returns (uint256) {
        return userLastLevelForTokenInContract[_contract][_token][_user];
    }

    function getTotalLevel(address _contract, address _user) external view returns (uint256) {
        return userTotalLevel[_contract][_user];
    }

    /** @dev Get particular tokens spent per particular pool and user */
    function getTokensSpentPerContract(
        address _contract,
        address _token,
        address _user
    ) external view returns (uint256) {
        return spentTokensPerContract[_contract][_token][_user];
    }

    /** @dev Get particular level cost for particulart token for particular contract */
    function getSpendableCostPerTokenForUser(
        address _contract,
        address _user,
        address _token,
        uint256 _level
    ) public view returns (uint256) {
        uint256 spent = spentTokensPerContract[_contract][_user][_token];
        uint256 cost = spendableInfos[_contract][_token][_level].cost;
        return cost.sub(spent);
    }

    /** @dev Get the total value for user in a pool, accounting for global */
    function getTotalValueForUser(address _contract, address _user) external view returns (uint256) {
        uint256 globalBalanceBig = globalEffectTokenForContract[_contract].balanceOf(_user);
        if (globalBalanceBig == 0) return 0;
        uint256 globalBalance = globalBalanceBig.div(1e18);
        uint256 globalValue;
        for (uint256 i = 1; i <= globalEffectCounts[_contract]; i++) {
            Range memory range = globalEffectInfos[_contract][i];
            if (globalBalance >= range.r1 && globalBalance < range.r2) {
                globalValue = range.amount;
            } else if (globalBalance >= range.r2) {
                globalValue = range.amount;
            }
        }
        return userValueFromSpending[_contract][_user].add(globalValue);
    }
}
