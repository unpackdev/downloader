// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "./IERC20.sol";
import "./LibPosition.sol";
import "./IRegistry.sol";
import "./IOpiumProxyFactory.sol";
import "./IOpiumPositionToken.sol";

interface IERC20Extended is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

struct PositionData {
    address positionAddress;
    string name;
    string symbol;
    uint256 totalSupply;
    LibDerivative.Derivative derivative;
    bool isLong;
}

contract OnChainPositionsLens {
    using LibDerivative for LibDerivative.Derivative;
    using LibPosition for bytes32;

    IRegistry public immutable registry;

    constructor(address _registry) {
        registry = IRegistry(_registry);
    }

    function predictPositionsAddressesByDerivative(LibDerivative.Derivative calldata _derivative)
        external
        view
        returns (address, address)
    {
        bytes32 derivativeHash = _derivative.getDerivativeHash();
        return _predictPositionsAddressesByDerivativeHash(derivativeHash);
    }

    function predictPositionsAddressesByDerivativeHash(bytes32 _derivativeHash)
        external
        view
        returns (address, address)
    {
        return _predictPositionsAddressesByDerivativeHash(_derivativeHash);
    }

    function getDerivativePositionsData(bytes32 _derivativeHash) external view returns (PositionData[2] memory) {
        return _getDerivativePositionsData(_derivativeHash);
    }

    function getDerivativesPositionsData(bytes32[] calldata _derivativesHash)
        external
        view
        returns (PositionData[2][] memory)
    {
        PositionData[2][] memory positionsData = new PositionData[2][](_derivativesHash.length);
        for (uint256 i = 0; i < _derivativesHash.length; i++) {
            positionsData[i] = _getDerivativePositionsData(_derivativesHash[i]);
        }
        return positionsData;
    }

    function _getDerivativePositionsData(bytes32 _derivativeHash) private view returns (PositionData[2] memory) {
        IOpiumProxyFactory opiumProxyFactory = IOpiumProxyFactory(registry.getProtocolAddresses().opiumProxyFactory);

        address longPositionAddress = _derivativeHash.predictDeterministicAddress(
            true,
            opiumProxyFactory.getImplementationAddress(),
            address(opiumProxyFactory)
        );
        address shortPositionAddress = _derivativeHash.predictDeterministicAddress(
            false,
            opiumProxyFactory.getImplementationAddress(),
            address(opiumProxyFactory)
        );

        return [
            PositionData({
                positionAddress: longPositionAddress,
                name: IERC20Extended(longPositionAddress).name(),
                symbol: IERC20Extended(longPositionAddress).symbol(),
                totalSupply: IERC20Extended(longPositionAddress).totalSupply(),
                derivative: IOpiumPositionToken(longPositionAddress).getPositionTokenData().derivative,
                isLong: true
            }),
            PositionData({
                positionAddress: shortPositionAddress,
                name: IERC20Extended(shortPositionAddress).name(),
                symbol: IERC20Extended(shortPositionAddress).symbol(),
                totalSupply: IERC20Extended(shortPositionAddress).totalSupply(),
                derivative: IOpiumPositionToken(shortPositionAddress).getPositionTokenData().derivative,
                isLong: false
            })
        ];
    }

    function _predictPositionsAddressesByDerivativeHash(bytes32 _derivativeHash)
        private
        view
        returns (address, address)
    {
        address longPositionAddress = _derivativeHash.predictDeterministicAddress(
            true,
            IOpiumProxyFactory(registry.getProtocolAddresses().opiumProxyFactory).getImplementationAddress(),
            registry.getProtocolAddresses().opiumProxyFactory
        );
        (
            true,
            IOpiumProxyFactory(registry.getProtocolAddresses().opiumProxyFactory).getImplementationAddress(),
            registry.getProtocolAddresses().opiumProxyFactory
        );
        address shortPositionAddress = _derivativeHash.predictDeterministicAddress(
            false,
            IOpiumProxyFactory(registry.getProtocolAddresses().opiumProxyFactory).getImplementationAddress(),
            registry.getProtocolAddresses().opiumProxyFactory
        );
        return (longPositionAddress, shortPositionAddress);
    }
}
