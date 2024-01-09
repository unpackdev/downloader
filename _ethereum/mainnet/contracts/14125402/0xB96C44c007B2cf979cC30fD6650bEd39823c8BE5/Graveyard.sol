// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";

/// @title Graveyard NFT Project's URN Token Interface
/// @author @0xyamyam
interface IUrn {
    function mint(address to, uint256 amount) external;
}

/// @title Graveyard NFT Project's Rewardable Token Interface
/// @author @0xyamyam
interface IRewardable {
    function getCommittalReward(address to) external view returns (uint256);
    function getRewardRate(address to) external view returns (uint256);
}

/// @title Graveyard NFT Project's CRYPT Token
/// @author @0xyamyam
/// CRYPT's are the centerpiece of the Graveyard NFT project.
contract Graveyard is IERC721Receiver, ReentrancyGuard, Ownable(5, true, false) {
    using SafeMath for uint256;

    /// 0 = inactive, 1 = accepting tokens for whitelist, 2 = whitelist mint, 3 = public
    uint256 public _releaseStage;
    uint256 public _startRewarding;

    /// URN address
    address public _urnAddress;

    /// Contracts able to generate rewards
    address[] public _rewardingContracts;

    /// URN rewards per address
    mapping(address => uint256) private _claimable;
    mapping(address => uint256) private _claimUpdated;

    /// Whitelisted addresses
    mapping(address => uint256) public _whitelist;

    /// Event for use in the crypt
    event Committed(address indexed from, address indexed contractAddress, uint256 indexed tokenId, bytes data);

    /// Event for release stage changing
    event ReleaseStage(uint256);

    /// Rewarding contracts are allowed to update rewards for addresses
    modifier onlyRewarding {
        bool authorised = false;
        address sender = _msgSender();
        for (uint256 i = 0;i < _rewardingContracts.length;i++) {
            if (_rewardingContracts[i] == sender) {
                authorised = true;
                break;
            }
        }
        require(authorised, "Unauthorized");
        _;
    }

    /// Determine the release stage
    function releaseStage() external view returns (uint256) {
        return _releaseStage;
    }

    /// Determine if the address is whitelisted
    /// @param from The address to check
    /// @param qty The qty to check for
    function isWhitelisted(address from, uint256 qty) external view returns (bool) {
        return _whitelist[from] >= qty;
    }

    /// The pending URN claim for address
    /// @param from The address to check for rewards
    /// @notice Rewards only claimable after reward claiming starts
    function claimable(address from) public view returns (uint256) {
        return _claimable[from] + _getPendingClaim(from);
    }

    /// Claim rewards from the graveyard
    function claim() external nonReentrant {
        require(_startRewarding != 0 && _urnAddress != address(0), "Rewards unavailable");
        address sender = _msgSender();
        uint256 amount = claimable(sender);
        require(amount > 0, "Nothing to claim");
        _claimable[sender] = 0;
        _claimUpdated[sender] = block.timestamp;
        IUrn(_urnAddress).mint(sender, amount);
    }

    /// Provide a batch transfer option for users with many tokens to commit.
    /// @param contracts Array of ERC721 contracts to batch transfer
    /// @param tokenIds Array of arrays of tokenIds matched to the contracts array
    /// @param data Array of arrays of bytes messages for each committed token matched to the contracts array
    /// @notice Sender MUST setApprovalForAll for this contract address on the contracts being supplied,
    /// this means to be efficient you will need to transfer 3 or more tokens from the contract to be worth it.
    function commitTokens(
        address[] calldata contracts, uint256[][] calldata tokenIds, bytes[][] calldata data
    ) external nonReentrant {
        require(contracts.length == tokenIds.length && tokenIds.length == data.length, "Invalid args");
        address sender = _msgSender();
        for (uint256 i = 0;i < contracts.length;i++) {
            IERC721 token = IERC721(contracts[i]);
            for (uint256 j = 0;j < tokenIds[i].length;j++) {
                token.safeTransferFrom(sender, address(this), tokenIds[i][j], data[i][j]);
            }
        }
    }

    /// Sets contract properties which control stages of the release.
    /// @param stage The stage of release
    /// @param contracts The rewarding contracts
    function setState(uint256 stage, address[] calldata contracts) external onlyOwner {
        _releaseStage = stage;
        _rewardingContracts = contracts;
        emit ReleaseStage(stage);
    }

    /// Set URN contract and and implicitly start rewards
    /// @param urnAddress URN contract
    function startRewards(address urnAddress) external onlyOwner {
        _urnAddress = urnAddress;
        _startRewarding = block.timestamp;
    }

    /// Update the whitelist amount for an address to prevent multiple mints in future
    /// @param from The whitelist address
    /// @param qty How many to remove from total
    function updateWhitelist(address from, uint256 qty) external onlyRewarding nonReentrant {
        _whitelist[from] -= qty;
    }

    /// Update the rewards for an address, this includes any pending rewards and updates the timestamp
    /// @param from The address for rewards
    /// @param qty The total to add to rewards
    function updateClaimable(address from, uint256 qty) external onlyRewarding nonReentrant {
       if (_startRewarding == 0)  {
           _claimable[from] += qty;
       } else {
           _claimable[from] += qty + _getPendingClaim(from);
           _claimUpdated[from] = block.timestamp;
       }
    }

    /// Instead of storing data on-chain for who sent what NFT's we emit events which can be queried later on.
    /// This is more efficient as event storage is significantly cheaper.
    /// If the sender owns a URN rewarding token (CRYPT) rewards are calculated.
    /// @inheritdoc IERC721Receiver
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        uint256 stage = _releaseStage;
        require(stage == 1 || stage > 2, "Cannot accept");

        emit Committed(from, _msgSender(), tokenId, data);

        if (stage == 1) {
            _whitelist[from] = 3;
        } else {
            uint256 amount = 0;
            for (uint256 i = 0;i < _rewardingContracts.length;i++) {
                amount += IRewardable(_rewardingContracts[i]).getCommittalReward(from);
            }
            _claimable[from] += amount;
        }

        return this.onERC721Received.selector;
    }

    /// Calculates the pending reward from rewarding contracts.
    /// URN rewards are calculated daily off the rate defined by rewarding contracts.
    /// @param from The address to calculate rewards for
    function _getPendingClaim(address from) internal view returns (uint256) {
        if (_startRewarding == 0) return 0;

        uint256 rate = 0;
        for (uint256 i = 0;i < _rewardingContracts.length;i++) {
            rate += IRewardable(_rewardingContracts[i]).getRewardRate(from);
        }

        uint256 startFrom = _claimUpdated[from] == 0 ? _startRewarding : _claimUpdated[from];

        return rate * (block.timestamp - startFrom) / 1 days;
    }
}
