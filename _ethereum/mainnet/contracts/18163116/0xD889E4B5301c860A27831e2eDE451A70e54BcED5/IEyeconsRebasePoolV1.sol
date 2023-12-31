// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "./IERC20MetadataUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./IERC721Upgradeable.sol";

interface IEyeconsRebasePoolV1 {
    enum TokenType { ERC20, ERC721, ERC1155 }

    error AttemptToLaunchAgain();
    error ForbiddenToUnpause();
    error InvalidArrayLength();
    error InvalidTokenIdToWithdraw(uint256 id);
    error AttemptToClaimAgain();
    error InvalidProof();

    event BasePowerFactorUpdated(
        uint256 indexed year, 
        uint256 indexed oldBasePowerFactor, 
        uint256 indexed newBasePowerFactor
    );
    event BasePowerIncreaseFactorUpdated(
        uint256 indexed year, 
        uint256 indexed oldBasePowerIncreaseFactor, 
        uint256 indexed newBasePowerIncreaseFactor
    );
    event UpgradingPriceUpdated(uint256 indexed oldUpgradingPrice, uint256 indexed newUpgradingPrice);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event MerkleRootSet(bytes32 indexed merkleRoot, address indexed token, uint256 indexed merkleRootId);
    event ERC20RewardProvided(address indexed token, uint256 indexed amount);
    event ERC721RewardProvided(address indexed token, uint256[] indexed tokenIds);
    event ERC1155RewardProvided(address indexed token, uint256[] indexed tokenIds, uint256[] indexed amounts);
    event Deposited(address indexed account, uint256[] indexed ids);
    event Withdrawn(address indexed account, uint256[] indexed ids);
    event Claimed(address account, address indexed token, uint256[] indexed ids, uint256[] indexed amounts);

    /// @notice Initializes the contract.
    /// @param upgradingPrice_ Upgrading price.
    /// @param tether_ Tether USD contract address.
    /// @param treasury_ Treasury address.
    /// @param eye_ eYe token contract address. 
    /// @param eyecons_ EYECONS collection contract address.
    /// @param authority_ Authorised address.
    function initialize(
        uint256 upgradingPrice_, 
        IERC20MetadataUpgradeable tether_,
        address payable treasury_,
        address eye_, 
        address eyecons_,
        address authority_
    ) 
        external;
    
    /// @notice Launches the contract.
    function launch() external;

    /// @notice Updates the base power factor.
    /// @param year_ Year for which the update applies.
    /// @param basePowerFactor_ New base power factor value.
    function updateBasePowerFactor(uint256 year_, uint256 basePowerFactor_) external;

    /// @notice Updates the base power increase factor.
    /// @param year_ Year for which the update applies.
    /// @param basePowerIncreaseFactor_ New base power increase factor value.
    function updateBasePowerIncreaseFactor(uint256 year_, uint256 basePowerIncreaseFactor_) external;

    /// @notice Updates the upgrading price.
    /// @param upgradingPrice_ New upgrading price.
    function updateUpgradingPrice(uint256 upgradingPrice_) external;

    /// @notice Updates the treasury.
    /// @param treasury_ New treasury address.
    function updateTreasury(address payable treasury_) external;

    /// @notice Sets the root of the Merkle tree.
    /// @dev The contract should be paused for safe settlements.
    /// @param token_ Token contract address.
    /// @param merkleRoot_ Merkle tree root.
    function setMerkleRoot(address token_, bytes32 merkleRoot_) external;

    /// @notice Pauses the contract.
    function pause() external;

    /// @notice Unauses the contract.
    function unpause() external;

    /// @notice Provides reward in ERC20 tokens.
    /// @param token_ Token contract address.
    /// @param amount_ Reward amount to transfer.
    function provideERC20Reward(IERC20MetadataUpgradeable token_, uint256 amount_) external;

    /// @notice Provides reward in ERC721 tokens.
    /// @param token_ Token contract address.
    /// @param tokenIds_ Token ids to transfer.
    function provideERC721Reward(IERC721Upgradeable token_, uint256[] calldata tokenIds_) external;

    /// @notice Provides reward in ERC1155 tokens.
    /// @param token_ Token contract address.
    /// @param tokenIds_ Token ids to transfer.
    /// @param amounts_ Amounts of tokens to transfer.
    function provideERC1155Reward(
        IERC1155Upgradeable token_, 
        uint256[] calldata tokenIds_, 
        uint256[] calldata amounts_
    ) 
        external;

    /// @notice Deposits tokens.
    /// @param tokenIds_ Token ids to deposit.
    function deposit(uint256[] calldata tokenIds_) external;

    /// @notice Withdraws tokens.
    /// @param tokenIds_ Token ids to withdraw.
    function withdraw(uint256[] calldata tokenIds_) external;

    /// @notice Transfers rewards.
    /// @dev The contract should be unpaused.
    /// @param tokenType_ Token type enum (ERC20, ERC721 or ERC1155).
    /// @param token_ Token contract address.
    /// @param merkleRootId_ Merkle root id.
    /// @param tokenIds_ Token ids that belong to callee.
    /// @param amounts_ Amount of tokens that belongs to callee.
    /// @param merkleProof_ Merkle proof.
    function claim(
        TokenType tokenType_,
        address token_, 
        uint256 merkleRootId_,
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_,
        bytes32[] calldata merkleProof_
    ) 
        external;
    
    /// @notice Checks whether the token id is eligible for reward in this cycle.
    /// @param tokenId_ Token id.
    /// @return Boolean value indicating whether token id is eligible for reward in this cycle.
    function isEligibleForRewardInThisCycle(uint256 tokenId_) external view returns (bool);

    /// @notice Calculates the cumulative power by token id.
    /// @param tokenId_ Token id.
    /// @return Cumulative power by token id.
    function cumulativePowerByTokenId(uint256 tokenId_) external view returns (uint256);

    /// @notice Retrieves the number of deposited tokens by account.
    /// @param account_ Account address.
    /// @return Number of deposited tokens by account.
    function numberOfDepositedTokensByAccount(address account_) external view returns (uint256);

    /// @notice Retrieves the token id deposited by account.
    /// @param account_ Account address.
    /// @param index_ Index value.
    /// @return Deposited token id by account.
    function getDepositedTokenIdByAccountAt(address account_, uint256 index_) external view returns (uint256);

    /// @notice Retrieves the number of depositors.
    /// @return Number of depositors.
    function numberOfDepositors() external view returns (uint256);

    /// @notice Retrieves the depositor address by index.
    /// @param index_ Index value.
    /// @return Depositor address by index.
    function getDepositorAt(uint256 index_) external view returns (address);

    /// @notice Retrieves the current _merkleRootId value.
    /// @return Current _merkleRootId value.
    function currentMerkleRootId() external view returns (uint256);

    /// @notice Retrieves the current _cycleId value.
    /// @return Current _cycleId value.
    function currentCycleId() external view returns (uint256);

    /// @notice Calculates the accumulated power since the last deposit,
    /// current power, current level and deposit duration by token id.
    /// @param tokenId_ Token id.
    /// @return accumulatedPower_ Accumulated power since the last deposit.
    /// @return currentPower_ Current power.
    /// @return currentLevel_ Current level.
    /// @return depositor_ Depositor address.
    function tokenInfo(
        uint256 tokenId_
    ) 
        external 
        view 
        returns (
            uint256 accumulatedPower_, 
            uint256 currentPower_, 
            uint256 currentLevel_,
            address depositor_
        );
}