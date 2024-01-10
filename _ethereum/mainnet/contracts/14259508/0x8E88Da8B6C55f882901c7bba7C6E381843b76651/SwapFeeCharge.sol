// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";

contract SwapFeeCharge is Ownable {
    address public treasury;
    mapping(address => uint256) public userFeeCharged;

    event FeePayed(address user, uint256 amount);
    event TreasuryChanged(address oldTreasury, address newTreasury);

    constructor(address _treasury) {
        require(_treasury != address(0), "Treasury address missing");
        treasury = _treasury;
    }

    /**
     * @dev Set treasury address
     * @param _treasury: treasury address
     **/
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Treasury address missing");

        address oldTreasury = treasury;
        treasury = _treasury;

        emit TreasuryChanged(oldTreasury, treasury);
    }

    /**
     * @dev Execute swap transaction
     * @param _target: swap router address
     * @param _data: swap data
     **/
    function executeSwap(address _target, bytes calldata _data)
        external
        payable
    {
        // exectue swap function
        (bool success, bytes memory returnData) = _target.delegatecall(_data);
        if (!success) {
            decodeRevert(returnData);
        }

        // charge ETH fee
        safeTransferETH(treasury, msg.value);

        userFeeCharged[msg.sender] += msg.value;

        emit FeePayed(msg.sender, msg.value);
    }

    /**
     * @dev Decode bytes result
     * @param _result     receipnt address
     */
    function decodeRevert(bytes memory _result) internal pure {
        if (_result.length < 68) revert();
        assembly {
            _result := add(_result, 0x04)
        }
        revert(abi.decode(_result, (string)));
    }

    /**
     * @dev Transfer eth
     * @param _to     receipnt address
     * @param _value  amount
     */
    function safeTransferETH(address _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}(new bytes(0));
        require(success, "SafeTransferETH: ETH transfer failed");
    }
}
