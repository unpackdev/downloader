pragma solidity ^0.5.16;

import "./ApeErc20.sol";
import "./ApeToken.sol";
import "./EIP20NonStandardInterface.sol";

contract ApeTokenAdmin is Exponential {
    uint256 public constant timeLock = 2 days;

    /// @notice Admin address
    address payable public admin;

    /// @notice Reserve manager address
    address payable public reserveManager;

    /// @notice Admin queue
    mapping(address => mapping(address => uint256)) public adminQueue;

    /// @notice Implementation queue
    mapping(address => mapping(address => uint256)) public implementationQueue;

    /// @notice Emits when a new admin is assigned
    event SetAdmin(address indexed oldAdmin, address indexed newAdmin);

    /// @notice Emits when a new reserve manager is assigned
    event SetReserveManager(address indexed oldReserveManager, address indexed newAdmin);

    /// @notice Emits when a new apeToken pending admin is queued
    event PendingAdminQueued(address indexed apeToken, address indexed newPendingAdmin, uint256 expiration);

    /// @notice Emits when a new apeToken pending admin is cleared
    event PendingAdminCleared(address indexed apeToken, address indexed newPendingAdmin);

    /// @notice Emits when a new apeToken pending admin becomes active
    event PendingAdminChanged(address indexed apeToken, address indexed newPendingAdmin);

    /// @notice Emits when a new apeToken implementation is queued
    event ImplementationQueued(address indexed apeToken, address indexed newImplementation, uint256 expiration);

    /// @notice Emits when a new apeToken implementation is cleared
    event ImplementationCleared(address indexed apeToken, address indexed newImplementation);

    /// @notice Emits when a new apeToken implementation becomes active
    event ImplementationChanged(address indexed apeToken, address indexed newImplementation);

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "only the admin may call this function");
        _;
    }

    /**
     * @dev Throws if called by any account other than the reserve manager.
     */
    modifier onlyReserveManager() {
        require(msg.sender == reserveManager, "only the reserve manager may call this function");
        _;
    }

    constructor(address payable _admin) public {
        _setAdmin(_admin);
    }

    /**
     * @notice Get block timestamp
     */
    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice Get apeToken admin
     * @param apeToken The apeToken address
     */
    function getApeTokenAdmin(address apeToken) public view returns (address) {
        return ApeToken(apeToken).admin();
    }

    /**
     * @notice Queue apeToken pending admin
     * @param apeToken The apeToken address
     * @param newPendingAdmin The new pending admin
     */
    function _queuePendingAdmin(address apeToken, address payable newPendingAdmin) external onlyAdmin {
        require(apeToken != address(0) && newPendingAdmin != address(0), "invalid input");
        require(adminQueue[apeToken][newPendingAdmin] == 0, "already in queue");
        uint256 expiration = add_(getBlockTimestamp(), timeLock);
        adminQueue[apeToken][newPendingAdmin] = expiration;

        emit PendingAdminQueued(apeToken, newPendingAdmin, expiration);
    }

    /**
     * @notice Clear apeToken pending admin
     * @param apeToken The apeToken address
     * @param newPendingAdmin The new pending admin
     */
    function _clearPendingAdmin(address apeToken, address payable newPendingAdmin) external onlyAdmin {
        adminQueue[apeToken][newPendingAdmin] = 0;

        emit PendingAdminCleared(apeToken, newPendingAdmin);
    }

    /**
     * @notice Toggle apeToken pending admin
     * @param apeToken The apeToken address
     * @param newPendingAdmin The new pending admin
     */
    function _togglePendingAdmin(address apeToken, address payable newPendingAdmin)
        external
        onlyAdmin
        returns (uint256)
    {
        uint256 result = adminQueue[apeToken][newPendingAdmin];
        require(result != 0, "not in queue");
        require(result <= getBlockTimestamp(), "queue not expired");

        adminQueue[apeToken][newPendingAdmin] = 0;

        emit PendingAdminChanged(apeToken, newPendingAdmin);

        return ApeTokenInterface(apeToken)._setPendingAdmin(newPendingAdmin);
    }

    /**
     * @notice Accept apeToken admin
     * @param apeToken The apeToken address
     */
    function _acceptAdmin(address apeToken) external onlyAdmin returns (uint256) {
        return ApeTokenInterface(apeToken)._acceptAdmin();
    }

    /**
     * @notice Set apeToken comptroller
     * @param apeToken The apeToken address
     * @param newComptroller The new comptroller address
     */
    function _setComptroller(address apeToken, ComptrollerInterface newComptroller)
        external
        onlyAdmin
        returns (uint256)
    {
        return ApeTokenInterface(apeToken)._setComptroller(newComptroller);
    }

    /**
     * @notice Set apeToken reserve factor
     * @param apeToken The apeToken address
     * @param newReserveFactorMantissa The new reserve factor
     */
    function _setReserveFactor(address apeToken, uint256 newReserveFactorMantissa)
        external
        onlyAdmin
        returns (uint256)
    {
        return ApeTokenInterface(apeToken)._setReserveFactor(newReserveFactorMantissa);
    }

    /**
     * @notice Reduce apeToken reserve
     * @param apeToken The apeToken address
     * @param reduceAmount The amount of reduction
     */
    function _reduceReserves(address apeToken, uint256 reduceAmount) external onlyAdmin returns (uint256) {
        return ApeTokenInterface(apeToken)._reduceReserves(reduceAmount);
    }

    /**
     * @notice Set apeToken IRM
     * @param apeToken The apeToken address
     * @param newInterestRateModel The new IRM address
     */
    function _setInterestRateModel(address apeToken, InterestRateModel newInterestRateModel)
        external
        onlyAdmin
        returns (uint256)
    {
        return ApeTokenInterface(apeToken)._setInterestRateModel(newInterestRateModel);
    }

    /**
     * @notice Set apeToken borrow fee
     * @param apeToken The apeToken address
     * @param newBorrowFee The new borrow fee
     */
    function _setBorrowFee(address apeToken, uint256 newBorrowFee) external onlyAdmin {
        ApeTokenInterface(apeToken)._setBorrowFee(newBorrowFee);
    }

    /**
     * @notice Set apeToken helper
     * @param apeToken The apeToken address
     * @param newHelper the new helper
     */
    function _setHelper(address apeToken, address newHelper) external onlyAdmin {
        ApeTokenInterface(apeToken)._setHelper(newHelper);
    }

    /**
     * @notice sets apeToken snapshot vote delegation
     * @param apeToken The apeToken address
     * @param delegateContract the delegation contract
     * @param id the space ID
     * @param delegate the delegate address
     */
    function _setDelegate(
        address apeToken,
        address delegateContract,
        bytes32 id,
        address delegate
    ) external onlyAdmin {
        ApeTokenInterface(apeToken)._setDelegate(delegateContract, id, delegate);
    }

    /**
     * @notice Set apeToken collateral cap
     * @dev It will revert if the apeToken is not CCollateralCap.
     * @param apeToken The apeToken address
     * @param newCollateralCap The new collateral cap
     */
    function _setCollateralCap(address apeToken, uint256 newCollateralCap) external onlyAdmin {
        ApeCollateralCapErc20Interface(apeToken)._setCollateralCap(newCollateralCap);
    }

    /**
     * @notice Queue apeToken pending implementation
     * @param apeToken The apeToken address
     * @param implementation The new pending implementation
     */
    function _queuePendingImplementation(address apeToken, address implementation) external onlyAdmin {
        require(apeToken != address(0) && implementation != address(0), "invalid input");
        require(implementationQueue[apeToken][implementation] == 0, "already in queue");
        uint256 expiration = add_(getBlockTimestamp(), timeLock);
        implementationQueue[apeToken][implementation] = expiration;

        emit ImplementationQueued(apeToken, implementation, expiration);
    }

    /**
     * @notice Clear apeToken pending implementation
     * @param apeToken The apeToken address
     * @param implementation The new pending implementation
     */
    function _clearPendingImplementation(address apeToken, address implementation) external onlyAdmin {
        implementationQueue[apeToken][implementation] = 0;

        emit ImplementationCleared(apeToken, implementation);
    }

    /**
     * @notice Toggle apeToken pending implementation
     * @param apeToken The apeToken address
     * @param implementation The new pending implementation
     * @param allowResign Allow old implementation to resign or not
     * @param becomeImplementationData The payload data
     */
    function _togglePendingImplementation(
        address apeToken,
        address implementation,
        bool allowResign,
        bytes calldata becomeImplementationData
    ) external onlyAdmin {
        uint256 result = implementationQueue[apeToken][implementation];
        require(result != 0, "not in queue");
        require(result <= getBlockTimestamp(), "queue not expired");

        implementationQueue[apeToken][implementation] = 0;

        emit ImplementationChanged(apeToken, implementation);

        CDelegatorInterface(apeToken)._setImplementation(implementation, allowResign, becomeImplementationData);
    }

    /**
     * @notice Extract reserves by the reserve manager
     * @param apeToken The apeToken address
     * @param reduceAmount The amount of reduction
     */
    function extractReserves(address apeToken, uint256 reduceAmount) external onlyReserveManager {
        require(ApeTokenInterface(apeToken)._reduceReserves(reduceAmount) == 0, "failed to reduce reserves");

        address underlying = ApeErc20(apeToken).underlying();
        _transferToken(underlying, reserveManager, reduceAmount);
    }

    /**
     * @notice Seize the stock assets
     * @param token The token address
     */
    function seize(address token) external onlyAdmin {
        uint256 amount = EIP20NonStandardInterface(token).balanceOf(address(this));
        if (amount > 0) {
            _transferToken(token, admin, amount);
        }
    }

    /**
     * @notice Set the admin
     * @param newAdmin The new admin
     */
    function setAdmin(address payable newAdmin) external onlyAdmin {
        _setAdmin(newAdmin);
    }

    /**
     * @notice Set the reserve manager
     * @param newReserveManager The new reserve manager
     */
    function setReserveManager(address payable newReserveManager) external onlyAdmin {
        address oldReserveManager = reserveManager;
        reserveManager = newReserveManager;

        emit SetReserveManager(oldReserveManager, newReserveManager);
    }

    /**
     * @notice Redeem apeToken
     * @param apeToken The apeToken address
     */
    function redeem(address apeToken) external onlyAdmin {
        uint256 redeemTokens = ApeTokenInterface(apeToken).balanceOf(address(this));
        if (redeemTokens > 0) {
            ApeErc20Interface(apeToken).redeem(address(uint160(address(this))), redeemTokens, 0);
        }
    }

    /* Internal functions */

    function _setAdmin(address payable newAdmin) private {
        require(newAdmin != address(0), "new admin cannot be zero address");
        address oldAdmin = admin;
        admin = newAdmin;
        emit SetAdmin(oldAdmin, newAdmin);
    }

    function _transferToken(
        address token,
        address payable to,
        uint256 amount
    ) private {
        require(to != address(0), "receiver cannot be zero address");

        EIP20NonStandardInterface(token).transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a complaint ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                if lt(returndatasize(), 32) {
                    revert(0, 0) // This is a non-compliant ERC-20, revert.
                }
                returndatacopy(0, 0, 32) // Vyper compiler before 0.2.8 will not truncate RETURNDATASIZE.
                success := mload(0) // See here: https://github.com/vyperlang/vyper/security/advisories/GHSA-375m-5fvv-xq23
            }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }
}
