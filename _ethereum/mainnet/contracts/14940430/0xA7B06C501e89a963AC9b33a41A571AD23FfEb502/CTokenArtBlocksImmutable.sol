// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./CTokenArtBlocks.sol";

/**
 * @title Drops's CErc721 Contract (Modified from "Compound's CErc20Immutable Contract")
 * @notice CTokens which wrap an EIP-20 underlying and are immutable
 * @author Drops Loan
 */
contract CTokenArtBlocksImmutable is CTokenArtBlocks {
    /**
     * @notice Construct a new money market
     * @param underlying_ The address of the underlying asset
     * @param comptroller_ The address of the Comptroller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param admin_ Address of the administrator of this token
     */
    constructor(address underlying_,
                ComptrollerInterface comptroller_,
                InterestRateModel interestRateModel_,
                uint initialExchangeRateMantissa_,
                string memory name_,
                string memory symbol_,
                uint8 decimals_,
                uint256 projectId_,
                address payable admin_) public {
        // Creator of the contract is admin during initialization
        admin = msg.sender;

        // Initialize the market
        initialize(underlying_, comptroller_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_, projectId_);

        // Set the proper admin now that initialization is done
        admin = admin_;
    }
}
