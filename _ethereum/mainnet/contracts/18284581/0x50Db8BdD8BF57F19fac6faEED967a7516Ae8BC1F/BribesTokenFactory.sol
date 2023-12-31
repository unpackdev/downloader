// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./BribesVotingToken.sol";

/**
 * @title   BribesTokenFactory
 * @author  ConvexFinance -> WombexFinance
 * @notice  Token factory used to create Bribe Voting Tokens. These are the tokenized votes
 */
contract BribesTokenFactory {
    address public immutable operator;

    event BribesTokenCreated(address token);

    /**
     * @param _operator         Operator is GaugeVoting
     */
    constructor(address _operator) public {
        operator = _operator;
    }

    function CreateBribesVotingToken() external returns(address) {
        require(msg.sender == operator, "!authorized");

        BribesVotingToken btoken = new BribesVotingToken(operator);
        emit BribesTokenCreated(address(btoken));
        return address(btoken);
    }
}
