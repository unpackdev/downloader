// SPDX-License-Identifier: MIT

import "Ownable.sol";
import "IERC20.sol";
import "IERC20Extended.sol";

pragma solidity 0.8.12;

/**
 * @title Blender is exchange contract for MILK2 => SHAKE tokens
 *
 * @dev Don't forget permit mint and burn in tokens contracts
 */
 contract Blender is Ownable {
        
    uint256 public constant  SHAKE_PRICE_STEP = 1e18;  // MILK2
    address public immutable MILK_ADDRESS;
    address public immutable SHAKE_ADDRESS;
    
    bool    public paused;
    uint256 public currShakePrice;
    uint256 public mintShakeLimit;
    uint256 public shakeMinted;
    
    /**
     * @dev Sets the values for {MILK_ADDRESS}, 
     * {SHAKE_ADDRESS}, initializes {currShakePrice} with
     */ 
    constructor (
        address _milkAddress,
        address _shakeAddress,
        uint256  _currShakePrice
    )
    {
        MILK_ADDRESS     = _milkAddress;
        SHAKE_ADDRESS    = _shakeAddress;
        currShakePrice   = _currShakePrice; // MILK2
    }
    
    /**
     * @dev Just exchage your MILK2 for one(1) SHAKE.
     * Caller must have MILK2 on his/her balance, see `currShakePrice`
     * Each call will increase SHAKE price with one step, see `SHAKE_PRICE_STEP`.
     *
     */
    function getOneShake() external {
        require(!paused, "Blender is paused");

        IERC20Extended milk2Token = IERC20Extended(MILK_ADDRESS);
        require(milk2Token.burn(msg.sender, currShakePrice), "Can't burn your MILK2");
        currShakePrice  += SHAKE_PRICE_STEP;

        IERC20Extended shakeToken = IERC20Extended(SHAKE_ADDRESS);
        shakeToken.mint(msg.sender, 1e18);
        shakeMinted += 1e18;
        require(shakeMinted <= mintShakeLimit, "Mint limit exceeded");
    }

    /////////////////////////////////////////////////////////////
    ////      Admin Function                               //////
    /////////////////////////////////////////////////////////////

    /**
    *@dev set pause state
    *for owner use ONLY!!
    */
    function setPauseState(bool _isPaused) external onlyOwner {
        paused = _isPaused;
    }

    /**
    *@dev set Mint Limit
    *for owner use ONLY!!
    */ 
    function setMintLimit(uint256 _value) external onlyOwner {
        mintShakeLimit = _value;
    }
}