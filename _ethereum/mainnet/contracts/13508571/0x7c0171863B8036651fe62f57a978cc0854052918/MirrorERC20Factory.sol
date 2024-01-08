// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./MirrorProxy.sol";
import "./IMirrorERC20Factory.sol";
import "./IMirrorERC20ProxyStorage.sol";

interface IERC20ProxyStorage {
    /// @notice Register new proxy and initialize metadata
    function initialize(
        address operator_,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) external;
}

/**
 * @title MirrorERC20Factory
 * @author MirrorXYZ
 */
contract MirrorERC20Factory is
    IMirrorERC20Factory,
    IMirrorERC20FactoryEvents,
    IMirrorERC20ProxyStorageEvents
{
    /// @notice Address that holds the relay logic for proxies
    address public immutable relayer;

    //======== Constructor =========

    constructor(address relayer_) {
        relayer = relayer_;
    }

    //======== Deploy function =========

    function create(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) external override returns (address erc20Proxy) {
        address operator = payable(msg.sender);

        bytes memory initializationData = abi.encodeWithSelector(
            IERC20ProxyStorage.initialize.selector,
            operator,
            name_,
            symbol_,
            totalSupply_,
            decimals_
        );

        erc20Proxy = address(
            new MirrorProxy{
                salt: keccak256(abi.encode(operator, name_, symbol_))
            }(relayer, initializationData)
        );

        emit ERC20ProxyDeployed(erc20Proxy, name_, symbol_, operator);
    }
}
