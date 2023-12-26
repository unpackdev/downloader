// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/*----------------------------------------------------------\
|                             _                 _           |
|        /\                  | |     /\        | |          |
|       /  \__   ____ _ _ __ | |_   /  \   _ __| |_ ___     |
|      / /\ \ \ / / _` | '_ \| __| / /\ \ | '__| __/ _ \    |
|     / ____ \ V / (_| | | | | |_ / ____ \| |  | ||  __/    |
|    /_/    \_\_/ \__,_|_| |_|\__/_/    \_\_|   \__\___|    |
|                                                           |
|    https://avantarte.com/careers                          |
|    https://avantarte.com/support/contact                  |
|                                                           |
\----------------------------------------------------------*/

import "./LazyMintByTokenIdERC1155.sol";

/**
 * @title A Lazy minting contract for Ringers #962: Edition by Dmitri Cherniak
 * @author Liron Navon
 */
contract Ringers962Edition is LazyMintByTokenIdERC1155 {
    constructor(
        string memory _name,
        address _minter,
        string memory _uri,
        address royaltiesReciever,
        uint256 royaltiesFraction
    )
        LazyMintByTokenIdERC1155(
            _name,
            _minter,
            _uri,
            royaltiesReciever,
            royaltiesFraction
        )
    {}
}
