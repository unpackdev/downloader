// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MarketRegistry.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
//import "./console.sol";

library OKXSeaportLib {

    using SafeERC20 for IERC20;

    address constant private OPENSEA_CONDUIT = 0x1E0049783F008A0085193E00003D00cd54003c71;

    bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;

    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;

    function buyAssetForETH(bytes calldata _calldata,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        address payToken,
        uint256 payAmount) external {

        address payable seaport = payable(
            0x00000000006c3852cbEf3e08E8dF289169EdE581
        );

        //console.log("balance %s", address(this).balance);

        (bool success, ) =  seaport.call{value: payAmount}(_calldata);

        require(success, "Seaport buy failed");
    }


    function buyAssetForERC20(bytes calldata _calldata,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        address payToken,
        uint256 payAmount) external {

        IERC20(payToken).safeTransferFrom(msg.sender,
            address(this),
            payAmount
        );
        //console.log("balance %s",  IERC20(payToken).balanceOf(address (this)));
         IERC20(payToken).safeApprove(OPENSEA_CONDUIT, payAmount);
        //IERC721(tokenAddress).setApprovalForAll(address(0x1E0049783F008A0085193E00003D00cd54003c71),true);
        address payable seaport = payable(
            0x00000000006c3852cbEf3e08E8dF289169EdE581
        );

        (bool success, ) =  seaport.call(_calldata);

        require(success, "Seaport buy failed");
        // revoke approval
        IERC20(payToken).safeApprove(OPENSEA_CONDUIT, 0);
    }


    function takeOfferForERC20(bytes calldata _calldata,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        address payToken,
        uint256 payAmount) external {

        address payable seaport = payable(
            0x00000000006c3852cbEf3e08E8dF289169EdE581
        );

        _tranferNFT(tokenAddress, msg.sender, address(this), tokenId, amount);


          // both ERC721 and ERC1155 share the same `setApprovalForAll` method.
        IERC721(tokenAddress).setApprovalForAll(OPENSEA_CONDUIT, true);
        IERC20(payToken).safeApprove(OPENSEA_CONDUIT, type(uint256).max);

       (bool success, ) = seaport.call(_calldata);

       require(success, "Seaport accept offer failed");

       SafeERC20.safeTransfer(
           IERC20(payToken),
           msg.sender,
           IERC20(payToken).balanceOf(address(this))
       );

       // revoke approval.
       IERC721(tokenAddress).setApprovalForAll(OPENSEA_CONDUIT, false);
       IERC20(payToken).safeApprove(OPENSEA_CONDUIT, 0);

    }

    function _tranferNFT(
        address tokenAddress,
        address from,
        address recipient,
        uint256 tokenId,
        uint256 amount
    ) internal {

        if (IERC165(tokenAddress).supportsInterface(IID_IERC1155)) {
            IERC1155(tokenAddress).safeTransferFrom(
                from,
                recipient,
                tokenId,
                amount,
                ""
            );
        }else if (IERC165(tokenAddress).supportsInterface(IID_IERC721)) {
            IERC721(tokenAddress).safeTransferFrom(
                from,
                recipient,
                tokenId
            );
        } else {
            revert("Unsupported interface");
        }
    }

}
