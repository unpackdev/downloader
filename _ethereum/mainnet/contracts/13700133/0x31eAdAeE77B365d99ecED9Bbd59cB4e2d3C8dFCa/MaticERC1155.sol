
// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.4;

/****************************************
 * @author: Squeebo                     *
 * @team:   Golden X                    *
 ****************************************/

import "./ERC1155.sol";
import "./ContextMixin.sol";
import "./NativeMetaTransaction.sol";

abstract contract MaticERC1155 is ERC1155, ContextMixin, NativeMetaTransaction {
    constructor (string memory name_, string memory uri_)
        ERC1155(uri_) {
        _initializeEIP712(name_);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal virtual override view returns (address sender){
        return ContextMixin.msgSender();
    }

    /**
    * As another option for supporting trading without requiring meta transactions, override isApprovedForAll to whitelist OpenSea proxy accounts on Matic
    */
    function isApprovedForAll( address _owner, address _operator ) public virtual override view returns (bool isOperator) {
        if (_operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)) {
            return true;
        }
        
        return ERC1155.isApprovedForAll(_owner, _operator);
    }
}
