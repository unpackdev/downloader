// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./IMyobuDistributor.sol";


contract MyobuDistributor is IMyobuDistributor, Ownable {
    mapping(address => bool) public isCall;
    mapping(uint256 => DistributeTo) private distributeTo_;
    
    function distributeTo(uint256 index)
        external
        view
        override
        returns (DistributeTo memory)
    {
        return distributeTo_[index];
    }

    uint256 public override distributeToCount;

    function addArrayToMapping(DistributeTo[] memory array) private {
        distributeToCount = array.length;
        for (uint256 i; i < array.length; i++) {
            distributeTo_[i] = array[i];
        }
    }

    function setDistributeTo(DistributeTo[] calldata toDistributeTo)
        external
        onlyOwner
    {
        if (distributeToCount != 0) distribute();
        uint256 totalPercentage;
        for (uint256 i; i < toDistributeTo.length; i++) {
            totalPercentage += toDistributeTo[i].percentage;
        }
        require(totalPercentage == 100, "Total percentage must equal to 100");

        addArrayToMapping(toDistributeTo);
        emit DistributeToChanged(toDistributeTo);
    }

    function setIsCall(address _address, bool onoff) external onlyOwner {
        isCall[_address] = onoff;
    }

    function distribute() public override {
        require(distributeToCount != 0, "Must have distribution set");
        if (address(this).balance == 0) return;
        uint256 totalBalance = address(this).balance;

        for (uint256 i; i < distributeToCount; i++) {
            address to = distributeTo_[i].addr;
            uint256 amount = totalBalance * distributeTo_[i].percentage / 100;
            if (isCall[to]) {
            // Calls with non empty calldata to trigger fallback()
                payable(to).call{value: amount} ("a"); 
            }
            else {
                payable(to).send(amount);
            }
        }
        emit Distributed(totalBalance, _msgSender());
    }

    // solhint-disable-next-line
    receive() external payable {}
}
