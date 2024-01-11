// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IUnifarmNFTManagerUpgradeable.sol";
import "./IUnifarmCohort.sol";
import "./TransferHelpers.sol";
import "./IUnifarmNFTDescriptorUpgradeable.sol";
import "./CohortHelper.sol";
import "./ReentrancyGuardUpgradeable.sol";

/// @title UnifarmNFTManagerUpgradeable Contract
/// @author UNIFARM
/// @notice NFT manager handles Unifarm cohort Stake/Unstake/Claim

contract UnifarmNFTManagerUpgradeable is
    IUnifarmNFTManagerUpgradeable,
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// @notice reciveing ETH
    receive() external payable {}

    /// @notice struct to hold cohort fees configuration
    struct FeeConfiguration {
        // protocol fee wallet address
        address payable feeWalletAddress;
        // protocol fee amount
        uint256 feeAmount;
    }

    /// @notice global fees pointer for all cohorts
    FeeConfiguration public fees;

    /// @notice factory contract address
    address public factory;

    /// @dev next token Id that will be minted
    uint256 private _id;

    /// @notice nft descriptor contract address
    address public nftDescriptor;

    /// @notice store tokenId to cohortAddress
    mapping(uint256 => address) public tokenIdToCohortId;

    /**
    @notice initialize the NFT manager contract
    @param feeWalletAddress fee wallet address
    @param nftDescriptor_ nft descriptor contract address
    @param feeAmount protocol fee amount 
    */

    function __UnifarmNFTManagerUpgradeable_init(
        address payable feeWalletAddress,
        address nftDescriptor_,
        address factory_,
        address masterAddress,
        address trustedForwarder,
        uint256 feeAmount
    ) external initializer {
        __ERC721_init('Unifarm Staking Collection', 'UNIFARM-STAKES');
        __UnifarmNFTManagerUpgradeable_init_unchained(feeWalletAddress, nftDescriptor_, factory_, feeAmount);
        __Ownable_init(masterAddress, trustedForwarder);
    }

    function __UnifarmNFTManagerUpgradeable_init_unchained(
        address payable feeWalletAddress,
        address nftDescriptor_,
        address factory_,
        uint256 feeAmount
    ) internal {
        nftDescriptor = nftDescriptor_;
        factory = factory_;
        setFeeConfiguration(feeWalletAddress, feeAmount);
    }

    /**
     * @notice function to set fee configuration for protocol
     * @param  feeWalletAddress_ fee wallet address
     * @param feeAmount_ protocol fee amount
     */

    function setFeeConfiguration(address payable feeWalletAddress_, uint256 feeAmount_) internal {
        require(feeWalletAddress_ != address(0), 'IFWA');
        require(feeAmount_ > 0, 'IFA');
        fees = FeeConfiguration({feeWalletAddress: feeWalletAddress_, feeAmount: feeAmount_});
        emit FeeConfigurtionAdded(feeWalletAddress_, feeAmount_);
    }

    /**
     * @inheritdoc IUnifarmNFTManagerUpgradeable
     */

    function updateFeeConfiguration(address payable feeWalletAddress_, uint256 feeAmount_) external override onlyOwner {
        setFeeConfiguration(feeWalletAddress_, feeAmount_);
    }

    /**
     * @notice tokenURI contains token metadata
     * @param tokenId NFT tokenId
     * @return base64 encoded token URI
     */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        address cohortId = tokenIdToCohortId[tokenId];
        require(cohortId != address(0), 'ICI');
        return IUnifarmNFTDescriptorUpgradeable(nftDescriptor).generateTokenURI(cohortId, tokenId);
    }

    /**
     * @notice function handles stake on unifarm
     * @param cohortId cohort address
     * @param rAddress referral address
     * @param farmToken farmToken address
     * @param sAmount stake amount
     * @param fid farm id
     * @return tokenId minted NFT tokenId
     */

    function _stakeOnUnifarm(
        address cohortId,
        address rAddress,
        address farmToken,
        uint256 sAmount,
        uint32 fid
    ) internal returns (uint256 tokenId) {
        require(cohortId != address(0), 'ICI');
        _id++;
        _mint(_msgSender(), (tokenId = _id));
        tokenIdToCohortId[tokenId] = cohortId;
        TransferHelpers.safeTransferFrom(farmToken, _msgSender(), cohortId, sAmount);
        IUnifarmCohort(cohortId).stake(fid, tokenId, _msgSender(), rAddress);
    }

    /**
     * @inheritdoc IUnifarmNFTManagerUpgradeable
     */

    function stakeOnUnifarm(
        address cohortId,
        address referralAddress,
        address farmToken,
        uint256 sAmount,
        uint32 farmId
    ) external override nonReentrant returns (uint256 tokenId) {
        (tokenId) = _stakeOnUnifarm(cohortId, referralAddress, farmToken, sAmount, farmId);
    }

    /**
     * @inheritdoc IUnifarmNFTManagerUpgradeable
     */

    function unstakeOnUnifarm(uint256 tokenId) external payable override nonReentrant {
        require(_msgSender() == ownerOf(tokenId), 'INO');
        require(msg.value >= fees.feeAmount, 'FAR');
        _burn(tokenId);
        address cohortId = tokenIdToCohortId[tokenId];
        IUnifarmCohort(cohortId).unStake(_msgSender(), tokenId, 0);
        TransferHelpers.safeTransferParentChainToken(fees.feeWalletAddress, fees.feeAmount);
        refundExcessEth((msg.value - fees.feeAmount));
    }

    /**
     * @inheritdoc IUnifarmNFTManagerUpgradeable
     */

    function claimOnUnifarm(uint256 tokenId) external payable override nonReentrant {
        require(_msgSender() == ownerOf(tokenId), 'INO');
        require(msg.value >= fees.feeAmount, 'FAR');
        address cohortId = tokenIdToCohortId[tokenId];
        IUnifarmCohort(cohortId).collectPrematureRewards(_msgSender(), tokenId);
        TransferHelpers.safeTransferParentChainToken(fees.feeWalletAddress, fees.feeAmount);
        refundExcessEth((msg.value - fees.feeAmount));
    }

    /**
     * @inheritdoc IUnifarmNFTManagerUpgradeable
     */

    function emergencyBurn(address user, uint256 tokenId) external onlyOwner {
        require(user == ownerOf(tokenId), 'INO');
        _burn(tokenId);
        address cohortId = tokenIdToCohortId[tokenId];
        IUnifarmCohort(cohortId).unStake(user, tokenId, 1);
    }

    /**
     * @notice refund excess fund
     * @param excess excess ETH value
     */

    function refundExcessEth(uint256 excess) internal {
        if (excess > 0) {
            TransferHelpers.safeTransferParentChainToken(_msgSender(), excess);
        }
    }

    /**
     * @notice buy booster pack for specific NFT tokenId
     * @param cohortId cohort Address
     * @param bpid booster pack Id
     * @param tokenId NFT tokenId for which booster pack to take
     */

    function _buyBooster(
        address cohortId,
        uint256 bpid,
        uint256 tokenId
    ) internal {
        (address registry, , ) = CohortHelper.getStorageContracts(factory);
        (, address paymentToken_, address boosterVault, uint256 boosterPackAmount) = CohortHelper.getBoosterPackDetails(registry, cohortId, bpid);
        require(_msgSender() == ownerOf(tokenId), 'INO');
        require(paymentToken_ != address(0), 'BNF');
        if (msg.value > 0) {
            require(msg.value >= boosterPackAmount, 'BAF');
            CohortHelper.depositWETH(paymentToken_, boosterPackAmount);
            TransferHelpers.safeTransfer(paymentToken_, boosterVault, boosterPackAmount);
            refundExcessEth((msg.value - boosterPackAmount));
        } else {
            TransferHelpers.safeTransferFrom(paymentToken_, _msgSender(), boosterVault, boosterPackAmount);
        }
        IUnifarmCohort(cohortId).buyBooster(_msgSender(), bpid, tokenId);
    }

    /**
     * @inheritdoc IUnifarmNFTManagerUpgradeable
     */

    function buyBoosterPackOnUnifarm(
        address cohortId,
        uint256 bpid,
        uint256 tokenId
    ) external payable override {
        require(cohortId != address(0), 'ICI');
        _buyBooster(cohortId, bpid, tokenId);
    }

    /**
     * @inheritdoc IUnifarmNFTManagerUpgradeable
     */

    function stakeAndBuyBoosterPackOnUnifarm(
        address cohortId,
        address referralAddress,
        address farmToken,
        uint256 bpid,
        uint256 sAmount,
        uint32 farmId
    ) external payable override returns (uint256 tokenId) {
        tokenId = _stakeOnUnifarm(cohortId, referralAddress, farmToken, sAmount, farmId);
        _buyBooster(cohortId, bpid, tokenId);
    }

    uint256[49] private __gap;
}
