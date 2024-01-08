//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Libraries
import "./SafeERC20.sol";

// Contracts
import "./StakingBase.sol";

// Interfaces
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Enumerable.sol";
import "./IERC20.sol";
import "./IMintableERC20.sol";
import "./IERC721Staking.sol";

contract ERC721Staking is StakingBase, IERC721Staking, IERC721Receiver {
    using SafeERC20 for IERC20;

    constructor(
        address settingsAddress,
        address outputAddress,
        address feeReceiverAddress,
        address tokenValuatorAddress,
        uint256 outputAmountPerBlock,
        uint256 startBlockNumber,
        uint256 bonusEndBlockNumber
    )
        public
        StakingBase(
            settingsAddress,
            outputAddress,
            feeReceiverAddress,
            tokenValuatorAddress,
            outputAmountPerBlock,
            startBlockNumber,
            bonusEndBlockNumber
        )
    {}

    function stake(uint256 pid, uint256 id)
        external
        override
        existPool(pid)
        whenPlatformIsNotPaused()
        whenPoolIsNotPaused(pid)
        onlyEOAIfSet(msg.sender)
    {
        _stake(pid, id);
    }

    function stakeAll(uint256 pid, uint256[] calldata ids)
        external
        override
        existPool(pid)
        whenPlatformIsNotPaused()
        whenPoolIsNotPaused(pid)
        onlyEOAIfSet(msg.sender)
    {
        require(ids.length > 0, "TOKEN_IDS_REQUIRED");
        for (uint256 indexAt = 0; indexAt < ids.length; indexAt++) {
            _stake(pid, ids[indexAt]);
        }
    }

    function stakeAll(uint256 pid)
        external
        override
        existPool(pid)
        whenPlatformIsNotPaused()
        whenPoolIsNotPaused(pid)
        onlyEOAIfSet(msg.sender)
    {
        PoolInfoLib.PoolInfo storage pool = poolInfo[pid];
        uint256 userBalance = IERC721Enumerable(pool.token).balanceOf(msg.sender);
        require(userBalance > 0, "USER_HASNT_STAKED_TOKENS");
        for (uint256 indexAt = 0; indexAt < userBalance; indexAt++) {
            _stake(
                pid,
                IERC721Enumerable(pool.token).tokenOfOwnerByIndex(
                    msg.sender,
                    userBalance.sub(1).sub(indexAt)
                )
            );
        }
    }

    function unstake(uint256 pid, uint256 id)
        external
        override
        existPool(pid)
        whenPlatformIsNotPaused()
        whenPoolIsNotPaused(pid)
        onlyEOAIfSet(msg.sender)
    {
        _unstake(pid, id);
    }

    function unstakeAll(uint256 pid)
        external
        override
        existPool(pid)
        whenPlatformIsNotPaused()
        whenPoolIsNotPaused(pid)
        onlyEOAIfSet(msg.sender)
    {
        UserInfoLib.UserInfo storage user = userInfo[pid][msg.sender];
        uint256[] memory tokenIDs = user.getTokenIds();
        require(tokenIDs.length > 0, "USER_HASNT_STAKED_TOKENS");
        for (uint256 indexAt = 0; indexAt < tokenIDs.length; indexAt++) {
            _unstake(pid, tokenIDs[indexAt]);
        }
    }

    function unstakeAll(uint256 pid, uint256[] memory ids)
        external
        override
        existPool(pid)
        whenPlatformIsNotPaused()
        whenPoolIsNotPaused(pid)
        onlyEOAIfSet(msg.sender)
    {
        require(ids.length > 0, "TOKEN_IDS_REQUIRED");
        for (uint256 indexAt = 0; indexAt < ids.length; indexAt++) {
            _unstake(pid, ids[indexAt]);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        // It is implemented to support ERC721 transfers.
        return IERC721Receiver.onERC721Received.selector;
    }

    /* View Functions */

    /* Internal Funcctions  */

    function _afterUserStake(
        uint256 amountOrId,
        uint256 valuedAmountOrId,
        PoolInfoLib.PoolInfo storage pool,
        UserInfoLib.UserInfo storage user
    ) internal override {
        valuedAmountOrId;
        pool;
        user.addTokenId(amountOrId);
    }

    function _afterUserUnstake(
        uint256 amountOrId,
        uint256 valuedAmountOrId,
        PoolInfoLib.PoolInfo storage pool,
        UserInfoLib.UserInfo storage user
    ) internal override {
        valuedAmountOrId;
        pool;
        user.removeTokenId(amountOrId);
    }

    function _beforeUserUnstake(
        address account,
        uint256 amountOrId,
        uint256 valuedAmountOrId,
        PoolInfoLib.PoolInfo storage pool,
        UserInfoLib.UserInfo storage user
    ) internal view override {
        account;
        valuedAmountOrId;
        pool;
        user.requireHasTokenId(amountOrId);
    }

    function _safePoolTokenTransferFrom(
        address poolToken,
        address from,
        address to,
        uint256,
        uint256 amount
    ) internal override {
        IERC721(poolToken).safeTransferFrom(from, to, amount);
    }

    function _safePoolTokenTransfer(
        address poolToken,
        address from,
        address to,
        uint256,
        uint256 amount
    ) internal override {
        IERC721(poolToken).safeTransferFrom(from, to, amount);
    }

    function _getPoolTokenBalance(
        address poolToken,
        address account,
        uint256
    ) internal view override returns (uint256) {
        return IERC721(poolToken).balanceOf(account);
    }

    function _safeOutputTokenTransfer(
        address,
        address to,
        uint256,
        uint256 amount
    ) internal override {
        uint256 outputBalance = IERC20(output).balanceOf(address(this));
        if (amount > outputBalance) {
            IERC20(output).safeTransfer(to, outputBalance);
        } else {
            IERC20(output).safeTransfer(to, amount);
        }
    }

    function _safeOutputTokenMint(
        address,
        address to,
        uint256,
        uint256 amount
    ) internal override {
        IMintableERC20(output).mint(to, amount);
    }

    function _emergencyUnstakeAll(
        address userAccount,
        uint256 pid,
        PoolInfoLib.PoolInfo storage pool,
        UserInfoLib.UserInfo storage user
    ) internal override {
        user.emergencyUnstakeAll();

        uint256 totalTokens = user.getTotalTokens();
        require(totalTokens > 0, "USER_HASNT_STAKED_TOKENS");
        uint256 totalValuedAmountOrId;
        for (uint256 indexAt = 0; indexAt < totalTokens; indexAt++) {
            uint256 tokenId = user.getTokenIdAt(indexAt);
            uint256 valuedAmountOrId =
                ITokenValuator(tokenValuator).valuate(pool.token, userAccount, pid, tokenId);
            totalValuedAmountOrId = totalValuedAmountOrId.add(valuedAmountOrId);

            _safePoolTokenTransfer(pool.token, address(this), userAccount, pid, tokenId);
        }
        user.cleanTokenIDs();
        pool.totalDeposit = pool.totalDeposit.sub(totalValuedAmountOrId);
    }

    function _sweep(
        address token,
        uint256 id,
        address to
    ) internal override returns (uint256) {
        IERC721(token).safeTransferFrom(address(this), to, id);
        return id;
    }
}
