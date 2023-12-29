// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC721.sol";
import "./IERC20.sol";

import "./INFTLending.sol";
import "./IXY3.sol";
import "./IWETH.sol";

/// @title X2Y2 Lending
/// @notice Manages creating and repaying a loan on X2Y2
contract X2Y2Lending is INFTLending {
    uint256 constant public MAX_INT_TYPE = type(uint256).max;

    /// @notice XY3 Contract
    IXY3 public constant xy3 =
        IXY3(0xB81965DdFdDA3923f292a47A1be83ba3A36B5133);

    /// @notice WETH Contract
    IWETH public constant weth =
        IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /// @inheritdoc INFTLending
    function getLoanDetails(
        uint256 _loanId
    ) external view returns (LoanDetails memory loanDetails) {
        uint32 loanId = uint32(_loanId);

        // Get LoanDetail for loanId
        IXY3.LoanDetail memory loanDetail = xy3.loanDetails(loanId);
        address nftAddress = xy3.nftAssetList()[loanDetail.nftAssetIndex];
        return LoanDetails(
            loanDetail.borrowAmount, // borrowAmount
            loanDetail.repayAmount, // repayAmount
            loanDetail.loanStart + loanDetail.loanDuration, // loanExpiration
            nftAddress, // nftAddress
            loanDetail.nftTokenId // tokenId
        );
    }

    /// @inheritdoc INFTLending
    function borrow(
        bytes calldata _inputData
    ) external payable returns (uint256) {
        // Decode `inputData` into Offer, Signature and BorrowerSettings
        (
            IXY3.Offer memory offer,
            uint256 nftId,
            IXY3.BrokerSignature memory brokerSignature,
            IXY3.CallData memory extraData
        ) = abi.decode(
                _inputData,
                (
                    IXY3.Offer,
                    uint256,
                    IXY3.BrokerSignature,
                    IXY3.CallData
                )
            );

        IERC721 nft = IERC721(offer.nftAsset);

        // Approve
        if (!nft.isApprovedForAll(address(this), address(xy3))) {
            nft.setApprovalForAll(address(xy3), true);
        }

        // Borrow on X2Y2
        uint32 loanId = xy3.borrow(
            offer,
            nftId,
            brokerSignature,
            extraData
        );

        // Unwrap WETH into ETH
        weth.withdraw(offer.borrowAmount);

        // Return loan id
        return uint256(loanId);
    }

    /// @inheritdoc INFTLending
    function repay(uint256 _loanId, address _receiver) external payable {
        uint32 loanId = uint32(_loanId);

        // Get LoanInfo for loanId
        IXY3.LoanDetail memory loanDetail = xy3.loanDetails(loanId);

        // Wrap ETH into WETH
        weth.deposit{value: loanDetail.repayAmount}();

        // Approve token to `xy3`
        if (weth.allowance(address(this), address(xy3)) < loanDetail.repayAmount) {
            weth.approve(address(xy3), MAX_INT_TYPE);
        }

        // Pay back loan
        xy3.repay(loanId);

        // Transfer NFT to a designated address
        if (_receiver != address(this)) {
            address nftAddress = xy3.nftAssetList()[loanDetail.nftAssetIndex];
            IERC721(nftAddress).safeTransferFrom(address(this), _receiver, loanDetail.nftTokenId);
        }
    }

    /// @notice Decodes the given input data into xy3 structs
    /// @param _inputData the input data
    function decode(bytes calldata _inputData) external pure returns (
        IXY3.Offer memory offer,
        uint256 nftId,
        IXY3.BrokerSignature memory brokerSignature,
        IXY3.CallData memory extraData) {
        return abi.decode(_inputData, (IXY3.Offer, uint256, IXY3.BrokerSignature, IXY3.CallData));
    }

    receive() external payable {}
}
