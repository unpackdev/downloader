pragma solidity ^0.6.0;

import "./SafeMath.sol";


/**
 * @title LinkedList
 * @dev An utility library for using sorted linked list data structures in your Solidity project.
 */
library LinkedList {
    using SafeMath for uint256;

    struct Node {
        uint256 amount;
        uint256 maturityEnd;
        uint256 prev; // if 0 then head list
        uint256 next; // if 0 then end list
    }

    struct List {
        uint256 head;
        uint256 end;
        uint256 counter;
        mapping(uint256 => Node) list;
    }

    /**
     * @dev Checks if the list exists
     * @param self stored linked list from contract
     * @return bool true if list exists, false otherwise
     */
    function listExists(List storage self) external view returns (bool) {
        return self.head != 0;
    }

    /**
     * @dev Returns a pointer to the beginning of the list
     * @param self stored linked list from contract
     * @return uint256 id
     */
    function getHead(List storage self) external view returns (uint256) {
        return self.head;
    }

    /**
     * @dev Returns a pointer to the end of the list
     * @param self stored linked list from contract
     * @return uint256 id
     */
    function getEnd(List storage self) external view returns (uint256) {
        return self.end;
    }

    /**
     * @dev Returns the value of the node
     * @param self stored linked list from contract
     * @param id node
     */
    function getNodeValue(List storage self, uint256 id)
        external
        view
        returns (
            uint256 amount,
            uint256 maturityEnd,
            uint256 prev,
            uint256 next
        )
    {
        amount = self.list[id].amount;
        maturityEnd = self.list[id].maturityEnd;
        prev = self.list[id].prev;
        next = self.list[id].next;
    }

    /**
     * @dev Setting the pointer to the beginning of the list
     * @param self stored linked list from contract
     * @param id node
     */
    function setHead(List storage self, uint256 id) external {
        self.head = id;
    }

    /**
     * @dev Add amount to element of the list
     * @param self stored linked list from contract
     * @param id element
     * @param amount tokens
     */
    function addElementAmount(List storage self, uint256 id, uint256 amount) external {
        self.list[id].amount = self.list[id].amount.add(amount);
    }

    /**
     * @dev Adding to the end of the list
     * @param self stored linked list from contract
     * @param amount number of tokens
     * @param maturityEnd end date of interest accrual
     */
    function pushBack(List storage self, uint256 amount, uint256 maturityEnd) external {
        self.counter += 1;

        if (self.end != 0) {
            self.list[self.end].next = self.counter;
        }

        self.list[self.counter] = Node(
            amount,
            maturityEnd,
            self.end,
            0
        );

        self.end = self.counter;
        self.head = self.head == 0 ? self.counter : self.head;
    }

    /**
     * @dev Adding to the list before a node
     * @param self stored linked list from contract
     * @param id node
     * @param amount number of tokens
     * @param maturityEnd end date of interest accrual
     */
    function pushBefore(
        List storage self,
        uint256 id,
        uint256 amount,
        uint256 maturityEnd
    )
        external
    {
        require(id > 0, "ID must be greater than 0");
        self.counter += 1;

        uint256 nodeIDPrev = self.list[id].prev;
        self.list[id].prev = self.counter;

        if (nodeIDPrev > 0) {
            self.list[nodeIDPrev].next = self.counter;
        } else {
            self.head = self.counter;
        }

        self.list[self.counter] = Node(
            amount,
            maturityEnd,
            nodeIDPrev,
            id
        );
    }

    /**
     * @dev Removing from the list
     * @param self stored linked list from contract
     * @param id node
     */
    function remove(List storage self, uint256 id) external {
        require(id > 0, "ID must be greater than 0");

        uint256 nodeIDPrev = self.list[id].prev;
        uint256 nodeIDNext = self.list[id].next;

        if (nodeIDPrev > 0) {
            self.list[nodeIDPrev].next = nodeIDNext;
        } else {
            self.head = nodeIDNext;
        }

        if (nodeIDNext > 0) {
            self.list[nodeIDNext].prev = nodeIDPrev;
        } else {
            self.end = nodeIDPrev;
        }

        delete self.list[id];
    }
}
