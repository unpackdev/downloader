pragma solidity >=0.8.0;

interface IConfig {
    enum EventType {FUND_CREATED, FUND_UPDATED, STAKE_CREATED, STAKE_UPDATED, REG_CREATED, REG_UPDATED, PFUND_CREATED, PFUND_UPDATED}

    function ceo() external view returns (address);

    function protocolPool() external view returns (address);

    function protocolToken() external view returns (address);

    function feeTo() external view returns (address);

    function nameRegistry() external view returns (address);

    //  function investTokenWhitelist() external view returns (address[] memory);

    function tokenMinFundSize(address token) external view returns (uint256);

    function investFeeRate() external view returns (uint256);

    function redeemFeeRate() external view returns (uint256);

    function claimFeeRate() external view returns (uint256);

    function poolCreationRate() external view returns (uint256);

    function slot0() external view returns (uint256);

    function slot1() external view returns (uint256);

    function slot2() external view returns (uint256);

    function slot3() external view returns (uint256);

    function slot4() external view returns (uint256);

    function notify(EventType _type, address _src) external;
}
