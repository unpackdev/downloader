// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/*

  ,----..                                                 ____                        ___
 /   /   \                                              ,'  , `. ,--,               ,--.'|_
|   :     : __  ,-.  ,---.                           ,-+-,.' _ ,--.'|        ,---,  |  | :,'
.   |  ;. ,' ,'/ /| '   ,'\  .--.--.   .--.--.    ,-+-. ;   , ||  |,     ,-+-. /  | :  : ' :
.   ; /--`'  | |' |/   /   |/  /    ' /  /    '  ,--.'|'   |  |`--'_    ,--.'|'   .;__,'  /
;   | ;   |  |   ,.   ; ,. |  :  /`./|  :  /`./ |   |  ,', |  |,' ,'|  |   |  ,"' |  |   |
|   : |   '  :  / '   | |: |  :  ;_  |  :  ;_   |   | /  | |--''  | |  |   | /  | :__,'| :
.   | '___|  | '  '   | .; :\  \    `.\  \    `.|   : |  | ,   |  | :  |   | |  | | '  : |__
'   ; : .';  : |  |   :    | `----.   \`----.   |   : |  |/    '  : |__|   | |  |/  |  | '.'|
'   | '/  |  , ;   \   \  / /  /`--'  /  /`--'  |   | |`-'     |  | '.'|   | |--'   ;  :    ;
|   :    / ---'     `----' '--'.     '--'.     /|   ;/         ;  :    |   |/       |  ,   /
 \   \ .'                    `--'---'  `--'---' '---'          |  ,   /'---'         ---`-'
  `---`                                                         ---`-'

*/

// Interfaces
import "./IERC20.sol";
import "./ICrossmintUpgradeable.sol";

// libraries
import "./Address.sol";
import "./SafeERC20.sol";

// Contracts
import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./Initializable.sol";

/// @title CrossmintTreasury
contract CrossmintTreasury is Initializable, AccessControlUpgradeable, UUPSUpgradeable, ICrossmintUpgradeable {
    using Address for address;
    using SafeERC20 for IERC20;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
    }

    struct TokenTransaction {
        address to;
        address token;
        uint256 amount;
        bytes data;
    }

    uint256 public constant ALLOWANCE_GAS_BUFFER = 2;
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    ////////////
    // Events //
    ////////////

    event TokenAddedToAllowlist(address indexed token);
    event TokenRemovedFromAllowlist(address indexed token);
    event Execution(address indexed token, address indexed spender, uint256 amount);

    ////////////
    // Errors //
    ////////////

    error InsufficientFunds(uint256 amount, uint256 balance);
    error TokenNotAllowed();
    error NonDustAllowance(uint256 allowance);
    error NonContractAddress();
    error ZeroAddressNotAllowed();
    error ExecutionOnAllowlistedToken();

    /////////////////////
    // State Variables //
    /////////////////////

    mapping(address => bool) private s_tokenAllowlist;

    ///////////////
    // Functions //
    ///////////////

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address[] calldata adminAccounts,
        address[] calldata treasuryAccounts,
        address[] calldata initialTokens
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setRoleAdmin(TREASURY_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

        for (uint256 i = 0; i < adminAccounts.length; i++) {
            if (adminAccounts[i] == address(0)) {
                revert ZeroAddressNotAllowed();
            }

            _grantRole(ADMIN_ROLE, adminAccounts[i]);
        }

        for (uint256 i = 0; i < treasuryAccounts.length; i++) {
            if (treasuryAccounts[i] == address(0)) {
                revert ZeroAddressNotAllowed();
            }

            _grantRole(TREASURY_ROLE, treasuryAccounts[i]);
        }

        for (uint256 i = 0; i < initialTokens.length; i++) {
            if (initialTokens[i] == address(0)) {
                revert ZeroAddressNotAllowed();
            }

            s_tokenAllowlist[initialTokens[i]] = true;
        }
    }

    fallback() external payable {}
    receive() external payable {}

    /////////////////////////////////
    // External Treasury Functions //
    /////////////////////////////////

    function execute(Transaction calldata txn) external payable onlyRole(TREASURY_ROLE) {
        _execute(txn.to, txn.value, txn.data);
    }

    function executeBatch(Transaction[] calldata txns) external payable onlyRole(TREASURY_ROLE) {
        for (uint256 i = 0; i < txns.length; i++) {
            _execute(txns[i].to, txns[i].value, txns[i].data);
        }
    }

    function approveAndExecute(TokenTransaction calldata txn) external onlyRole(TREASURY_ROLE) {
        if (!s_tokenAllowlist[address(txn.token)]) {
            revert TokenNotAllowed();
        }

        uint256 balance = IERC20(txn.token).balanceOf(address(this));
        if (balance < txn.amount) {
            revert InsufficientFunds(txn.amount, balance);
        }

        uint256 currentAllowance = IERC20(txn.token).allowance(address(this), txn.to);
        if (currentAllowance == 0) {
            IERC20(txn.token).safeIncreaseAllowance(txn.to, txn.amount + ALLOWANCE_GAS_BUFFER);
        } else {
            IERC20(txn.token).safeIncreaseAllowance(txn.to, txn.amount);
        }

        _execute(txn.to, 0, txn.data);

        /// @dev enforce allowance invariant
        uint256 allowanceAfter = IERC20(txn.token).allowance(address(this), txn.to);
        if (allowanceAfter != ALLOWANCE_GAS_BUFFER) {
            revert NonDustAllowance(allowanceAfter);
        }
    }

    //////////////////////////////
    // External Admin Functions //
    //////////////////////////////

    function addTokenToAllowlist(address token) external onlyRole(ADMIN_ROLE) {
        if (!token.isContract()) {
            revert NonContractAddress();
        }

        s_tokenAllowlist[token] = true;
    }

    function removeTokenFromAllowlist(address token) external onlyRole(ADMIN_ROLE) {
        s_tokenAllowlist[token] = false;
    }

    function withdrawTokens(address token, address recipient, uint256 amount) external onlyRole(ADMIN_ROLE) {
        if (!s_tokenAllowlist[address(token)]) {
            revert TokenNotAllowed();
        }

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance < amount) {
            revert InsufficientFunds(amount, balance);
        }

        IERC20(token).safeTransfer(recipient, amount);
    }

    function withdraw(address payable to, uint256 amount) external onlyRole(ADMIN_ROLE) {
        Address.sendValue(to, amount);
    }

    /////////////////////////////
    // External View Functions //
    /////////////////////////////

    function tokenOnAllowlist(address token) external view returns (bool) {
        return s_tokenAllowlist[token];
    }

    function getVersion() external pure returns (string memory version) {
        return "0.1";
    }

    ////////////////////////////////////
    // Private and Internal Functions //
    ////////////////////////////////////

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(ADMIN_ROLE) {}

    function _execute(address to, uint256 value, bytes calldata data) internal {
        if (s_tokenAllowlist[to]) {
            revert ExecutionOnAllowlistedToken();
        }

        to.functionCallWithValue(data, value);
    }
}
