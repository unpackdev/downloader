// SPDX-License-Identifier: PHUNKY

/**** EtherPhunksMarket.sol *
* ░░░░░░░░░░░░░░░░░░░░░░░░░ *
* ░░░░░░░░░░░░░░░░░░░░░░░░░ *
* ░░░░░▓▓▓▓░░░░░░▓▓▓▓░░░░░░ *
* ░░░░░▒▒██░░░░░░▒▒██░░░░░░ *
* ░░░░░░░░░░░░░░░░░░░░░░░░░ *
* ░░░░░░░░░░░░░░░░░░░░░░░░░ *
* ░░░░░░░░░████░░░░░░░░░░░░ *
* ░░░░░░░░░░░░░░░░░░░░░░░░░ *
* ░░░░░░░░░░░░░░░██░░░░░░░░ *
* ░░░░░░░░░██████░░░░░░░░░░ *
* ░░░░░░░░░░░░░░░░░░░░░░░░░ *
* ░░░░░░░░░░░░░░░░░░░░░░░░░ *
****************************/

pragma solidity 0.8.20;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MulticallUpgradeable.sol";

import "./IPoints.sol";
import "./EthscriptionsEscrower.sol";

contract EtherPhunksMarket is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    MulticallUpgradeable,
    EthscriptionsEscrower
{
    bytes32 constant DEPOSIT_AND_LIST_SIGNATURE = 0x4445504f5349545f414e445f4c4953545f5349474e4154555245000000000000;

    uint256 public contractVersion;
    address public pointsAddress;

    struct Offer {
        bool isForSale;
        bytes32 phunkId;
        address seller;
        uint minValue;
        address onlySellTo;
    }

    struct Bid {
        bool hasBid;
        bytes32 phunkId;
        address bidder;
        uint value;
    }

    mapping(bytes32 => Offer) public phunksOfferedForSale;
    mapping(bytes32 => Bid) public phunkBids;
    mapping(address => uint) public pendingWithdrawals;

    event PhunkOffered(
        bytes32 indexed phunkId,
        uint minValue,
        address indexed toAddress
    );
    event PhunkBidEntered(
        bytes32 indexed phunkId,
        uint value,
        address indexed fromAddress
    );
    event PhunkBidWithdrawn(
        bytes32 indexed phunkId,
        uint value,
        address indexed fromAddress
    );
    event PhunkBought(
        bytes32 indexed phunkId,
        uint value,
        address indexed fromAddress,
        address indexed toAddress
    );
    event PhunkNoLongerForSale(
      bytes32 indexed phunkId
    );

    function initialize(
        uint256 _contractVersion,
        address _initialPointsAddress
    ) public initializer {
        __Ownable_init(msg.sender);
        __Pausable_init();
        __ReentrancyGuard_init();

        contractVersion = _contractVersion;
        pointsAddress = _initialPointsAddress;
    }

    function offerPhunkForSale(
        bytes32 phunkId,
        uint minSalePriceInWei
    ) external nonReentrant {
        _offerPhunkForSale(phunkId, minSalePriceInWei);
    }

    function batchOfferPhunkForSale(
        bytes32[] calldata phunkIds,
        uint[] calldata minSalePricesInWei
    ) external nonReentrant {
        require(
            phunkIds.length == minSalePricesInWei.length,
            "Array lengths do not match"
        );

        for (uint i = 0; i < phunkIds.length; i++) {
            _offerPhunkForSale(phunkIds[i], minSalePricesInWei[i]);
        }
    }

    function offerPhunkForSaleToAddress(
        bytes32 phunkId,
        uint minSalePriceInWei,
        address toAddress
    ) public nonReentrant {
        require(
            !userEthscriptionDefinitelyNotStored(msg.sender, phunkId),
            unicode"That's not your Phunk 🖕"
        );

        phunksOfferedForSale[phunkId] = Offer(
            true,
            phunkId,
            msg.sender,
            minSalePriceInWei,
            toAddress
        );

        emit PhunkOffered(phunkId, minSalePriceInWei, toAddress);
    }

    function _offerPhunkForSale(
        bytes32 phunkId,
        uint minSalePriceInWei
    ) internal {
        require(
            !userEthscriptionDefinitelyNotStored(msg.sender, phunkId),
            unicode"That's not your Phunk 🖕"
        );

        phunksOfferedForSale[phunkId] = Offer(
            true,
            phunkId,
            msg.sender,
            minSalePriceInWei,
            address(0x0)
        );

        emit PhunkOffered(phunkId, minSalePriceInWei, address(0x0));
    }

    function phunkNoLongerForSale(bytes32 phunkId) external {
        require(
            !userEthscriptionDefinitelyNotStored(msg.sender, phunkId),
            unicode"That's not your Phunk 🖕"
        );

        _invalidateListing(phunkId);
    }

    function _buyPhunk(
        bytes32 phunkId,
        uint minSalePriceInWei
    ) internal {
        Offer memory offer = phunksOfferedForSale[phunkId];

        require(
            offer.isForSale &&
            (offer.onlySellTo == address(0x0) || offer.onlySellTo == msg.sender) &&
            minSalePriceInWei == offer.minValue &&
            offer.seller != msg.sender,
            unicode"No Phunk for you 🖕"
        );

        address seller = offer.seller;

        phunksOfferedForSale[phunkId] = Offer(
            false,
            phunkId,
            msg.sender,
            0,
            address(0x0)
        );

        pendingWithdrawals[seller] += minSalePriceInWei;
        _addPoints(seller, 100);

        _transferEthscription(seller, msg.sender, phunkId);
        emit PhunkBought(phunkId, minSalePriceInWei, seller, msg.sender);

        Bid memory bid = phunkBids[phunkId];
        if (bid.bidder == msg.sender) {
            pendingWithdrawals[msg.sender] += bid.value;
            phunkBids[phunkId] = Bid(false, phunkId, address(0x0), 0);
        }
    }

    function buyPhunk(
        bytes32 phunkId,
        uint minSalePriceInWei
    ) external payable whenNotPaused nonReentrant {
        _buyPhunk(phunkId, minSalePriceInWei);
    }

    function batchBuyPhunk(
        bytes32[] calldata phunkIds,
        uint[] calldata minSalePricesInWei
    ) external payable whenNotPaused nonReentrant {
        require(
            phunkIds.length == minSalePricesInWei.length,
            "Array lengths do not match"
        );

        uint totalSalePrice = 0;
        for (uint i = 0; i < phunkIds.length; i++) {
            _buyPhunk(phunkIds[i], minSalePricesInWei[i]);
            totalSalePrice += minSalePricesInWei[i];
        }

        require(msg.value == totalSalePrice, "Incorrect total Ether sent");
    }

    function enterBidForPhunk(
        bytes32 phunkId
    ) external payable whenNotPaused nonReentrant {
        require(msg.value != 0);

        Bid memory existing = phunkBids[phunkId];
        require(msg.value > existing.value);

        if (existing.value > 0) {
            pendingWithdrawals[existing.bidder] += existing.value;
        }

        phunkBids[phunkId] = Bid(true, phunkId, msg.sender, msg.value);
        emit PhunkBidEntered(phunkId, msg.value, msg.sender);
    }

    function acceptBidForPhunk(
        bytes32 phunkId,
        uint minPrice
    ) external whenNotPaused nonReentrant {
        require(
            !userEthscriptionDefinitelyNotStored(msg.sender, phunkId),
            unicode"That's not your Phunk 🖕"
        );

        address seller = msg.sender;

        Bid memory bid = phunkBids[phunkId];
        address bidder = bid.bidder;

        require(
            bid.value != 0 &&
            bid.value >= minPrice &&
            seller != bidder,
            unicode"No Phunk for you 🖕"
        );

        phunksOfferedForSale[phunkId] = Offer(
            false,
            phunkId,
            bidder,
            0,
            address(0x0)
        );

        uint amount = bid.value;
        pendingWithdrawals[seller] += amount;

        _addPoints(seller, 100);

        _transferEthscription(seller, bidder, phunkId);
        emit PhunkBought(phunkId, amount, seller, bidder);

        phunkBids[phunkId] = Bid(false, phunkId, address(0x0), 0);
    }

    function withdrawBidForPhunk(
      bytes32 phunkId
    ) external nonReentrant {
        Bid memory bid = phunkBids[phunkId];
        require(
            bid.bidder == msg.sender,
            unicode"That's not your bid, Phunk 🖕"
        );

        emit PhunkBidWithdrawn(phunkId, bid.value, msg.sender);

        uint amount = bid.value;
        phunkBids[phunkId] = Bid(false, phunkId, address(0x0), 0);

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function withdraw() public nonReentrant {
        require(
            pendingWithdrawals[msg.sender] != 0,
            unicode"You're poor, Phunk 🖕"
        );

        uint amount = pendingWithdrawals[msg.sender];

        pendingWithdrawals[msg.sender] = 0;

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function withdrawPhunk(bytes32 phunkId) public {
        require(
            !userEthscriptionDefinitelyNotStored(msg.sender, phunkId),
            unicode"That's not your Phunk 🖕"
        );

        super.withdrawEthscription(phunkId);

        Offer memory offer = phunksOfferedForSale[phunkId];
        if (offer.isForSale) {
            _invalidateListing(phunkId);
        }
    }

    function withdrawBatchPhunks(bytes32[] calldata phunkIds) external {
        for (uint i = 0; i < phunkIds.length; i++) {
            withdrawPhunk(phunkIds[i]);
        }
    }

    function _onPotentialEthscriptionDeposit(
        address previousOwner,
        bytes calldata userCalldata
    ) internal override {
        require(
            userCalldata.length % 32 == 0,
            "Invalid ethscription length"
        );

        for (uint256 i = 0; i < userCalldata.length / 32; i++) {
            bytes32 potentialEthscriptionId = abi.decode(slice(userCalldata, i * 32, 32), (bytes32));

            if (userEthscriptionPossiblyStored(previousOwner, potentialEthscriptionId)) {
                revert EthscriptionAlreadyReceivedFromSender();
            }

            EthscriptionsEscrowerStorage.s().ethscriptionReceivedOnBlockNumber[
                previousOwner
            ][potentialEthscriptionId] = block.number;
        }
    }

    function _onPotentialSingleEthscriptionDeposit(
        address previousOwner,
        bytes32 phunkId
    ) internal {
        if (userEthscriptionPossiblyStored(previousOwner, phunkId)) {
            revert EthscriptionAlreadyReceivedFromSender();
        }

        EthscriptionsEscrowerStorage.s().ethscriptionReceivedOnBlockNumber[
            previousOwner
        ][phunkId] = block.number;
    }

    function _invalidateListing(bytes32 phunkId) internal {
        phunksOfferedForSale[phunkId] = Offer(
            false,
            phunkId,
            msg.sender,
            0,
            address(0x0)
        );
        emit PhunkNoLongerForSale(phunkId);
    }

    function _addPoints(
        address phunk,
        uint256 amount
    ) internal {
        IPoints pointsContract = IPoints(pointsAddress);
        pointsContract.addPoints(phunk, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function slice(bytes memory data, uint256 start, uint256 len) internal pure returns (bytes memory) {
        bytes memory b = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            b[i] = data[i + start];
        }
        return b;
    }

    fallback() external {
        require(!paused(), "Contract is paused");

        bytes32 signature;
        assembly {
            signature := calldataload(32)
        }

        if (signature == DEPOSIT_AND_LIST_SIGNATURE) {
            require(msg.data.length % 32 == 0, "InvalidEthscriptionLength");

            bytes32 phunkId;
            bytes32 listingPrice;
            bytes32 toAddress;

            assembly {
                phunkId := calldataload(0)
                listingPrice := calldataload(64)
                toAddress := calldataload(96)
            }

            if (toAddress != 0x0) {
                address addrToAddress = address(uint160(uint256(toAddress)));

                _onPotentialSingleEthscriptionDeposit(msg.sender, phunkId);
                offerPhunkForSaleToAddress(phunkId, uint256(listingPrice), addrToAddress);
                return;
            }

            _onPotentialSingleEthscriptionDeposit(msg.sender, phunkId);
            _offerPhunkForSale(phunkId, uint256(listingPrice));
            return;
        }

        _onPotentialEthscriptionDeposit(msg.sender, msg.data);
    }
}
