// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface ITokenVesting {
    /* ========== TYPES ========== */

    enum RoundType {
        SEED,
        PRIVATE,
        STRATEGIC,
        PUBLIC
    }

    enum TeamType {
        ECOSYSTEM_AND_MARKETING,
        COMMUNITY_REWARDS,
        TEAM_AND_ADVISORS
    }

    /* ========== ADMIN FUNCTIONS ========== */

    function startOrUpdateStartTime(uint256 _startAfter) external;

    function addOrUpdateInvestor(
        RoundType _roundType,
        address _investor,
        uint256 _amount
    ) external;

    function addOrUpdateInvestors(
        RoundType[] calldata _roundType,
        address[] calldata _investor,
        uint256[] calldata _amount
    ) external;

    function recoverToken(address _token, uint256 amount) external;

    /* ========== TEAM FUNCTION ========== */

    function claimTeamUnlockedTokens(TeamType _teamType) external;

    /* ========== INVESTOR FUNCTION ========== */

    function claimInvestorUnlockedTokens(RoundType _roundType) external;

    /* ========== VIEWS ========== */

    function getInvestorClaimableTokens(RoundType _roundType, address _investor) external view returns (uint256);

    function getTeamClaimableTokens(TeamType _teamType) external view returns (uint256);

    function getInvestors(RoundType _roundType) external view returns (address[] memory);

    /* ========== EVENTS ========== */

    event StartVesting(uint256 startTime);

    event InvestorsAdded(RoundType[] roundType, address[] investors, uint256[] amount);

    event InvestorAdded(RoundType indexed roundType, address investors, uint256 amount);

    event InvestorTokensClaimed(RoundType indexed roundType, address indexed investor, uint256 amount);

    event TeamTokensClaimed(TeamType indexed teamType, address indexed beneficiary, uint256 amount);

    event RecoverToken(address indexed token, uint256 indexed amount);
}
