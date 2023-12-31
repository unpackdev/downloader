// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;


/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract Airdrop {
    function airdrop(address _token, address[] memory _tos, uint256[] memory _amounts) external {
        for (uint256 i = 0; i < _tos.length; i++) {
            IERC20(_token).transferFrom(msg.sender, _tos[i], _amounts[i]);
        }
    }
}