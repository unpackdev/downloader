pragma solidity ^0.6.0;

interface IDeflector {
    function getTotalValueForUser(address _pool, address _user) external view returns (uint256);

    function isSpendableTokenInContract(address _pool, address _token) external view returns (bool);

    function getTotalLevel(address _pool, address _user) external view returns (uint256);

    function getLastTokenLevelForUser(
        address _pool,
        address _user,
        address _token
    ) external view returns (uint256);

    function getSpendableCostPerTokenForUser(
        address _pool,
        address _user,
        address _token,
        uint256 _level
    ) external view returns (uint256);

    function purchase(
        address _pool,
        address _user,
        address _token,
        uint256 _newLevel
    ) external;

    function getTokensSpentPerContract(
        address _pool,
        address _token,
        address _user
    ) external view returns (uint256);
}
