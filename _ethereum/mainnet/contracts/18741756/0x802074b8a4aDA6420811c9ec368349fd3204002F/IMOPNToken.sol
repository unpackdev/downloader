// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20.sol";

interface IMOPNToken is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function mopnburn(address account, uint256 amount) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data
    ) external;

    function transferOwnership(address newOwner) external;
}
