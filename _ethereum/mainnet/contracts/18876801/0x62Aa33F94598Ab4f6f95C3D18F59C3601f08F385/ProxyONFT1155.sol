// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./MONFT1155Core.sol";
import "./IProxyONFT1155.sol";
import "./InterconnectorLeaf.sol";
import "./IERC1155.sol";
import "./ERC165Checker.sol";
import "./AccessControlUpgradeable.sol";

contract ProxyONFT1155 is MONFT1155Core, IProxyONFT1155, AccessControlUpgradeable, InterconnectorLeaf {
    using ERC165Checker for address;

    IERC1155 public token;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _lzEndpoint,
        address _token,
        address _owner
    ) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);

        token = IERC1155(_token);
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
    }

    function _msgData() internal view override(Context, ContextUpgradeable) returns (bytes calldata msgData) {
        return ContextUpgradeable._msgData();
    }

    function _msgSender() internal view override(Context, ContextUpgradeable) returns (address sender) {
        return ContextUpgradeable._msgSender();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, IERC165, ONFT1155Core)
        returns (bool)
    {
        return
            interfaceId == type(MONFT1155Core).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _debitFrom(
        address _from,
        uint16,
        bytes memory,
        uint256[] memory _tokenIds,
        uint256[] memory,
        uint256[] memory _amounts
    ) internal virtual override {
        require(_from == _msgSender(), "ProxyONFT1155: owner is not send caller");
        token.safeBatchTransferFrom(_from, address(this), _tokenIds, _amounts, "");
    }

    function _creditTo(
        uint16,
        address _toAddress,
        uint256[] memory _tokenIds,
        uint256[] memory,
        uint256[] memory _amounts
    ) internal virtual override {
        token.safeBatchTransferFrom(address(this), _toAddress, _tokenIds, _amounts, "");
    }

    function onERC1155Received(
        address _operator,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        // only allow `this` to tranfser token from others
        if (_operator != address(this)) return bytes4(0);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address _operator,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        // only allow `this` to tranfser token from others
        if (_operator != address(this)) return bytes4(0);
        return this.onERC1155BatchReceived.selector;
    }

    function _getEmissionBooster() internal view override returns (IEmissionBooster) {
        return getInterconnector().emissionBooster();
    }

    /// @dev Function with this modifier can be executed only by accounts with DEFAULT_ADMIN_ROLE.
    ///      Override standard `Ownable` behavior to keep original implementation of `LzApp` contract.
    modifier onlyOwner() override {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }
}
