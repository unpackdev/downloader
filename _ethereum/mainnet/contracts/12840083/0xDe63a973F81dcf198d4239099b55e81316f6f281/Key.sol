// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract KEY is ERC20Burnable, Ownable {
    using SafeMath for uint256;

    uint256 public constant BURN_LIMIT = 12;
    uint256 public burnCount;
    uint256[BURN_LIMIT] public burnAmount;
    uint256 public totalBurnAmount;
    uint256 private constant INITIAL_SUPPLY = 12e12 * 10**18; //12 trillion
    uint256 private constant INITIAL_AMOUNT = 120e9 * 10**18;
    uint256 public lastBurn;
    uint256 public totalAmountToBeBurned;

    constructor(
        address _receiver
    ) ERC20("VP Token", "KEY") {
        for(uint256 i = 0; i < BURN_LIMIT; i++) {
            burnAmount[i] = (INITIAL_SUPPLY.sub(totalAmountToBeBurned)).mul(10).div(100);
            totalAmountToBeBurned = totalAmountToBeBurned.add(burnAmount[i]);
        }
        _mint(_msgSender(), INITIAL_SUPPLY.sub(totalAmountToBeBurned).sub(INITIAL_AMOUNT));
        _mint(_receiver, INITIAL_AMOUNT);
        _mint(address(this), totalAmountToBeBurned);
    }

    function burnEveryMonth()
        public
        onlyOwner
    {
        _burn(address(this), burnAmount[burnCount]);
        totalBurnAmount = totalBurnAmount.add(burnAmount[burnCount]);
        burnCount++;
        lastBurn = block.timestamp;
    }
    
}
