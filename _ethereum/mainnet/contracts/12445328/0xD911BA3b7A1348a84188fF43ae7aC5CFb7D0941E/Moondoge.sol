// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC20Burnable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

interface Convertible {
    function moon(uint256 _amount) external;

    function unmoon(uint256 _amount) external;
}

interface Migrator {
    function migrate() external;
}

contract Moondoge is IERC20, ERC20, ERC20Burnable, Convertible, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public constant NAME = "Moondoge";
    string public constant SYMBOL = "mDOGE";
    uint256 public constant PEG = 1e6;
    uint256 public constant MAX_FEE = 1000;

    address public luna;
    uint256 public fee = 0;
    uint256 public accfee = 0;

    constructor(address _luna) ERC20(NAME, SYMBOL) {
        luna = _luna;
    }

    function setFee(uint256 _fee) public onlyOwner {
        require(_fee <= MAX_FEE, "limited");
        fee = _fee;
    }

    function lunchtime() public onlyOwner {
        uint256 amount = accfee;
        accfee = 0;
        IERC20(luna).safeTransfer(msg.sender, amount);
    }

    function migrate(address _migrator, address _luna) public onlyOwner {
        IERC20(luna).safeApprove(_migrator, type(uint256).max);
        Migrator(_migrator).migrate();
        luna = _luna;
    }

    function moon(uint256 _amount) public override {
        IERC20(luna).safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount.mul(PEG));
    }

    function unmoon(uint256 _amount) public override {
        uint256 returnAmount = _amount.div(PEG);
        accfee = accfee.add(returnAmount.mul(fee).div(MAX_FEE));

        super.burn(_amount);
        IERC20(luna).safeTransfer(
            msg.sender,
            returnAmount.sub(returnAmount.mul(fee).div(MAX_FEE))
        );
    }
}
