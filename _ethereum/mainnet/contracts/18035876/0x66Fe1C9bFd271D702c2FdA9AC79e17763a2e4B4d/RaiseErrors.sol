// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

/**************************************

    Raise errors

**************************************/

/// All errors connected with raises.
library RaiseErrors {
    // -----------------------------------------------------------------------
    //                              Raise Creation
    // -----------------------------------------------------------------------

    error InvalidRaiseId(string raiseId); // 0xc2f9a803
    error InvalidRaiseStartEnd(uint256 start, uint256 end); // 0xb2fb4a1d
    error InvalidVestedAmount(); // 0x17329d67
    error PriceNotMatchConfiguration(uint256 price, uint256 hardcap, uint256 vested); // 0x643c0fc5
    error InvalidTokenAddress(address token); // 0x73306803

    // -----------------------------------------------------------------------
    //                              Early Stage
    // -----------------------------------------------------------------------

    error OnlyForEarlyStage(string raiseId); // 0x2e14bd97
    error CannotForEarlyStage(string raiseId); // 0x28471ed7
    error TokenAlreadySet(string raiseId); // 0x11f125e1
    error TokenNotSet(string raiseId); // 0x64d2ac41

    // -----------------------------------------------------------------------
    //                              Investing
    // -----------------------------------------------------------------------

    error IncorrectAmount(uint256 amount); // 0x88967d2f
    error OwnerCannotInvest(address sender, string raiseId); // 0x44b4eea9
    error InvestmentOverLimit(uint256 existingInvestment, uint256 newInvestment, uint256 maxTicketSize); // 0x3ebbf796
    error InvestmentOverHardcap(uint256 existingInvestment, uint256 newInvestment, uint256 hardcap); // 0xf0152bdf
    error NotEnoughBalanceForInvestment(address sender, uint256 investment); // 0xaff6db15
    error NotEnoughAllowance(address sender, address spender, uint256 amount); // 0x892e7739

    // -----------------------------------------------------------------------
    //                              Raise State
    // -----------------------------------------------------------------------

    error RaiseAlreadyExists(string raiseId); // 0xa7bb9fe0
    error RaiseDoesNotExists(string raiseId); // 0x78134459
    error RaiseNotActive(string raiseId, uint256 currentTime); // 0x251061ff
    error RaiseNotFinished(string raiseId); // 0xab91f47a

    // -----------------------------------------------------------------------
    //                              Softcap / Hardcap
    // -----------------------------------------------------------------------

    error SoftcapAchieved(string raiseId); // 0x17d74e3f
    error SoftcapNotAchieved(string raiseId); // 0x63117c7e

    // -----------------------------------------------------------------------
    //                              Reclaim
    // -----------------------------------------------------------------------

    error NothingToReclaim(string raiseId); // 0xf803caaa
    error AlreadyReclaimed(string raiseId); // 0x5ab9f7ef

    // -----------------------------------------------------------------------
    //                              Refund
    // -----------------------------------------------------------------------

    error UserHasNotInvested(address sender, string raiseId); // 0xf2ed8df2
    error CallerNotStartup(address sender, string raiseId); // 0x73810657
    error InvestorAlreadyRefunded(address sender, string raiseId); // 0x2eff5e61
    error CollateralAlreadyRefunded(string raiseId); // 0xc4543938
}
