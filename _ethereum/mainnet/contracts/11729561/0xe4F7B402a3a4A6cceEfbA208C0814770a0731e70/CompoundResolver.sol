// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./FCompoundHasLiquidity.sol";
import "./FCompoundPositionWillBeSafe.sol";
import "./ICToken.sol";
import "./FCompound.sol";

contract CompoundResolver {
    function compoundHasLiquidity(uint256 _amountToBorrow, address _debtToken)
        public
        view
        returns (bool)
    {
        return _cTokenHasLiquidity(_debtToken, _amountToBorrow);
    }

    function cTokenBalance(address _token) public view returns (uint256) {
        return ICToken(_getCToken(_token)).getCash();
    }

    function compoundPositionWouldBeSafe(
        address _dsa,
        uint256 _colAmt,
        address _debtToken,
        uint256 _debtAmt
    ) public view returns (bool) {
        return _compoundPositionWillBeSafe(_dsa, _colAmt, _debtToken, _debtAmt);
    }
}
