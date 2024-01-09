// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IStaking.sol";


contract oldaKeeperRedeem is Ownable {
    using SafeMath for uint256;

    IERC20 public KEEPER;
    IERC20 public aKEEPER;
    address public staking;

    event KeeperRedeemed(address tokenOwner, uint256 amount);
    event TroveRedeemed(address tokenOwner, uint256 amount);
    
    constructor(address _KEEPER, address _aKEEPER, address _staking) {
        require( _KEEPER != address(0) );
        require( _aKEEPER != address(0) );
        require( _staking != address(0) );
        KEEPER = IERC20(_KEEPER);
        aKEEPER = IERC20(_aKEEPER);
        staking = _staking;
    }

    function setStaking(address _staking) external onlyOwner() {
        require( _staking != address(0) );
        staking = _staking;
    }

    function migrate(uint256 amount) public {
        require(aKEEPER.balanceOf(msg.sender) >= amount, "Cannot Redeem more than balance");
        aKEEPER.transferFrom(msg.sender, address(this), amount);
        KEEPER.transfer(msg.sender, amount);
        emit KeeperRedeemed(msg.sender, amount);
    }

    function migrateTrove(uint256 amount, bool _wrap) public {
        require(aKEEPER.balanceOf(msg.sender) >= amount, "Cannot Redeem more than balance");
        aKEEPER.transferFrom(msg.sender, address(this), amount);
        IERC20( KEEPER ).approve( staking, amount );
        IStaking( staking ).stake( amount, msg.sender, _wrap );
        emit TroveRedeemed(msg.sender, amount);
    }

    function withdraw() external onlyOwner() {
        uint256 amount = KEEPER.balanceOf(address(this));
        KEEPER.transfer(msg.sender, amount);
    }
}