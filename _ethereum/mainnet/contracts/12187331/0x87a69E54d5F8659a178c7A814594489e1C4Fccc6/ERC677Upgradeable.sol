// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./ERC677Receiver.sol";
import "./IERC677Upgradable.sol";
import "./ERC20Upgradeable.sol";

contract ERC677Upgradeable is ERC20Upgradeable, IERC677Upgradeable {

    function __ERC677_init(string memory name_, string memory symbol_) internal initializer {
        __ERC20_init(name_, symbol_);
    }

    /**
     * @dev transfer token to a contract address with additional data if the recipient is a contact.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     * @param _data The extra data to be passed to the receiving contract.
     */
    function transferAndCall(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public virtual override returns (bool success) {
        super.transfer(_to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        if (isContract(_to)) {
            contractFallback(_to, _value, _data);
        }
        return true;
    }

    // PRIVATE

    function contractFallback(
        address _to,
        uint256 _value,
        bytes memory _data
    ) private {
        ERC677Receiver receiver = ERC677Receiver(_to);
        receiver.onTokenTransfer(msg.sender, _value, _data);
    }

    function isContract(address _addr) private view returns (bool hasCode) {
        uint256 length;
        assembly {
            length := extcodesize(_addr)
        }
        return length > 0;
    }
}
