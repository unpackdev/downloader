//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";

import "./RiftRootGP.sol";

contract RiftRoot is Initializable, RiftRootGP {

    function initialize() external initializer {
        RiftRootGP.__RiftRootGP_init();
    }

    // Sends from L1 -> L2. Tokens in L1 are held in this contract.
    function transferToL2(
        uint256 _gpAmount,
        uint256[] calldata _wndTokenIds,
        uint256[] calldata _saIds,
        uint256[] calldata _saAmounts,
        uint256[] memory _consumableIds,
        uint256[] memory _consumableAmounts)
    external
    onlyEOA
    whenNotPaused
    contractsAreSet
    {
        require(_saIds.length == _saAmounts.length, "Bad SA lengths");
        require(_consumableIds.length == _consumableAmounts.length, "Bad lengths");

        require(amountCurrentlyStaked >= amountNeededToOpenPortal, "Not enough GP staked");

        bytes memory message = _getMessageForChild(_gpAmount, _wndTokenIds, _saIds, _saAmounts, _consumableIds, _consumableAmounts);

        rootTunnel.sendMessageToChild(message);
    }

    function _getMessageForChild(
        uint256 _gpAmount,
        uint256[] memory _wndTokenIds,
        uint256[] memory _saIds,
        uint256[] memory _saAmounts,
        uint256[] memory _consumableIds,
        uint256[] memory _consumableAmounts)
        internal returns(bytes memory)
    {
        if(_gpAmount > 0) {
            gp.burn(msg.sender, _gpAmount);
        }

        WizardDragon[] memory _traits = new WizardDragon[](_wndTokenIds.length);
        // Transfer WnD
        for(uint256 i = 0; i < _wndTokenIds.length; i++) {
            uint256 _id = _wndTokenIds[i];
            require(_id != 0, "Bad Wnd ID");

            _traits[i] = wnd.getTokenTraits(_id);

            if(wnd.ownerOf(_id) == address(oldTrainingGrounds) && oldTrainingGrounds.ownsToken(_id)) {
                wnd.transferFrom(address(oldTrainingGrounds), address(this), _id);
            } else {
                // Will throw if not in their wallet.
                wnd.safeTransferFrom(msg.sender, address(this), _id);
            }
        }

        if(_saIds.length > 0) {
            // No admin safe transfer on L1 sacrificial alter
            sacrificialAlter.safeBatchTransferFrom(msg.sender, address(this), _saIds, _saAmounts, "");
        }

        if(_consumableIds.length > 0) {
            consumables.adminSafeBatchTransferFrom(msg.sender, address(this), _consumableIds, _consumableAmounts);
        }

        bytes memory message = abi.encode(msg.sender, _gpAmount, _wndTokenIds, _traits, _saIds, _saAmounts, _consumableIds, _consumableAmounts);

        return message;
    }

    function handleMessage(bytes calldata _data) external override onlyAdminOrOwner {
        (address _to,
        uint256 _gpAmount,
        uint256[] memory _wndTokenIds,
        uint256[] memory _saIds,
        uint256[] memory _saAmounts,
        uint256[] memory _consumableIds,
        uint256[] memory _consumableAmounts) = abi.decode(
            _data,
            (address, uint256, uint256[], uint256[], uint256[], uint256[], uint256[])
        );

        processMessageFromChild(_to, _gpAmount, _wndTokenIds, _saIds, _saAmounts, _consumableIds, _consumableAmounts);
    }

    function processMessageFromChild(
        address _to,
        uint256 _gpAmount,
        uint256[] memory _wndTokenIds,
        uint256[] memory _saIds,
        uint256[] memory _saAmounts,
        uint256[] memory _consumableIds,
        uint256[] memory _consumableAmounts)
        public
        onlyAdminOrOwner
    {
        require(_saIds.length == _saAmounts.length, "Bad SA Amounts");
        require(_consumableIds.length == _consumableAmounts.length, "Bad SA Amounts");

        if(_gpAmount > 0) {
            gp.mint(_to, _gpAmount);
        }

        // 721s can only be minted on L1. If this is a valid token,
        // it should be in this contract already.
        for(uint256 i = 0; i < _wndTokenIds.length; i++) {
            uint256 _tokenId = _wndTokenIds[i];
            require(_tokenId != 0, "Bad token id");
            wnd.safeTransferFrom(address(this), _to, _tokenId);
        }

        if(_saIds.length > 0) {
            address[] memory _addresses = new address[](_saIds.length);
            for(uint256 i = 0; i < _saIds.length; i++) {
                _addresses[i] = address(this);
            }

            uint256[] memory _balances = sacrificialAlter.balanceOfBatch(_addresses, _saIds);

            for(uint256 i = 0; i < _saIds.length; i++) {
                uint256 _currentBalance = _balances[i];
                // They are requesting more than is held by this contract.
                //
                if(_currentBalance < _saAmounts[i]) {
                    sacrificialAlter.mint(_saIds[i], uint16(_saAmounts[i] - _currentBalance), address(this));
                }
            }

            // No admin safe transfer on L1 sacrificial alter
            sacrificialAlter.safeBatchTransferFrom(address(this), _to, _saIds, _saAmounts, "");
        }

        if(_consumableIds.length > 0) {
            address[] memory _addresses = new address[](_consumableIds.length);
            for(uint256 i = 0; i < _consumableIds.length; i++) {
                _addresses[i] = address(this);
            }

            uint256[] memory _balances = consumables.balanceOfBatch(_addresses, _consumableIds);

            for(uint256 i = 0; i < _consumableIds.length; i++) {
                uint256 _currentBalance = _balances[i];
                // They are requesting more than is held by this contract.
                //
                if(_currentBalance < _consumableAmounts[i]) {
                    consumables.mint(_consumableIds[i], uint16(_consumableAmounts[i] - _currentBalance), address(this));
                }
            }

            consumables.adminSafeBatchTransferFrom(address(this), _to, _consumableIds, _consumableAmounts);
        }
    }
}