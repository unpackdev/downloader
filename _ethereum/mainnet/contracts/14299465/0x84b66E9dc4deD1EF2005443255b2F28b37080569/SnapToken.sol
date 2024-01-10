// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import "./ERC20.sol";

contract SnapToken is ERC20 {
    event VotersAdded(address[] voters);
    event VotersRemoved(address[] voters);

    address public immutable owner;

    constructor(address _owner) ERC20("SnapToken mStable GrantsDAO", "mGDVT") {
        require(_owner != address(0), "Owner cannot be the zero address");
        owner = _owner;
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function addVoters(address[] calldata _voters) external {
        require(msg.sender == owner, "Only owner can add voters");

        for (uint256 i = 0; i < _voters.length; i++) {
            require(_voters[i] != address(0), "Voter cannot be the zero address");
            require(balanceOf(_voters[i]) == 0, "Voter already has token");
            _mint(_voters[i], 1);
        }

        emit VotersAdded(_voters);
    }

    function removeVoters(address[] calldata _voters) external {
        require(msg.sender == owner, "Only owner can remove voters");

        for (uint256 i = 0; i < _voters.length; i++) {
            require(_voters[i] != address(0), "Voter cannot be the zero address");
            require(balanceOf(_voters[i]) == 1, "Voter has no tokens to burn");
            _burn(_voters[i], 1);
        }

        emit VotersRemoved(_voters);
    }
}
