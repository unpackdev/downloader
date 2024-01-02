// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {ERC1155SupplyUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "./INonfungiblePositionManager.sol";
import "./IUniswapV3Factory.sol";
import "./IUniswapV3Pool.sol";
import "./FullMath.sol";
import "./PositionKey.sol";
import "./UniswapV3Position.sol";
import "./IERC1155UniswapV3Wrapper.sol";

contract ERC1155UniswapV3Wrapper is ERC1155SupplyUpgradeable, IERC1155UniswapV3Wrapper {
    using UniswapV3Position for UniswapV3Position.UniswapV3PositionData;

    INonfungiblePositionManager public positionManager;
    IUniswapV3Factory public factory;

    function initialize(INonfungiblePositionManager _positionManager) public initializer {
        __ERC1155_init("");
        positionManager = _positionManager;
        factory = IUniswapV3Factory(_positionManager.factory());
    }

    function onERC721Received(address operator, address, uint256 tokenId, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        if (_msgSender() != address(positionManager)) revert OnlyPositionManager();
        _mint(operator, tokenId, 10 ** 18, data);
        return IERC721Receiver.onERC721Received.selector;
    }

    function getPendingFees(uint256 tokenId) public view returns (uint256 amount0, uint256 amount1) {
        UniswapV3Position.UniswapV3PositionData memory position = _getPosition(tokenId);
        return position.getPendingFees();
    }

    function _getPosition(uint256 tokenId)
        internal
        view
        returns (UniswapV3Position.UniswapV3PositionData memory cache)
    {
        return UniswapV3Position.get(positionManager, factory, tokenId);
    }

    function burn(address account, uint256 tokenId, uint256 value, address recipient)
        public
        returns (uint256 amount0, uint256 amount1)
    {
        if (account != _msgSender() && !isApprovedForAll(account, _msgSender())) {
            revert ERC1155MissingApprovalForAll(_msgSender(), account);
        }

        uint256 _totalSupply = totalSupply(tokenId);

        _burn(account, tokenId, value);

        UniswapV3Position.UniswapV3PositionData memory position = _getPosition(tokenId);

        (uint256 fees0, uint256 fees1) = position.getPendingFees();

        (amount0, amount1) = positionManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: uint128(position.liquidity * value / _totalSupply),
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );

        amount0 += fees0 * value / _totalSupply;
        amount1 += fees1 * value / _totalSupply;

        positionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: recipient,
                amount0Max: uint128(amount0),
                amount1Max: uint128(amount1)
            })
        );
    }

    function unwrap(address account, uint256 tokenId, address recipient) public {
        if (account != _msgSender() && !isApprovedForAll(account, _msgSender())) {
            revert ERC1155MissingApprovalForAll(_msgSender(), account);
        }

        _burn(account, tokenId, totalSupply(tokenId));

        positionManager.safeTransferFrom(address(this), recipient, tokenId, "");
    }

    /// @inheritdoc ERC1155SupplyUpgradeable
    function totalSupply(uint256 id) public view override(ERC1155SupplyUpgradeable, IERC1155Supply) returns (uint256) {
        return ERC1155SupplyUpgradeable.totalSupply(id);
    }

    /// @inheritdoc ERC1155SupplyUpgradeable
    function totalSupply() public view override(ERC1155SupplyUpgradeable, IERC1155Supply) returns (uint256) {
        return ERC1155SupplyUpgradeable.totalSupply();
    }

    /// @inheritdoc ERC1155SupplyUpgradeable
    function exists(uint256 id) public view override(ERC1155SupplyUpgradeable, IERC1155Supply) returns (bool) {
        return ERC1155SupplyUpgradeable.exists(id);
    }
}
