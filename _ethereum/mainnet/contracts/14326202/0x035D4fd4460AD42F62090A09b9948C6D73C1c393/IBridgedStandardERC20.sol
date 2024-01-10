pragma solidity ^0.7.0;

import "./IERC20.sol";

interface IBridgedStandardERC20 is IERC20 {
    function configure(
        address _bridge,
        address _bridgingToken,
        string memory _name,
        string memory _symbol
    ) external;
    function bridgingToken() external returns (address);
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;

    function burnt() external view returns(uint256);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);

    event Mint(address indexed _account, uint256 _amount);
    event Burn(address indexed _account, uint256 _amount);
}
