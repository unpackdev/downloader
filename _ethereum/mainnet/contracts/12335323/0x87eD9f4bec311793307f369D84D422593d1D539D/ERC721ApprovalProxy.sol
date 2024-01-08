// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Operatable.sol";

interface IApprovalProxy {
    function setApprovalForAll(address _owner, address _spender, bool _approved) external;
    function isApprovedForAll(address _owner, address _spender, bool _original) external view returns (bool);
}

abstract contract ERC721ApprovalProxy is ERC721, Operatable {
    event UpdateApprovalProxy(address _newProxyContract);
    IApprovalProxy public approvalProxy;

    constructor() {}

    function setApprovalProxy(address _new) public onlyOperator() {
        approvalProxy = IApprovalProxy(_new);
        emit UpdateApprovalProxy(_new);
    }

    function setApprovalForAll(address _spender, bool _approved) virtual override public {
        if (address(approvalProxy) != address(0x0) && Address.isContract(_spender)) {
            approvalProxy.setApprovalForAll(msg.sender, _spender, _approved);
        }
        super.setApprovalForAll(_spender, _approved);
    }

    function isApprovedForAll(address _owner, address _spender) virtual override public view returns (bool) {
        bool original = super.isApprovedForAll(_owner, _spender);
        if (address(approvalProxy) != address(0x0)) {
            return approvalProxy.isApprovedForAll(_owner, _spender, original);
        }
        return original;
    }
}
