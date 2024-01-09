// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./INFTXVault.sol";
import "./INFTXVaultFactory.sol";
import "./INFTXFeeDistributor.sol";
import "./INFTXLPStaking.sol";
import "./ITimelockRewardDistributionToken.sol";
import "./IUniswapV2Router01.sol";
import "./IERC721.sol";
import "./IERC1155Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./OwnableUpgradeable.sol";

// Authors: @0xKiwi_.
abstract contract IWETH {
  function deposit() virtual external payable;
  function transfer(address to, uint value) virtual external returns (bool);
  function withdraw(uint) virtual external;
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

abstract contract INFTXStakingZap is IERC721ReceiverUpgradeable, IERC1155ReceiverUpgradeable {
  IWETH public immutable WETH; 
  INFTXLPStaking public immutable lpStaking;
  INFTXVaultFactory public immutable nftxFactory;
  IUniswapV2Router01 public immutable sushiRouter;
  uint256 public lockTime;

  constructor(address _nftxFactory, address _sushiRouter) {
    nftxFactory = INFTXVaultFactory(_nftxFactory);
    lpStaking = INFTXLPStaking(INFTXFeeDistributor(INFTXVaultFactory(_nftxFactory).feeDistributor()).lpStaking());
    sushiRouter = IUniswapV2Router01(_sushiRouter);
    WETH = IWETH(IUniswapV2Router01(_sushiRouter).WETH());
    IERC20Upgradeable(address(IUniswapV2Router01(_sushiRouter).WETH())).approve(_sushiRouter, type(uint256).max);
  }

  function setLockTime(uint256 newLockTime) virtual external;

  function addLiquidity721ETH(
    uint256 vaultId, 
    uint256[] memory ids, 
    uint256 minWethIn
  ) virtual external payable returns (uint256);

  function addLiquidity721ETHTo(
    uint256 vaultId, 
    uint256[] memory ids, 
    uint256 minWethIn,
    address to
  ) virtual external payable returns (uint256);

  function addLiquidity1155ETH(
    uint256 vaultId, 
    uint256[] memory ids, 
    uint256[] memory amounts,
    uint256 minEthIn
  ) virtual external payable returns (uint256);

  function addLiquidity1155ETHTo(
    uint256 vaultId, 
    uint256[] memory ids, 
    uint256[] memory amounts,
    uint256 minEthIn,
    address to
  ) virtual external payable returns (uint256);

  function addLiquidity721(
    uint256 vaultId, 
    uint256[] memory ids, 
    uint256 minWethIn,
    uint256 wethIn
  ) virtual external returns (uint256);

  function addLiquidity721To(
    uint256 vaultId, 
    uint256[] memory ids, 
    uint256 minWethIn,
    uint256 wethIn,
    address to
  ) virtual external returns (uint256);

  function addLiquidity1155(
    uint256 vaultId, 
    uint256[] memory ids,
    uint256[] memory amounts,
    uint256 minWethIn,
    uint256 wethIn
  ) virtual external returns (uint256);

  function addLiquidity1155To(
    uint256 vaultId, 
    uint256[] memory ids,
    uint256[] memory amounts,
    uint256 minWethIn,
    uint256 wethIn,
    address to
  ) virtual external returns (uint256);

  function lockedUntil(uint256 vaultId, address who) virtual external view returns (uint256);

  function lockedLPBalance(uint256 vaultId, address who) virtual external view returns (uint256);

  receive() virtual external payable;
}
