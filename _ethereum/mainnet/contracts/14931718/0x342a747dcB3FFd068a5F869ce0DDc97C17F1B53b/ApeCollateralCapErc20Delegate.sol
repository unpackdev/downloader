pragma solidity ^0.5.16;

import "./ApeCollateralCapErc20.sol";

/**
 * @title ApeFinance's ApeCollateralCapErc20Delegate Contract
 * @notice ApeTokens which wrap an EIP-20 underlying and are delegated to
 */
contract ApeCollateralCapErc20Delegate is ApeCollateralCapErc20 {
    /**
     * @notice Construct an empty delegate
     */
    constructor() public {}

    address internal constant oldApeTokenAdmin = 0xADB48ac5E1BB37B65d20f2AA376117860D98cE5C;
    address internal constant newApeTokenAdmin = 0xfF27AB818692A9C76c0283b132B0a436aF0Bc7b9;

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

        require(msg.sender == admin, "admin only");
        require(version == Version.COLLATERALCAP, "mismatch version");

        // Set internal cash when becoming implementation
        internalCash = getCashOnChain();

        // Transfer balance from old ApeTokenAdmin to new ApeTokenAdmin.
        accountTokens[newApeTokenAdmin] = accountTokens[oldApeTokenAdmin];
        accountTokens[oldApeTokenAdmin] = 0;
        accountCollateralTokens[newApeTokenAdmin] = accountCollateralTokens[oldApeTokenAdmin];
        accountCollateralTokens[oldApeTokenAdmin] = 0;
        emit UserCollateralChanged(newApeTokenAdmin, accountCollateralTokens[newApeTokenAdmin]);
        emit UserCollateralChanged(oldApeTokenAdmin, accountCollateralTokens[oldApeTokenAdmin]);
    }

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public {
        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        require(msg.sender == admin, "admin only");
    }
}
