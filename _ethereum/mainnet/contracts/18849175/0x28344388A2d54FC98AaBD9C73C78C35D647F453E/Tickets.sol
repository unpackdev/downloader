/*
    Copyright 2023 Lucky8 Lottery

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./ERC1155URIStorage.sol";

contract Tickets is Ownable, ERC1155Supply, ERC1155URIStorage {
    constructor(string memory _uri) 
        Ownable(msg.sender)
        ERC1155(_uri)
    {

    }

    ///////////////////////////////////////////
    ////////// ERC-1155 OVERRIDES /////////////
    ///////////////////////////////////////////

    function mint(address to, uint round, uint amount) public onlyOwner {
        _mint(to, round, amount, "");
    }

    /// @dev Override needed to make the tickets non-transferable.
    function safeTransferFrom(
        address, /* from */
        address, /* to */
        uint256, /* id */
        uint256, /* value */
        bytes memory /* data */
    )
        public
        pure
        override
    {
        revert("Lottery: Tickets are non-transferable");
    }

    /// @dev Override needed to make the tickets non-transferable.
    function safeBatchTransferFrom(
        address, /* from */
        address, /* to */
        uint256[] memory, /* ids */
        uint256[] memory, /* values */
        bytes memory /* data */
    )
        public
        pure
        override
    {
        revert("Lottery: Tickets are non-transferable");
    }

    /// @dev Override needed to get token id URI.
    function uri(uint256 id) public view override(ERC1155URIStorage, ERC1155) returns (string memory) {
        return super.uri(id);
    }

    /// @dev Override needed to update balances for ERC-1155 tokens.
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    )
        internal
        override(ERC1155Supply, ERC1155)
    {
        super._update(from, to, ids, values);
    }
}