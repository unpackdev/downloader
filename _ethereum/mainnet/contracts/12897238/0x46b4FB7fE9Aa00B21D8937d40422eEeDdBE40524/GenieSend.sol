// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./SpecialTransferHelper.sol";

contract GenieSend is SpecialTransferHelper {

    struct ERC20Details {
        address[] tokenAddrs;
        uint256[] amounts;
    }

    struct ERC721SendDetails {
        address tokenAddr;
        uint256[] ids;
    }

    struct ERC1155SendDetails {
        address tokenAddr;
        uint256[] ids;
        uint256[] amounts;
    }

    function transferERC20(
        ERC20Details memory erc20Details,
        address recipient
    ) public {
        // transfer ERC20 tokens from the sender to this contract
        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            require(
                IERC20(erc20Details.tokenAddrs[i]).transferFrom(
                    _msgSender(),
                    recipient,
                    erc20Details.amounts[i]
                ),
                "transferERC20: transfer failed"
            );
        }
    }

    function transferERC721(
        ERC721SendDetails[] memory erc721Details,
        address recipient
    ) public {
        for (uint256 i = 0; i < erc721Details.length; i++) {
            // accept CryptoPunks
            if (erc721Details[i].tokenAddr == 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB) {
                address[] memory _to = new address[](1);
                _to[0] = recipient;
                
                _acceptCryptoPunk(
                    ERC721Details(
                        erc721Details[i].tokenAddr,
                        _to,
                        erc721Details[i].ids
                    )
                );
                
                _transferCryptoPunk(
                    ERC721Details(
                        erc721Details[i].tokenAddr,
                        _to,
                        erc721Details[i].ids
                    )
                );
            }
            // accept Mooncat
            else if (erc721Details[i].tokenAddr == 0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6) {
                address[] memory _to = new address[](1);
                _to[0] = recipient;

                _acceptMoonCat(
                    ERC721Details(
                        erc721Details[i].tokenAddr,
                        _to,
                        erc721Details[i].ids
                    )
                );
                
                _transferMoonCat(
                    ERC721Details(
                        erc721Details[i].tokenAddr,
                        _to,
                        erc721Details[i].ids
                    )
                );
            }
            // default
            else {
                for (uint256 j = 0; j < erc721Details[i].ids.length; j++) {
                    IERC721(erc721Details[i].tokenAddr).transferFrom(
                        msg.sender,
                        recipient,
                        erc721Details[i].ids[j]
                    );
                }
            }
        }
    }

    function transferERC1155(
        ERC1155SendDetails[] memory erc1155Details, 
        address recipient
    ) public {
        for (uint256 i = 0; i < erc1155Details.length; i++) {
            IERC1155(erc1155Details[i].tokenAddr).safeBatchTransferFrom(
                msg.sender,
                recipient,
                erc1155Details[i].ids,
                erc1155Details[i].amounts,
                ""
            );
        }
    }

    function _transferEth(address _recipient) internal {
        if (address(this).balance > 0) {
            (bool success, ) = _recipient.call{value: address(this).balance}('');
            require(success, "_transferEth: Eth transfer failed");
        }
    }

    function transferAssets(
        ERC20Details memory erc20Details,
        ERC721SendDetails[] memory erc721Details,
        ERC1155SendDetails[] memory erc1155Details,
        address recipient
    ) external payable {
        _transferEth(recipient);
        transferERC20(erc20Details, recipient);
        transferERC721(erc721Details, recipient);
        transferERC1155(erc1155Details, recipient);
    }
}