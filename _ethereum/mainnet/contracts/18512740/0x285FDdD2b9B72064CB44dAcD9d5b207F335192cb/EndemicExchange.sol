// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./OwnableUpgradeable.sol";

import "./EndemicDutchAuction.sol";
import "./EndemicReserveAuction.sol";
import "./EndemicOffer.sol";
import "./EndemicSale.sol";

contract EndemicExchange is
    EndemicDutchAuction,
    EndemicReserveAuction,
    EndemicOffer,
    EndemicSale,
    OwnableUpgradeable
{
    /**
     * @notice Initialized Endemic exchange contract
     * @dev Only called once
     * @param _royaltiesProvider - royalyies provider contract
     * @param _paymentManager - payment manager contract address
     * @param _feeRecipientAddress - address to receive exchange fees
     * @param _approvedSigner - address to sign reserve auction orders
     */
    function __EndemicExchange_init(
        address _royaltiesProvider,
        address _paymentManager,
        address _feeRecipientAddress,
        address _approvedSigner
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();

        _updateDistributorConfiguration(_feeRecipientAddress);
        _updateExchangeConfiguration(
            _royaltiesProvider,
            _paymentManager,
            _approvedSigner
        );
    }

    /**
     * @notice Updated contract internal configuration, callable by exchange owner
     * @param _royaltiesProvider - royalyies provider contract
     * @param _paymentManager - payment manager contract address
     * @param _feeRecipientAddress - address to receive exchange fees
     * @param _approvedSigner - address to sign reserve auction orders
     */
    function updateConfiguration(
        address _royaltiesProvider,
        address _paymentManager,
        address _feeRecipientAddress,
        address _approvedSigner
    ) external onlyOwner {
        _updateDistributorConfiguration(_feeRecipientAddress);
        _updateExchangeConfiguration(
            _royaltiesProvider,
            _paymentManager,
            _approvedSigner
        );
    }
}
