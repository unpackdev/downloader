// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Mintable.sol";
import "./IERC721Burnable.sol";

/**
 * @title Mutytes token interface
 */
interface IMutytesToken is
    IERC721Burnable,
    IERC721Mintable,
    IERC721Enumerable,
    IERC721Metadata,
    IERC721,
    IERC165
{
    /**
     * @notice Get the available supply
     * @return supply The available supply amount
     */
    function availableSupply() external returns (uint256);

    /**
     * @notice Get the amount of tokens minted by an owner
     * @param owner The owner's address
     * @return balance The balance amount
     */
    function mintBalanceOf(address owner) external returns (uint256);
}
