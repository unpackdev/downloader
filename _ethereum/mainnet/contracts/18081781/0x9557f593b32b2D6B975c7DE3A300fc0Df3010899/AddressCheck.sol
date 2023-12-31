// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

contract AddressCheck {
    function isContract(address[] memory address_list)
        public
        view
        returns (address[] memory)
    {
        address[] memory new_address_list = new address[](address_list.length);
        uint256 cnt = 0;
        for (uint256 i = 0; i < address_list.length; i++) {
            if (contractExists(address_list[i])) {
                new_address_list[cnt] = address_list[i];
                cnt++;
            }
        }

        address[] memory final_address_list = new address[](cnt);
        for (uint256 i = 0; i < cnt; i++) {
            final_address_list[i] = new_address_list[i];
        }

        return final_address_list;
    }

    function contractExists(address addr) view private returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }

        return (size > 0);
    }
}