// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./RandomNumberConsumer.sol";
import "./INomoVault.sol";

/**
 * @title Contract for distributing ERC721 tokens.
 * The purpose is to give the ability to deplyer to airdrop ERC721, randomly chosen tokens from the collection.
 */
contract NFTAirdropMechanic is
    Ownable,
    ReentrancyGuard,
    RandomNumberConsumer
{
    using SafeMath for uint256;
    using Address for address;

    uint256[] private tokens;
    address[] public eligible;
    bool public isAirdropExecuted;
    uint256 public initialTokensLength;
    address public tokensVault;
    address public erc721Address;
    bytes32 public lastRequestId;

    mapping(uint256 => bool) public addedTokens;
    mapping(address => uint256) private addressToRandomNumber;

    event LogTokensBought(uint256[] _transferredTokens);
    event LogTokensAirdropped(uint256[] _airdroppedTokens);
    event LogInitialTokensLengthSet(uint256 _initialTokensLength);
    event LogEligibleSet(address[] _eligible);
    event LogTokensAdded(uint256 length);
    event LogRandomNumberRequested(address from);
    event LogRandomNumberSaved(address from);
    event LogSelectedUsers(address[] privileged);

    modifier isValidAddress(address addr) {
        require(addr != address(0), "Not a valid address!");
        _;
    }

    modifier isValidRandomNumber() {
        require(
            addressToRandomNumber[msg.sender] != 0,
            "Invalid random number"
        );
        _;
    }

    /**
     * @notice Construct and initialize the contract.
     * @param _erc721Address address of the associated ERC721 contract instance
     * @param _tokensVault address of the wallet used to store tokensArray
     */
    constructor(
        address _erc721Address,
        address _tokensVault,
        address _vrfCoordinator,
        address _LINKToken,
        bytes32 _keyHash,
        uint256 _fee
    )
        isValidAddress(_erc721Address)
        isValidAddress(_tokensVault)
        RandomNumberConsumer(_vrfCoordinator, _LINKToken, _keyHash, _fee)
    {
        erc721Address = _erc721Address;
        tokensVault = _tokensVault;
    }

    function addTokensToCollection(uint256[] memory tokensArray)
        external
        onlyOwner
    {
        require(
            tokensArray.length > 0,
            "Tokens array must include at least one item"
        );

        for (uint256 i = 0; i < tokensArray.length; i++) {
            require(
                !addedTokens[tokensArray[i]],
                "Token has been already added"
            );
            addedTokens[tokensArray[i]] = true;
            tokens.push(tokensArray[i]);
        }

        emit LogTokensAdded(tokensArray.length);
    }

    /**
     * @notice Sets initialTokensLength.
     * @param _initialTokensLength uint256 representing the initial length of the tokens
     */
    function setInitialTokensLength(uint256 _initialTokensLength)
        public
        onlyOwner
    {
        require(_initialTokensLength > 0, "must be above 0!");
        initialTokensLength = _initialTokensLength;
        emit LogInitialTokensLengthSet(initialTokensLength);
    }

    /**
     * @notice Sets eligible members who can claim free token.
     * @param members address[] representing the members will be eligible
     */
    function setEligible(address[] memory members) public onlyOwner {
        require(
            members.length > 0 && members.length <= 100,
            "Eligible members array length must be in the bounds of 1 and 100"
        );

        for (uint256 i = 0; i < members.length; i++) {
            eligible.push(members[i]);
        }

        emit LogEligibleSet(members);
    }

    /**
     * @notice Requests random number from Chainlink VRF.
     */
    function getRandomValue() public {
        lastRequestId = getRandomNumber();

        emit LogRandomNumberRequested(msg.sender);
    }

    /**
     *  @notice This is a callback method which is getting called in RandomConsumerNumber.sol
     */
    function saveRandomNumber(address from, uint256 n) internal override {
        addressToRandomNumber[from] = n;

        emit LogRandomNumberSaved(from);
    }

    /**
     * @notice Filters `eligible` users array in randomized way with Chainlink VRF.
     
     * @dev Deployer executes filtration with Chainlink VRF.
     *
     * @param privilegedMembers number of members who will be air-dropped one ERC721
     *
     * Requirements:
     * - the caller must be owner.
     * - random number must be different than zero
     * - eligible members must be more than the privileged
     *
     */
    function filterEligible(uint256 privilegedMembers)
        public
        onlyOwner
        isValidRandomNumber
    {
        require(
            eligible.length > privilegedMembers,
            "Eligible members must be more than privileged"
        );

        uint256 usersToRemove = eligible.length - privilegedMembers;

        uint256[] memory randomNumbers = expand(
            addressToRandomNumber[msg.sender],
            usersToRemove
        );
        
        addressToRandomNumber[msg.sender] = 0;

        for (uint256 i = 0; i < usersToRemove; i++) {
            uint256 randomNumber = randomNumbers[i] % eligible.length;
            eligible[randomNumber] = eligible[eligible.length - 1];
            eligible.pop();
        }

        emit LogSelectedUsers(eligible);
    }

    /**
     * @notice Transfers ERC721 token to `n` number of eligible users.
     
     * @dev Deployer executes airdrop.
     * NFTAirdropMechanic distributes one token to each of the eligible addresses if the requirements are met.
     *
     * Requirements:
     * - the caller must be owner.
     */
    function executeAirdrop() public onlyOwner isValidRandomNumber {
        require(!isAirdropExecuted, "Airdrop has been executed");
        require(
            (tokens.length >= eligible.length) && (eligible.length > 0),
            "Invalid airdrop parameters"
        );

        uint256[] memory randomNumbers = expand(
            addressToRandomNumber[msg.sender],
            eligible.length
        );
        uint256[] memory airdroppedTokens = new uint256[](eligible.length);

        isAirdropExecuted = true;

        addressToRandomNumber[msg.sender] = 0;

        for (uint256 i = 0; i < eligible.length; i++) {
            uint256 randomNumber = randomNumbers[i] % tokens.length;
            uint256 tokenId = tokens[randomNumber];
            airdroppedTokens[i] = tokenId;
            tokens[randomNumber] = tokens[tokens.length - 1];
            tokens.pop();

            IERC721(erc721Address).safeTransferFrom(
                tokensVault,
                eligible[i],
                tokenId
            );
        }

        emit LogTokensAirdropped(airdroppedTokens);
    }

    /**
     * @dev Returns the number of tokens left in the collection.
     * @return the length of the collection
     */
    function getTokensLeft() public view returns (uint256) {
        return tokens.length;
    }
}
