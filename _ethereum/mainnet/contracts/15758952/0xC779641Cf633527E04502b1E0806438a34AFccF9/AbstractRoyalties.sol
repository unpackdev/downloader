// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LibPart.sol";

abstract contract AbstractRoyalties {
    mapping (uint256 => LibPart.Part[]) internal royalties;

    function _saveRoyalties(uint256 id, LibPart.Part[] memory _royalties) internal {
        uint256 totalValue;
        for (uint i = 0; i < _royalties.length; i++) {
            require(_royalties[i].account != address(0x0), "Recipient should be present");
            require(_royalties[i].value != 0, "Royalty value should be positive");
            totalValue += _royalties[i].value;
            royalties[id].push(_royalties[i]);
        }
        require(totalValue < 10000, "Royalty total value should be < 10000");
        _onRoyaltiesSet(id, _royalties);
    }

    function _updateRoyalties(uint256 id, address payable account, uint96 value) internal {
        uint256 totalValue;
        require(account != address(0x0), "Recipient should be present");
        require(value != 0, "Royalty value should be positive");
        for (uint i = 0; i < royalties[id].length; i++) {
            if(royalties[id][i].account == account) {
                royalties[id][i].value = value;
            }
            totalValue += royalties[id][i].value;
        }
        require(totalValue < 10000, "Royalty total value should be < 10000");
    }

    function _updateAccount(uint256 _id, address _from, address _to) internal {
        uint length = royalties[_id].length;
        for(uint i = 0; i < length; i++) {
            if (royalties[_id][i].account == _from) {
                royalties[_id][i].account = payable(address(uint160(_to)));
            }
        }
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) virtual internal;
}