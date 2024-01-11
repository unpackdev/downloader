// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

/**
 * @title Fanchise Benefit NFT
 */
contract Benefit is VRFConsumerBaseV2, ERC721Enumerable, ERC2981, Ownable {
    using ECDSA for bytes32;

    uint256 constant UINT256_MAX = 2**256 - 1;

    // Events
    event BenefitClaimed(uint256 indexed benefitId, uint256 indexed nonce, uint256 tokenId);
    event RaffleComplete(uint256 indexed raffleId, uint256 raffleWinner);

    // Base URI
    string private _baseURI;

    // Mapping from nonce value to bool documenting whether the given nonce was already used, used to guard against replay attacks
    mapping(uint256 => bool) private _nonceUsed;

    // Used to lock owner configuration functions
    bool private _locked;

    // The address of the server that signs all buy transactions; see docs on the buy function for more info
    address public _signerAddress;

    // A record of the winner of a particular raffle (identified by a benefitId)
    mapping(uint256 => uint256) _raffleWinners;

    // A record of the number of participants in a given raffle
    mapping(uint256 => uint256) _raffleParticipants;

    // A record of the the chainlink request per raffle
    mapping(uint256 => uint256) _raffleRequests;

    // Chainlink configuration
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    uint64 chainlinkSubscriptionId;
    bytes32 chainlinkKeyHash;

    constructor(
        string memory baseURI,
        string memory name,
        string memory symbol,
        address owner,
        address signer,
        address royaltiesReceiver,
        uint96 royaltiesFeeNumerator,
        address vrfCoordinator,
        address linkToken,
        uint64 subscriptionId,
        bytes32 keyHash
    ) ERC721(name, symbol) VRFConsumerBaseV2(vrfCoordinator) {
        _baseURI = baseURI;
        _signerAddress = signer;
        _setDefaultRoyalty(royaltiesReceiver, royaltiesFeeNumerator);
        transferOwnership(owner);

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(linkToken);
        chainlinkSubscriptionId = subscriptionId;
        chainlinkKeyHash = keyHash;
    }

    /**
     * Modifiers
     */

    modifier unlocked() {
        require(!_locked, "Contract locked");
        _;
    }

    /**
     * Public Transactions
     */

    /**
     * @notice Claim a benefit based on the holding of a Ballerz NFT.
     * @param nonce The nonce of this transaction; must be unique to protect against replay attacks.
     * @param sig The server's signature over all inputs: benefitId, nonce, this.address, msg.sender, msg.value
     */
    function claim(
        uint256 benefitId,
        uint256 nonce,
        bytes memory sig
    ) external payable {
        require(!_nonceUsed[nonce], "Nonce already used");

        require(_checkSig(nonce, msg.sender, msg.value, sig), "Invalid signature");

        _claim(nonce);

        emit BenefitClaimed(benefitId, nonce, latestTokenId());
    }

    /**
     * Public View Functions
     */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist.");
        return string(abi.encodePacked(_baseURI, Strings.toString(tokenId)));
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length;
    }

    function latestTokenId() public view returns (uint256) {
        return totalSupply() - 1;
    }

    function getRaffleWinner(uint256 raffleId) public view returns (uint256) {
        return _raffleWinners[raffleId];
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < _owners.length, "ERC721Enumerable: global index out of bounds");
        return index;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721Enumerable)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * Internal Functions
     */

    function _claim(uint256 nonce) internal {
        assert(!_nonceUsed[nonce]);

        _nonceUsed[nonce] = true;

        _safeMint(msg.sender);
    }

    function _setNumParticipants(uint256 raffleId, uint256 numParticipants) internal {
        require(raffleId > 0, "Invalid raffleId");
        require(_raffleParticipants[raffleId] == 0, "Raffle already begun");
        require(numParticipants > 0, "Raffle must have at least one participant");

        _raffleParticipants[raffleId] = numParticipants;
    }

    function _completeRaffle(uint256 raffleId, uint256 randomNumber) internal {
        require(raffleId > 0, "Invalid raffleId");
        require(_raffleWinners[raffleId] == 0, "Raffle already complete");

        uint256 numParticipants = _raffleParticipants[raffleId];
        uint256 raffleWinner = randomNumber % numParticipants;

        _raffleWinners[raffleId] = raffleWinner;

        emit RaffleComplete(raffleId, raffleWinner);
    }

    /**
     * @dev Added nonce and contract address in sig to guard against replay attacks
     */
    function _checkSig(
        uint256 nonce,
        address user,
        uint256 price,
        bytes memory sig
    ) internal view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encode(nonce, address(this), user, price))
            )
        );
        return _signerAddress == hash.recover(sig);
    }

    /**
     * Owner Functions
     */

    function setBaseURI(string memory baseURI) public onlyOwner unlocked {
        _baseURI = baseURI;
    }

    function changeSigner(address signerAddress) public onlyOwner unlocked {
        _signerAddress = signerAddress;
    }

    function lockContract() public onlyOwner {
        _locked = true;
    }

    function withdraw(uint256 amount, address payable to) public onlyOwner {
        require(amount <= address(this).balance, "Cannot withdraw more than current balance");
        to.transfer(amount);
    }

    uint32 constant numWords = 1;
    uint16 constant requestConfirmations = 3;
    uint32 constant callbackGasLimit = 250000;

    function chooseRaffleWinner(uint256 raffleId, uint256 numParticipants) public onlyOwner unlocked {
        _setNumParticipants(raffleId, numParticipants);

        require(chainlinkSubscriptionId > 0, "Chainlink subscriptionId not set");

        // Will revert if subscription is not set and funded.
        uint256 requestId = COORDINATOR.requestRandomWords(
            chainlinkKeyHash,
            chainlinkSubscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        _raffleRequests[requestId] = raffleId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 raffleId = _raffleRequests[requestId];
        _completeRaffle(raffleId, randomWords[0]);
    }

    /**
     * @dev External onlyOwner version of {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev External onlyOwner version of {ERC2981-_deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev External onlyOwner version of {ERC2981-_setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev External onlyOwner version of {ERC2981-_resetTokenRoyalty}.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    /**
     * @dev Update chainlink subscriptionId
     */
    function setChainlinkSubscriptionId(uint64 subscriptionId) external onlyOwner {
        chainlinkSubscriptionId = subscriptionId;
    }

    /**
     * @dev Update chainlink subscriptionId
     */
    function setChainlinkKeyHash(bytes32 keyHash) external onlyOwner {
        chainlinkKeyHash = keyHash;
    }
}
