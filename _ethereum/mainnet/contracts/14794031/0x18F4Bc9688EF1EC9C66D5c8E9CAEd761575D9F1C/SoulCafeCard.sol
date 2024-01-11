// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./OwnableUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./Initializable.sol";
import "./StringsUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./Staking.sol";
import "./ICafeStaking.sol";
import "./StakingCommons.sol";
import "./Errors.sol";
import "./ERC1155LockerUpgradeable.sol";
import "./ProxyRegistry.sol";

enum Stage {
    None,
    Init,
    Friendlies,
    Done
}

contract SoulCafeCard is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    ERC1155LockerUpgradeable
{
    using AutoStaking for uint256;
    using AutoStaking for StakeAction;
    using AutoStaking for StakeRequest;
    event ContractToggled(bool indexed newState);

    uint256 private constant MAX_GENESIS_SUPPLY = 3_333;
    uint256 private constant MAX_FRIENDLIES_SUPPLY = 14_333;
    uint256 public constant MAX_SUPPLY = 15_000;
    uint256 private constant TOKEN_ID = 0;
    bytes32 private _merkleRootGenesis;
    bytes32 private _merkleRootFriendlies;
    Stage public _stage;

    mapping(uint256 => uint256) private _genesisClaims;
    mapping(uint256 => uint256) private _friendlyClaims;
    uint256 public _stakingTrack;
    ICafeStaking public _staking;

    uint256 public totalSupply;
    bool public paused;

    /* ========== INITIALIZER ========== */

    function initialize(
        string calldata tokenURI,
        bytes32 merkleRootGenesis,
        bytes32 merkleRootFriendlies
    ) external initializer {
        __ERC1155_init(tokenURI);
        __Ownable_init();

        _merkleRootGenesis = merkleRootGenesis;
        _merkleRootFriendlies = merkleRootFriendlies;

        _stage = Stage.Init;
        paused = true;

        ERC1155LockerUpgradeable.__init();
    }

    /* ========== MUTATORS ========== */
    function claimGenesis(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        bool autostake
    ) external {
        account;
        _whenNotPaused();
        _onlyStage(Stage.Init);
        _verifyProof(
            index,
            msg.sender,
            amount,
            merkleProof,
            _merkleRootGenesis,
            _genesisClaims
        );

        _mintN(msg.sender, amount);

        if (autostake) {
            _autostake(msg.sender, amount);
        }
    }

    function claimFriendly(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        bool autostake
    ) external {
        account;
        _whenNotPaused();
        _onlyStage(Stage.Friendlies);
        _verifyProof(
            index,
            msg.sender,
            amount,
            merkleProof,
            _merkleRootFriendlies,
            _friendlyClaims
        );

        _mintN(msg.sender, amount);

        if (autostake) {
            _autostake(msg.sender, amount);
        }
    }

    function reclaim() external {
        _onlyOwner();
        _onlyStage(Stage.Done);

        uint256 amount = MAX_SUPPLY - totalSupply;

        _mintN(msg.sender, amount);
    }

    function setURI(string memory uri_) external {
        _onlyOwner();
        _setURI(uri_);
    }

    function configureStaking(address staking, uint256 trackId) external {
        _onlyOwner();
        _setLockerAdmin(staking);
        _staking = ICafeStaking(staking);
        _stakingTrack = trackId;
    }

    function toggle() external {
        _onlyOwner();
        emit ContractToggled(!paused);
        paused = !paused;
    }

    function friendlies() external {
        _onlyOwner();

        _stage = Stage.Friendlies;
    }

    function done() external {
        _onlyOwner();

        _stage = Stage.Done;
    }

    /* ========== VIEWS ========== */
    function isClaimedGenesis(uint256 index) external view returns (bool) {
        return _isClaimed(_genesisClaims, index);
    }

    function isClaimedFriendly(uint256 index) external view returns (bool) {
        return _isClaimed(_friendlyClaims, index);
    }

    /* ========== INTERNALS/MODIFIERS ========== */
    function _autostake(address account, uint256 amount) internal {
        if (_staking == ICafeStaking(address(0)))
            revert StakingTrackNotAssigned();

        StakeRequest[] memory msr = 
            StakeRequest(_stakingTrack, TOKEN_ID.arrayify(), amount.arrayify()).arrayify();

        StakeAction[][] memory actions = new StakeAction[][](1);
        actions[0] =  StakeAction.Stake.arrayify();

        _staking.execute4(account, msr, actions);
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner()) revert Unauthorized();
    }

    function _onlyStage(Stage stage) internal view {
        if (_stage != stage) revert InvalidStage();
    }

    function _verifyProof(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot,
        mapping(uint256 => uint256) storage claims
    ) internal {
        if (_isClaimed(claims, index)) revert DuplicateClaim();

        bytes32 node = keccak256(abi.encodePacked(index, account, amount));

        if (!MerkleProofUpgradeable.verify(merkleProof, merkleRoot, node))
            revert InvalidMerkleProof();

        _setClaimed(claims, index);
    }

    function _setClaimed(
        mapping(uint256 => uint256) storage claims,
        uint256 index
    ) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claims[claimedWordIndex] =
            claims[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function _isClaimed(
        mapping(uint256 => uint256) storage claims,
        uint256 index
    ) internal view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claims[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _whenNotPaused() internal view {
        if (paused) revert ContractPaused();
    }

    function _mintN(address to, uint256 qt) internal {
        _checkCap(qt);

        totalSupply += qt;

        _mint(to, TOKEN_ID, qt, "");
    }

    function _checkCap(uint256 qt) internal view {
        if (_stage == Stage.Init) {
            if (totalSupply + qt > MAX_GENESIS_SUPPLY) 
                revert MintingExceedsSupply(MAX_GENESIS_SUPPLY);
        } else if (_stage == Stage.Friendlies) {
            if (totalSupply + qt > MAX_FRIENDLIES_SUPPLY)
                revert MintingExceedsSupply(MAX_FRIENDLIES_SUPPLY);
        } else if (_stage == Stage.Done) {
            if (totalSupply + qt > MAX_SUPPLY)
                revert MintingExceedsSupply(MAX_SUPPLY);
        }
    }

    function isApprovedForAll(address owner_, address operator)
        public
        view
        override(ERC1155Upgradeable, IERC1155Upgradeable)
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(OS_PROXY_REGISTRY_ADDRESS);
        if (address(proxyRegistry.proxies(owner_)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner_, operator);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        operator;
        to;
        data;

        if (from == address(0)) return;

        for (uint256 t = 0; t < ids.length; t++) {
            if (balanceOf(from, ids[t]) - locked(from, ids[t]) < amounts[t])
                revert StakingLockViolation(t);
        }
    }    
}
