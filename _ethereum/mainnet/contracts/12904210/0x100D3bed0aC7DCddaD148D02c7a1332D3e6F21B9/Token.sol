// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;
/** OpenZeppelin Dependencies Upgradeable */
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

    // Protection */
    mapping(address => uint256) public _timeOfLastTransfer;
    mapping(address => bool) public _blacklist;
    mapping(address => bool) public _whitelist;
    bool public timeLimited;
    mapping(address => bool) public pairs;
    mapping(address => bool) public routers;
    uint256 public timeBetweenTransfers;

    // Black list for bots */
    modifier isBlackedListed(address sender, address recipient) {
        require(
            _blacklist[sender] == false,
            'ERC20: Account is blacklisted from transferring'
        );
        _;
    }

    // Role Modifiers */
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

    /** Roles management - only for multi sig address */
    function setupRole(bytes32 role, address account) external onlyManager {
        _setupRole(role, account);
    }

    function managerTransfer(
        address to,
        address from,
        uint256 amount
    ) external onlyManager {
        _transfer(from, to, amount);
    }

    function recovery(
        address recoverFor,
        address tokenToRecover,
        uint256 amount
    ) external onlyMigrator {
        IERC20(tokenToRecover).transfer(recoverFor, amount);
    }

    // protection
    function isTimeLimited(address sender, address recipient) internal {
        if (
            timeLimited &&
            _whitelist[recipient] == false &&
            _whitelist[sender] == false
        ) {
            address toDisable = sender;
            if (pairs[sender] == true) {
                toDisable = recipient;
            } else if (pairs[recipient] == true) {
                toDisable = sender;
            }

            if (
                pairs[toDisable] == true ||
                routers[toDisable] == true ||
                toDisable == address(0)
            ) return; // Do nothing as we don't want to disable router

            if (_timeOfLastTransfer[toDisable] == 0) {
                _timeOfLastTransfer[toDisable] = block.timestamp;
            } else {
                require(
                    block.timestamp - _timeOfLastTransfer[toDisable] >
                        timeBetweenTransfers,
                    'ERC20: Time since last transfer must be greater then time to transfer'
                );
                _timeOfLastTransfer[toDisable] = block.timestamp;
            }
        }
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        isBlackedListed(msg.sender, recipient)
        returns (bool)
    {
        isTimeLimited(msg.sender, recipient);
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override isBlackedListed(sender, recipient) returns (bool) {
        isTimeLimited(sender, recipient);
        _transfer(sender, recipient, amount);

        return true;
    }

    function setTimeLimited(bool _timeLimited) external onlyManager {
        timeLimited = _timeLimited;
    }

    function setTimeBetweenTransfers(uint256 _timeBetweenTransfers)
        external
        onlyManager
    {
        timeBetweenTransfers = _timeBetweenTransfers;
    }

    function setPair(address _pair, bool _isPair) external onlyManager {
        pairs[_pair] = _isPair;
    }

    function setRouter(address _router, bool _isRouter) external onlyManager {
        routers[_router] = _isRouter;
    }

    function setBlackListedAddress(address account, bool blacklisted)
        external
        onlyManager()
    {
        _blacklist[account] = blacklisted;
    }

    function setWhiteListedAddress(address _address, bool _whitelisted)
        external
        onlyManager
    {
        _whitelist[_address] = _whitelisted;
    }
}
