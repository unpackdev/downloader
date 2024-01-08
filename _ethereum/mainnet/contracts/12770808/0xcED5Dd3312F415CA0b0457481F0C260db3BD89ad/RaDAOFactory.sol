// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./RaDAO.sol";

contract RaDAOFactory {
    address public masterContract;

    event Created(address indexed contractAddress);

    constructor(address _masterContract) {
        masterContract = _masterContract;
    }

    function create(
      string memory name, string memory symbol, address wrappedToken,
      uint minBalanceToPropose, uint minPercentQuorum,
      uint minVotingTime, uint minExecutionDelay
    ) external returns (address) {
        RaDAO dao = RaDAO(createClone(masterContract));
        dao.snapshot();
        if (wrappedToken == address(0)) {
          dao.mint(msg.sender, 1);
        }
        dao.configure(
          name, symbol, address(dao), wrappedToken,
          minBalanceToPropose, minPercentQuorum, minVotingTime, minExecutionDelay
        );
        emit Created(address(dao));
        return address(dao);
    }

    // EIP-1167
    function createClone(address target) internal returns (address payable result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}
