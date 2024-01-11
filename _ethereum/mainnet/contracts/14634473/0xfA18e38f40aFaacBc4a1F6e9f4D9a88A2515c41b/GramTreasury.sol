pragma solidity 0.6.12;

import "./GramToken.sol";
import "./Ownable.sol";

// GramTreasury.
contract GramTreasury is Ownable {
    // The GRAM TOKEN!
    GramToken public gram;

    constructor(
        GramToken _gram
    ) public {
        gram = _gram;
    }

    // Safe gram transfer function, just in case if rounding error causes pool to not have enough GRAMs.
    function safeGramTransfer(address _to, uint256 _amount) public onlyOwner {
        uint256 gramBal = gram.balanceOf(address(this));
        if (_amount > gramBal) {
            gram.transfer(_to, gramBal);
        } else {
            gram.transfer(_to, _amount);
        }
    }
}
