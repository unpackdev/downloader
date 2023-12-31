// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ClonesUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC721CreatorUpgradeable.sol";
import "./ERC1155CreatorUpgradeable.sol";
import "./ERC721Extension.sol";
import "./LazyERC721CreatorUpgradeable.sol";
// import "./LazyERC1155CreatorUpgradeable.sol";

contract TokenFactoryUpgradeable is Initializable, UUPSUpgradeable {
    address public erc721ProxyImplAddress;
    address public erc1155ProxyImplAddress;
    address public lazyERC721ProxyImplAddress;
    address public lazyERC1155ProxyImplAddress;

    event TokenCreated(address indexed owner, address newToken, bool lazy, bool is721);
    event ExtensionCreated(address indexed owner, address extension, address creator);

    function initialize(
        address _erc721ProxyImplAddress,
        address _erc1155ProxyImplAddress,
        address _lazyERC721ProxyImplAddress,
        address _lazyERC1155ProxyImplAddress
    ) public initializer {
        erc721ProxyImplAddress = _erc721ProxyImplAddress;
        erc1155ProxyImplAddress = _erc1155ProxyImplAddress;
        lazyERC721ProxyImplAddress = _lazyERC721ProxyImplAddress;
        lazyERC1155ProxyImplAddress = _lazyERC1155ProxyImplAddress;
    }

    function createToken(
        bool isERC721,
        string memory name,
        string memory symbol,
        bool lazy
    ) external {
        if (!isERC721 && lazy) revert("not supported for lazy erc1155");

        address proxyImplAddr = isERC721
            ? lazy ? lazyERC721ProxyImplAddress : erc721ProxyImplAddress
            : erc1155ProxyImplAddress;
        address proxyAddr = ClonesUpgradeable.clone(proxyImplAddr);
        if (!lazy) {
            if (isERC721) {
                ERC721CreatorUpgradeable(proxyAddr).initialize(name, symbol);
                ERC721CreatorUpgradeable(proxyAddr).transferOwnership(msg.sender);
            } else {
                ERC1155CreatorUpgradeable(proxyAddr).initialize(name, symbol);
                ERC1155CreatorUpgradeable(proxyAddr).transferOwnership(msg.sender);
            }
        } else {
            if (isERC721) {
                LazyERC721CreatorUpgradeable(proxyAddr).initialize(name, symbol);
                LazyERC721CreatorUpgradeable(proxyAddr).transferOwnership(msg.sender);
            }
        }
        emit TokenCreated(msg.sender, proxyAddr, lazy, isERC721);
    }

    function createExtension(address creator) external {
        ERC721Extension extension = new ERC721Extension(creator);
        extension.transferOwnership(msg.sender);
        emit ExtensionCreated(msg.sender, address(extension), creator);
    }

    function _authorizeUpgrade(address) internal override {}
}
