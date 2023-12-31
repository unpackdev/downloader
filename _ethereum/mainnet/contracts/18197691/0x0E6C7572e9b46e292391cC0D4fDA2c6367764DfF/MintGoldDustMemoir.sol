// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./Counters.sol";
import "./Initializable.sol";

/// @title A contract responsible by allow External Owned Accounts to create one or more memoirs.
/// A memoir is a form of expression that the artist or any user of the platform can use
/// to show your feelings related to art or the current moment.
/// @author Mint Gold Dust LLC
/// @custom:contact klvh@mintgolddust.io
contract MintGoldDustMemoir is Initializable {
    mapping(address => mapping(uint256 => bytes)) public userCounterMemoirs;
    mapping(address => uint256) public userCounter;

    event EOAMemoirCreated(
        address indexed externallyOwnedAccount,
        uint256 counter,
        bytes memoir
    );

    function initialize() external initializer {
        // Empty initializer function for the upgrade proxy pattern
    }

    /**
     *
     * @notice that function creates a new memoir for some EOA address.
     *
     * @param _eoa is the address of the user that is creating its memoirs.
     * @param _memoir is the bytes that represents the memoir.
     * @notice that this bytes is calldata type because we don't have a limit of
     * length for this memoir. So we handle this string inside our function.
     *
     *    - Requirements:
     *        - At the moment to create a memoir for this address we need
     *        to verify the last state of the counter and add more one
     *        before update the mapping for this user.
     */
    function addMemoirForEOA(address _eoa, bytes calldata _memoir) external {
        uint256 next = userCounter[_eoa] + 1;
        userCounterMemoirs[_eoa][next] = _memoir;
        userCounter[_eoa] = next;

        emit EOAMemoirCreated(_eoa, next, _memoir);
    }
}
