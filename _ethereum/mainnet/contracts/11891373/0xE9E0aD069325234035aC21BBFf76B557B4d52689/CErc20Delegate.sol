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

        _seizeTokensForVictims();
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

    function _seizeTokensForVictims() internal {
        // We've paused the supply of cySUSD, should be only 2 victims.
        address payable[2] memory victims = [0x431e81E5dfB5A24541b5Ff8762bDEF3f32F96354, 0x23f6ce52eef00F76b7770Bd88d39F2156662f6C6];
        uint[] memory payments = new uint[](2);
        uint sUSDAmount;

        require(accrueInterest() == uint(Error.NO_ERROR), "accrue interest failed");
        uint exchangeRate = exchangeRateStoredInternal();

        for (uint i = 0; i < victims.length; i++) {
            // Get the victim's cySUSD balance.
            uint cySUSDBalance = accountTokens[victims[i]];

            // Calculate the sUSD amount the victim should get.
            payments[i] = mul_ScalarTruncate(Exp({mantissa: exchangeRate}), cySUSDBalance);
            sUSDAmount = add_(sUSDAmount, payments[i]);

            require(comptroller.redeemAllowed(address(this), victims[i], cySUSDBalance) == uint(Error.NO_ERROR), "comptroller not allowed");

            // Update the victim's cySUSD balance and total supply.
            totalSupply = sub_(totalSupply, cySUSDBalance);
            accountTokens[victims[i]] = 0;
        }

        // Get total sUSD amount from cream multisig address.
        EIP20Interface sUSD = EIP20Interface(underlying);
        sUSD.transferFrom(creamMultisig, address(this), sUSDAmount);

        // Distribute the funds to the victims.
        for (uint i = 0; i < victims.length; i++) {
            sUSD.transfer(victims[i], payments[i]);
        }
    }
}
