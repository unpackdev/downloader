// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC20.sol";

/// @title Airdrop Helper
/// @author metacrypt.org
contract AirdropHelper {
    function dispatchERC721(
        address _token,
        address[] memory _receivers,
        uint256[] memory _ids
    ) public {
        IERC721 tokToken = IERC721(_token);
        for (uint256 i = 0; i < _receivers.length; i++) {
            tokToken.transferFrom(msg.sender, _receivers[i], _ids[i]);
        }
    }

    function dispatchERC1155(
        address _token,
        address[] memory _receivers,
        uint256[] memory _ids,
        uint256[] memory _qty
    ) public {
        IERC1155 tokToken = IERC1155(_token);
        for (uint256 i = 0; i < _receivers.length; i++) {
            tokToken.safeTransferFrom(msg.sender, _receivers[i], _ids[i], _qty[i], "");
        }
    }

    function dispatchERC20(
        address _token,
        address[] memory _receivers,
        uint256[] memory _values
    ) public {
        IERC20 tokToken = IERC20(_token);
        for (uint256 i = 0; i < _receivers.length; i++) {
            tokToken.transferFrom(msg.sender, _receivers[i], _values[i]);
        }
    }
}
