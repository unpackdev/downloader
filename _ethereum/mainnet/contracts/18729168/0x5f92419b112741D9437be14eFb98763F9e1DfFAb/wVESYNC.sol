// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./IVESYNC.sol";

contract wVESYNC is ERC20 {
    using SafeERC20 for ERC20;
    using Address for address;
    using SafeMath for uint;

    address public immutable VESYNC;

    constructor(address _VESYNC) ERC20("Wrapped veSYNC", "wVESYNC", 18) {
        require(_VESYNC != address(0));
        VESYNC = _VESYNC;
    }

    /**
        @notice wrap VESYNC
        @param _amount uint
        @return uint
     */
    function wrap(uint _amount) external returns (uint) {
        IERC20(VESYNC).transferFrom(msg.sender, address(this), _amount);

        uint value = VESYNCTowVESYNC(_amount);
        _mint(msg.sender, value);
        return value;
    }

    /**
        @notice unwrap VESYNC
        @param _amount uint
        @return uint
     */
    function unwrap(uint _amount) external returns (uint) {
        _burn(msg.sender, _amount);

        uint value = wVESYNCToVESYNC(_amount);
        IERC20(VESYNC).transfer(msg.sender, value);
        return value;
    }

    /**
        @notice converts wVESYNC amount to VESYNC
        @param _amount uint
        @return uint
     */
    function wVESYNCToVESYNC(uint _amount) public view returns (uint) {
        return _amount.mul(IVESYNC(VESYNC).index()).div(10 ** decimals());
    }

    /**
        @notice converts VESYNC amount to wVESYNC
        @param _amount uint
        @return uint
     */
    function VESYNCTowVESYNC(uint _amount) public view returns (uint) {
        return _amount.mul(10 ** decimals()).div(IVESYNC(VESYNC).index());
    }
}
