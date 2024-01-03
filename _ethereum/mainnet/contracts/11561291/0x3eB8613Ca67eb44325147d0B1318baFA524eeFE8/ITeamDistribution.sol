pragma solidity >=0.6.6;

interface ITeamDistribution {
    function totalTeamDistribution() external view returns (uint);
    function availableTeamMemberAmountOf(address account) external view returns (uint);

    function teamMemberClaim(uint amount) external;
    function startTeamDistribution() external;
}   