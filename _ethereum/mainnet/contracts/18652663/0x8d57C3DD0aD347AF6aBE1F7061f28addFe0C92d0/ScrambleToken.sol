pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract ScrambleToken is ERC20, Ownable {
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * (10**18);
    uint256 public constant DAILY_EMISSION = 1_000_000 * (10**18);
    uint256 public debaseRate; 

    event Debase(uint256 amountBurned);

    constructor(address initialOwner) ERC20("Scramble Finance", "SCRAMBLE") Ownable(initialOwner) {
        _mint(initialOwner, INITIAL_SUPPLY);
    }

    function debase() external onlyOwner {
        uint256 burnAmount = (totalSupply() * debaseRate) / 100;
        _burn(address(this), burnAmount);
        emit Debase(burnAmount);
    }

    function setDebaseRate(uint256 _debaseRate) external onlyOwner {
        require(_debaseRate <= 100, "Debase rate cannot exceed 100%");
        debaseRate = _debaseRate;
    }
}