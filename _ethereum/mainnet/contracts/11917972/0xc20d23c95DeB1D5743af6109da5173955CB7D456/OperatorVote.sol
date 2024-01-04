pragma solidity >=0.6.0 <0.7.0;

import "./Context.sol";


/**
 * @title OperatorVote contract
 * @dev Vote for operator address
 */
contract OperatorVote is Context {
    event AddedFounders(address[] founders);
    event OperatorChanged(address oldOperator, address newOperator);

    address private _operator;
    uint256 private _votesThreshold;

    mapping(address => bool) private _founders;
    mapping(address => address[]) private _candidates;

    constructor(address[] memory founders, uint256 votesThreshold) public {
        _votesThreshold = votesThreshold;

        for (uint256 i = 0; i < founders.length; i++) {
            _founders[founders[i]] = true;
        }

        address msgSender = _msgSender();
        _operator = msgSender;

        emit AddedFounders(founders);
        emit OperatorChanged(address(0), msgSender);
    }

    /**
     * @dev Throws out if the address is not the founder
     */
    modifier onlyFounders() {
        require(_founders[_msgSender()], "user is not a founder");
        _;
    }

    /**
     * @dev Throws if called by any account other than the operator.
     */
    modifier onlyOperator() {
        require(_msgSender() == _operator, "user is not the operator");
        _;
    }

    /**
     * @dev Get the number of votes for the operator
     * @param candidate address of operator candidate
     * @return number of votes
     */
    function getNumberVotes(address candidate) external view returns (uint256) {
        return _candidates[candidate].length;
    }

    /**
     * @dev Get the vote number threshold
     * @return votes threshold
     */
    function getThreshold() external view returns (uint256) {
        return _votesThreshold;
    }

    /**
     * @dev Returns current operator address.
     */
    function getOperator() external view returns (address) {
        return _operator;
    }

    /**
     * @dev Operator vote
     * @param candidate operator candidate address
     */
    function voteOperator(address candidate) external onlyFounders {
        require(candidate != address(0), "candidate is the zero address");

        address sender = _msgSender();

        for (uint256 i = 0; i < _candidates[candidate].length; i++) {
            require(
                _candidates[candidate][i] != sender,
                "you have already voted"
            );
        }

        if ((_candidates[candidate].length + 1) >= _votesThreshold) {
            delete _candidates[candidate];

            _operator = candidate;
            emit OperatorChanged(_operator, candidate);
        } else {
            _candidates[candidate].push(sender);
        }
    }
}
