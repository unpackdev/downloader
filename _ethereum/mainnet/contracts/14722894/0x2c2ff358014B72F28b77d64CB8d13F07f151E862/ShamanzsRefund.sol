// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/// @title Shamanz DA Refunds
/// @author @KfishNFT
contract ShamanzRefund is Ownable, ReentrancyGuard {
    /// @notice Merkle Root used to verify if an address is part of the refund one list
    bytes32 public merkleRootOne;
    /// @notice Merkle Root used to verify if an address is part of the refund Two list
    bytes32 public merkleRootTwo;
    /// @notice Merkle Root used to verify if an address is part of the refund Three list
    bytes32 public merkleRootThree;
    /// @notice Used to keep track of addresses that have been refunded
    mapping(address => bool) public daRefunded;
    mapping(address => bool) public wlRefunded;
    mapping(address => bool) public alRefunded;
    /// @notice Toggleable flag for refund state
    bool public isRefundActive;
    /// @notice Wich refund phase are we in?
    bool public da = true;
    bool public wl = false;
    bool public al = false;
    /// @notice Refund amount for people who minted one Shamanz in DA
    uint256 public refundOneAmount = 0.35 ether;
    /// @notice Refund amount for people who minted two Shamanz in DA
    uint256 public refundTwoAmount = 0.7 ether;
    /// @notice Refund amount for people who minted three Shamanz in DA
    uint256 public refundThreeAmount = 1.05 ether;

    /// @notice Contract constructor
    /// @dev The merkle root can be added later if required
    /// @notice Emit event once ETH is received
    /// @param sender The sender of ETH
    /// @param value The amount of ETH
    event Received(address indexed sender, uint256 value);

    /// @notice Emit event once ETH is refunded
    /// @param sender The address being refunded
    /// @param value The amount of ETH
    event Refunded(address indexed sender, uint256 value);

    /// @notice Allow contract to receive eth
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /// @dev requires a valid merkleRoot to function
    /// @param _merkleProof the proof sent by an refundable user
    function refund(bytes32[] calldata _merkleProof, uint256 _toRefund) external nonReentrant {
        require(isRefundActive, "Refunding is not active yet");
        if (da) require(!daRefunded[msg.sender], "Already refunded");
        if (wl) require(!wlRefunded[msg.sender], "Already refunded");
        if (al) require(!alRefunded[msg.sender], "Already refunded");

        uint256 toPay = refundOneAmount;

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (_toRefund == 1) require(MerkleProof.verify(_merkleProof, merkleRootOne, leaf), "not refundable");

        if (_toRefund == 2) {
            require(MerkleProof.verify(_merkleProof, merkleRootTwo, leaf), "not refundable");
            toPay = refundTwoAmount;
        }

        if (_toRefund == 3) {
            require(MerkleProof.verify(_merkleProof, merkleRootThree, leaf), "not refundable");
            toPay = refundThreeAmount;
        }

        if (da) daRefunded[msg.sender] = true;
        if (wl) wlRefunded[msg.sender] = true;
        if (al) alRefunded[msg.sender] = true;

        if(toPay > 0) {
            (bool os, ) = payable(msg.sender).call{value: toPay}("");
            require(os);
            emit Refunded(msg.sender, toPay);
        }
    }

    /// @notice Function that sets refunding active or inactive
    /// @dev only callable from the contract owner
    function toggleIsRefundActive() external onlyOwner {
        isRefundActive = !isRefundActive;
    }

    /// @notice Set refund amounts for people who minted Shamanz in DA
    /// @param refundOneAmount_ Refund amount for people who minted one Shamanz in DA
    /// @param refundTwoAmount_ Refund amount for people who minted two Shamanz in DA
    /// @param refundThreeAmount_ Refund amount for people who minted three Shamanz in DA
    function setRefundAmounts(
        uint256 refundOneAmount_,
        uint256 refundTwoAmount_,
        uint256 refundThreeAmount_
    ) external onlyOwner {
        refundOneAmount = refundOneAmount_;
        refundTwoAmount = refundTwoAmount_;
        refundThreeAmount = refundThreeAmount_;
    }

    /// @notice Sets the merkle root for refunds verification
    /// @dev only callable from the contract owner
    /// @param merkleRootOne_ used to verify the refund list of one mint
    /// @param merkleRootTwo_ used to verify the refund list of two mints
    /// @param merkleRootThree_ used to verify the refund list of three mints
    function setMerkleRoots(
        bytes32 merkleRootOne_,
        bytes32 merkleRootTwo_,
        bytes32 merkleRootThree_
    ) external onlyOwner {
        merkleRootOne = merkleRootOne_;
        merkleRootTwo = merkleRootTwo_;
        merkleRootThree = merkleRootThree_;
    }

    /// @notice Sets refund phase DA
    /// @dev only callable from the contract owner
    /// @param _activate active phase
    function setDa(bool _activate) external onlyOwner {
        da = _activate;
    }

    /// @notice Sets refund phase WL
    /// @dev only callable from the contract owner
    /// @param _activate active phase
    function setWl(bool _activate) external onlyOwner {
        wl = _activate;
    }

    /// @notice Sets refund phase AL
    /// @dev only callable from the contract owner
    /// @param _activate active phase
    function setAl(bool _activate) external onlyOwner {
        al = _activate;
    }

    /// @notice Withdraw function in case anyone sends ETH to contract by mistake
    /// @dev only callable from the contract owner
    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
    
}
