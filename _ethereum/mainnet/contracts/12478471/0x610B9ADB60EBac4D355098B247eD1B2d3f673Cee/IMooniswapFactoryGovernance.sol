pragma solidity 0.6.2;

// https://etherscan.io/address/0xc4a8b7e29e3c8ec560cd4945c1cf3461a85a148d#code
interface IMooniswapFactoryGovernance {
    function defaultDecayPeriodVote(uint256 vote) external;
    function defaultFeeVote(uint256 vote) external;
    function defaultSlippageFeeVote(uint256 vote) external;
    function governanceShareVote(uint256 vote) external;
    function referralShareVote(uint256 vote) external;
}