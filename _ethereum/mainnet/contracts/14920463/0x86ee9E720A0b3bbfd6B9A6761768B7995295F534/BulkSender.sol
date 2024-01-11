// SPDX-License-Identifier: MIT
// https://0xinside.xyz
// Twitter: @0xInside

pragma solidity ^0.8.13;

import "./SafeERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

contract BulkSender {
    using SafeERC20 for IERC20;

    struct TokenDetails {
        address[] tokens;
        uint256[] amounts;
        uint256 ethAmount;
        address recipient;
    }

    struct ERC721Details {
        address token;
        uint256[] ids;
        address[] recipients;
    }

    struct ERC1155Details {
        address token;
        uint256[] ids;
        uint256[] amounts;
        address[] recipients;
    }

    function divide(address[] calldata addresses) external payable {
        for (uint256 i = 0; i < addresses.length; i++) {
            payable(addresses[i]).transfer(msg.value / addresses.length);
        }
        payable(msg.sender).transfer(address(this).balance);
    }

    function send(address[] calldata addresses, uint256[] calldata amounts) external payable {
        for (uint256 i = 0; i < addresses.length; i++) {
            payable(addresses[i]).transfer(amounts[i]);
        }
        payable(msg.sender).transfer(address(this).balance);
    }

    function divideToken(IERC20 token, address[] calldata addresses, uint256 amount) external {
        for (uint256 i = 0; i < addresses.length; i++) {
            token.safeTransferFrom(msg.sender, addresses[i], amount / addresses.length);
        }
    }

    function sendToken(IERC20 token, address[] calldata addresses, uint256[] calldata amounts) external {
        for (uint256 i = 0; i < addresses.length; i++) {
            token.safeTransferFrom(msg.sender, addresses[i], amounts[i]);
        }
    }

    function execute(TokenDetails[] memory tokenDetails, ERC721Details[] memory erc721Details, ERC1155Details[] memory erc1155Details) external payable {
        for (uint256 i = 0; i < tokenDetails.length; i++) {
            if (tokenDetails[i].ethAmount > 0) payable(tokenDetails[i].recipient).transfer(tokenDetails[i].ethAmount);
            for (uint256 j = 0; j < tokenDetails[i].tokens.length; j++) {
                IERC20(tokenDetails[i].tokens[j]).safeTransferFrom(
                    msg.sender, 
                    tokenDetails[i].recipient, 
                    tokenDetails[i].amounts[j]
                );
            }
        }

        for (uint256 i = 0; i < erc721Details.length; i++) {
            for (uint256 j = 0; j < erc721Details[i].ids.length; j++) {
                IERC721(erc721Details[i].token).transferFrom(
                    msg.sender, 
                    erc721Details[i].recipients[j], 
                    erc721Details[i].ids[j]
                );
            }
        }

        for (uint256 i = 0; i < erc1155Details.length; i++) {
            for (uint256 j = 0; j < erc1155Details[i].ids.length; j++) {
                IERC1155(erc1155Details[i].token).safeTransferFrom(
                    msg.sender, 
                    erc1155Details[i].recipients[j], 
                    erc1155Details[i].ids[j], 
                    erc1155Details[i].amounts[j], 
                    ""
                );
            }
        }

        payable(msg.sender).transfer(address(this).balance);
    }
}