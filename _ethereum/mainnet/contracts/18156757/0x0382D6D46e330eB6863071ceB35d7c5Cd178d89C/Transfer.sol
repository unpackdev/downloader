// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author kien-ngo
/// This contract is a simplification of thirdweb's Airdrop contracts
/// It can only allow you to transfer tokens to a SINGLE wallet instead of multiple
/// It should work perfectly with thirdweb's Gasless Extension
/// Also there is no event being emitted should an operation fail
/// With such limitation, it costs less gas to transfer and useful for when you want to perform batch transfer to a single recipient

import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./ERC2771ContextUpgradeable.sol";

contract Transfer is Initializable, ERC2771ContextUpgradeable {
    constructor() initializer {}

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address[] memory _trustedForwarders
    ) external initializer {
        __ERC2771Context_init_unchained(_trustedForwarders);
    }

    /// @dev See ERC2771
    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /// @dev See ERC2771
    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    /// ERC721

    /// This function uses `transferFrom` and NOT `safeTransferFrom`
    function transferERC721(
        address _tokenAddress,
        address _tokenOwner,
        address _recipient,
        uint256[] calldata _tokenIds
    ) external {
        uint256 len = _tokenIds.length;
        uint256 i;
        do {
            IERC721(_tokenAddress).transferFrom(
                _tokenOwner,
                _recipient,
                _tokenIds[i]
            );
            unchecked {
                ++i;
            }
        } while (i < len);
    }

    /// This function uses `safeTransferFrom` and NOT `transferFrom`
    function safeTransferERC721(
        address _tokenAddress,
        address _tokenOwner,
        address _recipient,
        uint256[] calldata _tokenIds
    ) external {
        uint256 len = _tokenIds.length;
        uint256 i;
        do {
            IERC721(_tokenAddress).safeTransferFrom(
                _tokenOwner,
                _recipient,
                _tokenIds[i]
            );
            unchecked {
                ++i;
            }
        } while (i < len);
    }

    /// ERC1155
    function transferERC1155(
        address _tokenAddress,
        address _tokenOwner,
        address _recipient,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external {
        uint256 _idLength = _tokenIds.length;
        require(_idLength == _amounts.length, "Length not match");
        uint256 i;
        do {
            IERC1155(_tokenAddress).safeTransferFrom(
                _tokenOwner,
                _recipient,
                _tokenIds[i],
                _amounts[i],
                ""
            );
            unchecked {
                ++i;
            }
        } while (i < _idLength);
    }

    /// ERC20

    /// This function uses `tranfer` and NOT `transferFrom`
    function transferERC20(
        address _tokenAddress,
        address _recipient,
        uint256 _amount
    ) external {
        IERC20(_tokenAddress).transfer(_recipient, _amount);
    }

    /// This function uses `tranferFrom` and NOT `transfer`
    function transferFromERC20(
        address _tokenAddress,
        address _tokenOwner,
        address _recipient,
        uint256 _amount
    ) external {
        IERC20(_tokenAddress).transferFrom(_tokenOwner, _recipient, _amount);
    }

    /// Seems unecessary to include this function. Because if a wallet's private key is leaked, the wallet should be drained and there will be no native token left
    /// If for some reason there are some native tokens left behind, the owner can just send it away using their own wallet
    // function transferNativeToken(address _recipient, uint256 _amount) external {
    //     _recipient.call{value: _amount}("");
    // }
}
