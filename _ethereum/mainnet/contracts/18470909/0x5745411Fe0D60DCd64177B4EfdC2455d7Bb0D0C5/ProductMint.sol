// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC1155.sol";
import "./Ownable.sol";

import "./IProductMint.sol";

interface INft {
    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        string[] memory _tokenUris,
        bytes memory _data
    ) external;
}

contract ProductMint is Ownable, IProductMint {
    /// @notice Address of the nft smart contract
    address public nftAddress = 0x6A82872743217A0988E4d72975D74432CfDeF9D7;

    /// @notice Address of the shop smart contract
    address public shopAddress = 0xd32034B5502910e5B56f5AC94ACb4198315c2Da2;

    /// @notice Max redeemable per transaction
    uint256 public maxRedeemablePerTxn = 1;

    /**
     * @notice Updates nft address
     * @dev Only callable by owner
     * @param _nftAddress New nft address
     */
    function setNftAddress(address _nftAddress) external onlyOwner {
        nftAddress = _nftAddress;
        emit NftAddressSet(_nftAddress);
    }

    /**
     * @notice Updates shop address
     * @dev Only callable by owner
     * @param _shopAddress New shop address
     */
    function setShopAddress(address _shopAddress) external onlyOwner {
        shopAddress = _shopAddress;
        emit ShopAddressSet(_shopAddress);
    }

    /**
     * @notice Sets max redeemable per transaction
     * @dev Only callable by owner
     * @param _maxRedeemablePerTxn Max redeemable per transaction
     */
    function setMaxRedeemablePerTxn(
        uint256 _maxRedeemablePerTxn
    ) external onlyOwner {
        maxRedeemablePerTxn = _maxRedeemablePerTxn;
        emit MaxRedeemablePerTxnSet(maxRedeemablePerTxn);
    }

    /**
     * @notice Executes batch mint to the provided address
     * @param _to Destination address
     * @param _multiplier Multiplier for the amount of token ids to send
     * @param _transactionId Id that is emitted for tracking
     * @param _ids List of token ids
     * @param _amounts List of amounts for each token id
     * @param _data Additional encoded data
     */
    function mintBatch(
        address _to,
        uint256 _multiplier,
        uint256 _transactionId,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        string[] memory _tokenUris,
        bytes memory _data
    ) external {
        if (msg.sender != shopAddress) {
            revert InvalidInvoker();
        }

        if (_multiplier > maxRedeemablePerTxn) {
            revert RedeemingTooMany(_amounts.length);
        }

        uint256[] memory amounts = new uint256[](_amounts.length);

        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = _amounts[i] * _multiplier;
        }

        INft(nftAddress).mintBatch(_to, _ids, amounts, _tokenUris, _data);

        emit NftMint(nftAddress, _to, _ids, _amounts, _transactionId);
    }
}
