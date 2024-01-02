// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./ReentrancyGuard.sol";

contract ShareDividend is Ownable, EIP712, ReentrancyGuard {
    // Store the amount each address has contributed
    mapping(address => uint256) public claimedDividend;

    address public masterAddress;

    bytes32 private EIP712_DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 private DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPE_HASH,
                keccak256(bytes("ShareDividend")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

    constructor() EIP712("ShareDividend", "1") {}

    function changeMasterAddress(address newAddress) external onlyOwner {
        masterAddress = newAddress;
    }

    function getSignedAddress(
        uint256 maxAmount,
        address sender,
        bytes memory signature
    ) public view returns (address) {
        bytes32 VALIDATE_CLAIM_DIVIDEND = keccak256(
            "ClaimDividend(uint256 maxAmount,address sender)"
        );
        bytes32 structHash = keccak256(
            abi.encode(VALIDATE_CLAIM_DIVIDEND, maxAmount, sender)
        );
        bytes32 digest = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, structHash);
        address recoveredAddress = ECDSA.recover(digest, signature);

        return recoveredAddress;
    }

    function claimDividend(
        uint256 maxAmount,
        bytes memory signature
    ) public payable nonReentrant {
        address sender = msg.sender;

        address recoveredAddress = getSignedAddress(
            maxAmount,
            sender,
            signature
        );

        require(recoveredAddress == masterAddress, "Invalid Master Address");
        require(maxAmount > 0, "Invalid maxAmount"); // Ensure maxAmount is greater than zero

        uint256 previouslyClaimedDividend = claimedDividend[sender];
        uint256 remainingDividend = maxAmount - previouslyClaimedDividend;
        require(remainingDividend > 0, "No dividend remaining to claim");

        (bool sent, ) = sender.call{value: remainingDividend}("");
        require(sent, "Failed to send Ether");

        claimedDividend[sender] += remainingDividend;
    }

    // This function allows the contract to receive Ether
    receive() external payable {
        // You can add custom logic here if needed
    }
}
