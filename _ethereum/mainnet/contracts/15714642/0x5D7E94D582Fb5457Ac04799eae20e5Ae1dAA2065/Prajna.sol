// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./console.sol";

import "./Interfaces.sol";

/// @title Prajna Token contract
contract Prajna is IPrajna, ERC20, Ownable {

    IRiseOfPunakawan public riseOfPunakawanContract;

    uint40 public yieldStartTime = 1665432000;
    uint40 public yieldEndTime = 1981051200;

    // Yield Info
    uint256 public globalModulus = (10 ** 14);
    uint40 public riseOfPunakawanYieldRate = uint40(15 ether / globalModulus);

    struct Yield {
        uint40 lastUpdatedTime;
        uint176 pendingRewards;
    }

    mapping(address => Yield) public addressToYield;

    event Claim(address to_, uint256 amount_);

    constructor() ERC20('Prajna', 'PRAJNA') {
    }

    function mint(address _account, uint256 _amount) public onlyOwner {
        _mint(_account, _amount);
    }

    function burn(address _from, uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    //// YIELD STUFF ////

    function setRiseofpunakawan(address _address) public onlyOwner {
        riseOfPunakawanContract = IRiseOfPunakawan(_address);
    }


    function _calculateYieldReward(address _address) internal view returns (uint176) {
        uint256 totalYieldRate = uint256(_getYieldRate(_address));
        if (totalYieldRate == 0) {return 0;}
        uint256 time = uint256(_getTimestamp());
        uint256 lastUpdate = uint256(addressToYield[_address].lastUpdatedTime);

        if (lastUpdate > yieldStartTime) {
            return uint176((totalYieldRate * (time - lastUpdate) / 1 days));
        } else {return 0;}
    }

    function _updateYieldReward(address _address) internal {
        uint40 time = _getTimestamp();
        uint40 lastUpdate = addressToYield[_address].lastUpdatedTime;

        if (lastUpdate > 0) {
            addressToYield[_address].pendingRewards += _calculateYieldReward(_address);
        }
        if (lastUpdate != yieldEndTime) {
            addressToYield[_address].lastUpdatedTime = time;
        }
    }

    function _claimYieldReward(address _address) internal {
        uint176 pendingRewards = addressToYield[_address].pendingRewards;

        if (pendingRewards > 0) {
            addressToYield[_address].pendingRewards = 0;

            uint256 expandedReward = uint256(uint256(pendingRewards) * globalModulus);

            _mint(_address, expandedReward);
            emit Claim(_address, expandedReward);
        }
    }

    function updateReward(address _address) public {
        _updateYieldReward(_address);
    }

    function claimTokens() public {
        _updateYieldReward(msg.sender);
        _claimYieldReward(msg.sender);
    }

    function setYieldEndTime(uint40 yieldEndTime_) external onlyOwner {
        yieldEndTime = yieldEndTime_;
    }

    // internal

    function _getSmallerValueUint40(uint40 a, uint40 b) internal pure returns (uint40) {
        return a < b ? a : b;
    }

    function _getTimestamp() internal view returns (uint40) {
        return _getSmallerValueUint40(uint40(block.timestamp), yieldEndTime);
    }

    function _getYieldRate(address _address) internal view returns (uint256) {
        uint256 riseOfPunakawanYield = 0;
        if (address(riseOfPunakawanContract) != address(0x0)) {
            riseOfPunakawanYield = (riseOfPunakawanContract.balanceOf(_address) * riseOfPunakawanYieldRate);
        }
        uint256 total = riseOfPunakawanYield;

        return total;
    }

    function getStorageClaimableTokens(address _address) public view returns (uint256) {
        return uint256(uint256(addressToYield[_address].pendingRewards) * globalModulus);
    }

    function getPendingClaimableTokens(address _address) public view returns (uint256) {
        return uint256(uint256(_calculateYieldReward(_address)) * globalModulus);
    }

    function getTotalClaimableTokens(address _address) public view returns (uint256) {
        return uint256((uint256(addressToYield[_address].pendingRewards) + uint256(_calculateYieldReward(_address))) * globalModulus);
    }

    function getYieldRateOfAddress(address _address) public view returns (uint256) {
        return uint256(uint256(_getYieldRate(_address)) * globalModulus);
    }

    function raw_getStorageClaimableTokens(address _address) public view returns (uint256) {
        return uint256(addressToYield[_address].pendingRewards);
    }

    function raw_getPendingClaimableTokens(address _address) public view returns (uint256) {
        return uint256(_calculateYieldReward(_address));
    }

    function raw_getTotalClaimableTokens(address _address) public view returns (uint256) {
        return uint256(uint256(addressToYield[_address].pendingRewards) + uint256(_calculateYieldReward(_address)));
    }


}
