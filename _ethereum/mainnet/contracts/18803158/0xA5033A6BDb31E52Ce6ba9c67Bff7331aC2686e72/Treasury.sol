// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "./Ownable.sol";
import "./SafeTransferLib.sol";
import "./WeightedMathLib.sol";

contract Treasury is Ownable {
    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------

    using FixedPointMathLib for *;

    using SafeTransferLib for address;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emitted when the fee recipient is updated.
    /// @param recipient The new fee recipient address.
    /// @param percentage The new fee recipient percentage.
    event FeeRecipientUpdated(address recipient, uint256 percentage);

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    /// @dev Error thrown when the input lenght is not same for recipients and percentages.
    error InvalidInput();

    /// @dev Error thrown when the percentage sum is not 100.
    error InvalidPercentageSum();

    /// @dev Error thrown when the address is 0x.
    error ZeroAddress();

    /// -----------------------------------------------------------------------
    /// Mutable Storage
    /// -----------------------------------------------------------------------

    /// @notice Mapping to track fee percentage for each address.
    mapping(address => uint256) private feePercents;

    /// @notice List of addresses of fee recipients.
    address[] private recipients;

    /// @notice Address of swap fee recipient.
    address private swapFeeRecipient;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    /// @param _owner The owner of the factory contract.
    constructor(address _owner) {
        // Initialize the owner and implementation address.
        _initializeOwner(_owner);

        // Set the initial recipientes here.
        recipients.push(_owner);
        feePercents[_owner] = 1 ether;

        swapFeeRecipient = _owner;
    }

    /**
     * @notice Update fee recipients and percentages.
     * @param _recipients List of addresses to be added as fee recipients.
     */
    function updateRecipients(
        address[] calldata _recipients,
        uint256[] calldata _percentages
    )
        public
        onlyOwner
    {
        if (_recipients.length != _percentages.length) revert InvalidInput();

        delete recipients;

        uint256 totalPercentage;

        for (uint8 i = 0; i < _recipients.length;) {
            if (_recipients[i] == address(0)) revert ZeroAddress();
            recipients.push(_recipients[i]);
            feePercents[_recipients[i]] = _percentages[i];
            totalPercentage += _percentages[i];
            emit FeeRecipientUpdated(_recipients[i], _percentages[i]);

            unchecked {
                ++i;
            }
        }

        if (totalPercentage != 1 ether) revert InvalidPercentageSum();
    }

    function updateSwapFeeRecipient(address _sfr) public onlyOwner {
        if (_sfr == address(0)) revert ZeroAddress();

        swapFeeRecipient = _sfr;

        emit FeeRecipientUpdated(_sfr, 0);
    }

    /**
     * @notice Distriburte the fee to the recipients.
     * @param asset Address of the asset that will be distrubuted.
     * @param amount Total amount of fees that will be distributed.
     */
    function distributeFee(
        address asset,
        uint256 amount,
        uint256 swapFeesAsset,
        address share,
        uint256 swapFeesShare
    )
        external
    {
        for (uint8 i = 0; i < recipients.length;) {
            uint256 feeP = feePercents[recipients[i]];
            uint256 feeShare = amount.mulWad(feeP);

            asset.safeTransfer(recipients[i], feeShare);

            unchecked {
                ++i;
            }
        }

        share.safeTransfer(swapFeeRecipient, swapFeesShare);
        asset.safeTransfer(swapFeeRecipient, swapFeesAsset);
    }
}
