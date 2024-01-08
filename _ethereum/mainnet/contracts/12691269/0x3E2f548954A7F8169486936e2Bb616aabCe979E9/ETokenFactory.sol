// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

import "./IETokenFactory.sol";
import "./ControllerMixin.sol";
import "./EToken.sol";

contract ETokenFactory is ControllerMixin, IETokenFactory {

    event CreatedEToken(address indexed eToken, address indexed ePool);

    constructor(IController _controller) ControllerMixin(_controller) {}

    /**
     * @notice Returns the address of the current Aggregator which provides the exchange rate between TokenA and TokenB
     * @return Address of aggregator
     */
    function getController() external view override returns (address) {
        return address(controller);
    }

    /**
     * @notice Updates the Controller
     * @dev Can only called by an authorized sender
     * @param _controller Address of the new Controller
     * @return True on success
     */
    function setController(address _controller) external override onlyDao("ETokenFactory: not dao") returns (bool) {
        _setController(_controller);
        return true;
    }

    /**
     * @notice Create a new EToken contract
     * @param name Name of the EToken
     * @param symbol Symbol of the EToken
     * @return Address of EToken
     */
    function createEToken(string memory name, string memory symbol) external override returns (IEToken) {
        EToken token = new EToken(controller, name, symbol, msg.sender);
        emit CreatedEToken(address(token), msg.sender);
        return IEToken(token);
    }
}
