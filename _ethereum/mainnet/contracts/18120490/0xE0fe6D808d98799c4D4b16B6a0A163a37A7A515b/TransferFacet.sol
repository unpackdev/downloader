// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./BFacetOwner.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./Tokens.sol";
import "./LibDiamond.sol";
import "./TransferStorage.sol";

contract TransferFacet is BFacetOwner {
    using Address for address payable;
    using SafeERC20 for IERC20;

    event LogTransfer(
        address[] tokens,
        address[] recipients,
        uint256[] amounts
    );

    event LogTransferAll(address[] tokens, address[] recipients);

    /**
     @dev senderIsOwnerOrManager is a modifier to restrict access to any function that moves
     funds to only owner or an approved list of managers.
     */
    modifier senderIsOwnerOrManager() {
        require(
            (LibDiamond.isContractOwner(msg.sender) ||
                isTransferManager(msg.sender)),
            "TransferFacet.senderIsOwnerOrManager"
        );
        _;
    }

    /**
    @dev transfer is used to transfer one or more tokens to one or more recipients.
    Tokens, recipients and amounts list lengths have to be equal except recipients
    which is allowed to also contain a single recipient.
    Moves funds so only callable by owner or a manager.
    */
    function transfer(
        address[] calldata _tokens,
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) external senderIsOwnerOrManager {
        bool isSingle = _recipients.length == 1;

        require(
            isSingle || _recipients.length == _tokens.length,
            "TransferFacet.transfer: recipients length"
        );

        for (uint256 i; i < _tokens.length; i++) {
            address recipient = isSingle ? _recipients[0] : _recipients[i];

            _tokens[i] == NATIVE_TOKEN
                ? payable(recipient).sendValue(_amounts[i])
                : IERC20(_tokens[i]).safeTransfer(recipient, _amounts[i]);
        }

        emit LogTransfer(_tokens, _recipients, _amounts);
    }

    /**
    @dev transferAll is the same as transfer but transfers the total available amount.
    Moves funds so only callable by owner or a manger.
    */
    function transferAll(
        address[] calldata _tokens,
        address[] calldata _recipients
    ) external senderIsOwnerOrManager {
        bool isSingle = _recipients.length == 1;

        require(
            isSingle || _recipients.length == _tokens.length,
            "TransferFacet.transferAll: recipients length"
        );

        for (uint256 i; i < _tokens.length; i++) {
            address recipient = isSingle ? _recipients[0] : _recipients[i];

            _tokens[i] == NATIVE_TOKEN
                ? payable(recipient).sendValue(address(this).balance)
                : IERC20(_tokens[i]).safeTransfer(
                    recipient,
                    IERC20(_tokens[i]).balanceOf(address(this))
                );
        }

        emit LogTransferAll(_tokens, _recipients);
    }

    function addTransferManager(
        address _manager
    ) external onlyOwner returns (bool) {
        return _addTransferManager(_manager);
    }

    function removeTransferManager(
        address _manager
    ) external onlyOwner returns (bool) {
        return _removeTransferManager(_manager);
    }

    function transferManagerAt(uint256 _index) external view returns (address) {
        return _transferManagerAt(_index);
    }

    function transferManagers() external view returns (address[] memory) {
        return _transferManagers();
    }

    function numberOfTransferManagers() external view returns (uint256) {
        return _numberOfTransferManagers();
    }

    function isTransferManager(address _manager) public view returns (bool) {
        return _isTransferManager(_manager);
    }
}
