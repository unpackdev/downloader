// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Initializable.sol";
import "./ICrowdsale.sol";
import "./Whitelist.sol";
import "./ERC2771Context.sol";

/**
 * @title An abstract class to implement base crowdsale functionality.
 * @notice Crowdsale is a contract for managing a token crowdsale for selling ArtToken (AT) tokens
 * for BaseToken (BT). USDC can be used as a base token. Deployer can specify start and end dates of the crowdsale,
 * along with the limits of purchase amount per transaction and total purchase amount per buyer.
 */
abstract contract LisaCrowdsaleBase is
    ICrowdsale,
    ERC2771Context,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // @notice The ArtToken token being sold
    IERC20Upgradeable internal tokenAT;

    // @notice The token used as a base currency (e.g. USDC)
    IERC20 public tokenBT;

    // @notice Address of the seller where funds are collected
    address public seller;

    // @notice Amount AT available for sale
    uint256 public amountLeftAT;

    // @notice Total amount of AT units a buyer gets per one BT unit
    uint256 public rate;

    // @notice UNIX timestamp of crowdsale start datetime in seconds
    uint256 public startTimestamp;

    // @notice UNIX timestamp of crowdsale end datetime in seconds
    uint256 public endTimestamp;

    // @notice Minimum amount of BT per a single purchase transaction
    uint256 public minPurchaseBT;

    // @notice Total amount of BT tokens that were collected during the crowdsale
    uint256 public collectedBT;

    // @notice Total amount of BT tokens that each buyer can spend with one or multiple transactions
    uint256 public maxPurchaseBT;

    // @notice Total price of the crowdsale in BT
    uint256 public totalPriceBT;

    // @notice Total amount of AT tokens allocated for this crowdsale
    uint256 public totalForSaleAT;

    // @notice Total amount of base tokens contributed by each address
    mapping(address => uint256) internal allocationsBT;

    // @notice Flag to indicate if the protocol fee was claimed
    bool public protocolFeeClaimed = false;

    // @notice Amount of AT tokens allocated for the protocol fee, taken from the totalForSaleAT
    uint256 public protocolFeeAT;

    // @notice Amount of BT tokens allocated for the protocol fee, taken from the totalPriceBT
    uint256 public protocolFeeBT;

    // @notice LisaSettings contract to access protocol settings
    ILisaSettings internal settings;

    // @notice Amount of BT tokens that should pe collected by participants (excluding seller allocation)
    uint256 public targetSaleProceedsBT;

    /// @notice the URI of the sales agreement stored in permanent storage
    string public salesAgreementURI;

    // -------------------  EXTERNAL, VIEW  -------------------

    /**
     * @notice  The amount of AT tokens available for a given buyer, taking into account their current allocation.
     * @dev     Does not take into account the total amount of AT tokens available for sale.
     * @param   buyer  Address of the buyer.
     * @return  uint256  Amount of AT tokens available for a given buyer.
     */
    function remainingToBuyAT(
        address buyer
    ) public view virtual returns (uint256) {
        return getTokenAmount(maxPurchaseBT) - getAllocationFor(buyer);
    }

    /**
     * @notice  Returns the crowdsale status at the moment of the call.
     * @return  CrowdsaleStatus enum value.
     */
    function status() public view virtual returns (CrowdsaleStatus);

    /**
     * @notice  Returns AT allocation for a given buyer (or seller if they want to retain some AT tokens).
     * @param   buyer Buyer's address that participated in this crowdsale.
     * @return  uint256 Amount of AT tokens allocated for a given buyer.
     */
    function getAllocationFor(
        address buyer
    ) public view virtual returns (uint256);

    /**
     * @notice Returns the number of AT that can be purchased with the specified amountBT
     * @param amountBT Value in baseTokens (e.g. USDC)
     * @return Number of AT that will be purchased with the specified amountBT
     */
    function getTokenAmount(
        uint256 amountBT
    ) public view virtual returns (uint256) {
        return amountBT * rate;
    }

    /**
     * @notice Returns the number of BT that the user should pay for a given number of AT.
     * @param amountAT Value in ArtTokens (refer to tokenAT)
     * @return The number of BT that the user should pay for a given number of AT.
     * For example if BT=USDC, costBT(1 * 10 ^ 18) should return the the cost of 1 AT token in USDC
     */
    function costBT(uint256 amountAT) public view returns (uint256) {
        require(
            amountAT == 0 || amountAT >= rate,
            "Crowdsale: amountAT should not be less than the rate"
        );
        return amountAT / rate;
    }

    /**
     * @notice  Returns the address of the token being sold.
     */
    function token() external view returns (address) {
        return address(tokenAT);
    }

    // -------------------  EXTERNAL, MUTATING  -------------------

    function buyTokens(uint256 amountBT) public virtual override;

    /**
     * @notice Buy tokens with ERC20 permit allowing approvals to be made via signatures, as defined in
     * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
     */
    function buyTokensWithPermit(
        uint256 amountBT,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        IERC20Permit(address(tokenBT)).permit(
            _msgSender(),
            address(this),
            amountBT,
            deadline,
            v,
            r,
            s
        );
        buyTokens(amountBT);
    }

    /**
     * @notice  Claim the protocol fee. Can only be called once by the LISA protocol admin
     * when the crowdsale is successful.
     * Transfers the protocol fee amount to the protocol fee wallet.
     */
    function claimProtocolFee() external {
        require(!protocolFeeClaimed, "Lisa fee already claimed");
        protocolFeeClaimed = true;
        require(
            status() == CrowdsaleStatus.SUCCESSFUL,
            "Crowdsale was not successful"
        );
        require(
            _msgSender() == settings.protocolAdmin(),
            "Only Admin can claim"
        );
        tokenAT.safeTransfer(
            settings.protocolArtTreasuryAddress(),
            protocolFeeAT
        );
        tokenBT.safeTransfer(
            settings.protocolArtTreasuryAddress(),
            protocolFeeBT
        );
    }

    /**
     * @notice  Claim the sale proceeds. Can only be called once by the seller when the crowdsale is successful.
     * Transfers the sale proceeds BT tokens to the caller.
     */
    function claimSaleProceeds() external virtual returns (uint256);

    /**
     * @notice  Request a refund. Can only be called by a participant after the crowdsale is unsuccessful.
     * Transfers the BT tokens to the caller.
     */
    function refund() public virtual nonReentrant returns (uint256) {
        require(
            status() == CrowdsaleStatus.UNSUCCESSFUL,
            "Crowdsale should be unsuccessful to claim tokens"
        );
        require(
            _msgSender() != seller,
            "Crowdsale: Seller cannot request refund"
        );
        uint256 refundBT = allocationsBT[_msgSender()];
        if (refundBT > 0) {
            allocationsBT[_msgSender()] = 0;
            emit TokensRefunded(_msgSender(), refundBT);
            IERC20(tokenBT).safeTransfer(_msgSender(), refundBT);
        }
        return refundBT;
    }

    /**
     * @dev fallback function
     */
    receive() external payable {
        revert("Crowdsale: sending ETH is not supported");
    }

    function updateTrustedForwarder(address forwarder) external {
        require(
            forwarder != address(0),
            "LisaCrowdsaleBase: forwarder cannot be zero"
        );
        require(
            _msgSender() == seller,
            "LisaCrowdsaleBase: Only Seller can update forwarder"
        );
        _trustedForwarder = forwarder;
    }

    // -------------------  INTERNAL, MUTATING  -------------------
    /**
     * @dev Executed when a purchase has been validated and is ready to be executed
     * @param buyer Address paying for the tokens
     * @param amountBT Number of baseTokens to be paid
     */
    function _processPurchase(
        address buyer,
        uint256 amountBT
    ) internal virtual {
        IERC20(tokenBT).safeTransferFrom(buyer, address(this), amountBT);
    }

    function _updatePurchasingState(
        address buyer,
        uint256 amountAT,
        uint256 amountBT
    ) internal virtual;
}
