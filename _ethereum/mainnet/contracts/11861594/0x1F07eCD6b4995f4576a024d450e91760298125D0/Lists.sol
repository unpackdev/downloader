// SPDX-License-Identifier: Unlicense

pragma solidity ^0.7.6;

import "./SafeMath.sol";
import "./StructuredLinkedList.sol";

/**
 * @title Lists implements two equal length, sorted lists
 * @notice This contract has a single "internal" (to be called from an inheriting contract) state-changing function, which accepts an account and a score.
 * The implementation details deal with either adding this account to the correct list, in the correct spot, if it's a new account
 * OR increasing the score of the account, and making sure it ends up in the correct list, in the correct spot, if the account is already on a list.
 * The two lists will always either have equal length, or the "positive" list will have a length one greater than the "negative" list.
 * The two lists will always be sorted (descending), according the account's score. Each entry in each list is effectively a tuple of (account, score).
 * The last score of the "postive" list will always be >= the first score of the "negative" list.
 * A plethora of public view functions expose various details about accounts, scores, and lists.
 * @dev We leverage a StructuredLinkedList library to achieve the sorted lists.
 */
contract Lists {
    using SafeMath for uint256;
    using StructuredLinkedList for StructuredLinkedList.List;

    // mapping of accounts, to their total current scores
    mapping(address => uint256) private _accountScores;
    
    // mapping of accounts, to a boolean indicating if they exist on the "positive" list
    mapping(address => bool) private _accountOnPositive;

    // this block of variables is everything needed to track one list (the "positive" list)
    uint256 private _positiveTicker; // unique node id incrementer (each item in the list stored as a simple integer)
    mapping(uint256 => address) private _positiveNodes; // mapping of node id to account
    mapping(address => uint256) private _positiveNodesPrime; // mapping of account to node id
    StructuredLinkedList.List private _positiveList; // instance of the StructuredLinkedList, which includes functions for push, pop, insert, etc
    uint256 private _positiveListTotalScore; // total score of the list

    // this block of variables is everything needed to track one list (the "negative" list)
    uint256 private _negativeTicker; // unique node id incrementer (each item in the list stored as a simple integer)
    mapping(uint256 => address) private _negativeNodes; // mapping of node id to account
    mapping(address => uint256) private _negativeNodesPrime; // mapping of account to node id
    StructuredLinkedList.List private _negativeList; // instance of the StructuredLinkedList, which includes functions for push, pop, insert, etc
    uint256 private _negativeListTotalScore; // total score of the list

    event AddedToPositiveList(address indexed account, uint256 score);
    event AddedToNegativeList(address indexed account, uint256 score);
    event RemovedFromPositiveList(address indexed account);
    event RemovedFromNegativeList(address indexed account);

    /**
     * @notice Given a list, a mapping of nodes, and a value, figure out and return the node that should come right before it (the value)
     * @param list the list to operate on (either the positive or negative list)
     * @param _nodes the mapping of nodes => addresses, used to help determine scores necessary for sorting comparisons
     * @param _value the new value that we need to figure out where it belongs in the given list
     * @dev Re-implementation of a function included in the library, but tweaked for implementing a "descending" list
     * https://github.com/vittominacori/solidity-linked-list/blob/4124595810e508edbb0125b72a79d6b8e1e30573/contracts/StructuredLinkedList.sol#L126
     */
    function getSortedSpot(StructuredLinkedList.List storage list, mapping(uint256 => address) storage _nodes, uint256 _value) private view returns (uint256) {
        if (list.sizeOf() == 0) {
            return 0;
        }

        // grab the last node on the list (node with smallest score)
        uint256 prev;
        (, prev) = list.getAdjacent(0, false);

        // while our new value is still greater than or equal to the score of the current node...
        while ((prev != 0) && ((_value < _accountScores[_nodes[prev]]) != true)) {
            // ...move to the next (larger) node (score)
            prev = list.list[prev][false];
        }
        
        // return the first node that has a score greater than or equal to our input value
        return prev;
    }

    /**
     * @notice removes the bottom node (lowest score) from the "positive" list
     * @return nodeAccount the account of the removed node
     * @return nodeScore the score of the removed node
     */
    function takeBottomOffPositive() private returns (address nodeAccount, uint256 nodeScore) {
        // use linked list functionality to pop the back (bottom) of the positive list, returning its node id
        uint256 nodeId = _positiveList.popBack();

        // get and return the account for that node id
        nodeAccount = _positiveNodes[nodeId];

        // get and return the score for that account
        nodeScore = _accountScores[nodeAccount];

        // delete this account and score from the "positive" mapping structures
        delete _positiveNodes[nodeId];
        delete _positiveNodesPrime[nodeAccount];

        // decrease the "positive list" score
        _positiveListTotalScore = _positiveListTotalScore.sub(nodeScore);

        emit RemovedFromPositiveList(nodeAccount);
    }

    /**
     * @notice removes the top node (highest score) from the "negative" list
     * @return nodeAccount the account of the removed node
     * @return nodeScore the score of the removed node
     */
    function takeTopOffNegative() private returns (address nodeAccount, uint256 nodeScore) {
        // use linked list functionality to pop the front (top) of the negative list, returning its node id
        uint256 nodeId = _negativeList.popFront();

        // get and return the account for that node id
        nodeAccount = _negativeNodes[nodeId];

        // get and return the score for that account
        nodeScore = _accountScores[nodeAccount];

        // delete this account and score from the "negative" mapping structures
        delete _negativeNodes[nodeId];
        delete _negativeNodesPrime[nodeAccount];

        // decrease the "negative list" score
        _negativeListTotalScore = _negativeListTotalScore.sub(nodeScore);

        emit RemovedFromNegativeList(nodeAccount);
    }

    /**
     * @notice Given an account and score, insert that "tuple" into the positive list in the correctly sorted spot
     * @param nodeAccount the account to add to the list
     * @param nodeScore the score to add to the list
     */
    function pushIntoPositive(address nodeAccount, uint256 nodeScore) private {
        // find the position (node id) of the node that should come directly before the new node that we'll create
        uint256 position = getSortedSpot(_positiveList, _positiveNodes, nodeScore);

        // increase our node id counter to get a fresh node id
        _positiveTicker = _positiveTicker.add(1);

        // insert the new node id into the list at the correct location
        _positiveList.insertAfter(position, _positiveTicker);

        // link the new node id to the input account and score
        _positiveNodes[_positiveTicker] = nodeAccount;
        _positiveNodesPrime[nodeAccount] = _positiveTicker;

        // set the mapping structure to indicate that this account exists on the positive list
        _accountOnPositive[nodeAccount] = true;

        // increase the total positive list score
        _positiveListTotalScore = _positiveListTotalScore.add(nodeScore);

        emit AddedToPositiveList(nodeAccount, nodeScore);
    }

    /**
     * @notice Given an account and score, insert that "tuple" into the negative list in the correctly sorted spot
     * @param nodeAccount the account to add to the list
     * @param nodeScore the score to add to the list
     */
    function pushIntoNegative(address nodeAccount, uint256 nodeScore) private {
        // find the position (node id) of the node that should come directly before the new node that we'll create
        uint256 position = getSortedSpot(_negativeList, _negativeNodes, nodeScore);

        // increase our node id counter to get a fresh node id
        _negativeTicker = _negativeTicker.add(1);

        // insert the new node id into the list at the correct location
        _negativeList.insertAfter(position, _negativeTicker);

        // link the new node id to the input account and score
        _negativeNodes[_negativeTicker] = nodeAccount;
        _negativeNodesPrime[nodeAccount] = _negativeTicker;

        // set the mapping structure to indicate that this account does not exist on the positive list
        _accountOnPositive[nodeAccount] = false;

        // increase the total negative list score
        _negativeListTotalScore = _negativeListTotalScore.add(nodeScore);

        emit AddedToNegativeList(nodeAccount, nodeScore);
    }
    
    /**
     * @notice Takes an account address, and an "increase", and performs all of the logic necessary to:
     * 1) either: add this account to the proper list, if it's a new account
     * 2) or: update the account by adding the score increase to their existing score
     * 3) rearrange the lists so that they are properly sorted
     * 4) rearrange the lists so that they are properly balanced
     * @param account the address that has a score increase
     * @param increase the increase score amount
     * @return newScore the new total score for the account
     */
    function addScore(address account, uint256 increase) internal returns (uint256 newScore) {
        // grab the account's current score
        uint256 currentScore = _accountScores[account];

        // calculate their new score
        newScore = currentScore.add(increase);

        // update the score mapping with their new score
        _accountScores[account] = newScore;

        // if the account's current score is not 0, then we know they exist on a list already.
        // we want to remove them from whatever list they're currently on
        if (currentScore != 0) {
            // if they're on the positive list...
            if (_accountOnPositive[account] == true) {
                // grab their node id, given their account
                uint256 nodeId = _positiveNodesPrime[account];

                // remove that node from the linked list
                _positiveList.remove(nodeId);

                // unlink the node id from their account and score
                delete _positiveNodes[nodeId];
                delete _positiveNodesPrime[account];

                // decrease the "positive list" score
                _positiveListTotalScore = _positiveListTotalScore.sub(currentScore);

                emit RemovedFromPositiveList(account);
            // else they must be on the negative list...
            } else {
                // grab their node id, given their account
                uint256 nodeId = _negativeNodesPrime[account];

                // remove that node from the linked list
                _negativeList.remove(nodeId);

                // unlink the node id from their account and score
                delete _negativeNodes[nodeId];
                delete _negativeNodesPrime[account];

                // decrease the "positive list" score
                _negativeListTotalScore = _negativeListTotalScore.sub(currentScore);

                emit RemovedFromNegativeList(account);
            }
        }
        // now, whether the account is new or existing, we are in the same place:
        // the two lists and all associated list-level data structures have no
        // knowledge of the account or score

        // optimistically push the account/score into the positive list
        pushIntoPositive(account, newScore);

        // if the positive list size is too big (two+ more items than negative list)...
        if (_positiveList.size.sub(1) > _negativeList.size) {
            // remove the lowest account/score from the positive list
            (address lastPositiveNodeAccount, uint256 lastPositiveNodeScore) = takeBottomOffPositive();

            // push that account/score into the negative list
            pushIntoNegative(lastPositiveNodeAccount, lastPositiveNodeScore);
        }

        // read the the bottom of the positive list, and the top of the negative list
        (, uint256 firstNegativeNodeId) = _negativeList.getNextNode(0);        
        (, uint256 lastPositiveNodeId) = _positiveList.getPreviousNode(0);

        // if the score of the bottom of the positive list is less than the score of the top of the negative list, we need to flip them
        if (_accountScores[_negativeNodes[firstNegativeNodeId]] > _accountScores[_positiveNodes[lastPositiveNodeId]]) {
            // take the bottom off the positive list (smaller score)
            (address lastPositiveNodeAccount, uint256 lastPositiveNodeScore) = takeBottomOffPositive();

            // take the top off the negative list (larger score)
            (address firstNegativeNodeAccount, uint256 firstNegativeNodeScore) = takeTopOffNegative();

            // push the smaller score into the negative list
            pushIntoNegative(lastPositiveNodeAccount, lastPositiveNodeScore);

            // push the larger score into the positive list
            pushIntoPositive(firstNegativeNodeAccount, firstNegativeNodeScore);
        }
    }

    /**
     * @notice given a node id, returns a bool indicating if there is a following node on the positive list, and that node id if applicable
     * @param id the node id to check
     * @return exists bool indicating if there is a node following the input node on the positive list
     * @return nextId the id of the next node on the positive list, if it exists
     */
    function getNextPositiveNode(uint256 id) public view returns (bool exists, uint256 nextId) {
        (exists, nextId) = _positiveList.getNextNode(id);
    }

    /**
     * @notice iven a node id, returns a bool indicating if there is a following node on the negative list, and that node id if applicable
     * @param id the node id to check
     * @return exists bool indicating if there is a node following the input node on the negative list
     * @return nextId the id of the next node on the negative list, if it exists
     */
    function getNextNegativeNode(uint256 id) public view returns (bool exists, uint256 nextId) {
        (exists, nextId) = _negativeList.getNextNode(id);
    }

    /**
     * @notice given a node id, returns the address associated with that id on the positive list
     * @param id the node id to check
     * @return account address of the account associated with the node id on the positive list
     */
    function getPositiveAddress(uint256 id) public view returns (address account) {
        account = _positiveNodes[id];
    }

    /**
     * @notice given a node id, returns the address associated with that id on the negative list
     * @param id the node id to check
     * @return account address of the account associated with the node id on the negative list
     */
    function getNegativeAddress(uint256 id) public view returns (address account) {
        account = _negativeNodes[id];
    }

    /**
     * @notice returns the score of a given account
     * @param account the account to check
     * @return score the score of the account
     */
    function getAccountScore(address account) public view returns (uint256 score) {
        score = _accountScores[account];
    }

    /**
     * @notice given an account, returns true if that account exists on the positive list, false otherwise
     * @param account the account to check
     * @return positive true if account exists on positive list, false otherwise
     */
    function getIsOnPositive(address account) public view returns (bool positive) {
        positive = _accountOnPositive[account];
    }

    /**
     * @notice given an account, returns true if that account exists on the negative list, false otherwise
     * @param account the account to check
     * @return negative true if account exists on negative list, false otherwise
     * @dev merely checking !_accountOnPositive[account] is not enough, since every single address is false by default,
     * need to check that the given account has a score, as well
     */
    function getIsOnNegative(address account) public view returns (bool negative) {
        negative = !_accountOnPositive[account] && _accountScores[account] > 0;
    }

    /**
     * @notice returns the size of the positive list
     * @return size size of the positive list
     */
    function getPositiveListSize() public view returns (uint256 size) {
        size = _positiveList.size;
    }

    /**
     * @notice returns the size of the negative list
     * @return size size of the negative list
     */
    function getNegativeListSize() public view returns (uint256 size) {
        size = _negativeList.size;
    }

    /**
     * @notice returns the total score of the positive list
     * @return score total score of the positive list
     */
    function getPositiveListTotalScore() public view returns (uint256 score) {
        score = _positiveListTotalScore;
    }

    /**
     * @notice returns the total score of the negative list
     * @return score total score of the negative list
     */
    function getNegativeListTotalScore() public view returns (uint256 score) {
        score = _negativeListTotalScore;
    }
}
