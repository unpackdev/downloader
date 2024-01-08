pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BoringOwnable.sol";
import "./MasterChefV2.sol";

contract ALCXRewarderPoke is BoringOwnable {
    MasterChefV2 public mcv2;
    uint256 public pid;

    constructor(MasterChefV2 _mcv2, uint256 _pid) public {
        mcv2 = _mcv2;
        pid = _pid;
    }

    function poke(address[] calldata accounts) external onlyOwner {
        uint256 len = accounts.length;
        for(uint256 i = 0; i < len; i++) {
            mcv2.deposit(pid, 0, accounts[i]);
        }
    }
}
