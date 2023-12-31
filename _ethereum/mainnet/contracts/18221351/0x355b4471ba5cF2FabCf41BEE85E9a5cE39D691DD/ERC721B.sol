// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SSTORE2.sol";

contract ERC721B {
    uint256 constant MAX_STORAGE = 24_576 - 1; // 1 extra by for stop opcode

    mapping(bytes32 => address[]) _data;

    error WriteConflicError(bytes32 id_);

    function _write(bytes32 id_, bytes calldata data_) internal {
        if (_data[id_].length != 0) revert WriteConflicError(id_);

        uint256 dataSize_ = data_.length;
        uint256 dataPages_ = dataSize_ / MAX_STORAGE + 1; // TODO why + 1?

        for (uint256 i_; i_ < dataPages_; i_++) {
            _data[id_].push(
                SSTORE2.write(
                    data_[i_ * MAX_STORAGE:dataSize_ > (i_ + 1) * MAX_STORAGE ? (i_ + 1) * MAX_STORAGE : dataSize_]
                )
            );
        }
    }

    function _read(bytes32 id_) internal view returns (bytes memory data_) {
        uint256 dataPages_ = _data[id_].length;

        for (uint256 i_; i_ < dataPages_; i_++) {
            data_ = bytes.concat(data_, SSTORE2.read(_data[id_][i_]));
        }
    }
}
