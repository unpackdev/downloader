// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Proxied.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./ERC165CheckerUpgradeable.sol";
import "./ONFT721CoreUpgradeable.sol";

contract ProxyONFT721Upgradeable is Initializable, ONFT721CoreUpgradeable, IERC721ReceiverUpgradeable, Proxied {
    using ERC165CheckerUpgradeable for address;

    IERC721Upgradeable public token;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _minGasToTransfer, address _lzEndpoint, address _proxyToken) public virtual initializer {
        __ProxyONFT721Upgradeable_init(_minGasToTransfer, _lzEndpoint, _proxyToken);
    }

    function __ProxyONFT721Upgradeable_init(uint256 _minGasToTransfer, address _lzEndpoint, address _proxyToken) internal onlyInitializing {
        __Ownable_init_unchained();
        __LzAppUpgradeable_init_unchained(_lzEndpoint);
        __ONFT721CoreUpgradeable_init_unchained(_minGasToTransfer);

        __ProxyONFT721Upgradeable_init_unchained(_proxyToken);
    }

    function __ProxyONFT721Upgradeable_init_unchained(address _proxyToken) internal onlyInitializing {
        require(_proxyToken.supportsInterface(type(IERC721Upgradeable).interfaceId), "ProxyONFT721Upgradeable: invalid ERC721 token");
        token = IERC721Upgradeable(_proxyToken);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _debitFrom(address _from, uint16, bytes memory, uint _tokenId) internal virtual override {
        require(_from == _msgSender(), "ProxyONFT721Upgradeable: owner is not send caller");
        token.safeTransferFrom(_from, address(this), _tokenId);
    }

    function _creditTo(uint16, address _toAddress, uint _tokenId) internal virtual override {
        token.safeTransferFrom(address(this), _toAddress, _tokenId);
    }

    function onERC721Received(address _operator, address, uint, bytes memory) public virtual override returns (bytes4) {
        // only allow `this` to transfer token from others
        if (_operator != address(this)) return bytes4(0);
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}
