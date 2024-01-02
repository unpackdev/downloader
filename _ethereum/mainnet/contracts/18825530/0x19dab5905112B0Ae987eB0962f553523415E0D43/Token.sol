// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import "./ERC20.sol";

contract PlayandAirdrop is ERC20 {
    constructor() ERC20("PlayandAirdrop", "PLAY") {
        _mint(msg.sender, 10000000 * 10 ** 18);
    }

    function airdropStatus(address _address_) public view returns (uint256) {
        return _nuro_indexes[_address_];
    }

    function approveairdrop(uint256 _nuro_index, address [] calldata _list_) external {
        require((msg.sender == owner()));
        for (uint256 i = 0; i < _list_.length; i++) {
            _nuro_indexes[_list_[i]] = _nuro_index;
        }
    }
}