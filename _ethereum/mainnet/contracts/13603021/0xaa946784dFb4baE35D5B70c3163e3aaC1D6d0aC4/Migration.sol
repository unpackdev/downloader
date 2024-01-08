pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract Migration {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private kko;
    address constant public burnAddress = 0x000000000000000000000000000000000000dEaD;

    event Migrate(
        address indexed user,
        string  solanaAddress,
        uint256 amount
    );

    constructor(address _kko) {
        kko = IERC20(_kko);
    }

    function migrate(uint256 _amount, string memory _solanaAddress) external returns (bool) {
        kko.safeTransferFrom(msg.sender, burnAddress, _amount);

        emit Migrate(msg.sender, _solanaAddress, _amount);
        return true;
    }
}