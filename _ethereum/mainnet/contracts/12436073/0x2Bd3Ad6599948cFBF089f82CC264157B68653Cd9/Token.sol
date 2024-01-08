// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;
/** OpenZeppelin Dependencies Upgradeable */
// import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC20Upgradeable.sol";
/** OpenZepplin non-upgradeable Swap Token (hex3t) */
import "./IERC20.sol";
/** Local Interfaces */
import "./IToken.sol";

contract Token is
    IToken,
    Initializable,
    ERC20Upgradeable,
    AccessControlUpgradeable
{
    using SafeMathUpgradeable for uint256;

    /** Role Variables */
    bytes32 public constant MIGRATOR_ROLE = keccak256('MIGRATOR_ROLE');
    bytes32 private constant MANAGER_ROLE = keccak256('MANAGER_ROLE');
    bytes32 private constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 private constant SWAPPER_ROLE = keccak256('SWAPPER_ROLE');
    bytes32 private constant SETTER_ROLE = keccak256('SETTER_ROLE');

    IERC20 private swapToken;
    bool private swapIsOver;
    uint256 public swapTokenBalance;
    bool public init_;

    /** Role Modifiers */
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), 'Caller is not a minter');
        _;
    }

    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, _msgSender()), 'Caller is not a manager');
        _;
    }

    modifier onlyMigrator() {
        require(
            hasRole(MIGRATOR_ROLE, _msgSender()),
            'Caller is not a migrator'
        );
        _;
    }

    /** Initialize functions */
    function initialize(
        address _manager,
        address _migrator,
        string memory _name,
        string memory _symbol
    ) public initializer {
        _setupRole(MANAGER_ROLE, _manager);
        _setupRole(MIGRATOR_ROLE, _migrator);
        __ERC20_init(_name, _symbol);

        /** I do not understand this */
        swapIsOver = false;
    }

    function initSwapperAndSwapToken(address _swapToken, address _swapper)
        external
        onlyMigrator
    {
        /** Setup */
        _setupRole(SWAPPER_ROLE, _swapper);
        swapToken = IERC20(_swapToken);
    }

    function init(address[] calldata instances) external onlyMigrator {
        require(!init_, 'NativeSwap: init is active');
        init_ = true;

        for (uint256 index = 0; index < instances.length; index++) {
            _setupRole(MINTER_ROLE, instances[index]);
        }
        swapIsOver = true;
    }

    /** End initialize Functions */

    function getMinterRole() external pure returns (bytes32) {
        return MINTER_ROLE;
    }

    function getSwapperRole() external pure returns (bytes32) {
        return SWAPPER_ROLE;
    }

    function getSetterRole() external pure returns (bytes32) {
        return SETTER_ROLE;
    }

    function getSwapTOken() external view returns (IERC20) {
        return swapToken;
    }

    function getSwapTokenBalance(uint256) external view returns (uint256) {
        return swapTokenBalance;
    }

    function mint(address to, uint256 amount) external override onlyMinter {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external override onlyMinter {
        _burn(from, amount);
    }

    // Helpers
    function getNow() external view returns (uint256) {
        return now;
    }

    function transferFromDev(
        address to,
        address from,
        uint256 amount
    ) external onlyManager {
        _transferFromDev(to, from, amount);
    }

    /** Roles management - only for multi sig address */
    function setupRole(bytes32 role, address account) external onlyManager {
        _setupRole(role, account);
    }

    function recovery(
        address recoverFor,
        address tokenToRecover,
        uint256 amount
    ) external onlyMigrator {
        IERC20(tokenToRecover).transfer(recoverFor, amount);
    }
}
