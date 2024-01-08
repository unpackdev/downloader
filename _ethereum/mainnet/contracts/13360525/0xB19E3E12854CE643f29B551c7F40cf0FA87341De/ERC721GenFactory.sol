// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import "./ERC721Gen.sol";
import "./TransparentUpgradeableProxy.sol";
import "./ProxyAdmin.sol";

import "./Ownable.sol";

/**
 * @dev This contract is for creating proxy to access ERC721Gen token.
 *
 * The beacon should be initialized before call ERC721GenFactory constructor.
 */
contract ERC721GenFactory is Ownable, Traits {
    //implementation of token
    address public implementation;

    //transferProxy to call transferFrom
    address public transferProxy;

    //operatorProxy to mint tokens
    address public operatorProxy;

    //baseURI for collections
    string public baseURI;

    event CollectionCreated(address owner, address collection, address admin);

    constructor(
        address _implementation,
        address _transferProxy,
        address _operatorProxy,
        string memory _baseURI
    ) {
        implementation = _implementation;
        transferProxy = _transferProxy;
        operatorProxy = _operatorProxy;
        baseURI = _baseURI;
    }

    function createCollection(
        string memory _name,
        string memory _symbol,
        LibPart.Part[] memory _royalties,
        Trait[] memory _traits,
        uint256 _total,
        uint256 _maxValue
    ) external {
        bytes memory data = abi.encodeWithSelector(
            ERC721Gen(0).__ERC721Gen_init.selector,
            _name,
            _symbol,
            baseURI,
            transferProxy,
            operatorProxy,
            _royalties,
            _traits,
            _total,
            _maxValue
        );
        ProxyAdmin admin = new ProxyAdmin();
        admin.transferOwnership(_msgSender());

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(implementation, address(admin), data);
        ERC721Gen token = ERC721Gen(address(proxy));
        token.transferOwnership(_msgSender());

        emit CollectionCreated(_msgSender(), address(token), address(admin));
    }

    function changeImplementation(address _implementation) external onlyOwner() {
      implementation = _implementation;
    }

    function changeBaseURI(string memory _baseURI) external onlyOwner() {
        baseURI = _baseURI;
    }
}
