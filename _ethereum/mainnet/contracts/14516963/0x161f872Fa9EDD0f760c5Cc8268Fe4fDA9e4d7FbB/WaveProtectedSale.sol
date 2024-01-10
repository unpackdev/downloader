// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./WaveTicketInfo.sol";

contract WaveProtectedSale is Ownable, EIP712 {
    bytes32 private constant PURCHASE_TYPEHASH = keccak256("Purchase(address buyer,TicketInfo ticketInfo,uint128 signedPrice,uint32 nonce)TicketInfo(uint16 id,uint8 typ,uint32 expiration,uint32 renewalPeriod,uint128 renewalPrice)");
    bytes32 private constant TICKETINFO_TYPEHASH = keccak256("TicketInfo(uint16 id,uint8 typ,uint32 expiration,uint32 renewalPeriod,uint128 renewalPrice)"); 
    address private PROTECTED_SIGNER;

    modifier isTransactionAuthorized(TicketInfo memory ticketInfo, uint128 signedPrice, uint32 nonce, bytes memory signature) {
        require(
            getSigner(msg.sender, ticketInfo, signedPrice, nonce, signature) == PROTECTED_SIGNER, "Invalid signature"
        );
        _;
    }

    constructor(string memory name, string memory version) EIP712(name, version) {}

    function setProtectedSigner(address signerAddress) external onlyOwner {
        PROTECTED_SIGNER = signerAddress;
    }
    
    function getSigner(address buyer, TicketInfo memory ticketInfo, uint128 signedPrice, uint32 nonce, bytes memory signature) private view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    PURCHASE_TYPEHASH, 
                    buyer, 
                    keccak256(
                        abi.encode(
                            TICKETINFO_TYPEHASH,
                            ticketInfo.id,
                            ticketInfo.typ,
                            ticketInfo.expiration,
                            ticketInfo.renewalPeriod,
                            ticketInfo.renewalPrice
                        )
                    ),
                    signedPrice, 
                    nonce
                )
            )
        );
        return ECDSA.recover(digest, signature);
    }
}