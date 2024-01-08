 
pragma abicoder v2;
pragma solidity 0.7.5;
import "./TimelockController.sol";
contract SquidTimeLock is TimelockController {
constructor(uint256 minDelay, address[] memory proposers, address[] memory executors) TimelockController(minDelay, proposers, executors) public {
    address daoMultiSig = 0x42E61987A5CbA002880b3cc5c800952a5804a1C5;
    _setupRole(TIMELOCK_ADMIN_ROLE, daoMultiSig);
}
}