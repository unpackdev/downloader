// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./OwnableUpgradeable.sol";
import "./ECDSA.sol";

library EvermoonDistributionStorage {
    struct Layout {
        address signer;
        mapping(uint256 => uint256) depositMap;
        mapping(address => uint256) claimerClaimedMap;
        uint256 depositCount;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("EvermoonDistribution.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

contract EvermoonDistribution is OwnableUpgradeable {
    event EvDeposit(address indexed depositor, uint256 depositID_, uint256 value);
    event EvClaim(address indexed claimer, uint256 value);

    error ErrInvalidDeposit();
    error ErrInvalidSignature();
    error ErrUseDeposit();
    error ErrClaimed();
    error ErrInvalidClaim();

    // constructor
    function initialize(address signer_) external initializer {
        __Ownable_init();
        EvermoonDistributionStorage.layout().signer = signer_;
    }

    // receive
    receive() external payable {
        revert ErrUseDeposit();
    }

    // owners
    function deposit(bytes calldata signature_) external payable onlyOwner {
        // check signature
        address __signer = EvermoonDistributionStorage.layout().signer;
        uint256 __depositID = EvermoonDistributionStorage.layout().depositCount;
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, msg.value, "deposit", __depositID));

        // check value
        if (msg.value == 0) {
            revert ErrInvalidDeposit();
        }

        if (ECDSA.recover(hash, signature_) != __signer) revert ErrInvalidSignature();

        // update
        EvermoonDistributionStorage.layout().depositMap[__depositID] = msg.value;
        EvermoonDistributionStorage.layout().depositCount = __depositID + 1;

        // emit
        emit EvDeposit(msg.sender, __depositID, msg.value);
    }

    function emergencyWithdraw() external onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function setSigner(address signer_) external onlyOwner {
        EvermoonDistributionStorage.layout().signer = signer_;
    }

    // public
    function claim(uint256 amount_, bytes calldata signature_, uint256 claimID_) external {
        // check signature
        uint256 __claimedID = EvermoonDistributionStorage.layout().claimerClaimedMap[msg.sender];
        address __signer = EvermoonDistributionStorage.layout().signer;
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, amount_, "claim", claimID_));
        if (ECDSA.recover(hash, signature_) != __signer) revert ErrInvalidSignature();

        // check claimID
        uint256 __depositID = EvermoonDistributionStorage.layout().depositCount;
        if (claimID_ <= __claimedID) {
            revert ErrClaimed();
        }

        if (claimID_ != __depositID) {
            revert ErrInvalidClaim();
        }

        // update state
        EvermoonDistributionStorage.layout().claimerClaimedMap[msg.sender] = claimID_;

        // send
        (bool success,) = payable(msg.sender).call{value: amount_}("");
        require(success);

        // emit
        emit EvClaim(msg.sender, amount_);
    }

    // getters
    function signer() external view returns (address) {
        return EvermoonDistributionStorage.layout().signer;
    }

    function claimerClaimedMap(address claimer_) external view returns (uint256) {
        return EvermoonDistributionStorage.layout().claimerClaimedMap[claimer_];
    }

    function depositMap(uint256 depositID_) external view returns (uint256) {
        return EvermoonDistributionStorage.layout().depositMap[depositID_];
    }

    function depositCount() external view returns (uint256) {
        return EvermoonDistributionStorage.layout().depositCount;
    }
}
