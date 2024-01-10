// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IEthCreditRecovery.sol";
import "./MarketHandlerBase.sol";

/**
 * @title EthCreditFacet
 *
 * @notice Handles distribution of any available ETH credits (from reverted attempts to distribute funds)
 */
contract EthCreditRecoveryFacet is IEthCreditRecovery, MarketHandlerBase {

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized()
    {

        MarketHandlerLib.MarketHandlerInitializers storage mhi = MarketHandlerLib.marketHandlerInitializers();
        require(!mhi.ethCreditRecoveryFacet, "Initializer: contract is already initialized");
        mhi.ethCreditRecoveryFacet = true;
        _;
    }

    /**
     * @notice Facet Initializer
     *
     * Register supported interfaces
     */
    function initialize()
    public
    onlyUnInitialized
    {
        DiamondLib.addSupportedInterface(type(IEthCreditRecovery).interfaceId);
    }

    /**
     * @notice Enables recovery of any ETH credit to an account which has credits
     *
     * Doesn't require that the caller of this function is the same address as the `_recipient`
     * as it is likely that `_recipient` may not be able to call this function if an ETH transfer to `_recipient` reverted
     *
     * See: {MarketHandlerBase.sendValueOrCreditAccount}
     *
     * Reverts if:
     * - Account has no ETH credits
     * - ETH cannot be sent to creditted account
     *
     * @param _recipient - id of the consignment being sold
     */
    function recoverEthCredits(address _recipient)
    external
    override
    {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();
        
        // Make sure there is enough ETH in contract & that credit exists
        uint256 ethCredit = mhs.addressToEthCredit[_recipient];
        require(address(this).balance >= ethCredit, "Address: insufficient balance");
        require(ethCredit > 0, "No ETH credits");

        // Set to zero in case of reentrancy
        mhs.addressToEthCredit[_recipient] = 0;

        (bool success, ) = _recipient.call{value: ethCredit}("");
        require(success, "Failed to disburse ETH credits");
        
        // Emit
        emit EthCreditRecovered(_recipient, ethCredit);
    }

    /**
     * @notice Enables MULTISIG recovery of any ETH credit for an account which has credits but can't recover the ETH via distributeEthCredits
     *
     * In rare cases, `_originalRecipient` may be unable to start receiving ETH again
     * therefore any ETH credits would get stuck
     *
     * See: {MarketHandlerBase.sendValueOrCreditAccount} & {EthCreditFacet.distributeEthCredits}
     *
     * Reverts if:
     * - Account has no ETH credits
     * - ETH cannot be sent to creditted account
     *
     * @param _originalRecipient - the account with unrecoverable (via distributeEthCredits) ETH credits
     */
    function fallbackRecoverEthCredit(address _originalRecipient)
    external
    override
    onlyRole(MULTISIG)
    {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();
        
        // Make sure there is enough ETH in contract & that credit exists
        uint256 ethCredit = mhs.addressToEthCredit[_originalRecipient];
        require(ethCredit > 0, "No ETH credits");
        require(address(this).balance >= ethCredit, "Address: insufficient balance");

        // Set to zero in case of reentrancy
        mhs.addressToEthCredit[_originalRecipient] = 0;
        
        // Send funds to MultiSig
        IMarketController marketController = getMarketController(); 
        address payable multisig = marketController.getMultisig();

        (bool success, ) = multisig.call{value: ethCredit}("");
        require(success, "Failed to disburse ETH credits");
        
        // Emit
        emit EthCreditFallbackRecovered(_originalRecipient, ethCredit, msg.sender, multisig);
    }

    /**
     * @notice returns the pending ETH credits for a recipient
     *
     * @param _recipient - the account to check ETH credits for
     */
    function availableCredits(address _recipient)
    external
    view
    override
    returns (uint256) {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();
        return mhs.addressToEthCredit[_recipient];
    }

}