// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./WrapNZap.sol";

contract WrapNZapFactory {
    event NewWrapNZap(address zappee, address wrapper, address WrapNZap);

    WrapNZap[] public wrapnzaps;
    uint256 public wrapnzapCount;

    function create(address _zappee, address _wrapper) external {
        require(
            _zappee != address(0) && _wrapper != address(0),
            "not real address"
        );
        WrapNZap wrapnzap = new WrapNZap(_zappee, _wrapper);
        wrapnzaps.push(wrapnzap);
        wrapnzapCount += 1;
        emit NewWrapNZap(_zappee, _wrapper, address(wrapnzap));
    }

    function createAndZap(address _zappee, address _wrapper) external payable {
        require(
            _zappee != address(0) && _wrapper != address(0),
            "not real address"
        );
        require(msg.value > 0, "no value sent");
        WrapNZap wrapnzap = (new WrapNZap){value: msg.value}(_zappee, _wrapper);
        wrapnzaps.push(wrapnzap);
        wrapnzapCount += 1;
        emit NewWrapNZap(_zappee, _wrapper, address(wrapnzap));
    }
}
