//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC1155.sol";
import "./IERC20.sol";
import "./IERC721.sol";

contract Distribute {
    function distributeSingleERC721(
        IERC721 _contract,
        address[] calldata _recipients,
        uint256[] calldata _tokenIds
    ) external {
        uint256 length = _recipients.length;
        require(length == _tokenIds.length, "Input lengths must be equal");

        for (uint256 i = 0; i < length; ++i) {
            _contract.transferFrom(msg.sender, _recipients[i], _tokenIds[i]);
        }
    }

    function distributeERC721(
        IERC721[] calldata _contracts,
        address[][] calldata _recipients,
        uint256[][] calldata _tokenIds
    ) external {
        uint256 length = _contracts.length;
        require(
            length == _recipients.length && length == _tokenIds.length,
            "Input lengths must be equal"
        );

        for (uint256 i = 0; i < length; ++i) {
            uint256 innerLength = _recipients[i].length;
            require(
                innerLength == _tokenIds[i].length,
                "Input lengths must be equal"
            );

            for (uint256 j = 0; j < innerLength; ++j) {
                _contracts[i].transferFrom(
                    msg.sender,
                    _recipients[i][j],
                    _tokenIds[i][j]
                );
            }
        }
    }

    function distributeSingleERC1155(
        IERC1155 _contract,
        address[] calldata _recipients,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external {
        uint256 length = _recipients.length;
        require(
            length == _tokenIds.length && length == _amounts.length,
            "Input lengths must be equal"
        );

        for (uint256 i = 0; i < length; ++i) {
            _contract.safeTransferFrom(
                msg.sender,
                _recipients[i],
                _tokenIds[i],
                _amounts[i],
                _data
            );
        }
    }

    function distributeERC1155(
        IERC1155[] calldata _contracts,
        address[][] calldata _recipients,
        uint256[][] calldata _tokenIds,
        uint256[][] calldata _amounts,
        bytes[] calldata _data
    ) external {
        uint256 length = _contracts.length;
        require(
            length == _recipients.length &&
                length == _tokenIds.length &&
                length == _amounts.length,
            "Input lengths must be equal"
        );

        for (uint256 i = 0; i < length; ++i) {
            uint256 innerLength = _recipients[i].length;
            require(
                innerLength == _tokenIds[i].length &&
                    innerLength == _amounts[i].length,
                "Input lengths must be equal"
            );

            for (uint256 j = 0; j < innerLength; ++j) {
                _contracts[i].safeTransferFrom(
                    msg.sender,
                    _recipients[i][j],
                    _tokenIds[i][j],
                    _amounts[i][j],
                    _data[i]
                );
            }
        }
    }

    function distributeEther(
        address payable[] calldata recipients,
        uint256[] calldata values
    ) external payable {
        uint256 length = recipients.length;
        require(
            length == values.length,
            "Recipients and values length mismatch"
        );

        for (uint256 i = 0; i < length; ++i) {
            recipients[i].transfer(values[i]);
        }

        uint256 balance = address(this).balance;
        if (balance > 0) payable(msg.sender).transfer(balance);
    }

    function distributeToken(
        IERC20 token,
        address[] calldata recipients,
        uint256[] calldata values
    ) external {
        uint256 total = 0;
        uint256 length = recipients.length;
        for (uint256 i = 0; i < length; ++i) total += values[i];

        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < length; ++i) {
            require(token.transfer(recipients[i], values[i]));
        }
    }

    function distributeMultipleTokenSimple(
        IERC20[] calldata token,
        address[][] calldata _recipients,
        uint256[][] calldata _values
    ) external {
        uint256 length = _recipients.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 innerLength = _recipients[i].length;
            for (uint256 j = 0; j < innerLength; ++j) {
                require(
                    token[i].transferFrom(
                        msg.sender,
                        _recipients[i][j],
                        _values[i][j]
                    )
                );
            }
        }
    }

    function distributeTokenSimple(
        IERC20 token,
        address[] calldata recipients,
        uint256[] calldata values
    ) external {
        uint256 length = recipients.length;
        for (uint256 i = 0; i < length; ++i) {
            require(token.transferFrom(msg.sender, recipients[i], values[i]));
        }
    }
}
