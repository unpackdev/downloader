// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./SafeERC20.sol";

contract ProtoClaim is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    error AlreadyActive();
    error AlreadyEnded();
    error NotStarted();
    error NotOpener();
    error TooEarlyToClose();
    error InvalidClaim();
    error InvalidEndAfterTime();

    bytes32 public merkleRoot;

    uint256 public canEndAfterTime;

    uint256 public openedAtTimestamp;

    mapping(address => bool) public alreadyClaimedByAddress;
    
    bool public ended;

    address public opener;

    address public distilleryAddress;

    IERC20 public rewardContract;

    constructor(bytes32 _merkleRoot, IERC20 _reward, address _distillery, uint256 _canEndAfterTime) {
        merkleRoot = _merkleRoot;
        opener = msg.sender;
        rewardContract = _reward;
        distilleryAddress = _distillery;

        if(_canEndAfterTime == 0) revert InvalidEndAfterTime();
        canEndAfterTime = _canEndAfterTime;
    }

    modifier onlyOpener() {
        if (msg.sender != opener) revert NotOpener();
        _;
    }
    modifier isStarted() {
        if (openedAtTimestamp == 0) revert NotStarted();
        _;
    }

    modifier notEnded() {
        if (ended) revert AlreadyEnded();
        _;
    }

    function openWindow() external onlyOpener() {
        if (openedAtTimestamp != 0) revert AlreadyActive(); 
        openedAtTimestamp = block.timestamp;
    }

    function closeWindow() external notEnded onlyOpener isStarted {
        if (block.timestamp < (openedAtTimestamp + canEndAfterTime)) revert TooEarlyToClose();

        ended = true;
        
        uint256 unclaimed = rewardContract.balanceOf(address(this));

        if (unclaimed != 0) {
            SafeERC20.safeTransfer(rewardContract, distilleryAddress, unclaimed);
        }
           
        opener = address(0);
    }

    function _claim(
        address _address,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) private isStarted notEnded nonReentrant {
        if(_canClaim(_address, _amount, _merkleProof) != true) revert InvalidClaim();
        alreadyClaimedByAddress[_address] = true;
        SafeERC20.safeTransfer(rewardContract, _address, _amount);
    }

    function claimForOther(
        address _address,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external onlyOpener {
        _claim(_address, _amount, _merkleProof);
    }

    function claim(
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external {
        _claim(msg.sender, _amount, _merkleProof);
    }

    function canClaim(
        address _address,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external view returns (bool) {
        return _canClaim(_address, _amount, _merkleProof);
    }

    function _canClaim(
        address user,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) isStarted notEnded internal view returns (bool canUserClaim) {
        if (alreadyClaimedByAddress[user]) {
            return false;
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(user, amount))));
        
        canUserClaim = MerkleProof.verify(merkleProof, merkleRoot, leaf);
        
        return canUserClaim;
    }
}
