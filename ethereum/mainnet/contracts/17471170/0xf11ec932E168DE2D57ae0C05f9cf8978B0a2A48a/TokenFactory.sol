// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Interfaces.sol";
import "./DepositToken.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";

/**
 * @title   TokenFactory
 * @author  ConvexFinance
 * @notice  Token factory used to create Deposit Tokens. These are the tokenized
 *          pool deposit tokens e.g cvx3crv
 */
contract TokenFactory {
    using Address for address;

    address public immutable operator;
    string public namePostfix;
    string public symbolPrefix;

    event DepositTokenCreated(address token, address lpToken);

    /**
     * @param _operator         Operator is Booster
     * @param _namePostfix      Postfixes lpToken name
     * @param _symbolPrefix     Prefixed lpToken symbol
     */
    constructor(
        address _operator,
        string memory _namePostfix,
        string memory _symbolPrefix
    ) public {
        operator = _operator;
        namePostfix = _namePostfix;
        symbolPrefix = _symbolPrefix;
    }

    function CreateDepositToken(address _lptoken) external returns(address){
        require(msg.sender == operator, "!authorized");

        DepositToken dtoken = new DepositToken(operator,_lptoken,namePostfix,symbolPrefix);
        emit DepositTokenCreated(address(dtoken), _lptoken);
        return address(dtoken);
    }
}
