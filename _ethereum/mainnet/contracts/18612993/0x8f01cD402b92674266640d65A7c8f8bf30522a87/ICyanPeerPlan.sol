// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICyanPeerPlan {
    enum PlanStatus {
        NONE,
        ACTIVE,
        DEFAULTED,
        COMPLETED,
        LIQUIDATED
    }
    struct LenderSignature {
        uint256 signedDate;
        uint256 expiryDate;
        uint32 maxUsageCount;
        bool extendable;
        bytes signature;
    }
    struct Plan {
        uint256 amount;
        address lenderAddress;
        address currencyAddress;
        uint32 interestRate;
        uint32 serviceFeeRate;
        uint32 term;
    }
    struct PaymentPlan {
        Plan plan;
        uint256 dueDate;
        address cyanWalletAddress;
        PlanStatus status;
        bool extendable;
    }
    struct Item {
        uint256 amount;
        uint256 tokenId;
        address contractAddress;
        // 1 -> ERC721
        // 2 -> ERC1155
        // 3 -> CryptoPunks
        uint8 itemType;
        bytes collectionSignature;
    }
}
