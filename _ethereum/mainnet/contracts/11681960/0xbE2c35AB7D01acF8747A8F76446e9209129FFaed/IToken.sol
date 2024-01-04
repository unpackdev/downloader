pragma solidity ^0.7.3;

import "./IEIP712.sol";

import "./IERC20.sol";

interface IToken is IERC20, IEIP712 {

    /* ========== OPTIONAL VIEWS ========== */

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /* ========== VIEWS ========== */

    function paused() external view returns (bool);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function initialize(address synthTrading, string memory _name, string memory _symbol) external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;

    function pause() external;
    function unpause() external;

}
