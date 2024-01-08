// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract enters OlympusDAO Ω with any token
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "./ZapBaseV2_2.sol";

interface IStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function unstake(uint256 _amount, bool _trigger) external;

    function claim(address _recipient) external;
}

interface IwsOHM {
    function unwrap(uint256 _amount) external returns (uint256);

    function wrap(uint256 _amount) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function wOHMTosOHM(uint256 _amount) external view returns (uint256);
}

contract OHM_Zap_V1 is ZapBaseV2_2 {
    using SafeERC20 for IERC20;

    address public constant OHM = 0x383518188C0C6d7730D91b2c03a03C837814a899;

    address public constant sOHM = 0x04F2694C8fcee23e8Fd0dfEA1d4f5Bb8c352111F;

    address public constant wsOHM = 0xCa76543Cf381ebBB277bE79574059e32108e3E65;

    IStaking public OHM_STAKING =
        IStaking(0xFd31c7d00Ca47653c6Ce64Af53c1571f9C36566a);

    // Emitted when `sender` Zaps In
    event zapIn(
        address sender,
        address token,
        uint256 tokensRec,
        address affiliate
    );

    // Emitted when `sender` Zaps Out
    event zapOut(
        address sender,
        address token,
        uint256 tokensRec,
        address affiliate
    );

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2_2(_goodwill, _affiliateSplit)
    {
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;

        transferOwnership(ZapperAdmin);
    }

    /**
     * @notice This function deposits assets into OlympusDAO
     * with ETH or ERC20 tokens
     * @param fromToken The token used for entry (address(0) if ether)
     * @param amountIn The amount of fromToken to invest
     * @param minOHM The minimum acceptable quantity sOHM
     * or wsOHM to receive. Reverts otherwise
     * @param swapTarget Excecution target for the swap or zap
     * @param swapData DEX or Zap data. Must swap to ibToken underlying address
     * @param affiliate Affiliate address
     * @return OHMRec Quantity of sOHM or wsOHM received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address toToken,
        uint256 minOHM,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 OHMRec) {
        require(
            toToken == sOHM || toToken == wsOHM,
            "toToken must be sOHM or wsOHM"
        );
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        uint256 tokensBought =
            _fillQuote(fromToken, OHM, toInvest, swapTarget, swapData);

        OHMRec = _enterOlympus(tokensBought, toToken);
        require(OHMRec > minOHM, "High Slippage");

        emit zapIn(msg.sender, sOHM, OHMRec, affiliate);
    }

    /**
     * @notice This function withdraws assets from OlympusDAO,
     * receiving tokens or ETH
     * @param fromToken The ibToken being withdrawn
     * @param amountIn The quantity of fromToken to withdraw
     * @param toToken Address of the token to receive (0 address if ETH)
     * @param minToTokens The minimum acceptable quantity
     * of tokens to receive. Reverts otherwise
     * @param swapTarget Excecution target for the swap or zap
     * @param swapData DEX or Zap data
     * @param affiliate Affiliate address
     * @return tokensRec Quantity of aTokens received
     */
    function ZapOut(
        address fromToken,
        uint256 amountIn,
        address toToken,
        uint256 minToTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external stopInEmergency returns (uint256 tokensRec) {
        require(
            fromToken == sOHM || fromToken == wsOHM,
            "fromToken must be sOHM or wsOHM"
        );

        amountIn = _pullTokens(fromToken, amountIn);

        uint256 OHMRec = _exitOlympus(fromToken, amountIn);

        tokensRec = _fillQuote(OHM, toToken, OHMRec, swapTarget, swapData);

        require(tokensRec >= minToTokens, "High Slippage");

        uint256 totalGoodwillPortion;

        if (toToken == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                tokensRec,
                affiliate,
                true
            );

            payable(msg.sender).transfer(tokensRec - totalGoodwillPortion);
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                toToken,
                tokensRec,
                affiliate,
                true
            );
            IERC20(toToken).safeTransfer(
                msg.sender,
                tokensRec - totalGoodwillPortion
            );
        }

        tokensRec = tokensRec - totalGoodwillPortion;

        emit zapOut(msg.sender, toToken, tokensRec, affiliate);
    }

    function _enterOlympus(uint256 amount, address toToken)
        internal
        returns (uint256)
    {
        _approveToken(OHM, address(OHM_STAKING), amount);

        if (toToken == wsOHM) {
            OHM_STAKING.stake(amount, address(this));
            OHM_STAKING.claim(address(this));

            _approveToken(sOHM, wsOHM, amount);

            uint256 beforeBalance = _getBalance(wsOHM);

            IwsOHM(wsOHM).wrap(amount);

            uint256 wsOHMRec = _getBalance(wsOHM) - beforeBalance;

            IERC20(wsOHM).safeTransfer(msg.sender, wsOHMRec);

            return wsOHMRec;
        }

        OHM_STAKING.stake(amount, msg.sender);
        OHM_STAKING.claim(msg.sender);

        return amount;
    }

    function _exitOlympus(address fromToken, uint256 amount)
        internal
        returns (uint256)
    {
        if (fromToken == wsOHM) {
            uint256 sOHMRec = IwsOHM(wsOHM).unwrap(amount);

            _approveToken(sOHM, address(OHM_STAKING), sOHMRec);

            OHM_STAKING.unstake(sOHMRec, true);

            return sOHMRec;
        }
        _approveToken(sOHM, address(OHM_STAKING), amount);

        OHM_STAKING.unstake(amount, true);

        return amount;
    }

    function removeLiquidityReturn(address fromToken, uint256 fromAmount)
        external
        view
        returns (uint256 ohmAmount)
    {
        if (fromToken == sOHM) {
            return fromAmount;
        } else if (fromToken == wsOHM) {
            return IwsOHM(wsOHM).wOHMTosOHM(fromAmount);
        }
    }

    function updateStaking(IStaking _staking) external onlyOwner {
        OHM_STAKING = _staking;
    }
}
