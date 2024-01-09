// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";

struct MerkleDrop {
    bytes32 root;
    uint256 amount;
    bool on;
    mapping(uint256 => uint256) claims;
}

interface IJPEG {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract IlliquidDAODropper is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    event JPEGDropInit(uint256 indexed index);
    event JPEGDropDone(uint256 indexed index);
    event ClaimExecuted(uint256 indexed dropIndex, address indexed account, uint256 indexed amount);
    address private constant BURN_ADDR = 0x000000000000000000000000000000000000dEaD;

    // -- APPEND-ONLY STORAGE --
    mapping(uint256 => MerkleDrop) public drops;
    uint256 public dropCounter;
    IJPEG public jpeg;

    function initialize(address jpeg_) external initializer {
        require(jpeg_ != address(0), "ZeroTokenAddress");
        jpeg = IJPEG(jpeg_);
        __Ownable_init();
        __Pausable_init();
    }

    function toggle() external {
        _onlyOwner();
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function createDrop(bytes32 root, address treasury, uint256 amount) external {
        _onlyOwner();
        require(amount > 0, "ZeroDropAmount");
        require(treasury != address(0), "ZeroTreasuryAddress");
        drops[dropCounter].root = root;
        drops[dropCounter].amount = amount * 1 ether;
        drops[dropCounter].on = true;
        dropCounter++;
        emit JPEGDropInit(dropCounter - 1);
        require(jpeg.transferFrom(treasury, address(this), amount * 1 ether), "TokenTransferFailed");
    }

    function completeDrop(uint256 index) external {
        _onlyOwner();
        require(index < dropCounter, "DropNotFound");
        MerkleDrop storage drop = drops[index];
        require(drop.on, "DropAlreadyDone");
        drop.on = false;
        emit JPEGDropDone(index);
        if (drop.amount > 0) {
            require(jpeg.transfer(BURN_ADDR, drop.amount), "TokenBurnFailed");
            drop.amount = 0;
        }
    }

    function claim(uint256 dropIndex, uint256 index, uint256 amount, bytes32[] calldata proof) external whenNotPaused {
        MerkleDrop storage drop = drops[dropIndex];
        uint256 _amount = amount * 1 ether;
        require(drop.on, "DropNotFoundOrDone");
        require(drop.amount >= _amount, "OutOfTokens");
        require(!_isClaimed(drop, index), "TokensAlreadyClaimed");
        _verifyProof(index, msg.sender, amount, proof, drop);
        _setClaimed(drop, index);
        drop.amount -= _amount;
        emit ClaimExecuted(dropIndex, msg.sender, _amount);
        require(jpeg.transfer(msg.sender, _amount), "TokenTransferFailed");
    }

    function isClaimed(uint256 dropIndex, uint256 index) external view returns (bool) {
        require(dropIndex < dropCounter, "DropNotFound");
        return _isClaimed(drops[dropIndex], index);
    }


    // - internals
    function _onlyOwner() internal view {
        require(msg.sender == owner(), "UnauthorizedAccess");
    }

    function _verifyProof(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        MerkleDrop storage drop
    ) internal view {
        bytes32 node = keccak256(
            abi.encodePacked(index, account, amount)
        );
        require(
            MerkleProofUpgradeable.verify(merkleProof, drop.root, node),
            "InvalidMerkleProof"
        );
    }

    function _setClaimed(MerkleDrop storage drop, uint256 index) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        drop.claims[claimedWordIndex] =
            drop.claims[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function _isClaimed(MerkleDrop storage drop, uint256 index) internal view returns (bool)
    {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = drop.claims[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }   
}