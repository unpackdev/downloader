// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import "./MarketToken.sol";
import "./MarketPaymentSplitter.sol";
import "./BeaconProxy.sol";
import "./Counters.sol";
import "./Clones.sol";
import "./ICollectionContractInitializer.sol";
import "./IPaymentSplitterInitializer.sol";

/**
 * @dev This contract is for creating proxy to access ERC721Rarible token.
 *
 * The beacon should be initialized before call ERC721RaribleFactoryC2 constructor.
 *
 */
contract ERC721MarketTokenFactoryC2 {
    using Counters for Counters.Counter;
    using Clones for address;
    Counters.Counter private _saltCounter;
    address public erc721beacon;
    address public paymentSplitterBeacon;
    address public trustedProxy;

    event CreateMarketTokenProxy(address token, address splitter);

    constructor(
        address _erc721beacon,
        address _paymentSplitterbeacon,
        address _trustedProxy
    ) {
        erc721beacon = _erc721beacon;
        paymentSplitterBeacon = _paymentSplitterbeacon;
        trustedProxy = _trustedProxy;
    }

    function _getSalt(address creator, uint256 nonce)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(creator, nonce));
    }

    function createCollection(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address _contractOwner,
        address[] memory _payees,
        uint256[] memory _shares
    ) external {
        _saltCounter.increment();
        uint256 salt = _saltCounter.current();

        address paymentAddress = paymentSplitterBeacon.cloneDeterministic(
            _getSalt(msg.sender, salt)
        );

        IPaymentSplitterInitializer(paymentAddress).initialize(
            _payees,
            _shares
        );
        address collectionAddress = erc721beacon.cloneDeterministic(
            _getSalt(msg.sender, salt)
        );

        ICollectionContractInitializer(collectionAddress).initialize(
            _name,
            _symbol,
            _contractURI,
            _contractOwner,
            trustedProxy,
            paymentAddress,
            _payees,
            _shares
        );
        emit CreateMarketTokenProxy(collectionAddress, paymentAddress);
    }

    //deploying BeaconProxy contract with create2
    function deployTokenProxy(bytes memory bytecode, uint256 salt)
        internal
        returns (address proxy)
    {
        assembly {
            proxy := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(proxy)) {
                revert(0, 0)
            }
        }
    }

    //adding constructor arguments to BeaconProxy bytecode
    function getCreationBytecode(address beacon, bytes memory _data)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                type(BeaconProxy).creationCode,
                abi.encode(beacon, _data)
            );
    }

    function getTokenData(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address _contractOwner,
        address _trustedProxy,
        address _royaltyRecipient,
        address[] memory _payees,
        uint256[] memory _shares
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                MarketToken(address(0)).initialize.selector,
                _name,
                _symbol,
                _contractURI,
                _contractOwner,
                _trustedProxy,
                _royaltyRecipient,
                _payees,
                _shares
            );
    }

    function getPaymentSplitterData(
        address[] memory payees,
        uint256[] memory shares_
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                MarketPaymentSplitter(payable(0)).initialize.selector,
                payees,
                shares_
            );
    }
}
