// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface ITokenVesting {
    /* ========== ADMIN FUNCTIONS ========== */

    function updateStartTime(uint256 _startAfter) external;

    function addOrUpdateInvestor(address _investor, uint256 _amount) external;

    function addOrUpdateInvestors(address[] calldata _investor, uint256[] calldata _amount) external;

    function recoverToken(address _token, uint256 amount) external;

    /* ========== INVESTOR FUNCTION ========== */

    function claimInvestorUnlockedTokens() external;

    /* ========== VIEWS ========== */

    function getInvestorClaimableTokens(address _investor) external view returns (uint256);

    /* ========== EVENTS ========== */

    event InvestorsAdded(address[] investors, uint256[] amount);

    event InvestorAdded(address investors, uint256 amount);

    event InvestorTokensClaimed(address indexed investor, uint256 amount);

    event RecoverToken(address indexed token, uint256 indexed amount);
}
