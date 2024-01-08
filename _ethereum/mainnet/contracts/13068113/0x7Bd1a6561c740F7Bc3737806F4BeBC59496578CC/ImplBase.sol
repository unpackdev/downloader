// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Ownable.sol";
import "./errors.sol";

abstract contract ImplBase is Ownable {
    address public immutable registry;

    constructor(address _registry) Ownable() {
        registry = _registry;
    }

    modifier onlyRegistry {
        require(msg.sender == registry, MovrErrors.INVALID_SENDER);
        _;
    }

    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _to,
        address _token,
        uint256 _toChainId,
        bytes memory _extraData
    ) external virtual;

    /// @notice this function is view for the time being, but might not be later
    function calculateOutput(
        uint256 _amount,
        address _token,
        bytes calldata _data
    ) external view virtual returns (uint256);
}
