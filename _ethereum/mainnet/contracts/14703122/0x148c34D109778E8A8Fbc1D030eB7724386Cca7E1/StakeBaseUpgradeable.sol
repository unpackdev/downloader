// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./UUPSUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC721Like.sol";
import "./Oil.sol";

/**
@title Habibiz Base Upgradeable Staking Contract
@author @KfishNFT
@notice Provides common initialization for upgradeable staking contracts in the Habibiz ecosystem
*/
abstract contract StakeBaseUpgradeable is Initializable, UUPSUpgradeable, AccessControlUpgradeable {
    using ECDSAUpgradeable for bytes32;
    /**
    @notice Used for management functions
    */
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    /**
    @notice Upgraders can use the UUPSUpgradeable upgrade functions
    */
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    /**
    @notice Role for addresses that are valid signers
    */
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    /**
    @notice Mapping of address to staked tokens
    */
    mapping(address => uint256[]) internal tokensOfOwner;
    /**
    @notice Timestamp of a tokenId that was staked
    */
    mapping(uint256 => uint256) internal tokenStakedTime;
    /**
    @notice Timestamp of the last unstake of an address's token
    */
    mapping(address => uint256) internal ownerLastUnstakedTime;
    /**
    @notice Mapping of tokenId to owner
    */
    mapping(uint256 => address) internal tokenOwner;
    /**
    @notice Keeping track of stakers in order to modify unique count
    */
    mapping(address => bool) internal stakers;
    /**
    @notice Unique owner count visibility
    */
    uint256 public uniqueOwnerCount;
    /**
    @notice ERC721 interface with the ability to add future functions
    */
    IERC721Like public tokenContract;
    /**
    @notice The address of $OIL
    */
    Oil public oilContract;
    /**
    @notice Address of the contract that will be used to stake tokens
    */
    address public stakingContract;
    /**
    @notice Keep track of nonces to avoid hijacking signatures
    */
    mapping(uint256 => bool) internal nonces;
    /**
    @notice Emitted when a token is Staked
    @param sender The msg.sender
    @param tokenId The token id
    */
    event TokenStaked(address indexed sender, uint256 tokenId);
    /**
    @notice Emitted when a token is Unstaked
    @param sender The msg.sender
    @param tokenId The token id
    */
    event TokenUnstaked(address indexed sender, uint256 tokenId);

    /**
    @dev Initializer
    @param stakingContract_ the contract where tokens will be transferred to
    @param tokenContract_ the ERC721 compliant contract
    @param oilContract_ the address of $OIL
    */
    function __StakeBaseUpgradeable_init(
        address stakingContract_,
        address tokenContract_,
        address oilContract_
    ) internal onlyInitializing {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        stakingContract = stakingContract_;
        oilContract = Oil(oilContract_);
        tokenContract = IERC721Like(tokenContract_);
    }

    /**
    @dev Initializer
    @param stakingContract_ the contract where tokens will be transferred to
    @param tokenContract_ the ERC721 compliant contract
    @param oilContract_ the address of $OIL
    */
    function __StakeBaseUpgradeable_unchained_init(
        address stakingContract_,
        address tokenContract_,
        address oilContract_
    ) internal onlyInitializing {
        __StakeBaseUpgradeable_init(stakingContract_, tokenContract_, oilContract_);
    }

    /**
    @notice Function to stake all tokens of an address
    */
    function stakeAll() external virtual {
        uint256[] memory tokenIds = tokenContract.tokensOfOwner(msg.sender);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(tokenIds[i]);
        }
        _updateUniqueOwnerCount(true);
    }

    /**
    @notice Function to unstake tokens of an address by their ids
    @param tokenIds_ the list of token ids to be staked
    */
    function unstake(uint256[] calldata tokenIds_) external virtual {
        require(tokensOfOwner[msg.sender].length > 0, "Stake: nothing to unstake");
        uint256 i = 0;
        for (i = 0; i < tokenIds_.length; i++) {
            require(tokenOwner[tokenIds_[i]] == msg.sender, "Stake: token not owned by sender");
            _unstake(tokenIds_[i]);
            delete tokenOwner[tokenIds_[i]];
        }
        for (i = tokensOfOwner[msg.sender].length - 1; i >= 0; i--) {
            for (uint256 j = 0; j < tokenIds_.length; j++) {
                if (tokensOfOwner[msg.sender][i] == tokenIds_[j]) {
                    tokensOfOwner[msg.sender][i] = tokensOfOwner[msg.sender][tokensOfOwner[msg.sender].length - 1];
                    tokensOfOwner[msg.sender].pop();
                    break;
                }
            }
        }
        ownerLastUnstakedTime[msg.sender] = block.timestamp;
        _updateUniqueOwnerCount(false);
    }

    /**
    @notice Function to unstake all tokens of an address
    */
    function unstakeAll() external virtual {
        uint256[] memory tokens = tokensOfOwner[msg.sender];
        require(tokens.length > 0, "Stake: nothing to unstake");
        for (uint256 i = 0; i < tokens.length; i++) {
            _unstake(tokens[i]);
        }
        delete tokensOfOwner[msg.sender];
        ownerLastUnstakedTime[msg.sender] = block.timestamp;
        _updateUniqueOwnerCount(false);
    }

    /**
    @notice Function to unstake tokens of an address by their ids
    @param tokenIds_ the list of token ids to be staked
    */
    function stake(uint256[] calldata tokenIds_) external virtual {
        require(
            tokenContract.isApprovedForAll(msg.sender, stakingContract),
            "Stake: contract is not approved operator"
        );
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(tokenContract.ownerOf(tokenIds_[i]) == msg.sender, "Stake: token not owned by sender");
            _stake(tokenIds_[i]);
        }
        _updateUniqueOwnerCount(true);
    }

    /**
    @notice Staking function that performs transfer of a token and sets the staked timestamp
    @param tokenId_ The token id that will be staked
    */
    function _stake(uint256 tokenId_) private {
        tokenContract.safeTransferFrom(msg.sender, stakingContract, tokenId_);
        tokensOfOwner[msg.sender].push(tokenId_);
        tokenOwner[tokenId_] = msg.sender;
        tokenStakedTime[tokenId_] = block.timestamp;

        emit TokenStaked(msg.sender, tokenId_);
    }

    /**
    @notice Unstaking function that performs transfer of a staked token
    @param tokenId_ The token id that will be staked
    */
    function _unstake(uint256 tokenId_) private {
        tokenContract.safeTransferFrom(address(stakingContract), msg.sender, tokenId_);

        emit TokenUnstaked(msg.sender, tokenId_);
    }

    /**
    @notice Updating the unique owner count after staking or unstaking
    @param isStaking_ Whether the action is stake or unstake
    */
    function _updateUniqueOwnerCount(bool isStaking_) private {
        if (isStaking_ && !stakers[msg.sender]) {
            stakers[msg.sender] = true;
            uniqueOwnerCount++;
        } else {
            if (tokensOfOwner[msg.sender].length == 0) {
                stakers[msg.sender] = false;
                uniqueOwnerCount--;
            }
        }
    }

    /**
    @notice Function required by UUPSUpgradeable in order to authorize upgrades
    @dev Only "UPGRADER_ROLE" addresses can perform upgrades
    @param newImplementation The address of the new implementation contract for the upgrade
    */
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /**
    @dev Reserved storage to allow layout changes
    */
    uint256[50] private __gap;
}
