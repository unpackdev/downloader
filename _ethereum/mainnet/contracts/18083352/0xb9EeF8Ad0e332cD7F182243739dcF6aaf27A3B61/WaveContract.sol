// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.21;
pragma abicoder v2;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC2771Context.sol";
import "./IWaveFactory.sol";
import "./IWaveContract.sol";
import "./IRaffleManager.sol";
import "./ERC721.sol";
import "./IERC20.sol";
import "./SignatureVerifier.sol";

contract WaveContract is ERC2771Context, Ownable, ERC721, SignatureVerifier, IWaveContract {
    IWaveFactory public factory;

    uint256 public lastId;
    uint256 public startTimestamp;
    uint256 public endTimestamp;

    string _metadataBaseURI;
    bool public customMetadata;
    bool public isSoulbound;

    mapping(address => bool) _claimed;
    mapping(bytes32 => bool) public tokenIdRewardIdxHashToHasWon;

    IWaveFactory.TokenRewards[] public claimRewards;
    IWaveFactory.TokenRewards[] public raffleRewards;
    uint8 public immutable claimRewardsLength;
    uint8 public immutable raffleRewardsLength;
    bool public raffleCompleted;

    error OnlyRaffleManager();
    error OnlyAuthorized();
    error InvalidTimings();
    error CampaignNotActive();
    error CampaignNotEnded();
    error RewardAlreadyClaimed();
    error PermitDeadlineExpired();
    error NotTransferrable();

    event Claimed(address indexed user, uint256 indexed tokenId);
    event FCFSAwarded(address indexed user, address indexed token, uint256 amount);
    event RaffleWon(address indexed user, address indexed token, uint256 amount);
    event RaffleStarted(address indexed user);
    event RaffleCompleted();
    event CampaignForceEnded();
    event ClaimRewardsFundsWithdrawn();
    event RaffleRewardsFundsWithdrawn();

    modifier onlyAuthorized() {
        if (_msgSender() != factory.keeper() && _msgSender() != owner()) revert OnlyAuthorized();
        _;
    }

    modifier onlyRaffleManager() {
        if (_msgSender() != factory.raffleManager()) revert OnlyRaffleManager();
        _;
    }

    modifier onlyActive() {
        if (block.timestamp < startTimestamp || block.timestamp > endTimestamp) {
            revert CampaignNotActive();
        }
        _;
    }

    modifier onlyEnded() {
        if (block.timestamp < endTimestamp) revert CampaignNotEnded();
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        bool _isSoulbound,
        address _trustedForwarder,
        IWaveFactory.TokenRewards[] memory _claimRewards,
        IWaveFactory.TokenRewards[] memory _raffleRewards
    ) ERC2771Context(_trustedForwarder) Ownable() ERC721(_name, _symbol) SignatureVerifier(_name) {
        if (_startTimestamp > _endTimestamp || _endTimestamp < block.timestamp) {
            revert InvalidTimings();
        }

        factory = IWaveFactory(_msgSender());
        _metadataBaseURI = _uri;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        isSoulbound = _isSoulbound;

        claimRewardsLength = uint8(_claimRewards.length);
        for (uint8 i = 0; i < claimRewardsLength; ++i) {
            claimRewards.push(_claimRewards[i]);
        }

        raffleRewardsLength = uint8(_raffleRewards.length);
        for (uint8 i = 0; i < raffleRewardsLength; ++i) {
            raffleRewards.push(_raffleRewards[i]);
        }
    }

    /// @notice Allows the governance and the owner of the contract to set metadata base URI for all tokens
    /// @param _uri The base URI to set
    /// @param _customMetadata Whether the metadata is encoded with rewardId or tokenId
    function changeBaseURI(string memory _uri, bool _customMetadata) public onlyAuthorized {
        _metadataBaseURI = _uri;
        customMetadata = _customMetadata;
    }

    /// @notice Allows the owner to set the campaign start timestamp
    function setStartTimestamp(uint256 _startTimestamp) public onlyOwner {
        require(block.timestamp < _startTimestamp && _startTimestamp < endTimestamp, "Invalid start timestamp");
        startTimestamp = _startTimestamp;
    }

    /// @notice Allows the governance to set the campaign end timestamp
    function setEndTimestamp(uint256 _endTimestamp) public onlyOwner {
        require(raffleRewardsLength == 0, "Can't change end timestamp for raffles");
        require(_endTimestamp > block.timestamp && _endTimestamp > startTimestamp, "Invalid end timestamp");
        endTimestamp = _endTimestamp;
    }

    /// @notice Allows the owner to end the campaign early
    function endCampaign() public onlyActive onlyOwner {
        endTimestamp = block.timestamp;
        emit CampaignForceEnded();
    }

    /// @notice Allows anyone to make the claim rewards funds
    /// return to the owner after the campaign is ended
    function withdrawClaimRewardsFunds() public onlyEnded {
        for (uint8 i = 0; i < claimRewardsLength; ++i) {
            _returnTokenToOwner(IERC20(claimRewards[i].token));
        }
        emit ClaimRewardsFundsWithdrawn();
    }

    /// @notice Execute the mint with permit by verifying the off-chain verifier signature
    /// @dev Also works with gasless EIP-2612 forwarders
    /// @param deadline The deadline for the permit
    /// @param v The v component of the signature
    /// @param r The r component of the signature
    /// @param s The s component of the signature
    function claim(uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual onlyActive {
        if (_claimed[_msgSender()]) {
            revert RewardAlreadyClaimed();
        }
        if (block.timestamp > deadline) revert PermitDeadlineExpired();

        _verifySignature(_msgSender(), deadline, v, r, s, factory.verifier());
        _mintBadge(_msgSender());

        _emitERC20Rewards(_msgSender());
    }

    /// @notice sends a request for random numbers to the raffle manager
    /// @dev this function can be called multiple times because Airnode
    /// might fail for whatever reason
    function startRaffle() public onlyEnded {
        require(!raffleCompleted, "Raffle already done");
        emit RaffleStarted(_msgSender());
        address raffleManager = factory.raffleManager();
        IRaffleManager(raffleManager).makeRequestUint256Array(raffleRewardsLength);
    }

    /// @notice fulfills the raffle by assigning random numbers to each reward
    /// and emitting the tokens. Then, returns the remaining funds for raffle rewards
    /// to the owner
    /// @param randomNumbers the random numbers to use for the raffle
    /// @dev the set of winning token ids per reward is generated by a single
    /// random number provided by the raffle manager
    function fulfillRaffle(uint256[] memory randomNumbers) public onlyEnded onlyRaffleManager {
        require(!raffleCompleted, "Raffle already done");
        for (uint8 i = 0; i < raffleRewardsLength; i++) {
            uint256 randomNumber = randomNumbers[i];
            address tokenAddress = raffleRewards[i].token;
            uint256 amountPerUser = raffleRewards[i].amountPerUser;
            IERC20 token = IERC20(tokenAddress);

            uint256 counter = 0;
            uint256 rewardsLeft = raffleRewards[i].rewardsLeft;

            if (lastId <= rewardsLeft) {
                for (uint256 tokenId = 1; tokenId <= lastId; tokenId++) {
                    address winner = ownerOf(tokenId);
                    token.transfer(winner, amountPerUser);
                    emit RaffleWon(winner, tokenAddress, amountPerUser);
                }
            } else {
                for (uint256 assigned = 0; assigned < rewardsLeft; assigned++) {
                    uint256 tokenId;
                    do {
                        tokenId =
                            uint256(keccak256(abi.encodePacked(randomNumber, counter, block.timestamp))) % lastId + 1;
                        counter++;
                    } while (tokenIdRewardIdxHashToHasWon[keccak256(abi.encodePacked(tokenId, i))]);

                    tokenIdRewardIdxHashToHasWon[keccak256(abi.encodePacked(tokenId, i))] = true;

                    address winner = ownerOf(tokenId);
                    token.transfer(winner, amountPerUser);
                    emit RaffleWon(winner, tokenAddress, amountPerUser);
                }
            }
        }

        raffleCompleted = true;
        emit RaffleCompleted();
        _withdrawRaffleRewardsFunds();
    }

    /// @notice returns the URI for a given token ID
    /// @param tokenId The token ID to get the URI for
    /// @return string The URI for the given token ID
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return customMetadata
            ? string(abi.encodePacked(_metadataBaseURI, "/", Strings.toString(tokenId), ".json"))
            : string(abi.encodePacked(_metadataBaseURI, "/metadata.json"));
    }

    /// @dev override the transfer function to allow transfers only if not soulbound
    /// @param from The address to transfer from
    /// @param to The address to transfer to
    /// @param tokenId The token ID to transfer
    function _transfer(address from, address to, uint256 tokenId) internal override {
        if (isSoulbound) revert NotTransferrable();
        super._transfer(from, to, tokenId);
    }

    /// @dev internal function to mint a reward for a user
    /// @param user The user to mint the reward for
    function _mintBadge(address user) internal {
        _safeMint(user, ++lastId);
        _claimed[user] = true;
        emit Claimed(user, lastId);
    }

    ///@dev use ERC2771Context to get msg data
    ///@return bytes calldata
    function _msgData() internal view override(ERC2771Context, Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    ///@dev use ERC2771Context to get msg sender
    ///@return address sender
    function _msgSender() internal view override(ERC2771Context, Context) returns (address) {
        return ERC2771Context._msgSender();
    }

    /// @dev internal function to emit the first FCFS ERC20 reward available
    /// @param claimer The address to emit the rewards to
    function _emitERC20Rewards(address claimer) internal {
        for (uint8 i = 0; i < claimRewardsLength; i++) {
            IERC20 token = IERC20(claimRewards[i].token);
            uint256 amountPerUser = claimRewards[i].amountPerUser;
            bool enoughBalance = amountPerUser <= token.balanceOf(address(this));

            if (claimRewards[i].rewardsLeft != 0 && enoughBalance) {
                token.transfer(claimer, amountPerUser);
                emit FCFSAwarded(claimer, claimRewards[i].token, amountPerUser);
                claimRewards[i].rewardsLeft--;
                break;
            }
        }
    }

    /// @dev internal function to call when withdrawing funds after campaign is ended
    /// @param token the token address of which balance has to be returned to the owner
    function _returnTokenToOwner(IERC20 token) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance != 0) {
            token.transfer(owner(), balance);
        }
    }

    /// @dev internal function to call after the raffle is completed, to return
    /// the remaining funds to the owner
    function _withdrawRaffleRewardsFunds() internal {
        for (uint8 i = 0; i < raffleRewardsLength; ++i) {
            _returnTokenToOwner(IERC20(raffleRewards[i].token));
        }
        emit RaffleRewardsFundsWithdrawn();
    }
}
