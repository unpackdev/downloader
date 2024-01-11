//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "./controllerPanel.sol";

error indexError(uint64 eIndex);

interface tokenContract {
    function mintCards(uint256 numberOfCards, address recipient) external;

    function reserveMintCards(uint256 numberOfCards, address recipient)
        external;
}

contract nTimesCall is controllerPanel {
    function nTimesCalls(
        uint64 _times,
        address target,
        bytes[] calldata data
    ) public onlyAllowed {
        for (uint64 j = 0; j < (_times); j++) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = target.call(data[j]);
            if (!success) {
                revert indexError({eIndex: j});
            }
        }
    }

    function airdropMint(
        uint256 _times,
        address _target,
        address[] memory _arrayAddresses,
        uint256 _amount
    ) public onlyAllowed {
        require(_times == _arrayAddresses.length, "!l");
        for (uint256 j = 0; j < (_times); j++) {
            tokenContract(_target).mintCards(_amount, _arrayAddresses[j]);
        }
    }

    function reserveMint(
        uint256 _times,
        address _target,
        address[] memory _arrayAddresses,
        uint256 _amount
    ) public onlyAllowed {
        require(_times == _arrayAddresses.length, "!l");
        for (uint256 j = 0; j < (_times); j++) {
            tokenContract(_target).reserveMintCards(
                _amount,
                _arrayAddresses[j]
            );
        }
    }
}
