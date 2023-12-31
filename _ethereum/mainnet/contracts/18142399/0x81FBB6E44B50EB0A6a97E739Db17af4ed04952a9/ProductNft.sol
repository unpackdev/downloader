// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC1155.sol";
import "./Ownable.sol";
import "./IProductNft.sol";

contract ProductNft is Ownable, IProductNft {
    /// @notice Pull from address for different NFTs (comics, hoodies, etc)
    address public pullFromAddress = 0x716E6b6873038a8243F5EB44e2b09D85DEFf45Ec;

    /// @notice Address of the nft smart contract
    address public nftAddress = 0x6A82872743217A0988E4d72975D74432CfDeF9D7;

    /// @notice Address of the shop smart contract
    address public shopAddress = 0xd32034B5502910e5B56f5AC94ACb4198315c2Da2;

    /**
     * @notice Updates pull from address
     * @dev Only callable by owner
     * @param _pullFromAddress New pull from address
     */
    function setPullFromAddress(address _pullFromAddress) external onlyOwner {
        pullFromAddress = _pullFromAddress;
    }

    /**
     * @notice Updates nft address
     * @dev Only callable by owner
     * @param _nftAddress New nft address
     */
    function setNftAddress(address _nftAddress) external onlyOwner {
        nftAddress = _nftAddress;
    }

    /**
     * @notice Updates shop address
     * @dev Only callable by owner
     * @param _shopAddress New shop address
     */
    function setShopAddress(address _shopAddress) external onlyOwner {
        shopAddress = _shopAddress;
    }

    /**
     * @notice Executes batch transfer to the provided address
     * @param _to Destination address
     * @param _multiplier Multiplier for the amount of token ids to send
     * @param _transactionId Id that is emitted for tracking
     * @param _ids List of token ids
     * @param _amounts List of amounts for each token id
     * @param _data Additional encoded data
     */
    function safeBatchTransferFrom(
        address _to,
        uint256 _multiplier,
        uint256 _transactionId,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) external {
        if (msg.sender != shopAddress) {
            revert InvalidInvoker();
        }

        uint256[] memory amounts = new uint256[](_amounts.length);

        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = _amounts[i] * _multiplier;
        }

        IERC1155(nftAddress).safeBatchTransferFrom(
            pullFromAddress,
            _to,
            _ids,
            amounts,
            _data
        );

        emit NftPurchase(nftAddress, _to, _ids, _amounts, _transactionId);
    }
}
