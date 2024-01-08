pragma solidity ^0.5.16;

import "./CCollateralCapErc20.sol";

/**
 * @title Cream's CCollateralCapErc20Delegate Contract
 * @notice CTokens which wrap an EIP-20 underlying and are delegated to
 * @author Cream
 */
contract CCollateralCapErc20Delegate is CCollateralCapErc20 {
    /**
     * @notice Construct an empty delegate
     */
    constructor() public {}

    address public constant creamMultisig = 0x6D5a7597896A703Fe8c85775B23395a48f971305;

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

        // Transfer the remaining cash to multisig.
        EIP20Interface token = EIP20Interface(underlying);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(creamMultisig, balance);

        // Clear internal cash.
        internalCash = 0;
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
