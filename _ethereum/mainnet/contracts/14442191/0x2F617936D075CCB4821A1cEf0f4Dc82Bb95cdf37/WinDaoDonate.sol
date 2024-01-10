// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IInfectionNFT.sol";


contract WinDaoDonate is  Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public infectionNFTAddr;

    address public winDaoTokenAddr;

    address public beneficiaryAddr  = 0xde0B295669a9FD93d5F28D9Ec85E40f4cb697BAe;

    bool public isActive = true;
    
    uint256 public donateSum;

    uint256 public MAX_UNIT = 9000;

    uint256 public UNIT_PRICE = 0.05 ether;
 
    uint256 public UNIT_TOKEN_AMOUNT = 711000 * 10 ** 18;
    
    // This event is triggered whenever a call to #donate succeeds.
    event Donate(address account, uint256 amount);

    constructor(address  _infectionNFTAddr,address  _winDaoTokenAddr)  {
        infectionNFTAddr = _infectionNFTAddr;
        winDaoTokenAddr = _winDaoTokenAddr;
    }
    
    function donate() external payable  {
        require(isActive, "Donate is not active");

        // Positive payments only.
        require(msg.value > 0 && msg.value.mod(UNIT_PRICE)==0, 'Bad amount');
        require((donateSum.add(msg.value)).div(UNIT_PRICE)<=MAX_UNIT, 'Donate exceeds max whileed');

        _transferEth(beneficiaryAddr, address(this).balance);
        
        donateSum +=msg.value;
        IInfectionNFT(infectionNFTAddr).ownerMinting{value: 0}(msg.sender, msg.value.div(UNIT_PRICE));
        IERC20(winDaoTokenAddr).transfer(msg.sender, msg.value.div(UNIT_PRICE).mul(UNIT_TOKEN_AMOUNT));
        
        emit Donate( msg.sender, msg.value);
    }

    function setActive(bool _isActive) external onlyOwner {
        isActive = _isActive;
    }

    receive() external payable {}
    
    function _transferEth(address _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}('');
        require(success, "_transferEth: Eth transfer failed");
    }

    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset,address to) onlyOwner external { 
        IERC20(asset).transfer(to, IERC20(asset).balanceOf(address(this)));
    }
    
}