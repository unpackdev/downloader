// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./ITokenV1.sol";

import "./console.sol";

contract TokenV1 is ITokenV1, ERC20, AccessControl {
    using SafeMath for uint256;

    bytes32 private constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 private constant SWAPPER_ROLE = keccak256('SWAPPER_ROLE');
    bytes32 private constant SETTER_ROLE = keccak256('SETTER_ROLE');

    IERC20 private swapToken;
    bool private swapIsOver;
    uint256 private swapTokenBalance;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), 'Caller is not a minter');
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _swapToken
    ) public ERC20(_name, _symbol) {
        swapToken = IERC20(_swapToken);
        swapIsOver = false;
    }

    function init(address[] calldata instances) external {
        require(instances.length == 5, 'NativeSwap: wrong instances number');

        for (uint256 index = 0; index < instances.length; index++) {
            _setupRole(MINTER_ROLE, instances[index]);
        }
        renounceRole(SETTER_ROLE, _msgSender());
        swapIsOver = true;
    }

    function getMinterRole() external pure returns (bytes32) {
        return MINTER_ROLE;
    }

    function getSetterRole() external pure returns (bytes32) {
        return SETTER_ROLE;
    }

    function getSwapTOken() external view returns (IERC20) {
        return swapToken;
    }

    function getSwapTokenBalance(uint256) external view returns (uint256) {
        return swapTokenBalance;
    }

    function mint(address to, uint256 amount) external override {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external override {
        _burn(from, amount);
    }

    // Helpers
    function getNow() external view returns (uint256) {
        return now;
    }
}
