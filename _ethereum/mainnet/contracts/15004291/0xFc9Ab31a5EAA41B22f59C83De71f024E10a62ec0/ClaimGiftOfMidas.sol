// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


import "./VRFConsumerBaseV2.sol";
import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./IERC721ABurnable.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Ownable.sol";


/**
 *  _______ __               _______                            __               __
 * |_     _|  |--.-----.    |   _   |.-----.----.-----.-----.--|  |.---.-.-----.|  |_.-----.
 *   |   | |     |  -__|    |       ||__ --|  __|  -__|     |  _  ||  _  |     ||   _|__ --|
 *   |___| |__|__|_____|    |___|___||_____|____|_____|__|__|_____||___._|__|__||____|_____|
**/

contract ClaimGiftOfMidas is VRFConsumerBaseV2, Ownable {

    IERC721ABurnable giftOfMidasInterface;
    uint256 totalGOMTokens;

    uint256 commonPrizeCounter;
    uint256[] commonPrizes;
    mapping(uint256 => commonPrize) public idToCommonPrize;

    struct commonPrize {
        IERC1155 IAddress;
        uint tokenId;
        uint amountRemaining;
    }

    uint256 legendaryPrizeCounter = 1; // start at 1 to keep zero as empty value in mapping GOMTokenIdToLegendaryPrizeId
    uint256[] public legendaryPrizes;
    mapping(uint256 => legendaryPrize) public idToLegendaryPrize;
    mapping(uint256 => uint256) public GOMTokenIdToLegendaryPrizeId;

    struct legendaryPrize {
        IERC721 IAddress;
        uint tokenId;
    }

    address holderAddress; // address which holds nfts that would be given out
    bool claimOpen;
    uint nonce;

    VRFCoordinatorV2Interface immutable COORDINATOR;
    LinkTokenInterface immutable LINKTOKEN;
    uint64 immutable s_subscriptionId;
    bytes32 immutable s_keyHash;
    uint16 immutable s_requestConfirmations = 3;
    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;

    error RandomNumbersDontMatchPrizePoolLength();
    error NotAuthorisedToAddPrizes();
    error NotOpenYet();

    event WinnerSet(uint256 indexed tokenId, uint256 prizeId);
    event PrizeClaimed(address indexed user, address indexed nftContract, uint256 tokenId);
    event ReturnedRandomness(uint256[] randomWords);
    event ReRollPrize(uint256 prizeIndex);

    /**
     * @notice Constructor inherits VRFConsumerBaseV2
     *
     * @param giftOfMidas - contract of NFTs to be burnt to claim
     * @param _holderAddress - address which holds the NFT prizes to be given out
     * @param subscriptionId - the subscription ID that this contract uses for funding requests
     * @param vrfCoordinator - coordinator, check https://docs.chain.link/docs/vrf-contracts/#configurations
     * @param keyHash - the gas lane to use, which specifies the maximum gas price to bump to
     */
    constructor(
        address giftOfMidas,
        address _holderAddress,
        uint64 subscriptionId,
        address vrfCoordinator,
        address link,
        bytes32 keyHash
    ) VRFConsumerBaseV2(vrfCoordinator) {
        giftOfMidasInterface = IERC721ABurnable(giftOfMidas);
        totalGOMTokens = giftOfMidasInterface.totalSupply();
        holderAddress = _holderAddress;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        s_keyHash = keyHash;
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    /**
      * @notice Set a winner for each random number generated from VRF for the legendary prize pool
     */
    function generateWinners() external onlyOwner {
        if (legendaryPrizes.length != s_randomWords.length) revert RandomNumbersDontMatchPrizePoolLength();
        for (uint i = 0; i < s_randomWords.length; i++) {
            setWinner(i, i);
        }
    }

    /**
     * @notice function for setting random token id from chain links VRF
     * We leave this public encase we have to re-roll a number in the very unlikely chance we get a duplicated winner
     * @param sWordsIndex - index of s_randomWords from VRF
     * @param prizeIndex - index of prize list
     */
    function setWinner(uint256 sWordsIndex, uint256 prizeIndex) public onlyOwner {
        uint256 randomTokenId = s_randomWords[sWordsIndex] % totalGOMTokens;
        s_randomWords[sWordsIndex] = randomTokenId;
        // Encase unlikely event a tokenId is selected twice
        if (GOMTokenIdToLegendaryPrizeId[randomTokenId] == 0) {
            GOMTokenIdToLegendaryPrizeId[randomTokenId] = legendaryPrizes[prizeIndex];
            emit WinnerSet(randomTokenId, legendaryPrizes[prizeIndex]);
        } else {
            emit ReRollPrize(prizeIndex);
        }
    }

    /**
     * @notice claim prize for given tokenId
     *
     * @param tokenId - Of GiftOfMidas
     */
    function claimPrize(uint256 tokenId) public {
        if (!claimOpen) revert NotOpenYet();
        giftOfMidasInterface.burn(tokenId);
        if (GOMTokenIdToLegendaryPrizeId[tokenId] != 0) {
            claimLegendaryPrize(tokenId);
        }
        else {
            claimCommonPrize();
        }
    }

    /**
     * @notice bulk claim prizes
     *
     * @param tokenIds - Of GiftOfMidas to claim
     */
    function bulkClaimPrizes(uint256[] memory tokenIds) external {
        if (!claimOpen) revert NotOpenYet();
        for (uint i = 0; i < tokenIds.length; i++) {
            claimPrize(tokenIds[i]);
        }

    }

    /**
     * @notice Claim legendary prize which has been set to tokenId
     *
     * @param tokenId - Of GiftOfMidas to be burned to claim prize
     */
    function claimLegendaryPrize(uint256 tokenId) internal {
        legendaryPrize memory prize = idToLegendaryPrize[GOMTokenIdToLegendaryPrizeId[tokenId]];
        prize.IAddress.safeTransferFrom(holderAddress, msg.sender, prize.tokenId, "");
        emit PrizeClaimed(msg.sender, address(prize.IAddress), prize.tokenId);
        delete GOMTokenIdToLegendaryPrizeId[tokenId];
    }

    /**
     * @notice Claim random common prize from common prize pool
     */
    function claimCommonPrize() internal {
        uint prizeIndexToClaim = generateRandomNumber(commonPrizes.length);
        uint commonPrizeId = commonPrizes[prizeIndexToClaim];
        commonPrize storage prize = idToCommonPrize[commonPrizeId];
        prize.amountRemaining--;
        if (prize.amountRemaining == 0) {
            _removePrize(prizeIndexToClaim, commonPrizes);
        }
        prize.IAddress.safeTransferFrom(holderAddress, msg.sender, prize.tokenId, 1, "");
        emit PrizeClaimed(msg.sender, address(prize.IAddress), prize.tokenId);
    }

    /**
      * @notice Add ERC721 legendary prize to the pool
      *
      * @param _address - address of nft
      * @param _tokenId - token id of prize
     */
    function addLegendaryPrize(address _address, uint _tokenId) external {
        if (msg.sender != holderAddress) revert NotAuthorisedToAddPrizes();
        legendaryPrize memory _prize = legendaryPrize(IERC721(_address), _tokenId);
        uint256 id = legendaryPrizeCounter++;
        idToLegendaryPrize[id] = _prize;
        legendaryPrizes.push(id);
    }

    /**
      * @notice Add ERC1155 to common prize to the pool
      *
      * @param _address - address of nft
      * @param _tokenId - token id of prize
      * @param _quantity - quantity of prizes
     */
    function addCommonPrize(address _address, uint _tokenId, uint _quantity) external {
        if (msg.sender != holderAddress) revert NotAuthorisedToAddPrizes();
        commonPrize memory _prize = commonPrize(IERC1155(_address), _tokenId, _quantity);
        uint256 id = commonPrizeCounter++;
        idToCommonPrize[id] = _prize;
        commonPrizes.push(id);
    }

    /**
      * @notice Remove a prize from a prize pool
      * swap and pop to remove element from array so it only contains active prizes without gaps in array
      * @param _index - index of prize in array
      * @param prizes - array of prizes to remove from
     */
    function _removePrize(uint256 _index, uint256[] storage prizes) internal {

        uint256 lastIndex = prizes.length - 1;
        prizes[_index] = prizes[lastIndex];
        prizes.pop();
    }


    /**
      * @notice Open claiming functionality
     */
    function toggleClaimOpen() onlyOwner external {
        claimOpen = !claimOpen;
    }

    /**
     * @notice generates a sudo random number
     * A sudo random number generator used for choosing common prizes where true randomness is not needed
     */
    function generateRandomNumber(uint maxNumber) internal returns (uint) {
        uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % maxNumber;
        nonce++;
        return randomNumber;
    }

    /**
     * @notice Requests randomness
     * Assumes the subscription is funded sufficiently; "Words" refers to unit of data in Computer Science
     */
    function requestRandomWords(uint32 s_amount, uint32 s_callbackGasLimit) external onlyOwner {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            s_amount
        );
    }

    /**
     * @notice Callback function used by VRF Coordinator
     *
     * @param requestId - id of the request
     * @param randomWords - array of random results from VRF Coordinator
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
    {
        s_randomWords = randomWords;
        emit ReturnedRandomness(randomWords);
    }

}
