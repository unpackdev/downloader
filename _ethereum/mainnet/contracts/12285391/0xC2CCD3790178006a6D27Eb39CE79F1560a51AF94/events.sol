pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

contract Events {
    event LogSettle(
        address[] tokens,
        uint256[] amts
    );

    event LogAaveV2Migrate(
        address indexed user,
        address indexed targetDsa,
        address[] supplyTokens,
        address[] borrowTokens,
        uint256[] supplyAmts,
        uint256[] variableBorrowAmts,
        uint256[] stableBorrowAmts
    );

    event LogUpdateVariables(
        uint256 oldFee,
        uint256 newFee,
        uint256 oldSafeRatioGap,
        uint256 newSafeRatioGap
    );

    event LogAddSupportedTokens(
        address[] tokens
    );

    event LogVariablesUpdate(uint _safeRatioGap, uint _fee);

}