pragma solidity >=0.8.0;

interface IFund {
    enum Status {Raise, Run, Liquidation, RaiseFailure}

    function invest(address owner, uint256 amount) external;

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint128 _minSize,
        uint256[2] memory _dates,
        uint16[4] memory _rates,
        address _manager,
        uint256 _amountOfManager,
        address[] memory _tokens
    ) external;

    function tokens() external view returns (address[] memory);

    function getToken(uint256) external view returns (address);
}
