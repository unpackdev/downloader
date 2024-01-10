// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IShareToken.sol";

/**
 * @title A {ERC20} token used for ride share.
 */
contract ShareToken is IShareToken, ERC20, Ownable {
    uint8 private immutable _decimals;

    address public broker;
    modifier onlyBroker() {
        require(msg.sender == broker, "caller is not broker");
        _;
    }

    event BrokerUpdated(address broker);

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address _broker
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
        broker = _broker;
    }

    function mint(address _to, uint256 _amount) external onlyBroker {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyBroker {
        _burn(_from, _amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function updateBroker(address _broker) external onlyOwner {
        broker = _broker;
        emit BrokerUpdated(broker);
    }
}
