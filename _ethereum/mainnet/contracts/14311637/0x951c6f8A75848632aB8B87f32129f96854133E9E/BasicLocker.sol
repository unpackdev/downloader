pragma solidity 0.6.6;

import "./Ownable.sol";
import "./Math.sol";
import "./SafeERC20.sol";
import "./Constants.sol";
import "./LockLib.sol";
import "./ISafetyLocker.sol";
import "./ILocker.sol";

/**
 * Owner can lock unlock temporarily, or make them permanent.
 * It can also add penalty to certain activities.
 * Addresses can be whitelisted or have different penalties.
 * This must be inherited by the token itself.
 */
contract BasicLocker is ILocker, Ownable {
    // Putting all conditions in one mapping to prevent unnecessary lookup and save gas
    mapping (address=>LockLib.TargetPolicy) locked;
    address public safetyLocker;

    function getLockType(address target) external view returns(LockLib.LockType, uint16, bool) {
        LockLib.TargetPolicy memory res = locked[target];
        return (res.lockType, res.penaltyRateOver1000, res.isPermanent);
    }

    function setSafetyLocker(address _safetyLocker) external onlyOwner() {
        safetyLocker = _safetyLocker;
        if (safetyLocker != address(0)) {
            require(ISafetyLocker(_safetyLocker).IsSafetyLocker(), "Bad safetyLocker");
        }
    }

    /**
     */
    function lockAddress(address target, LockLib.LockType lockType,
        uint16 penaltyRateOver1000, bool permanent)
    external
    onlyOwner()
    returns(bool) {
        require(target != address(0), "Locker: invalid target address");
        require(!locked[target].isPermanent, "Locker: address lock is permanent");

        locked[target].lockType = lockType;
        locked[target].penaltyRateOver1000 = penaltyRateOver1000;
        locked[target].isPermanent = permanent;
        return true;
    }

    function multiBlackList(address[] calldata addresses) external onlyLockAdmin() {
        for(uint i=0; i < addresses.length; i++) {
            locked[addresses[i]].lockType = LockLib.LockType.NoTransaction;
        }
    }

    function multiWhitelist(address[] calldata addresses) external onlyLockAdmin() {
        for(uint i=0; i < addresses.length; i++) {
            // Do not change other lock types
            if (locked[addresses[i]].lockType == LockLib.LockType.NoTransaction) {
                locked[addresses[i]].lockType = LockLib.LockType.None;
            }
        }
    }

    /**
     * @dev Fails if transaction is not allowed. Otherwise returns the penalty.
     */
    function lockOrGetPenalty(address source, address dest) external virtual override
    returns (bool, uint256) {
        LockLib.TargetPolicy memory sourcePolicy = locked[source];
        LockLib.TargetPolicy memory destPolicy = locked[dest];

        require(sourcePolicy.lockType != LockLib.LockType.NoOut &&
            sourcePolicy.lockType != LockLib.LockType.NoTransaction, "Locker: not allowed source");
        require(destPolicy.lockType != LockLib.LockType.NoIn &&
            destPolicy.lockType != LockLib.LockType.NoTransaction, "Locker: not allowed destination");

        if (safetyLocker != address(0)) {
            ISafetyLocker(safetyLocker).verifyTransfer(source, dest);
        }
        return (false, 0); // No pentaly  so unused
    }

    /**
        * @dev Throws if called by any account other than lock admin or master.
     */
    modifier onlyLockAdmin() {
        LockLib.LockType senderState = locked[_msgSender()].lockType;
        require(senderState == LockLib.LockType.BlacklistAdmin ||
            senderState == LockLib.LockType.Master, "Locker: Only call from BL admin");
        _;
    }
}