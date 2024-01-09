// SPDX-License-Identifier: MIT
// Sacred Coin Protocol v0.1.0

pragma solidity ^0.8.9;

/**
 * @title Sacred Coin Protocol v0.1.0
 *
 * @dev A protocol to build an ERC20 token that allows for the creation of guidelines,
 * or recommendations on how to use the coin that are intended for the those who interact with it.
 *
 * Works in conjunction with an ERC20 implementation, such as the OpenZeppelin ERC20 contract.
 *
 * To understand the philosophy behind it, visit:
 * https://sacredcoinprotocol.com
 *
 * To see examples on how to use this contract go to the GitHub page:
 * https://github.com/tokenosopher/sacred-coin-protocol
 *
 */

contract SacredCoin {

    uint public numberOfGuidelines;

    /**
    * @dev A string that holds all of the guidelines, for easy retrieval.
    */
    string [] private mergedGuidelines;

    /**
    * @dev The Guideline struct. Each guideline wil be stored in one.
    */
    struct Guideline {
        string summary;
        string guideline;
    }

    /**
    * @dev An array of Guideline structs that stores all of the guidelines, for easy retrieval.
    */
    Guideline[] public guidelines;

    /**
    * @dev An event that records the fact that a guideline has been created.
    * Because coin guidelines need to be explicitly stated during the coin creation,
    * this event only gets emitted when the coin is created, one event per guideline.
    */
    event GuidelineCreated(string guidelineSummary, string guideline);

    /**
    * @dev The main function of the contract. Should be called in the constructor function of the coin
    *
    * @param _guidelineSummary A summary of the guideline. The summary can be used as a title for
    * the guideline when it is retrieved and displayed on a front-end.
    *
    * @param _guideline The guideline itself.
    */
    function setGuideline(string memory _guidelineSummary, string memory _guideline) internal {

        /**
        * @dev creating a new struct instance of the type Guideline and storing it in memory.
        */
        Guideline memory guideline = Guideline(_guidelineSummary, _guideline);

        /**
        * @dev pushing the struct created above in the guideline_struct array.
        */
        guidelines.push(guideline);


        /**
        * @dev Emit the GuidelineCreated event.
        */
        emit GuidelineCreated(_guidelineSummary, _guideline);

        /**
        * @dev Increment numberOfGuidelines by one.
        */
        numberOfGuidelines++;
    }

    /**
    * @dev Function that returns a single guideline.
    * The element at location 0 of the array will store the guideline summary.
    * The element at location 1 of the array will store the guideline itself.
    */
    function returnSingleGuideline(uint _index) public view returns(string memory, string memory) {
        return (guidelines[_index].summary, guidelines[_index].guideline);
    }

    /**
    * @dev Function that returns all guidelines.
    * This allows iterating over all guidelines for the purpose of retrieval and/or display.
    */
    function returnAllGuidelines() public view returns(Guideline[] memory) {
        return (guidelines);
    }
}
