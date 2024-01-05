// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";
import "./IBPDV1.sol";

contract BPDV1 is IBPDV1, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant SETTER_ROLE = keccak256('SETTER_ROLE');
    bytes32 public constant SWAP_ROLE = keccak256('SWAP_ROLE');
    bytes32 public constant SUBBALANCE_ROLE = keccak256('SUBBALANCE_ROLE');

    uint256[5] public poolYearAmounts;
    bool[5] public poolTransferred;
    uint256[5] public poolYearPercentages = [10, 15, 20, 25, 30];

    address public mainToken;

    uint256 public constant PERCENT_DENOMINATOR = 100;

    modifier onlySetter() {
        require(hasRole(SETTER_ROLE, _msgSender()), 'Caller is not a setter');
        _;
    }

    function init(
        address _mainToken,
        address _foreignSwap,
        address _subBalancePool
    ) public {
        _setupRole(SWAP_ROLE, _foreignSwap);
        _setupRole(SUBBALANCE_ROLE, _subBalancePool);
        mainToken = _mainToken;
    }

    function getPoolYearAmounts()
        external
        view
        override
        returns (uint256[5] memory poolAmounts)
    {
        return poolYearAmounts;
    }

    function getClosestPoolAmount() public view returns (uint256 poolAmount) {
        for (uint256 i = 0; i < poolYearAmounts.length; i++) {
            if (poolTransferred[i]) {
                continue;
            } else {
                poolAmount = poolYearAmounts[i];
                return poolAmount;
            }

            // return 0;
        }
    }

    function callIncomeTokensTrigger(uint256 incomeAmountToken)
        external
        override
    {
        // Divide income to years
        uint256 part = incomeAmountToken.div(PERCENT_DENOMINATOR);

        uint256 remainderPart = incomeAmountToken;
        for (uint256 i = 0; i < poolYearAmounts.length; i++) {
            if (i != poolYearAmounts.length - 1) {
                uint256 poolPart = part.mul(poolYearPercentages[i]);
                poolYearAmounts[i] = poolYearAmounts[i].add(poolPart);
                remainderPart = remainderPart.sub(poolPart);
            } else {
                poolYearAmounts[i] = poolYearAmounts[i].add(remainderPart);
            }
        }
    }

    function transferYearlyPool(uint256 poolNumber)
        external
        override
        returns (uint256 transferAmount)
    {
        for (uint256 i = 0; i < poolYearAmounts.length; i++) {
            if (poolNumber == i) {
                require(!poolTransferred[i], 'Already transferred');
                transferAmount = poolYearAmounts[i];
                poolTransferred[i] = true;

                IERC20(mainToken).transfer(_msgSender(), transferAmount);
                return transferAmount;
            }
        }
    }
}
