// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IXY3 {    
    struct LoanDetail {
        uint8 state;
        uint64 reserved;
        uint32 loanDuration;
        uint16 adminShare;
        uint64 loanStart;
        uint8 borrowAssetIndex;
        uint32 nftAssetIndex;
        uint112 borrowAmount;
        uint112 repayAmount;
        uint256 nftTokenId;
    }

    struct CallData {
        address target;
        bytes4 selector;
        bytes data;
        uint256 referral;
        address onBehalf;
        bytes32[] proof;
    }

    struct Signature {
        address signer;
        bytes signature;
    }

    struct Offer {
        uint8 itemType;
        uint256 borrowAmount;
        uint256 repayAmount;
        address nftAsset;
        address borrowAsset;
        uint256 tokenId;
        uint32 borrowDuration;
        uint32 validUntil;
        uint32 amount;
        Signature signature;
    }

    struct BrokerSignature {
        address signer;
        bytes signature;
        uint32 expiry;
    }

    struct LoanInfo {
        uint32 loanId;
        address nftAsset;
        address borrowAsset;
        uint256 nftId;
        uint256 adminFee;
        uint256 payoffAmount;
        uint256 borrowAmount;
        uint256 maturityDate;
    }

    function borrowAssetList() external view returns (address[] memory);

    function getAddressProvider() external view returns (address);

    function nftAssetList() external view returns (address[] memory);

    /**
     * @dev The borrower accept a lender's offer to create a loan.
     *
     * @param _offer - The offer made by the lender.
     * @param _nftId - The ID
     * @param _brokerSignature - The broker's signature.
     * @param _extraData - Create a new loan by getting a NFT colleteral from external contract call.
     * The external contract can be lending market or deal market, specially included the restricted repay of myself.
     * But should not be the Xy3Nft.mint, though this contract maybe have the permission.
     */
    function borrow(
        Offer memory _offer,
        uint256 _nftId,
        BrokerSignature memory _brokerSignature,
        CallData memory _extraData
    ) external returns (uint32 loanId);

    function repay(address _sender, bytes memory _param) external;

    function borrowAssetIndex(address asset) external view returns (uint8);

    function nftAssetsIndex(address asset) external view returns (uint32);

    function getLoanInfo(uint32 _loanId)
        external
        view
        returns (LoanInfo memory loanInfo);

    function getRepayAmount(uint32 _loanId) external view returns (uint256);

    function loanDetails(uint32 _loanId)
        external
        view
        returns (LoanDetail memory);

    function loanState(uint32 _loanId) external view returns (uint8);

    function repay(uint32 _loanId) external;
}
