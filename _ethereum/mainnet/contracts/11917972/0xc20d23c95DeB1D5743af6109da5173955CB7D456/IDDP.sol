pragma solidity >=0.6.0 <0.7.0;

interface IDDP {
    function deposit(
        uint256 tokenId,
        uint256 value,
        uint256 maturity,
        address to
    ) external;

    function setClaimPeriod(uint256 claimPeriod) external;
}
