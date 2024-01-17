// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./SafeERC20.sol";

import "./IX2Y2Adapter.sol";

library X2Y2Lib {
    using SafeERC20 for IERC20;

    address private constant _x2y2Exchange =
        0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3;
    address private constant _x2y2ERC721Delegate =
        0xF849de01B080aDC3A814FaBE1E2087475cF2E354;
    address private constant _x2y2ERC1155Delegate =
        0x024aC22ACdB367a3ae52A3D94aC6649fdc1f0779;

    bytes4 private constant IID_IERC1155 = type(IERC1155).interfaceId;
    bytes4 private constant IID_IERC721 = type(IERC721).interfaceId;

    function buyAssetForEth(Market.RunInput memory input) external {
        //// NOTE: For eth, we dont need to calculate the accurate price of order,
        //// because x2y2 exchange has refund process in its function procession.
        try IX2Y2Exchange(_x2y2Exchange).run{value: msg.value}(input) {
            // transfer nfts to buyer
            for (uint256 i = 0; i < input.details.length; i++) {
                // which order & orderItem(in order) buyer takes
                Market.Order memory order = input.orders[
                    input.details[i].orderIdx
                ];
                Market.OrderItem memory orderItem = order.items[
                    input.details[i].itemIdx
                ];

                // Follow x2y2 origin code
                {
                    // prettier-ignore
                    if (order.dataMask.length > 0 && input.details[i].dataReplacement.length > 0) {
                        _arrayReplace(orderItem.data, input.details[i].dataReplacement, order.dataMask);
                    }
                }

                _nftTransfer(
                    address(this),
                    msg.sender,
                    orderItem,
                    address(input.details[i].executionDelegate)
                );
            }
        } catch {
            revert("Buyer takes order failed.");
        }
    }

    function _nftTransfer(
        address from,
        address to,
        Market.OrderItem memory orderItem,
        address executionDelegate
    ) internal {
        if (executionDelegate == _x2y2ERC721Delegate) {
            // nft is ERC721
            // prettier-ignore
            IDelegate.ERC721Pair[] memory pairs = decodeERC721Pair(orderItem.data);
            for (uint256 i = 0; i < pairs.length; i++) {
                IDelegate.ERC721Pair memory p = pairs[i];
                p.token.safeTransferFrom(from, to, p.tokenId);
            }
        } else if (executionDelegate == _x2y2ERC1155Delegate) {
            // nft is ERC1155
            IDelegate.ERC1155Pair[] memory pairs = decodeERC1155Pair(
                orderItem.data
            );
            for (uint256 i = 0; i < pairs.length; i++) {
                IDelegate.ERC1155Pair memory p = pairs[i];
                p.token.safeTransferFrom(from, to, p.tokenId, p.amount, "0x");
            }
        } else {
            revert("executionDelegate address is wrong.");
        }
    }

    function decodeERC721Pair(bytes memory data)
        internal
        pure
        returns (IDelegate.ERC721Pair[] memory)
    {
        return abi.decode(data, (IDelegate.ERC721Pair[]));
    }

    function decodeERC1155Pair(bytes memory data)
        internal
        pure
        returns (IDelegate.ERC1155Pair[] memory)
    {
        return abi.decode(data, (IDelegate.ERC1155Pair[]));
    }

    // modifies `src`
    function _arrayReplace(
        bytes memory src,
        bytes memory replacement,
        bytes memory mask
    ) internal pure {
        require(src.length == replacement.length);
        require(src.length == mask.length);

        for (uint256 i = 0; i < src.length; i++) {
            if (mask[i] != 0) {
                src[i] = replacement[i];
            }
        }
    }
}
