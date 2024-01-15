// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./IERC721.sol";
import "./ERC20Burnable.sol";
import "./TransferHelper.sol";
import "./Ownable.sol";
import "./IErc721BurningErc20OnMint.sol";

enum SwapKind {
    GIVEN_IN,
    GIVEN_OUT
}

struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    address assetIn;
    address assetOut;
    uint256 amount;
    bytes userData;
}

struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
}

interface Vault {
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256 amountCalculated);
}

interface ERC721 {
    function mint() external returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract NftSwapProxy is Ownable {
    event Received(address, uint256);

    address public immutable vaultAddress;

    constructor(address _vaultAddress) {
        vaultAddress = _vaultAddress;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline,
        address nftContractAddress
    ) external payable returns (uint256 amountCalculated) {
        require(vaultAddress != address(0), "vaultAddress must be defined");
        require(nftContractAddress != address(0), "nftContractAddress must be defined");
        require(ERC20(singleSwap.assetOut).decimals() == 0, "assetOut must be a zero decimal token");

        //perform swap
        TransferHelper.safeTransferFrom(singleSwap.assetIn, msg.sender, address(this), singleSwap.amount);
        TransferHelper.safeApprove(singleSwap.assetIn, vaultAddress, singleSwap.amount);
        uint256 mintpassAmount = Vault(vaultAddress).swap{value: msg.value}(singleSwap, funds, limit, deadline);
        TransferHelper.safeApprove(singleSwap.assetOut, nftContractAddress, mintpassAmount);

        if (singleSwap.kind == SwapKind.GIVEN_OUT) {
            mintpassAmount = singleSwap.amount;
        }

        for (uint256 i = 0; i < mintpassAmount; i++) {
            //perform mint to the nft proxy
            uint256 tokenId = ERC721(nftContractAddress).mint();
            //transfer nft token to user
            ERC721(nftContractAddress).safeTransferFrom(address(this), msg.sender, tokenId);
        }
        return mintpassAmount;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
