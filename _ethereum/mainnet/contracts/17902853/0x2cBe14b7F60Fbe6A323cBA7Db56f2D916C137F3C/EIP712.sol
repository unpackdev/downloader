// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

abstract contract EIP712 {
    /// -----------------------------------------------------------------------
    /// Structs
    /// -----------------------------------------------------------------------

    /// @param v Part of the ECDSA signature
    /// @param r Part of the ECDSA signature
    /// @param s Part of the ECDSA signature
    struct WithdrawalPacket {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
        uint256 amount;
        uint256 nonce;
        address account;
    }

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The chain ID used by EIP-712
    uint256 internal immutable INITIAL_CHAIN_ID;

    /// @notice The domain separator used by EIP-712
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor() {
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    /// -----------------------------------------------------------------------
    /// Packet verification
    /// -----------------------------------------------------------------------

    function _verifySig(bytes memory data, uint8 v, bytes32 r, bytes32 s) internal virtual returns (address) {
        // verify signature
        address recoveredAddress =
            ecrecover(keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), keccak256(data))), v, r, s);
        return recoveredAddress;
    }

    /// @notice Verifies whether a packet is valid and returns the result.
    /// @dev The deadline, request, and signature are verified.
    /// @param packet The packet provided by the offchain data provider
    function _verifyWithdrawal(WithdrawalPacket calldata packet) internal virtual returns (address) {
        // verify deadline
        require(block.timestamp < packet.deadline, ">deadline");

        // verify signature
        address recoveredAddress = _verifySig(
            abi.encode(
                keccak256("VerifyWithdrawal(uint256 deadline,uint256 amount,uint256 nonce,address account)"),
                packet.deadline,
                packet.amount,
                packet.nonce,
                packet.account
            ),
            packet.v,
            packet.r,
            packet.s
        );
        return recoveredAddress; // Invariant: sequencer != address(0), we maintain this every time sequencer is set
    }

    struct Bid {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes32 auctionId;
        uint256 maxAmount;
    }

    function _verifyBid(Bid calldata packet) internal virtual returns (address) {
        address recoveredAddress = _verifySig(
            abi.encode(keccak256("Bid(bytes32 auctionId,uint256 maxAmount)"), packet.auctionId, packet.maxAmount),
            packet.v,
            packet.r,
            packet.s
        );
        require(recoveredAddress != address(0), "sig");
        return recoveredAddress;
    }

    struct BidWinner {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes32 auctionId;
        uint256 amount;
        address winner;
    }

    function _verifyBidWinner(BidWinner calldata packet) internal virtual returns (address) {
        return _verifySig(
            abi.encode(
                keccak256("BidWinner(bytes32 auctionId,uint256 amount,address winner)"),
                packet.auctionId,
                packet.amount,
                packet.winner
            ),
            packet.v,
            packet.r,
            packet.s
        );
    }

    struct CancelAuction {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes32 auctionId;
        uint256 deadline;
    }

    function _verifyCancelAuction(CancelAuction calldata packet) internal virtual returns (address) {
        require(block.timestamp <= packet.deadline, "deadline");
        return _verifySig(
            abi.encode(
                keccak256("CancelAuction(bytes32 auctionId,uint256 deadline)"), packet.auctionId, packet.deadline
            ),
            packet.v,
            packet.r,
            packet.s
        );
    }

    struct Offer {
        uint8 v;
        bytes32 r;
        bytes32 s;
        address nftContract;
        uint256 nftId;
        uint256 amount;
        uint256 deadline;
        uint256 counter;
        uint256 nonce;
    }

    function _verifyBuyOffer(Offer calldata packet) internal virtual returns (address) {
        return _verifySig(
            abi.encode(
                keccak256(
                    "BuyOffer(address nftContract,uint256 nftId,uint256 amount,uint256 deadline,uint256 counter,uint256 nonce)"
                ),
                packet.nftContract,
                packet.nftId,
                packet.amount,
                packet.deadline,
                packet.counter,
                packet.nonce
            ),
            packet.v,
            packet.r,
            packet.s
        );
    }

    function _verifySellOffer(Offer calldata packet) internal virtual returns (address) {
        return _verifySig(
            abi.encode(
                keccak256(
                    "SellOffer(address nftContract,uint256 nftId,uint256 amount,uint256 deadline,uint256 counter,uint256 nonce)"
                ),
                packet.nftContract,
                packet.nftId,
                packet.amount,
                packet.deadline,
                packet.counter,
                packet.nonce
            ),
            packet.v,
            packet.r,
            packet.s
        );
    }

    struct OfferAttestation {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes32 auctionId;
        uint256 amount;
        address buyer;
        address seller;
        uint256 deadline;
    }

    function _verifyOfferAttestation(OfferAttestation calldata packet) internal virtual returns (address) {
        return _verifySig(
            abi.encode(
                keccak256(
                    "OfferAttestation(bytes32 auctionId,uint256 amount,address buyer,address seller,uint256 deadline)"
                ),
                packet.auctionId,
                packet.amount,
                packet.buyer,
                packet.seller,
                packet.deadline
            ),
            packet.v,
            packet.r,
            packet.s
        );
    }

    /// -----------------------------------------------------------------------
    /// EIP-712 compliance
    /// -----------------------------------------------------------------------

    /// @notice The domain separator used by EIP-712
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    /// @notice Computes the domain separator used by EIP-712
    function _computeDomainSeparator() internal view virtual returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("SealedArtMarket"),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }
}
