/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./PodTransfer.sol";
import "./LibSilo.sol";
import "./LibBeanSilo.sol";

/**
 * @author Publius
 * @title Replant2 undoes 2 transactions that occured post-exploit.
 * BIP-20 proposes to honor Circulating and Wrapped Beans as of the Pre-Exploit Block: 14602789.
 * Both of these transactions were performed with Circulating Beans obtained after the Pre-Exploit Block.
 * 1. A Bean Deposit
 * 2. A Fill Listing
 * ------------------------------------------------------------------------------------
 * Bean Deposit:
 * transactionHash: 0x571247df9ec89811cc7568ab16201be8db0af86cfa6e6b6e06f3b5f33de0ea18
 * The following Bean Deposit will be removed:
 * Address: 0x87233bae0bcd477a158832e7c17cb1b0fa44447d
 * Season   6074
 * Amount   71286585
 * ------------------------------------------------------------------------------------
 * Fill Listing:
 * transactionHash: 0x571247df9ec89811cc7568ab16201be8db0af86cfa6e6b6e06f3b5f33de0ea18
 * The Plot with
 * Id:   731394902132721
 * Pods: 3760739846
 * Must be transferred returned
 * From: 0x4307011e9Bad016F70aA90A23983F9428952f2A2
 * To:   0x26258096ADE7E73B0FCB7B5e2AC1006A854deEf6
 * ------------------------------------------------------------------------------------
 **/

contract Replant2 is PodTransfer {

    using SafeMath for uint256;

    uint256 constant INDEX = 731394902132721;
    uint256 constant PODS = 3760739846;
    uint256 constant START = 0;
    address constant FROM = 0x4307011e9Bad016F70aA90A23983F9428952f2A2;
    address constant TO = 0x26258096ADE7E73B0FCB7B5e2AC1006A854deEf6;

    uint32 constant SEASON = 6074;
    address constant ADDRESS = 0x87233BAe0bCD477a158832e7c17Cb1B0fa44447D;
    uint256 constant AMOUNT = 71286585;

    function init() external {
        _transferPlot(FROM, TO, INDEX, START, PODS);

        delete s.a[ADDRESS].bean.deposits[SEASON];
        LibBeanSilo.decrementDepositedBeans(AMOUNT);
        LibSilo.withdrawSiloAssets(
            ADDRESS,
            AMOUNT.mul(C.getSeedsPerBean()),
            AMOUNT.mul(C.getStalkPerBean())
        );
    }
}
