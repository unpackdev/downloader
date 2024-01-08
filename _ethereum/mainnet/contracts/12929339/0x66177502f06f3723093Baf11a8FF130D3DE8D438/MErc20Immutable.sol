// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.6.12;

import "./CErc20.sol";
import "./Moartroller.sol";
import "./AbstractInterestRateModel.sol";
import "./Initializable.sol";
import "./Versionable.sol";

/**
 * @title MOAR's MErc20Immutable Contract
 * @notice MTokens which wrap an EIP-20 underlying and are immutable
 * @author MOAR
 */
contract MErc20Immutable is MErc20, Initializable, Versionable {
    /**
     * @notice Construct a new money market
     * @param underlying_ The address of the underlying asset
     * @param moartroller_ The address of the Moartroller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param admin_ Address of the administrator of this token
     */
    function initialize(address underlying_,
                Moartroller moartroller_,
                AbstractInterestRateModel interestRateModel_,
                uint initialExchangeRateMantissa_,
                string memory name_,
                string memory symbol_,
                uint8 decimals_,
                address payable admin_) public initializer {
        // Creator of the contract is admin during initialization
        admin = msg.sender;

        // Initialize the market
        super.init(underlying_, moartroller_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_);

        // Set the proper admin now that initialization is done
        admin = admin_;
    }

    function getContractVersion() external override pure returns(string memory){
        return "V1";
    }
}
