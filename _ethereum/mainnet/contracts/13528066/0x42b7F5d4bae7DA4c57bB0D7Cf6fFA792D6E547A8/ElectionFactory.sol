//SPDX-License-Identifier: MIT
/**
                                            ..
                                          ,*.
                                        .**,
                                       ,***.
                                 .,.   ,***,
                               .**,    *****.
                             .****.    ,*****,
                           .******,     ,******,
                         .*******.       .********,              .
                       ,******.            .*************,,*****.
                     ,*****.        ,,.        ,************,.
                  .,****.         ,*****,
                 ,***,          ,*******,.              ..
               ,**,          .*******,.       ,********.
                           .******,.       .********,
                         .*****,         .*******,
                       ,****,          .******,
                     ,***,.          .*****,
                   ,**,.           ./***,
                  ,,             .***,
                               .**,
            __  _______  ____  _   _______ __  ______  ______
           /  |/  / __ \/ __ \/ | / / ___// / / / __ \/_  __/
          / /|_/ / / / / / / /  |/ /\__ \/ /_/ / / / / / /
         / /  / / /_/ / /_/ / /|  /___/ / __  / /_/ / / /
        /_/  /_/\____/\____/_/_|_//____/_/_/_/\____/_/_/__    ________
          / ____/ __ \/ /   / /   / ____/ ____/_  __/  _/ |  / / ____/
         / /   / / / / /   / /   / __/ / /     / /  / / | | / / __/
        / /___/ /_/ / /___/ /___/ /___/ /___  / / _/ /  | |/ / /___
        \____/\____/_____/_____/_____/\____/ /_/ /___/  |___/_____/
*/
pragma solidity ^0.8.9;

import "./Distributor.sol";
import "./IERC20.sol";

contract ElectionFactory is Distributor {
    event NewElection(string electionId, address sender);
    event PaidElection(string electionId, address sender);

    string[] public elections;

    function _emitNewElection(string memory electionId) internal {
        emit NewElection(electionId, msg.sender);
    }

    function _emitPaidElection(string memory electionId) internal {
        emit PaidElection(electionId, msg.sender);
    }

    function _createElection(string memory electionId)
        internal
        returns (string memory)
    {
        elections.push(electionId);
        _emitNewElection(electionId);
        return electionId;
    }

    function _payElection(
        string memory electionId,
        address[] memory candidates,
        uint256[] memory shares,
        address token
    ) internal {
        // NOTE: Not Escrow Version
        if (token == address(0)) {
            _sharePayedETH(candidates, shares);
        } else {
            _sharePayedToken(candidates, shares, IERC20(token), msg.sender); // Token needs to IERC20
        }
        _emitPaidElection(electionId);
    }
}
