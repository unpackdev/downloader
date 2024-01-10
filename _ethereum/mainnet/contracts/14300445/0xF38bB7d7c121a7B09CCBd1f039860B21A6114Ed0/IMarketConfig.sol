// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./SeenTypes.sol";

/**
 * @title IMarketController
 *
 * @notice Manages configuration and consignments used by the Seen.Haus contract suite.
 * @dev Contributes its events and functions to the IMarketController interface
 *
 * The ERC-165 identifier for this interface is: 0x57f9f26d
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
interface IMarketConfig {

    /// Events
    event NFTAddressChanged(address indexed nft);
    event EscrowTicketerAddressChanged(address indexed escrowTicketer, SeenTypes.Ticketer indexed ticketerType);
    event StakingAddressChanged(address indexed staking);
    event MultisigAddressChanged(address indexed multisig);
    event VipStakerAmountChanged(uint256 indexed vipStakerAmount);
    event PrimaryFeePercentageChanged(uint16 indexed feePercentage);
    event SecondaryFeePercentageChanged(uint16 indexed feePercentage);
    event MaxRoyaltyPercentageChanged(uint16 indexed maxRoyaltyPercentage);
    event OutBidPercentageChanged(uint16 indexed outBidPercentage);
    event DefaultTicketerTypeChanged(SeenTypes.Ticketer indexed ticketerType);

    /**
     * @notice Sets the address of the xSEEN ERC-20 staking contract.
     *
     * Emits a NFTAddressChanged event.
     *
     * @param _nft - the address of the nft contract
     */
    function setNft(address _nft) external;

    /**
     * @notice The nft getter
     */
    function getNft() external view returns (address);

    /**
     * @notice Sets the address of the Seen.Haus lots-based escrow ticketer contract.
     *
     * Emits a EscrowTicketerAddressChanged event.
     *
     * @param _lotsTicketer - the address of the items-based escrow ticketer contract
     */
    function setLotsTicketer(address _lotsTicketer) external;

    /**
     * @notice The lots-based escrow ticketer getter
     */
    function getLotsTicketer() external view returns (address);

    /**
     * @notice Sets the address of the Seen.Haus items-based escrow ticketer contract.
     *
     * Emits a EscrowTicketerAddressChanged event.
     *
     * @param _itemsTicketer - the address of the items-based escrow ticketer contract
     */
    function setItemsTicketer(address _itemsTicketer) external;

    /**
     * @notice The items-based escrow ticketer getter
     */
    function getItemsTicketer() external view returns (address);

    /**
     * @notice Sets the address of the xSEEN ERC-20 staking contract.
     *
     * Emits a StakingAddressChanged event.
     *
     * @param _staking - the address of the staking contract
     */
    function setStaking(address payable _staking) external;

    /**
     * @notice The staking getter
     */
    function getStaking() external view returns (address payable);

    /**
     * @notice Sets the address of the Seen.Haus multi-sig wallet.
     *
     * Emits a MultisigAddressChanged event.
     *
     * @param _multisig - the address of the multi-sig wallet
     */
    function setMultisig(address payable _multisig) external;

    /**
     * @notice The multisig getter
     */
    function getMultisig() external view returns (address payable);

    /**
     * @notice Sets the VIP staker amount.
     *
     * Emits a VipStakerAmountChanged event.
     *
     * @param _vipStakerAmount - the minimum amount of xSEEN ERC-20 a caller must hold to participate in VIP events
     */
    function setVipStakerAmount(uint256 _vipStakerAmount) external;

    /**
     * @notice The vipStakerAmount getter
     */
    function getVipStakerAmount() external view returns (uint256);

    /**
     * @notice Sets the marketplace fee percentage.
     * Emits a PrimaryFeePercentageChanged event.
     *
     * @param _primaryFeePercentage - the percentage that will be taken as a fee from the net of a Seen.Haus primary sale or auction
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setPrimaryFeePercentage(uint16 _primaryFeePercentage) external;

    /**
     * @notice Sets the marketplace fee percentage.
     * Emits a SecondaryFeePercentageChanged event.
     *
     * @param _secondaryFeePercentage - the percentage that will be taken as a fee from the net of a Seen.Haus secondary sale or auction (after royalties)
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setSecondaryFeePercentage(uint16 _secondaryFeePercentage) external;

    /**
     * @notice The primaryFeePercentage and secondaryFeePercentage getter
     */
    function getFeePercentage(SeenTypes.Market _market) external view returns (uint16);

    /**
     * @notice Sets the external marketplace maximum royalty percentage.
     *
     * Emits a MaxRoyaltyPercentageChanged event.
     *
     * @param _maxRoyaltyPercentage - the maximum percentage of a Seen.Haus sale or auction that will be paid as a royalty
     */
    function setMaxRoyaltyPercentage(uint16 _maxRoyaltyPercentage) external;

    /**
     * @notice The maxRoyaltyPercentage getter
     */
    function getMaxRoyaltyPercentage() external view returns (uint16);

    /**
     * @notice Sets the marketplace auction outbid percentage.
     *
     * Emits a OutBidPercentageChanged event.
     *
     * @param _outBidPercentage - the minimum percentage a Seen.Haus auction bid must be above the previous bid to prevail
     */
    function setOutBidPercentage(uint16 _outBidPercentage) external;

    /**
     * @notice The outBidPercentage getter
     */
    function getOutBidPercentage() external view returns (uint16);

    /**
     * @notice Sets the default escrow ticketer type.
     *
     * Emits a DefaultTicketerTypeChanged event.
     *
     * Reverts if _ticketerType is Ticketer.Default
     * Reverts if _ticketerType is already the defaultTicketerType
     *
     * @param _ticketerType - the new default escrow ticketer type.
     */
    function setDefaultTicketerType(SeenTypes.Ticketer _ticketerType) external;

    /**
     * @notice The defaultTicketerType getter
     */
    function getDefaultTicketerType() external view returns (SeenTypes.Ticketer);

    /**
     * @notice Get the Escrow Ticketer to be used for a given consignment
     *
     * If a specific ticketer has not been set for the consignment,
     * the default escrow ticketer will be returned.
     *
     * @param _consignmentId - the id of the consignment
     * @return ticketer = the address of the escrow ticketer to use
     */
    function getEscrowTicketer(uint256 _consignmentId) external view returns (address ticketer);
}