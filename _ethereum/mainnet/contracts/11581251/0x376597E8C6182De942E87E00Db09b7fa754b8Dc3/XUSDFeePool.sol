// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./Context.sol";
import "./IERC20.sol";
import "./ERC20Custom.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

contract XUSDFeePool {
    using SafeMath for uint256;

    // XUSD mint/redeem fees will be sent to this contract and will be distributed to XUS holders in the future
    address timelock_address;
    address xusd_address;

    modifier onlyByTimelock() {
        require(msg.sender == timelock_address, "not timelock");
        _;
    }

    constructor(address _xusd_address, address _timelock_address) public {
        xusd_address = _xusd_address;
        timelock_address = _timelock_address;
    }

    function setTimelock(address _timelock) external onlyByTimelock {
        timelock_address = _timelock;
    }

    function withdraw(uint256 _address, uint256 _amount, address _to) external onlyByTimelock {
        ERC20(_address).transfer(_to, _amount);
    }

    function recoverETH(address payable _to) external onlyByTimelock {
        require(address(this).balance > 0);
        _to.transfer(address(this).balance);
    }
}
