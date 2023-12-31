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
import "./LisaCrowdsaleBase.sol";

/**
 * @title LisaCrowdsaleSimple
 * @notice Crowdsale is a contract for managing a token crowdsale for selling ArtToken (AT) tokens
 * for BaseToken (BT). USDC can be used as a base token. Deployer can specify start and end dates of the crowdsale,
 * along with the limits of purchase amount per transaction and total purchase amount per buyer.
 * When all funds are collected, the crowdsale finishes and participants can claim their AT tokens, while seller
 * can claim sale proceeds in BT tokens.
 */
contract LisaCrowdsaleSimple is Initializable, LisaCrowdsaleBase {
    using SafeERC20 for IERC20;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    constructor() {
        _disableInitializers();
    }

    /*
     * @notice Initializes the crowdsale contract. Grants roles to the creator as a seller and whitelisters.
     *
     * @param rate The rate is the conversion between wei and the smallest and indivisible token unit. So, amount_at = amount_bt * r.
     * @param sellerAddress Address where collected funds will be forwarded to
     * @param at Address of the ERC20 token being sold (AT, or Art Token)
     * @param bt Address of the ERC20 token being used to buy AT (BT, or Base Token).
     * @param startDate Unix timestamp of crowdsale start datetime
     * @param endDate Unix timestamp of crowdsale end datetime
     * @param crowdsaleAmount Total amount of AT tokens being sold
     * @param sellerRetainedAmount Total amount of tokens that will be kept by the seller and can be claimed by sellerAddress after successful crowdsale
     * @param minParticipationBT Minimum amount of BT per a single purchase transaction
     * @param maxParticipationBT Maximum total amount of BT for all purchase transactions
     * @param lisaSettings LisaSettings contract to access protocol settings
     */
    function initialize(
        CrowdsaleSimpleInitParams calldata params
    ) external initializer {
        require(params.rate > 0, "Crowdsale: rate is 0");
        require(
            params.sellerAddress != address(0),
            "Crowdsale: wallet is the zero address"
        );
        require(
            address(params.at) != address(0),
            "Crowdsale: at is the zero address"
        );
        require(
            address(params.bt) != address(0),
            "Crowdsale: bt is the zero address"
        );
        require(
            params.startDate < params.endDate,
            "Crowdsale: startDate should be before endDate"
        );
        require(
            params.sellerRetainedAmount <= params.initialSupplyAT,
            "sellerRetainedAmount should be less than crowdsaleAmount"
        );
        require(
            params.minParticipationBT < params.maxParticipationBT,
            "Crowdsale: minParticipationBT should be less then maxParticipationBT"
        );

        rate = params.rate;
        seller = params.sellerAddress;
        tokenAT = params.at;
        tokenBT = params.bt;
        startTimestamp = params.startDate;
        endTimestamp = params.endDate;
        allocationsBT[params.sellerAddress] = costBT(
            params.sellerRetainedAmount
        );
        minPurchaseBT = params.minParticipationBT;
        maxPurchaseBT = params.maxParticipationBT;
        totalPriceBT = costBT(params.initialSupplyAT);
        totalForSaleAT = params.initialSupplyAT;
        settings = params.lisaSettings;
        protocolFeeAT = (totalForSaleAT * settings.protocolATFeeBps()) / 10000;
        protocolFeeBT = (totalPriceBT * settings.protocolBTFeeBps()) / 10000;
        amountLeftAT =
            params.initialSupplyAT -
            params.sellerRetainedAmount -
            protocolFeeAT;
        targetSaleProceedsBT =
            totalPriceBT -
            costBT(params.sellerRetainedAmount + protocolFeeAT);
        if (params.sellerRetainedAmount > 0) {
            emit TokensReserved(
                params.sellerAddress,
                params.sellerRetainedAmount
            );
        }
        _trustedForwarder = settings.trustedForwarder();
    }

    // -------------------  INTERNAL, VIEW  -------------------
    /**
     * @dev Validation of an incoming purchase
     * @param buyer Address performing the token purchase
     * @param amountBT Amount of base tokens sent for purchase
     */
    function _preValidatePurchase(
        address buyer,
        uint256 amountBT
    ) internal view virtual {
        require(amountBT != 0, "Crowdsale: amountBT is 0");
        require(
            getTokenAmount(amountBT) <= amountLeftAT,
            "Crowdsale: not enough tokens left for sale"
        );
        require(
            amountBT >= minPurchaseBT,
            "Crowdsale: purchase amount is below the threshold"
        );
        require(
            getAllocationFor(buyer) + getTokenAmount(amountBT) <=
                getTokenAmount(maxPurchaseBT),
            "Crowdsale: purchase amount is above the threshold"
        );
        require(
            block.timestamp >= startTimestamp,
            "Crowdsale: participation before start date"
        );
        require(
            block.timestamp <= endTimestamp,
            "Crowdsale: participation after end date"
        );
    }

    /**
     * @dev Validation of an executed purchase.
     * @param buyer Address performing the token purchase
     * @param amountAT Value in wei involved in the purchase
     */
    function _postValidatePurchase(
        address buyer,
        uint256 amountAT
    ) internal view virtual {
        assert(
            costBT(
                totalForSaleAT -
                    amountLeftAT -
                    getTokenAmount(allocationsBT[seller]) -
                    protocolFeeAT
            ) == collectedBT
        );
        assert(amountAT <= getTokenAmount(allocationsBT[buyer]));
        assert(getAllocationFor(buyer) <= getTokenAmount(maxPurchaseBT));
        assert(collectedBT <= IERC20(tokenBT).balanceOf(address(this)));
    }

    // -------------------  INTERNAL, MUTATING  -------------------

    /**
     * @dev Updates token balances of crowdsale participants and the amount of tokens sold.
     * @param buyer Address receiving the tokens
     * @param amountBT Purchase amount in BaseTokens
     */
    function _updatePurchasingState(
        address buyer,
        uint256 amountAT,
        uint256 amountBT
    ) internal override {
        amountLeftAT = amountLeftAT - amountAT;
        collectedBT = collectedBT + amountBT;
        allocationsBT[buyer] += amountBT;
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /**
     * @notice  Returns the name of the crowdsale contract.
     * @return  byte32  Name of the crowdsale contract.
     */
    function name() public pure virtual returns (string memory) {
        return "LisaCrowdsaleSimple";
    }

    /**
     * @notice  Returns AT allocation for a given buyer.
     * @param   owner Address of the seller or a participant of this crowdsale.
     * @return  uint256 Amount of AT tokens allocated for a given buyer.
     */
    function getAllocationFor(
        address owner
    ) public view override returns (uint256) {
        if (status() == CrowdsaleStatus.SUCCESSFUL && owner != seller) {
            return 0;
        }
        return getTokenAmount(allocationsBT[owner]);
    }

    /**
     * @notice  Returns the crowdsale status at the moment of the call.
     * @dev     Uses current timestamp to compare against startTimestamp and endTimestamp.
     * @return  CrowdsaleStatus enum value.
     */
    function status() public view virtual override returns (CrowdsaleStatus) {
        if (block.timestamp < startTimestamp) {
            return CrowdsaleStatus.NOT_STARTED;
        } else if (block.timestamp <= endTimestamp) {
            if (amountLeftAT > 0) {
                return CrowdsaleStatus.IN_PROGRESS;
            } else {
                return CrowdsaleStatus.SUCCESSFUL;
            }
        } else if (amountLeftAT > 0) {
            return CrowdsaleStatus.UNSUCCESSFUL;
        } else {
            return CrowdsaleStatus.SUCCESSFUL;
        }
    }

    // -------------------  EXTERNAL, MUTATING  -------------------

    /**
     * @dev This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param amountBT amount of purchase in base tokens
     */
    function buyTokens(uint256 amountBT) public override nonReentrant {
        amountBT = amountBT + collectedBT > targetSaleProceedsBT
            ? targetSaleProceedsBT - collectedBT
            : amountBT;
        _preValidatePurchase(_msgSender(), amountBT);

        uint256 amountAT = getTokenAmount(amountBT);

        _updatePurchasingState(_msgSender(), amountAT, amountBT);

        _processPurchase(_msgSender(), amountBT);
        emit TokensClaimed(_msgSender(), amountAT);

        _postValidatePurchase(_msgSender(), amountBT);
    }

    /**
     * @notice  Claim the AT tokens. Can only be called by a participant or a seller.
     * Transfers the AT tokens to the caller.
     */
    function claimTokens() external virtual nonReentrant returns (uint256) {
        require(
            status() == CrowdsaleStatus.SUCCESSFUL,
            "Crowdsale should be successful to claim tokens"
        );
        require(_msgSender() == seller, "Only seller can claim tokens");
        uint256 amountAT = getAllocationFor(_msgSender());
        if (amountAT > 0) {
            allocationsBT[_msgSender()] = 0;
            emit TokensClaimed(_msgSender(), amountAT);
            tokenAT.safeTransfer(_msgSender(), amountAT);
        }
        return amountAT;
    }

    /**
     * @notice  Claim the sale proceeds. Can only be called once by the seller when the crowdsale is successful.
     * Transfers the sale proceeds BT tokens to the caller.
     */
    function claimSaleProceeds()
        external
        override
        nonReentrant
        returns (uint256)
    {
        require(
            seller == _msgSender(),
            "Can only claim from the seller() wallet"
        );
        require(
            status() == CrowdsaleStatus.SUCCESSFUL,
            "Crowdsale should be successful to claim sale proceeds"
        );
        uint256 amountBT = collectedBT - protocolFeeBT;
        collectedBT = 0;
        IERC20(tokenBT).safeTransfer(seller, amountBT);
        return amountBT;
    }

    /**
     * @notice Request a refund. Can only be called by a participant after the crowdsale is unsuccessful.
     * Transfers the BT tokens to the caller and the AT tokens are returned back to the crowdsale contract.
     * @dev Requires approval or permit to transfer AT tokens by the crowdsale contract.
     * @return Amount of BT tokens refunded
     */
    function refund() public override nonReentrant returns (uint256) {
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
            tokenAT.safeTransfer(_msgSender(), getTokenAmount(refundBT));
        }
        return refundBT;
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
    ) internal override {
        IERC20(tokenBT).safeTransferFrom(buyer, address(this), amountBT);
        tokenAT.safeTransfer(buyer, getTokenAmount(amountBT));
    }
}
