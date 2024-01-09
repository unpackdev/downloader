// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Ownable.sol";


interface KeeperCompatibleInterface {
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  function performUpkeep(bytes calldata performData) external;
}


interface IStaking {
    function rebase() external;
}

interface ITreasury {
    function auditTotalReserves() external;
}

interface ISPV {
    function auditTotalValue() external;
}


contract DailyUpkeep is KeeperCompatibleInterface, Ownable {
    /**
    * Use an interval in seconds and a timestamp to slow execution of Upkeep
    */
    uint public immutable interval;
    uint public nextTimeStamp;

    address public staking;
    address public treasury;
    address public spv;


    constructor(address _staking, address _treasury, address _spv, uint _nextTimeStamp, uint _interval) {
      staking = _staking;
      treasury = _treasury;
      spv = _spv;
      nextTimeStamp = _nextTimeStamp;
      interval = _interval;
    }


    function setStaking(address _staking) external onlyOwner() {
        staking = _staking;
    }


    function setTreasury(address _treasury) external onlyOwner() {
        treasury = _treasury;
    }


    function setSPV(address _spv) external onlyOwner() {
        spv = _spv;
    }


    function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = block.timestamp > nextTimeStamp;
    }


    function performUpkeep(bytes calldata /* performData */) external override {
        if (staking != address(0)) {
            IStaking(staking).rebase();
        }
        if (treasury != address(0)) {
            ITreasury(treasury).auditTotalReserves();
        }
        if (spv != address(0)) {
            ISPV(spv).auditTotalValue();
        }
        nextTimeStamp = nextTimeStamp + interval;
    }
}
