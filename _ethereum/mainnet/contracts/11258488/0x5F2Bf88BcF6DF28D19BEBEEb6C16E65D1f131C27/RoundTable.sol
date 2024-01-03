pragma solidity 0.6.12;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";


contract RoundTable is ERC20("RoundTable", "xKING"){
    using SafeMath for uint256;
    IERC20 public king;

    constructor(IERC20 _king) public {
        require(address(_king) != address(0), "invalid address");
        king = _king;
    }

    // Join the table. Pay some $KINGs. Earn some shares.
    function enter(uint256 _amount) public {
        uint256 totalKing = king.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        if (totalShares == 0 || totalKing == 0) {
            _mint(msg.sender, _amount);
        } else {
            uint256 what = _amount.mul(totalShares).div(totalKing);
            _mint(msg.sender, what);
        }
        king.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the table. Claim back your $KINGs.
    function leave(uint256 _share) public {
        uint256 totalShares = totalSupply();
        uint256 what = _share.mul(king.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        king.transfer(msg.sender, what);
    }
}
