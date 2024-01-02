// SPDX-License-Identifier: MIT
//       _____                       .__
//      /     \   ___________   ____ |  |   ____
//     /  \ /  \_/ __ \_  __ \_/ ___\|  | _/ __ \
//    /    Y    \  ___/|  | \/\  \___|  |_\  ___/
//    \____|__  /\___  >__|    \___  >____/\___  >
//        \/     \/            \/          \/

pragma solidity ^0.8.9;

import "./ECDSA.sol";

interface IErc721AccessControl {
    function CLAIM_ISSUER_ROLE() external view returns (bytes32);

    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);

    function mintNFT(
        address recipient,
        string memory tokenUri
    ) external returns (uint256);
}

contract MintWithClaim {
    struct Domain {
        string name;
        string version;
        address verifyingContract;
        uint256 chainId;
    }
    struct AttestClaim {
        address to;
        address from;
        string tokenUri;
        uint256 timestamp;
        uint256 fee;
    }

    bytes32 private constant DOMAIN_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 private constant ATTESTED_HASH =
        keccak256(
            "AttestClaim(address to,address from,string tokenUri,uint256 timestamp,uint256 fee)"
        );

    mapping(bytes32 => bool) isClaimUsed;

    address public treasury;

    constructor(address _treasury) {
        treasury = _treasury;
    }

    function mintNFTClaim(
        Domain calldata domain,
        AttestClaim calldata message,
        bytes memory sign
    ) external payable returns (uint256) {
        require(verifyClaim(domain, message, sign) == true, "not allowed");
        require(msg.value == message.fee, "fee required");

        bool sent = payable(treasury).send(msg.value);
        require(sent, "fee failed");

        IErc721AccessControl nft = IErc721AccessControl(
            domain.verifyingContract
        );

        uint256 tokenId = nft.mintNFT(message.to, message.tokenUri);

        isClaimUsed[keccak256(abi.encodePacked(sign))] = true;

        return tokenId;
    }

    function verifyClaim(
        Domain calldata domain,
        AttestClaim calldata message,
        bytes memory sign
    ) public view returns (bool) {
        // verify token owner
        IErc721AccessControl nft = IErc721AccessControl(
            domain.verifyingContract
        );

        bool isDuplicate = isClaimUsed[keccak256(abi.encodePacked(sign))] == true;

        bool isFromSender = message.to == msg.sender;

        // verify claim signature
        bytes32 digest = hashTypedDataV4(domain, message);
        address issuerAddress = ECDSA.recover(digest, sign);

        bool isSignValid = issuerAddress == message.from;

        // verify issuer role
        bool issuerHasRole = nft.hasRole(
            nft.CLAIM_ISSUER_ROLE(),
            issuerAddress
        );

        return isSignValid && issuerHasRole && isFromSender && !isDuplicate;
    }

    function hashTypedDataV4(
        Domain calldata domain,
        AttestClaim calldata message
    ) internal view returns (bytes32) {
        return
            ECDSA.toTypedDataHash(
                keccak256(
                    abi.encode(
                        DOMAIN_HASH,
                        keccak256(abi.encodePacked(domain.name)),
                        keccak256(abi.encodePacked(domain.version)),
                        block.chainid,
                        address(domain.verifyingContract)
                    )
                ),
                _keccak256AttestClaim(message)
            );
    }

    function _keccak256AttestClaim(
        AttestClaim calldata message
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    /**
                     * Make sure to match order of variables as in the types array used with ethers.js
                     */
                    ATTESTED_HASH,
                    message.to,
                    message.from,
                    keccak256(abi.encodePacked(message.tokenUri)),
                    message.timestamp,
                    message.fee
                )
            );
    }

    function setTreasury(address _treasury) public {
        treasury = _treasury;
    }
}
