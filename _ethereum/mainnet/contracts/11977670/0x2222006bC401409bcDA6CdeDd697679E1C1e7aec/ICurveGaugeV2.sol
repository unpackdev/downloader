pragma solidity 0.6.6;

interface ICurveGaugeV2 {
    function deposit(uint256 _value, address _addr) external;

    function withdraw(uint256 _value) external;

    function balanceOf(address _addr) external view returns (uint256);

    function approve(address _addr, uint256 _amount) external returns (bool);

    function crv_token() external returns (address);

    function claim_rewards(address _addr) external;

    function claimable_reward(address _addr, address _token) external view returns (uint256);

    function claimable_tokens(address addr) external returns (uint256);

    function allowance(address _owner, address _spender) external returns (uint256);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function transfer(address _to, uint256 _amount) external returns (bool);
}