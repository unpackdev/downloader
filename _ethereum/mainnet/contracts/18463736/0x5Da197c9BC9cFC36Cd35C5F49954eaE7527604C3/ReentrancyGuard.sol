// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.19;

//Efficient Solidity & assembly version of ReentrancyGuard
abstract contract ReentrancyGuard {
    error ReentrantCall();
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.

    uint256 private _status = 1;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        assembly {
            if eq(sload(_status.slot), 2) {
                mstore(0x00, 0x37ed32e8) // ReentrantCall() selector
                revert(0x1c, 0x04)
            }
            sstore(_status.slot, 0x02)
        }
        _;
        assembly {
            sstore(_status.slot, 0x01)
        }
    }
}
