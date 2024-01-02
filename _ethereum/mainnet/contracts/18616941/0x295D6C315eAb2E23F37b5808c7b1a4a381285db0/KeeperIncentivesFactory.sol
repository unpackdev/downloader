pragma solidity 0.8.19;

import "./BasefeeOSMDeviationCallBundler.sol";

contract KeeperIncentivesFactory {
    function deploy(
        address treasury_,
        address osm_,
        address oracleRelayer_,
        bytes32[3] memory collateral_,
        uint256 reward_,
        uint256 delay_,
        address coinOracle_,
        address ethOracle_,
        uint256 acceptedDeviation_,
        address owner_
    ) external returns (address) {
        BasefeeOSMDeviationCallBundler bundler = new BasefeeOSMDeviationCallBundler(
                treasury_,
                osm_,
                oracleRelayer_,
                collateral_,
                reward_,
                delay_,
                coinOracle_,
                ethOracle_,
                acceptedDeviation_
            );
        bundler.addAuthorization(owner_);
        bundler.removeAuthorization(address(this));            
        return address(bundler);
    }
}
