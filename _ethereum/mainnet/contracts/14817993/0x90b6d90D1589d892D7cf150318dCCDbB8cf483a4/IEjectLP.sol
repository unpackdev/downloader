// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "./IUniswapV3Pool.sol";
import "./INonfungiblePositionManager.sol";
import "./IPokeMe.sol";
import "./SEject.sol";

interface IEjectLP {
    function cancel(uint256 tokenId_, Order memory order_) external;

    function schedule(OrderParams memory orderParams_) external payable;

    function ejectOrSettle(
        uint256 tokenId_,
        Order memory order_,
        bool isEjection_
    ) external;

    function hashById(uint256 tokenId_) external view returns (bytes32);

    function factory() external view returns (address);

    function pokeMe() external view returns (IPokeMe);

    function nftPositionManager()
        external
        view
        returns (INonfungiblePositionManager);

    function isEjectable(
        uint256 tokenId_,
        Order memory order_,
        IUniswapV3Pool pool_
    ) external view returns (bool, string memory);

    function isExpired(Order memory order_)
        external
        view
        returns (bool, string memory);

    function isBurnt(uint256 tokenId_)
        external
        view
        returns (bool, string memory);

    function isNotApproved(uint256 tokenId_)
        external
        view
        returns (bool, string memory);

    function ownerHasChanged(uint256 tokenId_, address owner_)
        external
        view
        returns (bool, string memory);
}
