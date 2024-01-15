// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

contract MultiMigration is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 accuracyFactor = 10**18;
    uint256 divisor = 10**18;

    address public immutable oldPYE = 0x4d542De559D9696cbC15a3937Bf5c89fEdb5b9c7;
    address public immutable oldFORCE = 0xEcE3D017A62b8723F3648a9Fa7cD92f603E88a0E;
    address public immutable oldAPPLE = 0x5a83d81daCDcd3f5a5A712823FA4e92275d8ae9F;
    address public immutable oldCHERRY = 0xc1D6A3ef07C6731DA7FDE4C54C058cD6e371dA04;

    uint256 public pyeRate = 125;
    uint256 public forceRate = 200;

    address public newPYE;
    address public newAPPLE;
    address public newCHERRY;

    address deadWallet = 0x000000000000000000000000000000000000dEaD;

    event NewTokenTransfered(address indexed operator, IERC20 newToken, uint256 sendAmount);

    // update migrate info    
    function setConversionRates(uint256 _pyeRate, uint256 _forceRate) external onlyOwner{    
        pyeRate = _pyeRate;
        forceRate = _forceRate;
    }

    function setNewTokens(address _newPYE, address _newAPPLE, address _newCHERRY) external onlyOwner{
        newPYE = _newPYE;
        newAPPLE = _newAPPLE;
        newCHERRY = _newCHERRY;
    }

    function handlePYE(address account) internal {
        uint256 newPYEAmount = 0;

        uint256 oldPYEAmount = IERC20(oldPYE).balanceOf(account);
        uint256 oldFORCEAmount = IERC20(oldFORCE).balanceOf(account);

        if(oldPYEAmount > 0) {
            newPYEAmount += oldPYEAmount.mul(accuracyFactor).div(pyeRate).div(divisor);
            IERC20(oldPYE).safeTransferFrom(account, deadWallet, oldPYEAmount);
        }
        if(oldFORCEAmount > 0) {
            newPYEAmount += oldFORCEAmount.mul(accuracyFactor).div(forceRate).div(divisor);
            IERC20(oldFORCE).safeTransferFrom(account, deadWallet, oldFORCEAmount);
        }

        if(newPYEAmount > 0) {
            IERC20(newPYE).safeTransfer(account, newPYEAmount);
            emit NewTokenTransfered(account, IERC20(newPYE), newPYEAmount); 
        }
    }

    function handleAPPLE(address account) internal {
        uint256 oldAPPLEAmount = IERC20(oldAPPLE).balanceOf(account);

        if(oldAPPLEAmount > 0) {
            IERC20(oldAPPLE).safeTransferFrom(account, deadWallet, oldAPPLEAmount);
            IERC20(newAPPLE).mint(account, oldAPPLEAmount);
            emit NewTokenTransfered(account, IERC20(newAPPLE), oldAPPLEAmount);  
        }
    }

    function handleCHERRY(address account) internal {
        uint256 oldCHERRYAmount = IERC20(oldCHERRY).balanceOf(account);

        if(oldCHERRYAmount > 0) {
            IERC20(oldCHERRY).safeTransferFrom(account, deadWallet, oldCHERRYAmount);
            IERC20(newCHERRY).mint(account, oldCHERRYAmount);
            emit NewTokenTransfered(account, IERC20(newCHERRY), oldCHERRYAmount); 
        }
    }

    // Migration
    function migration() external nonReentrant {
        require(msg.sender != deadWallet, "Not allowed to dead wallet");
        handlePYE(msg.sender);
        handleAPPLE(msg.sender);
        handleCHERRY(msg.sender);
    }

    // Withdraw rest or wrong tokens that are sent here by mistake
    function drainBEP20Token(IERC20 token, uint256 amount, address to) external onlyOwner {
        if( token.balanceOf(address(this)) < amount ) {
            amount = token.balanceOf(address(this));
        }
        token.safeTransfer(to, amount);
    }
}