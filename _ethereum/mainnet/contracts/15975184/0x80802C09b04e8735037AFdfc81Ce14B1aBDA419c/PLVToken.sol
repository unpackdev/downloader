//
//  ________  ___       ___      ___
// |\   __  \|\  \     |\  \    /  /|
// \ \  \|\  \ \  \    \ \  \  /  / /
//  \ \   ____\ \  \    \ \  \/  / /
//   \ \  \___|\ \  \____\ \    / /
//    \ \__\    \ \_______\ \__/ /
//     \|__|     \|_______|\|__|/
//
// Paralverse PLV Token
//
// by @G2#5600
//
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;
import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./ERC20Pausable.sol";

contract PLVToken is ERC20, ERC20Burnable, ERC20Snapshot, ERC20Pausable, Ownable {
    string public constant NAME = "Paralverse Token";
    string public constant SYMBOL = "PLV";
    uint8 private constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 5 * 1e10 * (10**uint256(DECIMALS));

    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public isMinter;

    event Blacklisted(address indexed account, bool value);
    event SetMinter(address indexed _minter, bool _isMinter);

    /* ==================== MODIFIERS ==================== */

    modifier onlyMinter() {
        require(isMinter[_msgSender()], "onlyMinter: only minter can call this operation");
        _;
    }

    /* ==================== METHODS ==================== */
    constructor() ERC20(NAME, SYMBOL) {
        _initialize();
    }

    /**
     * @dev send full amount of tokens to minter
     */
    function _initialize() internal onlyOwner {
        isMinter[_msgSender()] = true;
        mint(_msgSender(), INITIAL_SUPPLY);
    }

    /* ==================== GETTER METHODS ==================== */

    function decimals() public view virtual override returns (uint8) {
        return DECIMALS;
    }

    /* ==================== INTERNAL METHODS ==================== */

    /**
     * @dev check black list transactions and block transactions
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Snapshot, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);

        require(!isBlacklisted[from] && !isBlacklisted[to], "Account blacklisted");
    }

    /* ==================== OWNER METHODS ==================== */

    /**
     * @dev flag black account
     *
     * @param _who Account to be blocked
     * @param _value block status of true/false
     */
    function blacklistMalicious(address _who, bool _value) external onlyOwner {
        isBlacklisted[_who] = _value;

        emit Blacklisted(_who, _value);
    }

    /**
     * @dev set minter permission to address
     *
     * @param _who Address of minter
     * @param _isMinter status of minter - ture/false
     */
    function setMinter(address _who, bool _isMinter) external onlyOwner {
        require(_who != address(0), "invalid minter address");
        isMinter[_who] = _isMinter;

        emit SetMinter(_who, _isMinter);
    }

    /**
     * @dev owner can pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function snapshot() external onlyOwner {
        _snapshot();
    }

    function mint(address _to, uint256 _amount) public onlyMinter {
        require(_to != address(0), "Invalid address");
        _mint(_to, _amount);
    }
}
