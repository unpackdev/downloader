//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Validator.sol";
import "./IBonusProgram.sol";
import "./IHoney.sol";

contract ExtraHoneyProgram is IBonusProgram, Validator {
    IHoney private _honey;

    event ExtraHoney(address owner, uint256 num);

    constructor(IHoney honey) {
        require(address(honey) != address(0), "IHoney must be specified");
        _honey = honey;
    }

    function description() public pure override returns (string memory)
    {
        return "ExtraHoney";
    }

    function bonusAmount(uint256 num) public pure override returns (uint256) {
        if (num < 5) return 0;

        if (num < 10) {
            return 100;
        } else if (num < 15) {
            return 300;
        } else if (num < 20) {
            return 500;
        } else {
            return 750;
        }
    }

    function onPurchase(address owner, uint256 num) public override onlyValidator {
        uint256 bonus = bonusAmount(num);
        if (bonus > 0) {
            _honey.mint(owner, bonus * 1e18);
            emit ExtraHoney(owner, bonus);
        }
    }
}
