pragma solidity 0.7.6;

import "./IDeployer01.sol";
import "./Pool.sol";

contract Deployer01 is IDeployer01 {
    function deploy(address poolToken, address uniPool, address setting, string memory tradePair, bool reverse, uint8 oracle) external override returns (address, address) {
        Pool pool = new Pool(poolToken, uniPool, setting, tradePair, reverse, oracle);
        return (address(pool), pool.debtToken());
    }
}
