pragma solidity 0.6.12;

// SPDX-License-Identifier: MIT



import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

/**
 *  @title  eTacoBar contract
 *  @notice This contract handles swapping to and from xeTaco, TacoSwap's staking token
 **/

contract eTacoBar is ERC20("eTacoBar", "xeTaco"){
    using SafeMath for uint256;
    IERC20 public etaco;

    /**
     * @notice Define the eTaco token contract
     *  @param _etaco The address of eTacoToken contract.
     **/

    constructor(IERC20 _etaco) public {
        etaco = _etaco;
    }

    /**
     * @notice Pay some eTacos. Earn some shares. Locks eTaco and mints xeTaco
     *  @param _amount The amount of eTaco tokens that should be locked.
     **/
    function enter(uint256 _amount) public {
        // Gets the amount of eTaco locked in the contract
        uint256 totaleTaco = etaco.balanceOf(address(this));
        // Gets the amount of xeTaco in existence
        uint256 totalShares = totalSupply();
        // If no xeTaco exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totaleTaco == 0) {
            _mint(msg.sender, _amount);
        } 
        // Calculate and mint the amount of xeTaco the eTaco is worth. The ratio will change overtime, 
        // as xeTaco is burned/minted and eTaco deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totaleTaco);
            _mint(msg.sender, what);
        }
        // Lock the eTaco in the contract
        etaco.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your eTacos.
    // Unlocks the staked + gained eTaco and burns xeTaco
    function leave(uint256 _share) public {
        // Gets the amount of xeTaco in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of eTaco the xeTaco is worth
        uint256 what = _share.mul(etaco.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        etaco.transfer(msg.sender, what);
    }
}
