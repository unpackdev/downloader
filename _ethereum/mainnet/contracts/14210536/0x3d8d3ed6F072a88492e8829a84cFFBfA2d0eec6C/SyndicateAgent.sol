// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Receiver.sol";
import "./Counters.sol";
import "./Strings.sol";

contract SyndicateAgent is ERC1155, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter public id;

    string public name = "Syndicate 893 Dynasty";
    uint256 private totalSupply = 59;

    constructor(
        string memory _uri,
        uint256 _totalSupply,
        address _mintAllTo
    ) ERC1155(_uri) {
        totalSupply = _totalSupply;

        _airdropBatch(_mintAllTo, 59);
    }

    function _airdropBatch(address _user, uint256 _amount) internal {
        uint256 _tokenId = id.current();
        uint256[] memory _ids = new uint256[](_amount);
        uint256[] memory _amounts = new uint256[](_amount);

        for (uint256 _i = _tokenId; _i < _amount; _i++) {
            id.increment();
            _ids[_i] = _i;
            _amounts[_i] = 1;
        }
        _mintBatch(_user, _ids, _amounts, "");
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(_id < id.current(), "Invalid id");
        return
            string(
                abi.encodePacked(
                    super.uri(_id),
                    Strings.toString(_id + 1),
                    ".json"
                )
            );
    }
}
