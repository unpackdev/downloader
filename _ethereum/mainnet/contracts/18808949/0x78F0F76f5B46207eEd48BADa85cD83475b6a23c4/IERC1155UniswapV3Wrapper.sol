// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import "./IERC1155Supply.sol";
import "./INonfungiblePositionManager.sol";
import "./IUniswapV3Factory.sol";
import "./IUniswapV3Pool.sol";
import "./IERC721Receiver.sol";

interface IERC1155UniswapV3Wrapper is IERC721Receiver, IERC1155Supply {
    error OnlyPositionManager();

    function positionManager() external view returns (INonfungiblePositionManager);

    function factory() external view returns (IUniswapV3Factory);

    function initialize(INonfungiblePositionManager _positionManager) external;

    function getPendingFees(uint256 tokenId) external view returns (uint256 amount0, uint256 amount1);

    function burn(address account, uint256 tokenId, uint256 value, address recipient)
        external
        returns (uint256 amount0, uint256 amount1);

    function unwrap(address account, uint256 tokenId, address recipient) external;
}
