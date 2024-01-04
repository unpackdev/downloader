//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ERC20.sol";

contract JTestaToken is ERC20("jTesta", "jTESTA"){
    using SafeMath for uint256;
    IERC20 public testa;

    constructor(IERC20 _testa) public {
        testa = _testa;
    }

    // Enter the TESTA. Earn some shares.
    function enter(uint256 _amount) public {
        uint256 totalTesta = testa.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        if (totalShares == 0 || totalTesta == 0) {
            _mint(msg.sender, _amount);
        } else {
            uint256 what = _amount.mul(totalShares).div(totalTesta);
            _mint(msg.sender, what);
        }
        testa.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the jTesta. Claim back your TESTA.
    function leave(uint256 _share) public {
        uint256 totalShares = totalSupply();
        uint256 what = _share.mul(testa.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        testa.transfer(msg.sender, what);
    }
}