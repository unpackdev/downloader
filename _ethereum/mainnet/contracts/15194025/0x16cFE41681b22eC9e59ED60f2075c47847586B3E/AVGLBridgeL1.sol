// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ReentrancyGuardUpgradeable.sol";
import "./ECDSA.sol";
import "./SafeMath.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20.sol";

contract AVGLBridgeL1 is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;

    IERC20 public avgl;
    mapping(uint256 => bool) public txClaimed;
    address public signer;

    constructor() {}

    function initialize(address _avgl, address _signer) public initializer {
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        avgl = IERC20(_avgl);
        signer = _signer;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function withdraw(uint256 _amount) external onlyOwner {
        avgl.transfer(msg.sender, _amount);
    }

    function checkClaimValidity(
        bytes32 hash,
        bytes calldata signature,
        uint256 txid,
        uint256 claimAmount
    ) public view returns (bool) {
        require(ECDSA.recover(hash, signature) == signer, "Invalid signature");
        require(
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        "l1-claiming",
                        claimAmount,
                        "fromTX",
                        txid
                    )
                )
            ) == hash,
            "Invalid hash"
        );
        return true;
    }

    function claimAVGL(
        bytes32 hash,
        bytes calldata signature,
        uint256 txid,
        uint256 claimAmount
    ) external nonReentrant {
        require(checkClaimValidity(hash, signature, txid, claimAmount));
        require(!txClaimed[txid], "Already claimed");
        txClaimed[txid] = true;
        avgl.transfer(msg.sender, claimAmount);
    }
}
