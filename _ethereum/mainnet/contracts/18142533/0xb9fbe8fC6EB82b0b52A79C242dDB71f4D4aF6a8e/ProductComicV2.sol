// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC1155.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./ProductComicLib.sol";
import "./IProductComicV2.sol";

contract ProductComicV2 is
    VRFConsumerBaseV2,
    Ownable,
    IProductComic,
    ReentrancyGuard
{
    // Chainlink Parameters
    VRFCoordinatorV2Interface public vrfCoordinator;
    uint64 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit = 2000000;
    uint32 public numWords = 1;
    uint16 public requestConfirmations = 3;

    // Pull from address for different NFTs (comics, hoodies, etc)
    address public pullFromAddress = 0x716E6b6873038a8243F5EB44e2b09D85DEFf45Ec;

    address public comicAddress = 0x6A82872743217A0988E4d72975D74432CfDeF9D7;
    address public parallelAlphaAddress =
        0x76BE3b62873462d2142405439777e971754E8E77;

    address public shopAddress = 0xd32034B5502910e5B56f5AC94ACb4198315c2Da2;

    uint256 public comicSupplyRemaining;
    uint256 public cardBackSupplyRemaining;
    uint256 public numRequestsRemaining;

    uint256[] public comicTokenIds;
    uint256[] public cardBackTokenIds;

    bool public isCardBackDisabled;

    mapping(uint256 => ProductComicLib.Request) public vrfRequestIdToRequest;
    mapping(uint256 => uint256) public comicMaxSupply;
    mapping(uint256 => uint256) public comicPurchased;
    mapping(uint256 => uint256) public cardBackMaxSupply;
    mapping(uint256 => uint256) public cardBackPurchased;

    constructor(
        uint64 _subscriptionId,
        address _coordinator,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_coordinator) {
        // Chainlink Addresses Doc: https://docs.chain.link/docs/vrf-contracts/#ethereum-mainnet
        // Ethereum Mainnet
        // VRF Coordinator 0x271682DEB8C4E0901D1a1550aD2e64D568E69909
        // Key Hash 200 GWei 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef
        // Key Hash 500 GWei 0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92
        // Key Hash 1000 GWei 0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805
        // Goerli testnet
        // VRF Coordinator 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
        // Key Hash 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15
        vrfCoordinator = VRFCoordinatorV2Interface(_coordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
    }

    /**
     * @notice Updates subscription id
     * @dev Only callable by owner
     * @param _subscriptionId New subscription id
     */
    function setSubscriptionId(uint64 _subscriptionId) public onlyOwner {
        subscriptionId = _subscriptionId;
        emit SubscriptionIdSet(subscriptionId);
    }

    /**
     * @notice Updates key hash
     * @dev Only callable by owner
     * @param _keyHash New key hash
     */
    function setKeyHash(bytes32 _keyHash) public onlyOwner {
        keyHash = _keyHash;
        emit KeyHashSet(keyHash);
    }

    /**
     * @notice Updates vfr coordinator
     * @dev Only callable by owner
     * @param _vrfCoordinator New vrf coordinator
     */
    function setVrfCoordinator(address _vrfCoordinator) public onlyOwner {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        emit VrfCoordinatorSet(_vrfCoordinator);
    }

    /**
     * @notice Updates pull from address
     * @dev Only callable by owner
     * @param _pullFromAddress New pull from address
     */
    function setPullFromAddress(address _pullFromAddress) external onlyOwner {
        pullFromAddress = _pullFromAddress;
        emit PullFromAddressSet(pullFromAddress);
    }

    /**
     * @notice Updates comic address
     * @dev Only callable by owner
     * @param _comicAddress New comic address
     */
    function setComicAddress(address _comicAddress) external onlyOwner {
        comicAddress = _comicAddress;
        emit ComicAddressSet(comicAddress);
    }

    /**
     * @notice Updates parallel alpha address
     * @dev Only callable by owner
     * @param _parallelAlphaAddress New parallel alpha address
     */
    function setParallelAlphaAddress(
        address _parallelAlphaAddress
    ) external onlyOwner {
        parallelAlphaAddress = _parallelAlphaAddress;
        emit ParallelAlphaAddressSet(parallelAlphaAddress);
    }

    /**
     * @notice Updates shop address
     * @dev Only callable by owner
     * @param _shopAddress New shop address
     */
    function setShopAddress(address _shopAddress) external onlyOwner {
        shopAddress = _shopAddress;
        emit ShopContractSet(shopAddress);
    }

    /**
     * @notice Sets comic max supply for each comic tier
     * @dev Only callable by owner
     * @param _comicSupply List of comic supply for each comic tier
     */
    function setComicMaxSupply(
        uint256[2] memory _comicTokenIds,
        uint256[2] memory _comicSupply
    ) external onlyOwner {
        if (_comicTokenIds.length != _comicSupply.length) {
            revert ParamLengthMissMatch();
        }

        comicSupplyRemaining = 0;
        numRequestsRemaining = 0;
        comicTokenIds = _comicTokenIds;

        for (uint256 i = 0; i < comicTokenIds.length; i++) {
            comicPurchased[comicTokenIds[i]] = 0;
            comicMaxSupply[comicTokenIds[i]] = _comicSupply[i];
            comicSupplyRemaining += _comicSupply[i];
            numRequestsRemaining += _comicSupply[i];
        }
        emit ComicSupplySet(_comicTokenIds, _comicSupply);
    }

    /**
     * @notice Sets card back max supply along with card back token ids
     * @dev Only callable by owner
     * @param _cardBackTokenIds List of card back token ids
     * @param _cardBackSupply List card back supply for each token id
     */
    function setCardBackTokenIds(
        uint256[] memory _cardBackTokenIds,
        uint256[] memory _cardBackSupply
    ) external onlyOwner {
        if (_cardBackTokenIds.length != _cardBackSupply.length) {
            revert ParamLengthMissMatch();
        }

        cardBackSupplyRemaining = 0;
        cardBackTokenIds = _cardBackTokenIds;
        for (uint256 i = 0; i < _cardBackTokenIds.length; i++) {
            cardBackPurchased[_cardBackTokenIds[i]] = 0;
            cardBackMaxSupply[_cardBackTokenIds[i]] = _cardBackSupply[i];
            cardBackSupplyRemaining += _cardBackSupply[i];
        }
        emit CardBackSupplySet(_cardBackTokenIds, _cardBackSupply);
    }

    /**
     * @notice Updates card back disable status
     * @dev Only callable by owner
     * @param _isCardBackDisabled New card back disable status
     */
    function setCardBackDisabled(bool _isCardBackDisabled) external onlyOwner {
        isCardBackDisabled = _isCardBackDisabled;
        emit CardBackDisabledSet(isCardBackDisabled);
    }

    /**
     * @notice Kicks off VRF request for the given user
     * @dev Only callable by shop contract
     * @param _to Destination address
     * @param _amount Number of comics to assign
     * @param _transactionId Id based by server to include in event for tracking
     */
    function getComics(
        address _to,
        uint256 _amount,
        uint256 _transactionId
    ) external {
        if (msg.sender != shopAddress) {
            revert InvalidInvoker();
        }

        if (numRequestsRemaining < _amount) {
            revert SupplyOverflow();
        }
        numRequestsRemaining -= _amount;

        // Create request struct and store in mapping under VRF request Id
        ProductComicLib.Request memory newRequest;
        newRequest.owner = _to;
        newRequest.numComicsToSend = _amount;

        // Request VRF
        uint256 requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        vrfRequestIdToRequest[requestId] = newRequest;
        emit ComicPurchased(_to, _amount, requestId, _transactionId);
    }

    /**
     * @notice Callback function hit by ChainLink VRF. Assigns comics, shards and card back (if need be)
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override nonReentrant {
        ProductComicLib.Request storage request = vrfRequestIdToRequest[
            _requestId
        ];
        if (request.owner == address(0)) {
            revert EmptyRequestFulfillment();
        }
        if (request.isAssigned) {
            revert RequestAlreadyFulfilled();
        }

        uint256 randomSeed;
        uint256[] memory assignedComicTokenIds = new uint256[](
            request.numComicsToSend
        );
        uint256[] memory assignedCardBackTokenIds = new uint256[](
            request.numComicsToSend
        );
        for (uint256 i = 0; i < request.numComicsToSend; i++) {
            randomSeed = uint256(
                keccak256(abi.encodePacked(_randomWords[0], i))
            );
            assignedComicTokenIds[i] = _getComicTokenId(randomSeed);

            IERC1155(comicAddress).safeTransferFrom(
                pullFromAddress,
                request.owner,
                assignedComicTokenIds[i],
                1,
                bytes("")
            );

            if (!isCardBackDisabled) {
                randomSeed = uint256(
                    keccak256(abi.encodePacked(randomSeed, i))
                );
                assignedCardBackTokenIds[i] = _getCardBackTokenId(randomSeed);
                IERC1155(parallelAlphaAddress).safeTransferFrom(
                    pullFromAddress,
                    request.owner,
                    assignedCardBackTokenIds[i],
                    1,
                    bytes("")
                );
            }
        }

        request.isAssigned = true;
        emit ComicTransferred(
            request.owner,
            request.numComicsToSend,
            _requestId,
            request.transactionId,
            assignedComicTokenIds,
            assignedCardBackTokenIds
        );
    }

    /**
     * @notice Re-trigger request. Deletes the old request
     * @dev Old request most not be fulfilled. Only callable by owner
     * @param _oldRequestId If of the request to re-trigger
     */
    function recoverRequestId(uint256 _oldRequestId) external onlyOwner {
        ProductComicLib.Request memory oldRequest = vrfRequestIdToRequest[
            _oldRequestId
        ];
        if (oldRequest.isAssigned) {
            revert RequestAlreadyFulfilled();
        }

        // fire off new one
        uint256 newRequestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        ProductComicLib.Request memory newRequest;
        newRequest.owner = oldRequest.owner;
        newRequest.numComicsToSend = oldRequest.numComicsToSend;
        newRequest.transactionId = oldRequest.transactionId;

        vrfRequestIdToRequest[newRequestId] = newRequest;

        // delete old request
        delete vrfRequestIdToRequest[_oldRequestId];

        // Emit new requestId
        emit RequestRecovered(
            newRequest.owner,
            newRequest.numComicsToSend,
            newRequestId,
            newRequest.transactionId
        );
    }

    /**
     * @notice Calculates random comic token id based on the remaining supply
     * @param _randomSeed Random seed to use for token id selection
     */
    function _getComicTokenId(uint256 _randomSeed) internal returns (uint256) {
        uint256 randomPercent = _randomSeed % 100;

        uint256 silverPercent = ((comicMaxSupply[comicTokenIds[0]] -
            comicPurchased[comicTokenIds[0]]) * 100) / comicSupplyRemaining;

        comicSupplyRemaining -= 1;

        if (randomPercent < silverPercent) {
            comicPurchased[comicTokenIds[0]] += 1;
            return comicTokenIds[0];
        } else {
            comicPurchased[comicTokenIds[1]] += 1;
            return comicTokenIds[1];
        }
    }

    /**
     * @notice Calculates random card back token id based on the remaining supply
     * @param _randomSeed Random seed to use for token if selection
     */
    function _getCardBackTokenId(
        uint256 _randomSeed
    ) internal returns (uint256) {
        uint256 randomPercent = _randomSeed % 100;
        uint256 selectedIndex;
        uint256 cardBackPercent;
        while (selectedIndex != cardBackTokenIds.length - 1) {
            cardBackPercent +=
                ((cardBackMaxSupply[cardBackTokenIds[selectedIndex]] -
                    cardBackPurchased[cardBackTokenIds[selectedIndex]]) * 100) /
                cardBackSupplyRemaining;
            if (randomPercent < cardBackPercent) {
                break;
            }
            selectedIndex += 1;
        }
        uint256 selectedTokenId = cardBackTokenIds[selectedIndex];
        if (
            cardBackPurchased[selectedTokenId] ==
            cardBackMaxSupply[selectedTokenId]
        ) {
            revert CardBackSUpplyOverflow();
        }
        cardBackPurchased[selectedTokenId] += 1;
        cardBackSupplyRemaining -= 1;
        if (
            cardBackPurchased[selectedTokenId] ==
            cardBackMaxSupply[selectedTokenId]
        ) {
            cardBackTokenIds[selectedIndex] = cardBackTokenIds[
                cardBackTokenIds.length - 1
            ];
            cardBackTokenIds.pop();
        }

        return selectedTokenId;
    }
}
