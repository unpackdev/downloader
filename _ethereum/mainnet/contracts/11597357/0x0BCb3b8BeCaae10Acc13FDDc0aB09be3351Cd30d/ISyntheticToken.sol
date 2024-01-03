// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./Amount.sol";

interface ISyntheticToken {

    function symbolKey()
        external
        view
        returns (bytes32);

    function mint(
        address to,
        uint256 value
    )
        external;

    function burn(
        address to,
        uint256 value
    )
        external;

    function transferCollateral(
        address token,
        address to,
        uint256 value
    )
        external
        returns (bool);

    function getMinterIssued(
        address _minter
    )
        external
        view
        returns (Amount.Principal memory);

    function getMinterLimit(
        address _minter
    )
        external
        view
        returns (uint256);

}
