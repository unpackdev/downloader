// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IDickManiac.sol";

contract FreeMint is ReentrancyGuard, Ownable {
    IDickManiac public immutable dmss;
    uint256 public freemintSize;

    constructor(IDickManiac _dmss, uint256 _freemintSize) {
        dmss = _dmss;
        freemintSize = _freemintSize;
    }

    function mintNewDicks(uint256 quantity) external payable nonReentrant {
        require(
            dmss.getCurrentTokenTracker() + quantity <= freemintSize,
            "Sold out"
        );

        for (uint256 i = 0; i < quantity; i++) {
            dmss.mint(msg.sender);
        }
    }

    function call(
        address payable _to,
        uint256 _value,
        bytes calldata _data
    ) external payable onlyOwner returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success);
        return _result;
    }
}
