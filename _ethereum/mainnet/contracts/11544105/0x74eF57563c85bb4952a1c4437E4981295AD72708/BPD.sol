// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/** OpenZeppelin Dependencies (Via NodeModules) */
// import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
/** Local Interfaces */
import "./IBPD.sol";

contract BPD is IBPD, Initializable, AccessControlUpgradeable {
	using SafeMathUpgradeable for uint256;

    /** Role Vars */
    bytes32 public constant MIGRATOR_ROLE = keccak256("MIGRATOR_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
	bytes32 public constant SWAP_ROLE = keccak256("SWAP_ROLE");
    bytes32 public constant SUBBALANCE_ROLE = keccak256("SUBBALANCE_ROLE");

    /** BPD Mapping */
    uint256[5] public poolYearAmounts;
    bool[5] public poolTransferred;
    uint256[5] public poolYearPercentages;

    /** Address Vars */
    address public mainToken;
    /** Constants */
	uint256 public constant PERCENT_DENOMINATOR = 100;
    /** Booleans */
    bool public init_;

    /** With upgradeable contracts, there is no need for a setter role as initialize can only be called once. */
    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Caller is not a manager");
        _;
    }

    modifier onlySwapper() {
        require(hasRole(SWAP_ROLE, _msgSender()), "Caller is not a swapper");
        _;
    }

    modifier onlySubBalance() {
        require(hasRole(SUBBALANCE_ROLE, _msgSender()), "Caller is not a Sub Balance");
        _;
    }

    modifier onlyMigrator() {
        require(hasRole(MIGRATOR_ROLE, _msgSender()), "Caller is not a migrator");
        _;
    }

    /** initializers */
    function initialize(
        address _manager,
        address _migrator
    ) public initializer {
        _setupRole(MANAGER_ROLE, _manager);
        _setupRole(MIGRATOR_ROLE, _migrator);
        poolYearPercentages = [10, 15, 20, 25, 30];
        init_ = false;
    }

    function init(
        address _mainToken,
        address _foreignSwap,
        address _subBalancePool
    ) public onlyMigrator {
        require(!init_, "Init is active");
        init_ = true;
        /** Setup */
        _setupRole(SWAP_ROLE, _foreignSwap);
        _setupRole(SUBBALANCE_ROLE, _subBalancePool);
        mainToken = _mainToken;
    }
    /** end initializers */

    function getPoolYearAmounts() external view override returns (uint256[5] memory poolAmounts) {
        return poolYearAmounts;
    }

    function getClosestPoolAmount() public view returns (uint256 poolAmount) {
         for (uint256 i = 0; i < poolYearAmounts.length; i++) {
            if (poolTransferred[i]) {
                continue;
            } else {
                poolAmount = poolYearAmounts[i];
                break;
            }

            // return 0;
        }
    }

    function callIncomeTokensTrigger(uint256 incomeAmountToken) external override onlySwapper {
    	require(hasRole(SWAP_ROLE, _msgSender()), "Caller is not a swap role");

        // Divide income to years
        uint256 part = incomeAmountToken.div(PERCENT_DENOMINATOR);

        uint256 remainderPart = incomeAmountToken;
        for (uint256 i = 0; i < poolYearAmounts.length; i++) {
            if (i != poolYearAmounts.length - 1) {
                uint256 poolPart = part.mul(poolYearPercentages[i]);
                poolYearAmounts[i] = poolYearAmounts[i].add(poolPart);
                remainderPart = remainderPart.sub(poolPart);
            } else {
                poolYearAmounts[i] = poolYearAmounts[i].add(remainderPart);
            }
        }
    }

    function transferYearlyPool(uint256 poolNumber) external override onlySubBalance returns (uint256 transferAmount) {
    	require(hasRole(SUBBALANCE_ROLE, _msgSender()), "Caller is not a subbalance role");

        for (uint256 i = 0; i < poolYearAmounts.length; i++) {
            if (poolNumber == i) {
                require(!poolTransferred[i], "Already transferred");
                transferAmount = poolYearAmounts[i];
                poolTransferred[i] = true;

                IERC20Upgradeable(mainToken).transfer(_msgSender(), transferAmount);
                return transferAmount;
            }
        }
    }

    /** Roles management - only for multi sig address */
    function setupRole(bytes32 role, address account) external onlyManager {
        _setupRole(role, account);
    }
}
