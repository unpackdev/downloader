pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./ECDSA.sol";
import "./LibExchange.sol";

library LibAtomic {
    using ECDSA for bytes32;

    struct LockOrder {
        address sender;
        address asset;
        uint64 amount;
        uint64 expiration;
        bytes32 secretHash;
        bool used;
    }

    struct ClaimOrder {
        address receiver;
        bytes32 secretHash;
    }

    struct RedeemOrder {
        address sender;
        address receiver;
        address claimReceiver;
        address asset;
        uint64 amount;
        uint64 expiration;
        bytes32 secretHash;
        bytes signature;
    }

    struct RedeemInfo {
        address claimReceiver;
        bytes secret;
    }

    function doLockAtomic(LockOrder memory swap,
        mapping(bytes32 => LockOrder) storage atomicSwaps,
        mapping(bytes32 => RedeemInfo) storage secrets,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) public {
        require(msg.sender == swap.sender, "E3C");
        require(swap.expiration/1000 >= block.timestamp, "E17E");
        require(secrets[swap.secretHash].claimReceiver == address(0), "E17R");
        require(atomicSwaps[swap.secretHash].sender == address(0), "E17R");

        int remaining = swap.amount;
        if (msg.value > 0) {
            require(swap.asset == address(0), "E17ETH");
            uint112 eth_sent = uint112(LibUnitConverter.baseUnitToDecimal(address(0), msg.value));
            if (eth_sent < swap.amount) {
                remaining = int(swap.amount) - eth_sent;
            } else {
                swap.amount = uint64(eth_sent);
                remaining = 0;
            }
        }

        if (remaining > 0) {
            LibExchange._updateBalance(swap.sender, swap.asset, -1*remaining, assetBalances, liabilities);
            require(assetBalances[swap.sender][swap.asset] >= 0, "E1A");
        }

        bytes32 secretHash = swap.secretHash;
        swap.secretHash = bytes32(0);
        atomicSwaps[secretHash] = swap;
    }

    function doRedeemAtomic(
        LibAtomic.RedeemOrder calldata order,
        bytes calldata secret,
        mapping(bytes32 => RedeemInfo) storage secrets,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) public {
        require(msg.sender == order.receiver, "E3C");
        require(secrets[order.secretHash].claimReceiver == address(0), "E17R");
        require(getEthSignedAtomicOrderHash(order).recover(order.signature) == order.sender, "E2");
        require(order.expiration/1000 >= block.timestamp, "E4A");
        require(order.secretHash == keccak256(secret), "E17");

        LibExchange._updateBalance(order.sender, order.asset, -1*int(order.amount), assetBalances, liabilities);

        LibExchange._updateBalance(order.receiver, order.asset, order.amount, assetBalances, liabilities);
        secrets[order.secretHash] = RedeemInfo(order.claimReceiver, secret);
    }

    function doClaimAtomic(
        address receiver,
        bytes calldata secret,
        bytes calldata matcherSignature,
        address allowedMatcher,
        mapping(bytes32 => LockOrder) storage atomicSwaps,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) public returns (LockOrder storage swap) {
        bytes32 secretHash = keccak256(secret);
        bytes32 coHash = getEthSignedClaimOrderHash(ClaimOrder(receiver, secretHash));
        require(coHash.recover(matcherSignature) == allowedMatcher, "E2");

        swap = atomicSwaps[secretHash];
        require(swap.sender != address(0), "E17NF");
        require(swap.expiration/1000 >= block.timestamp, "E17E");
        require(!swap.used, "E17U");

        swap.used = true;
        LibExchange._updateBalance(receiver, swap.asset, swap.amount, assetBalances, liabilities);
    }

    function doRefundAtomic(
        bytes32 secretHash,
        mapping(bytes32 => LockOrder) storage atomicSwaps,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) public returns(LockOrder storage swap) {
        swap = atomicSwaps[secretHash];
        require(swap.sender != address(0x0), "E17NF");
        require(swap.expiration/1000 < block.timestamp, "E17NE");
        require(!swap.used, "E17U");

        swap.used = true;
        LibExchange._updateBalance(swap.sender, swap.asset, int(swap.amount), assetBalances, liabilities);
    }

    function getEthSignedAtomicOrderHash(RedeemOrder calldata _order) internal view returns (bytes32) {
        uint256 chId;
        assembly {
            chId := chainid()
        }
        return keccak256(
            abi.encodePacked(
                "atomicOrder",
                chId,
                _order.sender,
                _order.receiver,
                _order.claimReceiver,
                _order.asset,
                _order.amount,
                _order.expiration,
                _order.secretHash
            )
        ).toEthSignedMessageHash();
    }

    function getEthSignedClaimOrderHash(ClaimOrder memory _order) internal pure returns (bytes32) {
        uint256 chId;
        assembly {
            chId := chainid()
        }
        return keccak256(
            abi.encodePacked(
                "claimOrder",
                chId,
                _order.receiver,
                _order.secretHash
            )
        ).toEthSignedMessageHash();
    }
}
