// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";

interface IVLandDAO {

    function snapshot() external returns (uint256);

    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);

    function totalSupplyAt(uint256 snapshotId) external view returns (uint256);

}

contract PoolDistributor is Ownable {

    IVLandDAO immutable public vLand;
    uint256 public lastDistribution;

    struct DistributionData {
        uint256 snapshotId;
        uint256 amount;
    }

    mapping(uint256 => DistributionData) public distributions;
    mapping(address => uint256) public distributed;
    mapping(address => bool) public managers;

    constructor(address vLand_) {
        vLand = IVLandDAO(vLand_);
    }

    modifier onlyManager() {
        require(managers[msg.sender], "Distributor: caller is not a manager");
        _;
    }

    function addManager(address manager_) external onlyOwner {
        require(manager_ != address(0), "Distributor: manager address can not be null");
        managers[manager_] = true;
    }

    function snapshot() public onlyManager returns (uint256) {
        return vLand.snapshot();
    }

    function receiveFee(uint256 snapshotId) external payable onlyManager {
        lastDistribution++;
        distributions[lastDistribution] = DistributionData(snapshotId, msg.value);
    }

    function claimableAmount(address account) public view returns (uint256) {
        uint256 accountLastDistributed = distributed[account];
        uint256 claimable;
        for (uint256 i = accountLastDistributed + 1; i <= lastDistribution; i++) {
            DistributionData memory distributionData = distributions[i];
            uint256 snapshotId = distributionData.snapshotId;
            uint256 balance = vLand.balanceOfAt(account, snapshotId);
            if (balance > 0) {
                uint256 totalSupply = vLand.totalSupplyAt(snapshotId);
                claimable += (distributionData.amount * balance) / totalSupply;
            }
        }
        return claimable;
    }

    function claim() external {
        uint256 claimable = claimableAmount(msg.sender);
        require(claimable > 0, "Distributor: nothing to claim");
        distributed[msg.sender] = lastDistribution;
        (bool success,) = payable(msg.sender).call{value : claimable}("");
        require(success, "Distributor: unsuccessful payment");
    }
}
