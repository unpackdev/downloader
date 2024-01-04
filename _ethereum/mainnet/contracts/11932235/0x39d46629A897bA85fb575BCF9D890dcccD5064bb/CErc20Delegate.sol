pragma solidity ^0.5.16;

import "./CErc20.sol";

/**
 * @title Compound's CErc20Delegate Contract
 * @notice CTokens which wrap an EIP-20 underlying and are delegated to
 * @author Compound
 */
contract CErc20Delegate is CErc20, CDelegateInterface {
    /**
     * @notice Construct an empty delegate
     */
    constructor() public {}

    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) public {
        // Shh -- currently unused
        data;

        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        require(msg.sender == admin, "only the admin may call _becomeImplementation");

        _syncTotalBorrowsAndAlphaDebt();
    }

    function _syncTotalBorrowsAndAlphaDebt() internal {
        require(accrueInterest() == uint(Error.NO_ERROR), "accrue interest failed");

        address evilSpell = 0x560A8E3B79d23b0A525E15C6F3486c6A293DDAd2;
        BorrowSnapshot storage borrowSnapshot = accountBorrows[evilSpell];
        require(borrowSnapshot.principal != 0);

        /* Calculate new borrow balance using the interest index:
         *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
         */
        uint principalTimesIndex = mul_(borrowSnapshot.principal, borrowIndex);
        uint result = div_(principalTimesIndex, borrowSnapshot.interestIndex);
        accountBorrows[evilSpell].principal = result;
        accountBorrows[evilSpell].interestIndex = borrowIndex;
    }

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public {
        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        require(msg.sender == admin, "only the admin may call _resignImplementation");
    }
}
