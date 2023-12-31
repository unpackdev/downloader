// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./IDittoPool.sol";
import "./DittoPoolMain.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";
import { ReentrancyGuard } from
    "../../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import { EnumerableSet } from
    "../../lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import { EnumerableMap } from
    "../../lib/openzeppelin-contracts/contracts/utils/structs/EnumerableMap.sol";

/**
 * @title DittoPool
 * @notice Parent contract defines common functions for DittoPool AMM shared liquidity trading pools.
 */
abstract contract DittoPoolMarketMake is DittoPoolMain {
    using SafeTransferLib for ERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToUintMap;

    // ***************************************************************
    // * ========================= EVENTS ========================== *
    // ***************************************************************

    event DittoPoolMarketMakeLiquidityAdded(
        address liquidityProvider, 
        uint256 lpId, 
        uint256[] tokenIds, 
        uint256 tokenDepositAmount,
        bytes referrer
    );
    event DittoPoolMarketMakeLiquidityCreated(
        address liquidityProvider, 
        uint256 lpId, 
        uint256[] tokenIds, 
        uint256 tokenDepositAmount,
        address initialPositionTokenOwner,
        bytes referrer
    );
    event DittoPoolMarketMakeLiquidityRemoved(
        uint256 lpId, 
        uint256[] nftIds, 
        uint256 tokenWithdrawAmount
    );

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************
    error DittoPoolMarketMakeMustDepositLiquidity();
    error DittoPoolMarketMakeWrongPoolForLpId();
    error DittoPoolMarketMakeNotAuthorizedForLpId();
    error DittoPoolMarketMakeInsufficientBalance();
    error DittoPoolMarketMakeInvalidNftTokenId();
    error DittoPoolMarketMakeOneLpPerPrivatePool();

    // ***************************************************************
    // * ======= FUNCTIONS TO MARKET MAKE: ADD LIQUIDITY =========== *
    // ***************************************************************

    ///@inheritdoc IDittoPool
    function createLiquidity(
        address lpRecipient_,
        uint256[] calldata nftIdList_,
        uint256 tokenDepositAmount_,
        bytes calldata permitterData_,
        bytes calldata referrer_
    ) external nonReentrant returns (uint256 lpId) {
        if (tokenDepositAmount_ == 0 && nftIdList_.length == 0) {
            revert DittoPoolMarketMakeMustDepositLiquidity();
        }
        lpId = _lpNft.mint(lpRecipient_);
        if(_isPrivatePool) {
            if(_privatePoolOwnerLpId != 0) {
                revert DittoPoolMarketMakeOneLpPerPrivatePool();
            } else {
                _privatePoolOwnerLpId = lpId;
            }
        }
        _lpIdToTokenBalance.set(lpId, 0); // tracking full set of lpIds for this pool
        _transferInLiquidity(lpId, nftIdList_, tokenDepositAmount_, permitterData_);

        emit DittoPoolMarketMakeLiquidityCreated(msg.sender, lpId, nftIdList_, tokenDepositAmount_, lpRecipient_, referrer_);
    }

    ///@inheritdoc IDittoPool
    function addLiquidity(
        uint256 lpId_,
        uint256[] calldata nftIdList_,
        uint256 tokenDepositAmount_,
        bytes calldata permitterData_,
        bytes calldata referrer_
    ) external nonReentrant {
        if(_isPrivatePool){
            _onlyOwner();
            if(_privatePoolOwnerLpId != lpId_){
                revert DittoPoolMarketMakeOneLpPerPrivatePool();
            }
        }
        if (tokenDepositAmount_ == 0 && nftIdList_.length == 0) {
            revert DittoPoolMarketMakeMustDepositLiquidity();
        }
        if (address(_lpNft.getPoolForLpId(lpId_)) != address(this)) {
            revert DittoPoolMarketMakeWrongPoolForLpId();
        }
        _transferInLiquidity(lpId_, nftIdList_, tokenDepositAmount_, permitterData_);

        emit DittoPoolMarketMakeLiquidityAdded(msg.sender, lpId_, nftIdList_, tokenDepositAmount_, referrer_);
    }

    /**
     * @notice Helper function to deposits NFTS+ERC20 liquidity into the pool. See the external function documentation.
     * @dev If the msg.sender has not set approvals for this contract then the transaction will fail.
     */
    function _transferInLiquidity(
        uint256 lpId_,
        uint256[] calldata nftIdList_,
        uint256 tokenDepositAmount_,
        bytes calldata permitterData_
    ) internal {
        uint256 nftId;
        uint256 countNftIds = nftIdList_.length;

        // TRANSFER IN NFT LIQUIDITY
        if (countNftIds > 0) {
            _checkPermittedTokens(nftIdList_, permitterData_);

            for (uint256 i = 0; i < countNftIds;) {
                nftId = nftIdList_[i];
                _nft.transferFrom(msg.sender, address(this), nftId);
                _poolOwnedNftIds.add(nftId);
                _nftIdToLpId[nftId] = lpId_;

                unchecked {
                    ++i;
                }
            }

            _lpIdToNftBalance[lpId_] += countNftIds;
            _nftLiquidityAdded(countNftIds);
        }

        // TRANSFER IN TOKEN LIQUIDITY
        if (tokenDepositAmount_ > 0) {
            _token.transferFrom(msg.sender, address(this), tokenDepositAmount_);

            (, uint256 currentTokenBalance) = _lpIdToTokenBalance.tryGet(lpId_);
            _lpIdToTokenBalance.set(lpId_, currentTokenBalance + tokenDepositAmount_);
            _tokenLiquidityAdded(tokenDepositAmount_);
        }
    }

    // ***************************************************************
    // * ===== FUNCTIONS TO MARKET MAKE: REMOVE LIQUIDITY ========== *
    // ***************************************************************

    ///@inheritdoc IDittoPool
    function pullLiquidity(
        address withdrawalAddress_,
        uint256 lpId_,
        uint256[] calldata nftIdList_,
        uint256 tokenWithdrawAmount_
    ) external nonReentrant {
        // CHECK INPUTS
        (IDittoPool pool, address lpNftOwner) = _lpNft.getPoolAndOwnerForLpId(lpId_);
        if (address(pool) != address(this)) {
            revert DittoPoolMarketMakeWrongPoolForLpId();
        }
        if (lpNftOwner != msg.sender && !_lpNft.isApproved(msg.sender, lpId_)) {
            revert DittoPoolMarketMakeNotAuthorizedForLpId();
        }

        // TRANSFER OUT NFT LIQUIDITY
        {
            uint256 countNftIds = nftIdList_.length;
            for (uint256 i = 0; i < countNftIds;) {
                uint256 nftId = nftIdList_[i];
                if (_nftIdToLpId[nftId] != lpId_) {
                    revert DittoPoolMarketMakeInvalidNftTokenId();
                }

                _nft.safeTransferFrom(address(this), withdrawalAddress_, nftId);

                _poolOwnedNftIds.remove(nftId);
                delete _nftIdToLpId[nftId];

                unchecked {
                    ++i;
                }
            }

            _lpIdToNftBalance[lpId_] -= countNftIds;
            _nftLiquidityRemoved(countNftIds);
        }

        // TRANSFER OUT TOKEN LIQUIDITY
        (, uint256 currentTokenBalance) = _lpIdToTokenBalance.tryGet(lpId_);
        if (tokenWithdrawAmount_ > 0) {
            if (tokenWithdrawAmount_ > currentTokenBalance) {
                revert DittoPoolMarketMakeInsufficientBalance();
            }

            _token.safeTransfer(withdrawalAddress_, tokenWithdrawAmount_);

            currentTokenBalance -= tokenWithdrawAmount_;
            _lpIdToTokenBalance.set(lpId_, currentTokenBalance);

            _tokenLiquidityRemoved(tokenWithdrawAmount_);
        }

        // HANDLE LP POSITION BURNING
        if (_lpIdToNftBalance[lpId_] == 0 && currentTokenBalance == 0) {
            _lpNft.burn(lpId_);
            _lpIdToTokenBalance.remove(lpId_); // tracking full set of lpIds for this pool
        }

        emit DittoPoolMarketMakeLiquidityRemoved(lpId_, nftIdList_, tokenWithdrawAmount_);
    }
}
