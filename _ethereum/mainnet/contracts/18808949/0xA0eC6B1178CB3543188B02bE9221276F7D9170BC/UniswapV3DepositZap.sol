// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "./IERC1155UniswapV3Wrapper.sol";
import "./IPoolAddressesProvider.sol";
import "./INonfungiblePositionManager.sol";
import "./IERC721Receiver.sol";
import "./IERC1155Receiver.sol";
import "./IPool.sol";

/// @author YLDR <admin@apyflow.com>
contract UniswapV3DepositZap is IERC721Receiver, IERC1155Receiver {
    error InvalidCaller();

    IERC1155UniswapV3Wrapper public immutable positionWrapper;
    INonfungiblePositionManager public immutable positionManager;
    IPool public immutable pool;
    address public immutable nToken;

    constructor(IPoolAddressesProvider _addressesProvider, IERC1155UniswapV3Wrapper _positionWrapper) {
        pool = IPool(_addressesProvider.getPool());
        nToken = pool.getERC1155ReserveData(address(_positionWrapper)).nTokenAddress;
        positionWrapper = _positionWrapper;
        positionManager = _positionWrapper.positionManager();

        positionWrapper.setApprovalForAll(address(pool), true);
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata)
        public
        virtual
        override
        returns (bytes4)
    {
        if (msg.sender != address(positionManager)) revert InvalidCaller();

        positionManager.safeTransferFrom(address(this), address(positionWrapper), tokenId);
        pool.supplyERC1155({
            asset: address(positionWrapper),
            tokenId: tokenId,
            amount: positionWrapper.balanceOf(address(this), tokenId),
            onBehalfOf: from,
            referralCode: 0
        });
        return this.onERC721Received.selector;
    }

    function _processNToken(uint256 tokenId, uint256 amount, address from) internal {
        pool.withdrawERC1155({asset: address(positionWrapper), tokenId: tokenId, amount: amount, to: address(this)});

        if (amount == positionWrapper.totalSupply(tokenId)) {
            positionWrapper.unwrap(address(this), tokenId, from);
        } else {
            positionWrapper.burn(address(this), tokenId, amount, from);
        }
    }

    function onERC1155Received(address, address from, uint256 tokenId, uint256 amount, bytes calldata)
        public
        virtual
        override
        returns (bytes4)
    {
        if (msg.sender == address(positionWrapper)) {
            return this.onERC1155Received.selector;
        } else if (msg.sender == nToken) {
            _processNToken(tokenId, amount, from);
            return this.onERC1155Received.selector;
        } else {
            revert InvalidCaller();
        }
    }

    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata
    ) external returns (bytes4) {
        if (msg.sender == address(positionWrapper)) {
            return this.onERC1155Received.selector;
        } else if (msg.sender == nToken) {
            for (uint256 i = 0; i < ids.length; i++) {
                _processNToken(ids[i], values[i], from);
            }
            return this.onERC1155Received.selector;
        } else {
            revert InvalidCaller();
        }
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId;
    }
}
