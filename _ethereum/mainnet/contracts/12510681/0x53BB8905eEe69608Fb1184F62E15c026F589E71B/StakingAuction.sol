// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./IERC721.sol";
import "./Clones.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./AuctionBase.sol";
import "./IStakedAave.sol";
import "./IERC20Permit.sol";
import "./IVault.sol";
import "./DataTypes.sol";
import "./Errors.sol";
import "./VersionedInitializable.sol";

/**
 * @title StakingAuction Contract
 * @author Aito
 *
 * @dev Contract that manages staking auctions using stkAAVE.
 */
contract StakingAuction is VersionedInitializable, AuctionBase, ReentrancyGuard {
    using SafeERC20 for IERC20Permit;
    using SafeERC20 for IStakedAave;
    using SafeMath for uint256;

    uint256 public constant STAKINGAUCTION_REVISION = 0x1;
    IERC20Permit public constant AAVE = IERC20Permit(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
    IStakedAave public constant STKAAVE = IStakedAave(0x4da27a545c0c5B758a6BA100e3a049001de870f5);

    mapping(address => mapping(uint256 => DataTypes.StakingAuctionFullData)) internal _nftData;

    uint256 internal _auctionCounter;
    address internal _vaultLogic;
    uint16 internal _burnPenaltyBps;

    /**
     * @notice Emitted upon contract initialization.
     *
     * @param treasury The treasury address set.
     * @param treasuryFeeBps The treasury fee basis points set.
     * @param burnPenaltyBps The burn penalty basis points set.
     * @param overtimeWindow The overtime window set.
     * @param minimumAuctionDuration The minimum auction duration set.
     * @param distributionCap The maximum amount of distributions set.
     */
    event Initialized(
        address treasury,
        uint16 treasuryFeeBps,
        uint16 burnPenaltyBps,
        uint40 overtimeWindow,
        uint40 minimumAuctionDuration,
        uint8 distributionCap
    );

    /**
     * @notice Emitted when a new auction is scheduled on a given NFT.
     *
     * @param auctionId The auction identifier.
     * @param nft The NFT address of the token to auction.
     * @param nftId The NFT ID of the token to auction.
     * @param auctionId The auction identifier.
     * @param auctioner The address starting the auction.
     * @param startTimestamp The auction's starting timestamp.
     * @param endTimestamp The auction's ending timestamp.
     * @param startPrice The auction's starting price.
     */
    event AuctionCreated(
        address indexed nft,
        uint256 indexed nftId,
        uint256 auctionId,
        address auctioner,
        uint40 startTimestamp,
        uint40 endTimestamp,
        uint256 startPrice
    );

    /**
     * @notice Emitted when a new bid or outbid is created on a given NFT.
     *
     * @param auctionId The auction identifier.
     * @param bidder The bidder address.
     * @param spender The address spending currency.
     * @param amount The amount used to bid.
     */
    event BidSubmitted(
        uint256 indexed auctionId,
        address bidder,
        address spender,
        uint256 amount
    );

    /**
     * @notice Emitted when an auction is extended via overtime window.
     *
     * @param auctionId The auction identifier.
     * @param newEndTimestamp The new auction end timestamp.
     */
    event AuctionExtended(
        uint256 indexed auctionId,
        uint40 newEndTimestamp
    );

    /**
     * @notice Emitted when an NFT is won and claimed.
     *
     * @param auctionId The auction identifier.
     * @param nft The NFT address of the token claimed.
     * @param nftId The NFT ID of the token claimed.
     * @param winner The winner of the NFT.
     */
    event WonNftClaimed(
        address indexed nft,
        uint256 indexed nftId,
        uint256 auctionId,
        address winner
    );

    /**
     * @notice Emitted when an NFT is redeemed for the underlying stake in it's corresponding vault.
     *
     * @param auctionId The auction identifier.
     * @param nft The NFT address redeemed.
     * @param nftId The NFT ID redeemed.
     */
    event Redeemed(address indexed nft, uint256 indexed nftId, uint256 auctionId);

    /**
     * @notice Emitted when an NFT's staking rewards are claimed.
     *
     * @param nft The NFT address claimed for.
     * @param nftId The NFT ID claimed for.
     * @param auctionId The auction identifier.
     */
    event RewardsClaimed(address indexed nft, uint256 indexed nftId, uint256 auctionId);

    /**
     * @notice Emitted when an NFT is reclaimed from an expired auction with no bids.
     *
     * @param auctionId The auction identifier.
     * @param nft The NFT address reclaimed.
     * @param nftId The NFT ID reclaimed.
     */
    event Reclaimed(uint256 indexed auctionId, address indexed nft, uint256 indexed nftId);

    /**
     * @notice Emitted when the burn penalty is updated.
     *
     * @param newBurnPenaltyBps The new burn penalty in basis points.
     */
    event BurnPenaltyChanged(uint16 newBurnPenaltyBps);

    /**
     * @notice Emitted when the vault implementation is updated.
     *
     * @param newVaultLogic The new vault implementation
     */
    event VaultImplementationChanged(address newVaultLogic);

    /**
     * @dev Initializes the contract.
     *
     * @param vaultLogic The vault logic implementation address to clone.
     * @param treasury The treasury to send fees to.
     * @param treasuryFeeBps The treasury fee basis points sent upon claiming and burning.
     * @param burnPenaltyBps The amount of stkAAVE to distribute upon burning.
     * @param overtimeWindow The overtime window, triggers when a bid is sent within endTimestamp - overtimeWindow.
     * @param minimumAuctionDuration The minimum auction duration.
     * @param admin The administrator address to set, allows pausing.
     * @param distributionCap The maximum amount of distributions to allow auctions to have.
     */
    function initialize(
        address vaultLogic,
        address treasury,
        uint16 treasuryFeeBps,
        uint16 burnPenaltyBps,
        uint40 overtimeWindow,
        uint40 minimumAuctionDuration,
        address admin,
        uint8 distributionCap
    ) external initializer {
        require(
            admin != address(0) &&
                treasury != address(0) &&
                vaultLogic != address(0) &&
                treasuryFeeBps < BPS_MAX &&
                burnPenaltyBps < BPS_MAX &&
                overtimeWindow < minimumAuctionDuration &&
                overtimeWindow < 2 days &&
                distributionCap > 0 &&
                distributionCap < 6,
            Errors.INVALID_INIT_PARAMS
        );

        _vaultLogic = vaultLogic;
        _treasury = treasury;
        _treasuryFeeBps = treasuryFeeBps;
        _burnPenaltyBps = burnPenaltyBps;
        _overtimeWindow = overtimeWindow;
        _minimumAuctionDuration = minimumAuctionDuration;
        _admin = admin;
        _distributionCap = distributionCap;
        _paused = false;
        AAVE.safeApprove(address(STKAAVE), type(uint256).max);

        emit Initialized(
            treasury,
            treasuryFeeBps,
            burnPenaltyBps,
            overtimeWindow,
            minimumAuctionDuration,
            distributionCap
        );
    }

    /**
     * @notice Creates an auction on a given NFT with specified parameters. Initiator must be the owner of the NFT.
     *
     * @param nft The NFT address to auction.
     * @param nftId The NFT ID to auction.
     * @param startTimestamp The starting auction timestamp.
     * @param endTimestamp The ending auction timestamp.
     * @param startPrice The starting price for the auction.
     * @param distribution The distribution to follow upon completion
     */
    function createAuction(
        address nft,
        uint256 nftId,
        uint40 startTimestamp,
        uint40 endTimestamp,
        uint256 startPrice,
        DataTypes.DistributionData[] calldata distribution
    ) external nonReentrant onlyAdmin whenNotPaused {
        DataTypes.StakingAuctionFullData storage nftData = _nftData[nft][nftId];
        require(nftData.auctioner == address(0), Errors.AUCTION_EXISTS);
        require(
            distribution.length <= _distributionCap && distribution.length >= 1,
            Errors.INVALID_DISTRIBUTION_COUNT
        );
        require(
            startTimestamp > block.timestamp && endTimestamp > startTimestamp,
            Errors.INVALID_AUCTION_TIMESTAMPS
        );
        require(
            endTimestamp - startTimestamp >= _minimumAuctionDuration,
            Errors.INVALID_AUCTION_DURATION
        );

        uint256 neededBps = uint256(BPS_MAX).sub(_treasuryFeeBps);
        uint256 totalBps;
        for (uint256 i = 0; i < distribution.length; i++) {
            totalBps = totalBps.add(distribution[i].bps);
        }
        require(totalBps == neededBps, Errors.INVALID_DISTRIBUTION_BPS);

        DataTypes.StakingAuctionData memory auctionData =
            DataTypes.StakingAuctionData(startPrice, address(0), startTimestamp, endTimestamp);

        _nftData[nft][nftId].auction = auctionData;
        _nftData[nft][nftId].auctionId = _auctionCounter;
        _nftData[nft][nftId].auctioner = msg.sender;

        for (uint256 i = 0; i < distribution.length; i++) {
            require(distribution[i].recipient != address(0), Errors.ZERO_RECIPIENT);
            _nftData[nft][nftId].distribution.push(distribution[i]);
        }

        IERC721(nft).transferFrom(msg.sender, address(this), nftId);
        emit AuctionCreated(
            nft,
            nftId,
            _auctionCounter++,
            msg.sender,
            startTimestamp,
            endTimestamp,
            startPrice
        );
    }

    /**
     * @notice Bids using EIP-2612 permit to approve within the same function call.
     *
     * @param params The BidWithPermitParams struct containing the necessary information.
     */
    function bidWithPermit(DataTypes.BidWithPermitParams calldata params)
        external
        nonReentrant
        whenNotPaused
    {
        AAVE.permit(
            msg.sender,
            address(this),
            params.amount,
            params.deadline,
            params.v,
            params.r,
            params.s
        );
        _bid(msg.sender, params.onBehalfOf, params.nft, params.nftId, params.amount);
    }

    /**
     * @notice Claims a won NFT after an auction. Can be called by anyone.
     * This function initializes the vault and staking mechanism.
     *
     * @param nft The NFT address of the token to claim.
     * @param nftId The NFT ID of the token to claim.
     */
    function claimWonNFT(address nft, uint256 nftId) external nonReentrant whenNotPaused {
        DataTypes.StakingAuctionData storage auction = _nftData[nft][nftId].auction;

        address winner = auction.currentBidder;

        require(block.timestamp > auction.endTimestamp, Errors.AUCTION_ONGOING);
        require(winner != address(0), Errors.INVALID_BIDDER);

        address clone = Clones.clone(_vaultLogic);
        _nftData[nft][nftId].vault = clone;

        STKAAVE.stake(clone, auction.currentBid);

        delete (_nftData[nft][nftId].auction);
        IERC721(nft).safeTransferFrom(address(this), winner, nftId);

        emit WonNftClaimed(nft, nftId, _nftData[nft][nftId].auctionId, winner);
    }

    /**
     * @notice Reclaims an NFT in the unlikely event that an auction did not result in any bids.
     *
     * @param nft The NFT address of the token to reclaim.
     * @param nftId The NFT ID of the token to reclaim.
     */
    function reclaimEndedAuction(address nft, uint256 nftId) external nonReentrant whenNotPaused {
        DataTypes.StakingAuctionData storage auction = _nftData[nft][nftId].auction;
        address auctioner = _nftData[nft][nftId].auctioner;
        address currentBidder = auction.currentBidder;

        require(block.timestamp > auction.endTimestamp, Errors.AUCTION_ONGOING);
        require(currentBidder == address(0), Errors.VALID_BIDDER);

        uint256 auctionIdCached = _nftData[nft][nftId].auctionId;

        delete (_nftData[nft][nftId]);
        IERC721(nft).safeTransferFrom(address(this), auctioner, nftId);

        emit Reclaimed(auctionIdCached, nft, nftId);
    }

    /**
     * @notice Redeems an NFT to unlock the stake less penalty.
     *
     * @param nft The NFT address of the token to redeem.
     * @param nftId The NFT ID of the token to redeem.
     */
    function redeem(address nft, uint256 nftId) external nonReentrant whenNotPaused {
        IERC721 nftContract = IERC721(nft);
        DataTypes.StakingAuctionFullData storage nftData = _nftData[nft][nftId];
        address vault = nftData.vault;
        address auctioner = nftData.auctioner;
        DataTypes.DistributionData[] memory distribution = nftData.distribution;

        require(vault != address(0), Errors.NONEXISTANT_VAULT);

        uint256 rewardsBalance = STKAAVE.getTotalRewardsBalance(vault);
        uint256 stkAaveVaultBalance = STKAAVE.balanceOf(vault);
        uint256 auctionIdCached = nftData.auctionId;
        delete (_nftData[nft][nftId]);

        _claimAndRedeem(vault, stkAaveVaultBalance);

        uint256 penaltyAmount = uint256(_burnPenaltyBps).mul(stkAaveVaultBalance).div(BPS_MAX);
        STKAAVE.safeTransfer(msg.sender, stkAaveVaultBalance.sub(penaltyAmount));

        _distribute(address(AAVE), rewardsBalance, distribution);
        _distribute(address(STKAAVE), penaltyAmount, distribution);

        require(nftContract.ownerOf(nftId) == msg.sender, Errors.NOT_NFT_OWNER);
        nftContract.safeTransferFrom(msg.sender, auctioner, nftId);

        emit Redeemed(nft, nftId, auctionIdCached);
    }

    /**
     * @notice Claims rewards associated with a given NFT.
     *
     * @param nft The NFT address to claim for.
     * @param nftId The NFT Id to claim for.
     */
    function claimRewards(address nft, uint256 nftId) external nonReentrant whenNotPaused {
        DataTypes.StakingAuctionFullData storage nftData = _nftData[nft][nftId];
        DataTypes.DistributionData[] storage distribution = _nftData[nft][nftId].distribution;
        address vault = nftData.vault;
        require(vault != address(0), Errors.NONEXISTANT_VAULT);

        uint256 rewardsBalance = STKAAVE.getTotalRewardsBalance(vault);
        bytes memory rewardFunctionData = _buildClaimRewardsParams(address(this));
        address[] memory targets = new address[](1);
        bytes[] memory params = new bytes[](1);
        DataTypes.CallType[] memory callTypes = new DataTypes.CallType[](1);

        targets[0] = address(STKAAVE);
        params[0] = rewardFunctionData;
        callTypes[0] = DataTypes.CallType.Call;
        IVault(vault).execute(targets, params, callTypes);

        _distribute(address(AAVE), rewardsBalance, distribution);

        emit RewardsClaimed(nft, nftId, nftData.auctionId);
    }

    /**
     * @dev Admin function to set the burn penalty BPS.
     *
     * @param newBurnPenaltyBps The new burn penalty BPS to use.
     */
    function setBurnPenaltyBps(uint16 newBurnPenaltyBps) external onlyAdmin {
        require(newBurnPenaltyBps < BPS_MAX, Errors.INVALID_INIT_PARAMS);
        _burnPenaltyBps = newBurnPenaltyBps;

        emit BurnPenaltyChanged(newBurnPenaltyBps);
    }

    /**
     * @dev Admin function to set the vault logic address.
     *
     * @param newVaultLogic The new vault logic address.
     */
    function setNewVaultLogic(address newVaultLogic) external onlyAdmin {
        require(newVaultLogic != address(0), Errors.INVALID_INIT_PARAMS);
        _vaultLogic = newVaultLogic;

        emit VaultImplementationChanged(newVaultLogic);
    }

    /**
     * @notice Returns the current configuration of the auction's internal parameters.
     *
     * @return An StakingAuctionConfiguration struct containing the configuration.
     */
    function getConfiguration()
        external
        view
        returns (DataTypes.StakingAuctionConfiguration memory)
    {
        return
            DataTypes.StakingAuctionConfiguration(
                _vaultLogic,
                _treasury,
                _minimumAuctionDuration,
                _overtimeWindow,
                _treasuryFeeBps,
                _burnPenaltyBps
            );
    }

    /**
     * @notice Returns the auction data for a given NFT.
     *
     * @param nft The NFT address to query.
     * @param nftId The NFT ID to query.
     *
     * @return The StakingAuctionFullData containing all data related to a given NFT.
     */
    function getNftData(address nft, uint256 nftId)
        external
        view
        returns (DataTypes.StakingAuctionFullData memory)
    {
        return _nftData[nft][nftId];
    }

    function _bid(
        address spender,
        address onBehalfOf,
        address nft,
        uint256 nftId,
        uint256 amount
    ) internal override {
        require(onBehalfOf != address(0), Errors.INVALID_BIDDER);
        DataTypes.StakingAuctionData storage auction = _nftData[nft][nftId].auction;
        uint256 currentBid = auction.currentBid;
        address currentBidder = auction.currentBidder;
        uint40 endTimestamp = auction.endTimestamp;
        uint40 startTimestamp = auction.startTimestamp;

        require(
            block.timestamp > startTimestamp && block.timestamp < endTimestamp,
            Errors.INVALID_BID_TIMESTAMPS
        );
        require(amount > currentBid, Errors.INVALID_BID_AMOUNT);

        if (_overtimeWindow > 0 && block.timestamp > endTimestamp - _overtimeWindow) {
            uint40 newEndTimestamp = endTimestamp + _overtimeWindow;
            auction.endTimestamp = newEndTimestamp;

            emit AuctionExtended(_nftData[nft][nftId].auctionId, newEndTimestamp);
        }

        auction.currentBidder = onBehalfOf;
        auction.currentBid = amount;

        if (currentBidder != address(0)) {
            AAVE.safeTransfer(currentBidder, currentBid);
        }

        AAVE.safeTransferFrom(spender, address(this), amount);

        emit BidSubmitted(_nftData[nft][nftId].auctionId, onBehalfOf, spender, amount);
    }

    /**
     * @dev Internal function that handles the vault call upon NFT redemption. Does not distribute.
     *
     * @param vault The vault address to call.
     * @param stkAaveAmount The amount (equivalent to the stkAAVE balance of the vault) to transfer in.
     */
    function _claimAndRedeem(address vault, uint256 stkAaveAmount) internal {
        bytes memory rewardFunctionData = _buildClaimRewardsParams(address(this));
        bytes memory transferFunctionData = _buildTransferParams(address(this), stkAaveAmount);

        address[] memory targets = new address[](2);
        bytes[] memory params = new bytes[](2);
        DataTypes.CallType[] memory callTypes = new DataTypes.CallType[](2);

        targets[0] = address(STKAAVE);
        targets[1] = address(STKAAVE);
        params[0] = rewardFunctionData;
        params[1] = transferFunctionData;
        callTypes[0] = DataTypes.CallType.Call;
        callTypes[1] = DataTypes.CallType.Call;

        IVault(vault).execute(targets, params, callTypes);
    }

    /**
     * @dev Internal function that builds stkAAVE claim reward params.
     *
     * @param to The address to claim rewards to.
     *
     * @return Bytes containing the claimRewards data needed.
     */
    function _buildClaimRewardsParams(address to) internal pure returns (bytes memory) {
        bytes4 claimRewardsSelector = IStakedAave.claimRewards.selector;
        bytes memory rewardFunctionData =
            abi.encodeWithSelector(claimRewardsSelector, to, type(uint256).max);
        return rewardFunctionData;
    }

    /**
     * @dev Internal function that builds ERC20 transfer params.
     *
     * @param to The address to transfer to.
     * @param amount The amount to transfer.
     *
     * @return Bytes containing the transfer data needed.
     */
    function _buildTransferParams(address to, uint256 amount) internal pure returns (bytes memory) {
        bytes4 transferSelector = IERC20.transfer.selector;
        bytes memory transferFunctionData = abi.encodeWithSelector(transferSelector, to, amount);
        return transferFunctionData;
    }

    function getRevision() internal pure override returns (uint256) {
        return STAKINGAUCTION_REVISION;
    }
}
