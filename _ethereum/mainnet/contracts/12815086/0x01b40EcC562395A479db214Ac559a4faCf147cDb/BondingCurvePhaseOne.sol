// contracts/BondingCurvePhaseOne.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ERC20Rug.sol";

contract BondingCurvePhaseOne is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Rug;

    ERC20Rug public rugToken;

    uint256 public rugTarget; // target amount of rug to sell
    uint256 public weiTarget; // target amount of eth for phase one
    uint256 public multiplier; // rugTarget ÷ weiTarget
    bool public isActive; // is the sale active
    bool public hasEnded; // has the sale been ended

    event Start(address account);
    event Pause(address account);
    event End(address account);
    event Bought(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event Burn(address indexed account, uint256 amount);

    constructor(
        ERC20Rug _token,
        uint256 _rugTarget,
        uint256 _weiTarget,
        address newOwner
    ) {
        transferOwnership(newOwner);
        require(owner() == newOwner, "Ownership not transferred");
        rugToken = _token;
        rugTarget = _rugTarget;
        weiTarget = _weiTarget;
        multiplier = rugTarget.div(weiTarget);
        isActive = false;
        hasEnded = false;
    }

    function startSale() external onlyOwner {
        require(isActive == false, "Phase One already started!");
        require(hasEnded == false, "Cannot restart sale!");
        require(rugToken.balanceOf(address(this)) > 0, "Cannot start phase one with no balance.");
        isActive = true;
        emit Start(msg.sender);
    }

    function pauseSale() external onlyOwner {
        require(hasEnded == false, "Cannot pause ended sale!");
        require(isActive == true, "Phase One not started!");
        isActive = false;
        emit Pause(msg.sender);
    }

    function endSale() external onlyOwner {
        require(hasEnded == false, "Sale already ended!");
        require(isActive == true, "Phase One not started!");
        isActive = false;
        hasEnded = true;
        emit End(msg.sender);
    }

    function buy() public payable {
        require(isActive == true, "Phase One has not yet started!");

        uint256 amount = msg.value.mul(multiplier);
        // check that amount doesnt exceed remaining balance
        require(amount <= rugToken.balanceOf(address(this)), "Exceeds amount available!");

        // transfer amount
        rugToken.transfer(msg.sender, amount);
        emit Bought(msg.sender, amount);
    }

    function withdrawETH() external onlyOwner {
        require(hasEnded == true, "Sale not ended!");

        uint256 amount = address(this).balance;
        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function rugBurn() external onlyOwner {
        require(hasEnded == true, "Sale not ended!");

        uint256 amountToBurn = rugToken.balanceOf(address(this));
        rugToken.burn(amountToBurn);
        emit Burn(msg.sender, amountToBurn);
    }
}
