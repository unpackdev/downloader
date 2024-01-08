// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./Address.sol";
import "./SafeMath.sol";
import "./IConjureFactory.sol";
import "./IConjureRouter.sol";

contract OpenOracleFramework {

    // using Openzeppelin contracts for SafeMath and Address
    using SafeMath for uint256;
    using Address for address;

    // the address of the collateral contract factory
    address public factoryContract;

    // address used for pay out
    address payable public payoutAddress;

    // number of signers
    uint256 public signerLength;

    // addresses of the signers
    address[] public signers;

    // threshold which has to be reached
    uint256 public signerThreshold;

    // struct to keep the values for each individual round
    struct feedRoundStruct {
        uint256 value;
        uint256 timestamp;
    }

    // stores historical values of feeds
    mapping(uint256 => mapping(uint256 => uint256)) private historicalFeeds;

    // indicates if sender is a signer
    mapping(address => bool) private isSigner;

    // mapping to store the actual submitted values per FeedId, per round number
    mapping(uint256 => mapping(uint256 => mapping(address => feedRoundStruct))) private feedRoundNumberToStructMapping;

    // indicates support of feeds
    mapping(uint256 => uint256) public feedSupport;

    // indicates if address si subscribed to a feed
    mapping(address => mapping(uint256 => uint256)) private subscribedTo;

    struct oracleStruct {
        string feedName;
        uint256 feedDecimals;
        uint256 feedTimeslot;
        uint256 latestPrice;
        uint256 latestPriceUpdate;
        // 0... donation, 1... subscription
        uint256 revenueMode;
        uint256 feedCost;
    }

    oracleStruct[] private feedList;

    // indicates if oracle subscription is turned on. 0 indicates no pass
    uint256 public subscriptionPassPrice;

    mapping(address => uint256) private hasPass;

    struct proposalStruct {
        uint256 uintValue;
        address addressValue;
        address proposer;
        // 0 ... pricePass
        // 1 ... threshold
        // 2 ... add signer
        // 3 ... remove signer
        // 4 ... payoutAddress
        // 5 ... revenueMode
        // 6 ... feedCost
        uint256 proposalType;
        uint256 proposalFeedId;
        uint256 proposalActive;
    }

    proposalStruct[] public proposalList;

    mapping(uint256 => mapping(address => bool)) private hasSignedProposal;

    event contractSetup(address[] signers, uint256 signerThreshold, address payout);
    event feedAdded(string name, string description, uint256 decimal, uint256 timeslot, uint256 feedId, uint256 mode, uint256 price);
    event feedSigned(uint256 feedId, uint256 roundId, uint256 value, uint256 timestamp, address signer);
    event routerFeeTaken(uint256 value, address sender);
    event feedSupported(uint256 feedId, uint256 supportvalue);
    event newProposal(uint256 proposalId, uint256 uintValue, address addressValue, uint256 oracleType, address proposer);
    event proposalSigned(uint256 proposalId, address signer);
    event newFee(uint256 value);
    event newThreshold(uint256 value);
    event newSigner(address signer);
    event signerRemoved(address signer);
    event newPayoutAddress(address payout);
    event newRevenueMode(uint256 mode, uint256 feed);
    event newFeedCost(uint256 cost, uint256 feed);
    event subscriptionPassPriceUpdated(uint256 newPass);

    // only Signer modifier
    modifier onlySigner {
        _onlySigner();
        _;
    }

    // only Signer view
    function _onlySigner() private view {
        require(isSigner[msg.sender], "Only a signer can perform this action");
    }

    constructor() {
        // Don't allow implementation to be initialized.
        factoryContract = address(1);
    }

    function initialize(
        address[] memory signers_,
        uint256 signerThreshold_,
        address payable payoutAddress_,
        uint256 subscriptionPassPrice_,
        address factoryContract_
    ) external
    {
        require(factoryContract == address(0), "already initialized");
        require(factoryContract_ != address(0), "factory can not be null");
        require(signerThreshold_ != 0, "Threshold cant be 0");
        require(signerThreshold_ <= signers_.length, "Threshold cant be more then signer count");

        factoryContract = factoryContract_;
        signerThreshold = signerThreshold_;
        signers = signers_;

        for(uint i=0; i< signers.length; i++) {
            require(signers[i] != address(0), "Not zero address");
            isSigner[signers[i]] = true;
        }

        signerLength = signers_.length;
        payoutAddress = payoutAddress_;
        subscriptionPassPrice = subscriptionPassPrice_;

        emit contractSetup(signers_, signerThreshold, payoutAddress);
    }

    //---------------------------helper functions---------------------------

    /**
    * @dev implementation of a quicksort algorithm
    *
    * @param arr the array to be sorted
    * @param left the left outer bound element to start the sort
    * @param right the right outer bound element to stop the sort
    */
    function quickSort(uint[] memory arr, int left, int right) private pure {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }

    /**
    * @dev sort implementation which calls the quickSort function
    *
    * @param data the array to be sorted
    * @return the sorted array
    */
    function sort(uint[] memory data) private pure returns (uint[] memory) {
        quickSort(data, int(0), int(data.length - 1));
        return data;
    }

    //---------------------------view functions ---------------------------

    function getHistoricalFeeds(uint256[] memory feedIDs, uint256[] memory timestamps) external view returns (uint256[] memory) {

        uint256 feedLen = feedIDs.length;
        uint256[] memory returnPrices = new uint256[](feedLen);
        require(feedIDs.length == timestamps.length, "Feeds and Timestamps must match");

        for (uint i = 0; i < feedIDs.length; i++) {

            if (subscriptionPassPrice > 0) {
                if (hasPass[msg.sender] <= block.timestamp) {
                    if (feedList[feedIDs[i]].revenueMode == 1 && subscribedTo[msg.sender][feedIDs[i]] < block.timestamp) {
                        revert("No subscription to feed");
                    }
                }
            } else {
                if (feedList[feedIDs[i]].revenueMode == 1 && subscribedTo[msg.sender][feedIDs[i]] < block.timestamp) {
                    revert("No subscription to feed");
                }
            }

            uint256 roundNumber = timestamps[i] / feedList[feedIDs[i]].feedTimeslot;
            returnPrices[i] =  historicalFeeds[feedIDs[i]][roundNumber];
        }

        return (returnPrices);
    }


    /**
    * @dev getFeeds function lets anyone call the oracle to receive data (maybe pay an optional fee)
    *
    * @param feedIDs the array of feedIds
    */
    function getFeeds(uint256[] memory feedIDs) external view returns (uint256[] memory, uint256[] memory, uint256[] memory) {

        uint256 feedLen = feedIDs.length;
        uint256[] memory returnPrices = new uint256[](feedLen);
        uint256[] memory returnTimestamps = new uint256[](feedLen);
        uint256[] memory returnDecimals = new uint256[](feedLen);

        for (uint i = 0; i < feedIDs.length; i++) {
            (returnPrices[i] ,returnTimestamps[i], returnDecimals[i]) = getFeed(feedIDs[i]);
        }

        return (returnPrices, returnTimestamps, returnDecimals);
    }

    /**
    * @dev getFeed function lets anyone call the oracle to receive data (maybe pay an optional fee)
    *
    * @param feedID the array of feedId
    */
    function getFeed(uint256 feedID) public view returns (uint256, uint256, uint256) {

        uint256 returnPrice;
        uint256 returnTimestamp;
        uint256 returnDecimals;

        if (subscriptionPassPrice > 0) {
            if (hasPass[msg.sender] <= block.timestamp) {
                if (feedList[feedID].revenueMode == 1 && subscribedTo[msg.sender][feedID] < block.timestamp) {
                    revert("No subscription to feed");
                }
            }
        } else {
            if (feedList[feedID].revenueMode == 1 && subscribedTo[msg.sender][feedID] < block.timestamp) {
                revert("No subscription to feed");
            }
        }

        returnPrice = feedList[feedID].latestPrice;
        returnTimestamp = feedList[feedID].latestPriceUpdate;
        returnDecimals = feedList[feedID].feedDecimals;

        return (returnPrice, returnTimestamp, returnDecimals);
    }

    function getFeedLength() external view returns(uint256){
        return feedList.length;
    }

    function getFeedList(uint256[] memory feedIDs) external view returns(string[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {

        uint256 feedLen = feedIDs.length;
        string[] memory returnNames = new string[](feedLen);
        uint256[] memory returnDecimals = new uint256[](feedLen);
        uint256[] memory returnTimeslot = new uint256[](feedLen);
        uint256[] memory returnRevenueMode = new uint256[](feedLen);
        uint256[] memory returnCost = new uint256[](feedLen);

        for (uint i = 0; i < feedIDs.length; i++) {
            returnNames[i] = feedList[feedIDs[i]].feedName;
            returnDecimals[i] = feedList[feedIDs[i]].feedDecimals;
            returnTimeslot[i] = feedList[feedIDs[i]].feedTimeslot;
            returnRevenueMode[i] = feedList[feedIDs[i]].revenueMode;
            returnCost[i] = feedList[feedIDs[i]].feedCost;
        }

        return (returnNames, returnDecimals, returnTimeslot, returnRevenueMode, returnCost);
    }

    //---------------------------oracle management functions ---------------------------

    // function to withdraw funds
    function withdrawFunds() external {

        if (payoutAddress == address(0)) {
            for (uint n = 0; n < signers.length; n++){
                payable(signers[n]).transfer(address(this).balance/signers.length);
            }
        } else {
            payoutAddress.transfer(address(this).balance);
        }
    }

    function createNewFeeds(string[] memory names, string[] memory descriptions, uint256[] memory decimals, uint256[] memory timeslots, uint256[] memory feedCosts, uint256[] memory revenueModes) onlySigner external {
        require(names.length == descriptions.length, "Length mismatch");
        require(descriptions.length == decimals.length, "Length mismatch");
        require(decimals.length == timeslots.length, "Length mismatch");
        require(timeslots.length == feedCosts.length, "Length mismatch");
        require(feedCosts.length == revenueModes.length, "Length mismatch");

        for(uint i = 0; i < names.length; i++) {
            require(decimals[i] <= 18, "Decimal places too high");
            require(timeslots[i] > 0, "Timeslot cannot be 0");
            require(revenueModes[i] <= 1, "Wrong revenueMode parameter");

            feedList.push(oracleStruct({
            feedName: names[i],
            feedDecimals: decimals[i],
            feedTimeslot: timeslots[i],
            latestPrice: 0,
            latestPriceUpdate: 0,
            revenueMode: revenueModes[i],
            feedCost: feedCosts[i]
            }));

            emit feedAdded(names[i], descriptions[i], decimals[i], timeslots[i], feedList.length - 1, revenueModes[i], feedCosts[i]);
        }
    }

    /**
    * @dev submitFeed function lets a signer submit as many feeds as they want to
    *
    * @param values the array of values
    * @param feedIDs the array of feedIds
    */
    function submitFeed(uint256[] memory feedIDs, uint256[] memory values) onlySigner external {
        require(values.length == feedIDs.length, "Value length and feedID length do not match");

        // process feeds
        for (uint i = 0; i < values.length; i++) {
            // get current round number for feed
            uint256 roundNumber = block.timestamp / feedList[feedIDs[i]].feedTimeslot;

            // check if the signer already pushed an update for the given period
            if (feedRoundNumberToStructMapping[feedIDs[i]][roundNumber][msg.sender].timestamp != 0) {
                delete feedRoundNumberToStructMapping[feedIDs[i]][roundNumber][msg.sender];
            }

            // feed - number and push value
            feedRoundNumberToStructMapping[feedIDs[i]][roundNumber][msg.sender] = feedRoundStruct({
            value: values[i],
            timestamp: block.timestamp
            });

            emit feedSigned(feedIDs[i], roundNumber, values[i], block.timestamp, msg.sender);

            // check if threshold was met
            uint256 signedFeedsLen;
            uint256[] memory prices = new uint256[](signers.length);
            uint256 k;

            for (uint j = 0; j < signers.length; j++) {
                if (feedRoundNumberToStructMapping[feedIDs[i]][roundNumber][signers[j]].timestamp != 0) {
                    signedFeedsLen++;
                    prices[k++] = feedRoundNumberToStructMapping[feedIDs[i]][roundNumber][signers[j]].value;
                }
            }

            // Change the list size of the array in place
            assembly {
                mstore(prices, k)
            }

            // if threshold is met process price
            if (signedFeedsLen >= signerThreshold) {

                uint[] memory sorted = sort(prices);
                uint returnPrice;

                // uneven so we can take the middle
                if (sorted.length % 2 == 1) {
                    uint sizer = (sorted.length + 1) / 2;
                    returnPrice = sorted[sizer-1];
                    // take average of the 2 most inner numbers
                } else {
                    uint size1 = (sorted.length) / 2;
                    returnPrice =  (sorted[size1-1]+sorted[size1])/2;
                }

                // process the struct for storing
                if (block.timestamp / feedList[feedIDs[i]].feedTimeslot > feedList[feedIDs[i]].latestPriceUpdate / feedList[feedIDs[i]].feedTimeslot) {
                    historicalFeeds[feedIDs[i]][feedList[feedIDs[i]].latestPriceUpdate / feedList[feedIDs[i]].feedTimeslot] = feedList[feedIDs[i]].latestPrice;
                }
                feedList[feedIDs[i]].latestPriceUpdate = block.timestamp;
                feedList[feedIDs[i]].latestPrice = returnPrice;
            }
        }
    }

    function signProposal(uint256 proposalId) onlySigner external {
        require(proposalList[proposalId].proposalActive != 0, "Proposal not active");

        hasSignedProposal[proposalId][msg.sender] = true;
        emit proposalSigned(proposalId, msg.sender);

        uint256 signedProposalLen;

        for(uint i = 0; i < signers.length; i++) {
            if (hasSignedProposal[proposalId][signers[i]]) {
                signedProposalLen++;
            }
        }

        // execute proposal
        if (signedProposalLen >= signerThreshold) {
            if (proposalList[proposalId].proposalType == 0) {
                updatePricePass(proposalList[proposalId].uintValue);
            } else if (proposalList[proposalId].proposalType == 1) {
                updateThreshold(proposalList[proposalId].uintValue);
            } else if (proposalList[proposalId].proposalType == 2) {
                addSigners(proposalList[proposalId].addressValue);
            } else if (proposalList[proposalId].proposalType == 3) {
                removeSigner(proposalList[proposalId].addressValue);
            } else if (proposalList[proposalId].proposalType == 4) {
                updatePayoutAddress(proposalList[proposalId].addressValue);
            } else if (proposalList[proposalId].proposalType == 5) {
                updateRevenueMode(proposalList[proposalId].uintValue, proposalList[proposalId].proposalFeedId);
            } else {
                updateFeedCost(proposalList[proposalId].uintValue, proposalList[proposalId].proposalFeedId);
            }

            // lock proposal
            proposalList[proposalId].proposalActive = 0;
        }
    }

    function createProposal(uint256 uintValue, address addressValue, uint256 proposalType, uint256 feedId) onlySigner external {

        uint256 proposalArrayLen = proposalList.length;

        // fee or threshold
        if (proposalType == 0 || proposalType == 1 || proposalType == 7) {
            proposalList.push(proposalStruct({
            uintValue: uintValue,
            addressValue: address(0),
            proposer: msg.sender,
            proposalType: proposalType,
            proposalFeedId: 0,
            proposalActive: 1
            }));
        } else if (proposalType == 5 || proposalType == 6) {
            proposalList.push(proposalStruct({
            uintValue: uintValue,
            addressValue: address(0),
            proposer: msg.sender,
            proposalType: proposalType,
            proposalFeedId : feedId,
            proposalActive: 1
            }));
        } else {
            proposalList.push(proposalStruct({
            uintValue: 0,
            addressValue: addressValue,
            proposer: msg.sender,
            proposalType: proposalType,
            proposalFeedId : 0,
            proposalActive: 1
            }));
        }

        hasSignedProposal[proposalArrayLen][msg.sender] = true;

        emit newProposal(proposalArrayLen, uintValue, addressValue, proposalType, msg.sender);
        emit proposalSigned(proposalArrayLen, msg.sender);
    }

    function updatePricePass(uint256 newPricePass) private {
        subscriptionPassPrice = newPricePass;

        emit subscriptionPassPriceUpdated(newPricePass);
    }

    function updateRevenueMode(uint256 newRevenueModeValue, uint256 feedId ) private {
        require(newRevenueModeValue <= 1, "Invalid argument for revenue Mode");
        feedList[feedId].revenueMode = newRevenueModeValue;
        emit newRevenueMode(newRevenueModeValue, feedId);
    }

    function updateFeedCost(uint256 feedCost, uint256 feedId) private {
        require(feedCost > 0, "Feed price cant be 0");
        feedList[feedId].feedCost = feedCost;
        emit newFeedCost(feedCost, feedId);
    }

    function updateThreshold(uint256 newThresholdValue) private {
        require(newThresholdValue != 0, "Threshold cant be 0");
        require(newThresholdValue <= signerLength, "Threshold cant be bigger then length of signers");

        signerThreshold = newThresholdValue;
        emit newThreshold(newThresholdValue);
    }

    function addSigners(address newSignerValue) private {

        // check for duplicate signer
        for (uint i=0; i < signers.length; i++) {
            if (signers[i] == newSignerValue) {
                revert("Signer already exists");
            }
        }

        signers.push(newSignerValue);
        signerLength++;
        isSigner[newSignerValue] = true;
        emit newSigner(newSignerValue);
    }

    function updatePayoutAddress(address newPayoutAddressValue) private {
        payoutAddress = payable(newPayoutAddressValue);
        emit newPayoutAddress(newPayoutAddressValue);
    }

    function removeSigner(address toRemove) internal {
        require(isSigner[toRemove], "Address to remove has to be a signer");
        require(signers.length -1 >= signerThreshold, "Less signers than threshold");

        for (uint i = 0; i < signers.length; i++) {
            if (signers[i] == toRemove) {
                delete signers[i];
                signerLength --;
                isSigner[toRemove] = false;
                emit signerRemoved(toRemove);
            }
        }
    }

    //---------------------------subscription functions---------------------------

    function subscribeToFeed(uint256[] memory feedIDs, uint256[] memory durations, address buyer) payable external {
        require(feedIDs.length == durations.length, "Length mismatch");

        uint256 total;
        for (uint i = 0; i < feedIDs.length; i++) {
            require(feedList[feedIDs[i]].revenueMode == 1, "Donation mode turned on");
            require(durations[i] >= 3600, "Minimum subscription is 1h");

            if (subscribedTo[buyer][feedIDs[i]] <=block.timestamp) {
                subscribedTo[buyer][feedIDs[i]] = block.timestamp.add(durations[i]);
            } else {
                subscribedTo[buyer][feedIDs[i]] = subscribedTo[buyer][feedIDs[i]].add(durations[i]);
            }

            total += feedList[feedIDs[i]].feedCost * durations[i] / 3600;
        }

        // check if enough payment was sent
        require(msg.value >= total, "Not enough funds sent to cover oracle fees");

        // send feeds to router
        address payable conjureRouter = IConjureFactory(factoryContract).getConjureRouter();
        IConjureRouter(conjureRouter).deposit{value:msg.value/50}();
        emit routerFeeTaken(msg.value/50, msg.sender);
    }

    function buyPass(address buyer, uint256 duration) payable external {
        require(subscriptionPassPrice != 0, "Subscription Pass turned off");
        require(duration >= 3600, "Minimum subscription is 1h");
        require(msg.value >= subscriptionPassPrice * duration / 86400, "Not enough payment");

        if (hasPass[buyer] <=block.timestamp) {
            hasPass[buyer] = block.timestamp.add(duration);
        } else {
            hasPass[buyer] = hasPass[buyer].add(duration);
        }

        address payable conjureRouter = IConjureFactory(factoryContract).getConjureRouter();
        IConjureRouter(conjureRouter).deposit{value:msg.value/50}();
        emit routerFeeTaken(msg.value/50, msg.sender);
    }

    function supportFeeds(uint256[] memory feedIds, uint256[] memory values) payable external {
        require(feedIds.length == values.length, "Length mismatch");

        uint256 total;
        for (uint i = 0; i < feedIds.length; i++) {
            require(feedList[feedIds[i]].revenueMode == 0, "Subscription mode turned on");
            feedSupport[feedIds[i]] = feedSupport[feedIds[i]].add(values[i]);
            total += values[i];

            emit feedSupported(feedIds[i], values[i]);
        }

        require(msg.value >= total, "Msg.value does not meet support values");

        address payable conjureRouter = IConjureFactory(factoryContract).getConjureRouter();
        IConjureRouter(conjureRouter).deposit{value:total/100}();
        emit routerFeeTaken(total/100, msg.sender);
    }
}
