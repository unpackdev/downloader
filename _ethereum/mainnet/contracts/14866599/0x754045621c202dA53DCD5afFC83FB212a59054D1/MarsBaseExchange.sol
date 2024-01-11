// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./MarsBase.sol";
import "./MarsBaseCommon.sol";

import "./IERC20.sol";

/// @title MarsBaseExchange
/// @author dOTC Marsbase
/// @notice This contract contains the public facing elements of the marsbase exchange. 
contract MarsBaseExchange {
    /// Emitted when an offer is created
    event OfferCreated(
        uint256 offerId,
        address sender,
        uint256 blockTimestamp,
        MarsBaseCommon.MBOffer offer
    );

    /// Emitted when an offer has it's parameters or capabilities modified
    event OfferModified(
        uint256 offerId,
        address sender,
        uint256 blockTimestamp,
        MarsBaseCommon.OfferParams offerParameters
    );

    /// Emitted when an offer is accepted.
    /// This includes partial transactions, where the whole offer is not bought out and those where the exchange is not finallized immediatley.
    event OfferAccepted(
        uint256 offerId,
        address sender,
        uint256 blockTimestamp,
        uint256 amountAliceReceived,
        uint256 amountBobReceived,
        address tokenAddressAlice,
        address tokenAddressBob,
        MarsBaseCommon.OfferType offerType,
        uint256 feeAlice,
        uint256 feeBob
    );

    /// Emitted when the offer is cancelled either by the creator or because of an unsuccessful auction
    event OfferCancelled(
        uint256 offerId,
        address sender,
        uint256 blockTimestamp
    );

    event OfferClosed(
        uint256 offerId,
        MarsBaseCommon.OfferCloseReason reason,
        uint256 blockTimestamp
    );

    event ContractMigrated();

    /// Emitted when a buyer cancels their bid for a offer were tokens have not been exchanged yet and are still held by the contract.
    event BidCancelled(uint256 offerId, address sender, uint256 blockTimestamp);

    /// Emitted only for testing usage
    event Log(uint256 log);

    address marsBaseOffersAddress;
    address marsBaseMinimumOffersAddress;
    address owner;

    uint256 nextOfferId;

    uint256 minimumFee = 10;

    address commissionWallet;

    bool locked;

    mapping(uint256 => MarsBaseCommon.MBOffer) public offers;

    /// Constructor sets owner and commission wallet to the contract creator initially.
    constructor() {
        owner = msg.sender;
        commissionWallet = msg.sender;
        locked = false;
    }

    struct MBAddresses {
        address offersContract;
        address minimumOffersContract;
    }

    modifier unlocked {
        require(locked == false, "S9");
        _;
    }

    /// Updates the address where the commisions are sent
    /// Can only be called by the owner
    function setCommissionAddress(address wallet) unlocked public {
        require(msg.sender == owner, "S7");
        require(wallet != address(0), "T0");

        commissionWallet = wallet;
    }

    /// Updates the minimum fee amount
    /// Can be only called by the owner
    /// Is in the format of an integer, with a maximum of 1000.
    /// For example, 1% fee is 10, 100% is 1000 and 0.1% is 1.
    function setMinimumFee(uint256 _minimumFee) unlocked public {
        require(msg.sender == owner, "S7");

        minimumFee = _minimumFee;
    }

    function setNextOfferId(uint256 _nextOfferId) unlocked public {
        require(msg.sender == owner, "S7");

        nextOfferId = _nextOfferId;
    }

    /// Gets an offer by its id
    function getOffer(uint256 offerId)
        public
        view
        returns (MarsBaseCommon.MBOffer memory)
    {
        return offers[offerId];
    }

    /// Gets the next offer ID
    /// This should return the amount of offers that have ever been created, including those that are no longer active.
    function getNextOfferId() public view returns (uint256) {
        return nextOfferId;
    }


    /// Return the address of the current owner.
    function getOwner() public view returns (address) {
        return owner;
    }


    // Gets a list of all active offers
    function getAllOffers()
        public
        view
        returns (MarsBaseCommon.MBOffer[] memory)
    {
        MarsBaseCommon.MBOffer[]
            memory openOffers = new MarsBaseCommon.MBOffer[](nextOfferId);
        uint256 counter = 0;

        for (uint256 index = 0; index < nextOfferId; index++) {
            if (getOffer(index).active == true) {
                openOffers[counter] = getOffer(index);
                counter++;
            }
        }

        return openOffers;
    }


    /// Creates an offer
    /// tokenAlice - the address of the token that will be put up for sale
    /// tokenBob - a list of tokens that we are willing to accept in exchange for token alice.
    /// NOTE: If the user would like to accept native ether, token bob should have an element with a zero address. This indicates that we accept native ether.
    /// amountAlice - the amount of tokenAlice we are putting for sale, in wei.
    /// amountBob - a list of the amounts we are willing to accept for each token bob. This is then compared with amountAlice to generate a fixed exchange rate.
    /// offerParamaters - The configureation parameters for the offer to set the conditions for the sale. 
    function createOffer(
        address tokenAlice,
        address[] calldata tokenBob,
        uint256 amountAlice,
        uint256[] calldata amountBob,
        MarsBaseCommon.OfferParams calldata offerParameters
    ) unlocked public payable {
        require(
            offerParameters.feeAlice + offerParameters.feeBob >= minimumFee,
            "M0"
        );

        offers[nextOfferId] = MarsBase.createOffer(
            nextOfferId,
            tokenAlice,
            tokenBob,
            amountAlice,
            amountBob,
            offerParameters
        );
        emit OfferCreated(
            nextOfferId,
            msg.sender,
            block.timestamp,
            offers[nextOfferId]
        );

        nextOfferId++;
    }

    /// Cancels the offer at the provided ID
    /// Must be the offer creator.
    function cancelOffer(uint256 offerId) public {
        offers[offerId] = MarsBase.cancelOffer(offers[offerId]);
        emit OfferCancelled(offerId, msg.sender, block.timestamp);
        emit OfferClosed(offerId, MarsBaseCommon.OfferCloseReason.CancelledBySeller, block.timestamp);
    }

    /// Calculate the price for a given situarion
    function price(
        uint256 amountAlice,
        uint256 offerAmountAlice,
        uint256 offerAmountBob
    ) public pure returns (uint256) {
        return MarsBase.price(amountAlice, offerAmountAlice, offerAmountBob);
    }

    /// Accepts an offer
    /// This can be either in full or partially. Uses the provided token and amount.
    /// NOTE: for native ether, tokenBob should be a zero address. amountBob is set by the transaction value automatically, but should match the amount provided when calling.
    /// The proper function to handle the proccess is selected automatically.
    function acceptOffer(
        uint256 offerId,
        address tokenBob,
        uint256 amountBob
    ) unlocked public payable {
        MarsBaseCommon.MBOffer memory offer = offers[offerId];
        MarsBaseCommon.OfferType offerType = offer.offerType;

        if (tokenBob == address(0)) {
            amountBob = msg.value;
        }

        if (
            MarsBase.contractType(offerType) ==
            MarsBaseCommon.ContractType.Offers
        ) {
            if (
                offerType == MarsBaseCommon.OfferType.FullPurchase ||
                offerType == MarsBaseCommon.OfferType.LimitedTime
            ) {
                offers[offerId] = MarsBase.acceptOffer(
                    offer,
                    tokenBob,
                    amountBob
                );
            } else {
                offers[offerId] = MarsBase.acceptOfferPart(
                    offer,
                    tokenBob,
                    amountBob
                );
            }
        } else {
            offers[offerId] = MarsBase.acceptOfferPartWithMinimum(
                offer,
                tokenBob,
                amountBob
            );
        }

        uint256 amountTransacted = offer.amountRemaining - offers[offerId].amountRemaining;

        emit OfferAccepted(
            offerId,
            msg.sender,
            block.timestamp,
            amountTransacted,
            amountBob,
            offer.tokenAlice,
            tokenBob,
            offerType,
            amountTransacted - (amountTransacted * (1000-offer.feeAlice) / 1000),
            amountBob - (amountBob * (1000-offer.feeBob) / 1000)
        );

        if (offers[offerId].active == false) {
            emit OfferClosed(offerId, MarsBaseCommon.OfferCloseReason.Success, block.timestamp);
        }
    }

    /// Allows the offer creator to set the offer parameters after creation.
    function changeOfferParams(
        uint256 offerId,
        address[] calldata tokenBob,
        uint256[] calldata amountBob,
        MarsBaseCommon.OfferParams calldata offerParameters
    ) unlocked public {
        offers[offerId] = MarsBase.changeOfferParams(
            offers[offerId],
            tokenBob,
            amountBob,
            offerParameters
        );

        emit OfferModified(
            offerId,
            msg.sender,
            block.timestamp,
            offerParameters
        );
    }

    /// Allows the buyer to cancel his bid in situations where the exchange has not occured yet.
    /// This applys only to offers where minimumSize is greater than zero and the minimum has not been met.
    function cancelBid(uint256 offerId) public {
        offers[offerId] = MarsBase.cancelBid(offers[offerId]);

        emit BidCancelled(offerId, msg.sender, block.timestamp);
    }

    /// A function callable by the contract owner to cancel all offers where the time has expired.
    function cancelExpiredOffers() public payable {
        require(msg.sender == owner, "S8");

        for (uint256 index = 0; index < nextOfferId; index++) {
            if (
                block.timestamp >= offers[index].deadline &&
                offers[index].deadline != 0 &&
                MarsBase.contractType(offers[index].offerType) == MarsBaseCommon.ContractType.Offers
            ) {
                offers[index] = MarsBase.cancelExpiredOffer(offers[index]);
                emit OfferClosed(index, MarsBaseCommon.OfferCloseReason.DeadlinePassed, block.timestamp);
            } else {
                offers[index] = MarsBase.cancelExpiredMinimumOffer(offers[index]);
                emit OfferClosed(index, MarsBaseCommon.OfferCloseReason.DeadlinePassed, block.timestamp);

            }
        }
    }

    function migrateContract() unlocked public payable {
        require(msg.sender == owner, "S8");

        for (uint256 index = 0; index < nextOfferId; index++) {
            if (
                offers[index].active == true &&
                MarsBase.contractType(offers[index].offerType) == MarsBaseCommon.ContractType.Offers
            ) {
                offers[index] = MarsBase.cancelExpiredOffer(offers[index]);
                emit OfferClosed(index, MarsBaseCommon.OfferCloseReason.DeadlinePassed, block.timestamp);
            } else if (offers[index].active == true) {
                offers[index] = MarsBase.cancelExpiredMinimumOffer(offers[index]);
                emit OfferClosed(index, MarsBaseCommon.OfferCloseReason.DeadlinePassed, block.timestamp);
            }
        }

        locked = true;

        emit ContractMigrated();
    }

    function withdrawCommission(address token, uint256 amount) public payable {
        require(msg.sender == owner, "S8");

        if (token == address(0)) {
            (bool success, bytes memory data) = commissionWallet.call{value: amount}("");
            require(success, "T1b");
        } else {
            require(IERC20(token).transfer(commissionWallet, amount), "T1b");
        }
    }
}
