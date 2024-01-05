/*
This is a proposal to update the TornadoTrees smart contract. It significantly reduces the cost of
updating tornado merkle trees by offloading onchain updates to zkSNARKs.

The proposal will:
- disable old tornado proxy
- deploy new contracts:
  - TornadoTrees - new contract for tree updates
  - AdminUpgradeableProxy - upgradeability proxy for TornadoTrees
  - TornadoProxy - new tornado proxy with ERC20 support
- migrate state from old TornadoTrees contract to the new one
- set deployed AdminUpgradeableProxy as new a tree contract in Miner

More info: https://torn.community/t/anonymity-mining-technical-overview/15
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ITornadoTreesV1.sol";
import "./IBatchTreeUpdateVerifier.sol";
import "./TornadoTrees.sol";
import "./AdminUpgradeableProxy.sol";
import "./TornadoProxy.sol";
import "./ITornadoInstance.sol";
import "./ENS.sol";
import "./ITornadoProxyV1.sol";
import "./IMiner.sol";

contract Proposal is EnsResolve {
  ITornadoTreesV1 public constant tornadoTreesV1 = ITornadoTreesV1(0x43a3bE4Ae954d9869836702AFd10393D3a7Ea417);
  ITornadoProxyV1 public constant tornadoProxyV1 = ITornadoProxyV1(0x905b63Fff465B9fFBF41DeA908CEb12478ec7601);
  IMiner public constant miner = IMiner(0x746Aebc06D2aE31B71ac51429A19D54E797878E9);

  event DeploymentOf(string name, address addr);

  address public immutable verifier;

  // params used to search for array lengths on V1 contracts
  uint256 private immutable depositsFrom;
  uint256 private immutable depositsStep;
  uint256 private immutable withdrawalsFrom;
  uint256 private immutable withdrawalsStep;

  constructor(
    address _verifier,
    uint256 _depositsFrom,
    uint256 _depositsStep,
    uint256 _withdrawalsFrom,
    uint256 _withdrawalsStep
  ) public {
    verifier = _verifier;
    depositsFrom = _depositsFrom;
    depositsStep = _depositsStep;
    withdrawalsFrom = _withdrawalsFrom;
    withdrawalsStep = _withdrawalsStep;
  }

  function executeProposal() public {
    // Disable all instances on old tornado proxy
    bytes32[4] memory miningInstances = getEthInstances();
    for (uint256 i = 0; i < miningInstances.length; i++) {
      tornadoProxyV1.updateInstance(resolve(miningInstances[i]), false);
    }

    // Deploy new TornadoTrees implementation
    TornadoTrees tornadoTreesImpl = new TornadoTrees(address(this), tornadoTreesV1, getSearchParams());
    emit DeploymentOf("TornadoTrees implementation", address(tornadoTreesImpl));

    // Deploy TornadoTrees upgradeable proxy
    AdminUpgradeableProxy upgradeableProxy = new AdminUpgradeableProxy(address(tornadoTreesImpl), address(this), "");
    TornadoTrees tornadoTrees = TornadoTrees(address(upgradeableProxy));
    emit DeploymentOf("TornadoTrees upgradeable proxy", address(upgradeableProxy));

    // Deploy new TornadoProxy
    TornadoProxy tornadoProxy = new TornadoProxy(address(tornadoTrees), address(this), getInstances());
    emit DeploymentOf("TornadoProxy", address(tornadoProxy));

    // Init tornado trees
    tornadoTrees.initialize(address(tornadoProxy), IBatchTreeUpdateVerifier(verifier));

    // Update TornadoTrees address on the mining contract
    miner.setTornadoTreesContract(address(tornadoTrees));
  }

  function getSearchParams() public view returns (TornadoTrees.SearchParams memory) {
    return
      TornadoTrees.SearchParams({
        depositsFrom: depositsFrom,
        depositsStep: depositsStep,
        withdrawalsFrom: withdrawalsFrom,
        withdrawalsStep: withdrawalsStep
      });
  }

  function getEthInstances() internal pure returns (bytes32[4] memory) {
    return [
      bytes32(0xc041982b4f77cbbd82ef3b9ea748738ac6c281d3f1af198770d29f75ac32d80a), // eth-01.tornadocash.eth
      bytes32(0x9e5bc9215eecd103644145a5db4f69d5efaf4885bb5bf968f8db271ec5cd539b), // eth-1.tornadocash.eth
      bytes32(0x917e42347647689051abc744f502bff342c76ad30c0670b46b305b2f7e1f893d), // eth-10.tornadocash.eth
      bytes32(0xddfc726d74f912f49389ef7471e75291969852ce7e5df0509a17bc1e46646985) //  eth-100.tornadocash.eth
    ];
  }

  function getErc20Instances() internal pure returns (bytes32[15] memory) {
    return [
      bytes32(0x95ad5771ba164db3fc73cc74d4436cb6a6babd7a2774911c69d8caae30410982), // dai-100.tornadocash.eth
      bytes32(0x109d0334da83a2c3a687972cc806b0eda52ee7a30f3e44e77b39ae2a20248321), // dai-1000.tornadocash.eth
      bytes32(0x3de4b55be5058f538617d5a6a72bff5b5850a239424b34cc5271021cfcc4ccc8), // dai-10000.tornadocash.eth
      bytes32(0xf50559e0d2f0213bcb8c67ad45b93308b46b9abdd5ca9c7044efc025fc557f59), // dai-100000.tornadocash.eth
      bytes32(0xc9395879ffcee571b0dfd062153b27d62a6617e0f272515f2eb6259fe829c3df), // cdai-5000.tornadocash.eth
      bytes32(0xf840ad6cba4dbbab0fa58a13b092556cd53a6eeff716a3c4a41d860a888b6155), // cdai-50000.tornadocash.eth
      bytes32(0x8e52ade66daf81cf3f50053e9bfca86a57d685eca96bf6c0b45da481806952b1), // cdai-500000.tornadocash.eth
      bytes32(0x0b86f5b8c2f9dcd95382a469480b35302eead707f3fd36359e346b59f3591de2), // cdai-5000000.tornadocash.eth
      bytes32(0xd49809328056ea7b7be70076070bf741ec1a27b86bebafdc484eee88c1834191), // usdc-100.tornadocash.eth
      bytes32(0x77e2b15eddc494b6da6cee0d797ed30ed3945f2c7de0150f16f0405a12e5665f), // usdc-1000.tornadocash.eth
      bytes32(0x36bab2c045f88613be6004ec1dc0c3937941fcf4d4cb78d814c933bf1cf25baf), // usdt-100.tornadocash.eth
      bytes32(0x7a3b0883165756c26821d9b8c9737166a156a78b478b17e42da72fba7a373356), // usdt-1000.tornadocash.eth
      bytes32(0x10ca74c40211fa1598f0531f35c7d54c19c808082aad53c72ad1fb22ea94ab83), // wbtc-01.tornadocash.eth
      bytes32(0x6cea0cba8e46fc4ffaf837edf544ba36e5a35503636c6bca4578e965ab640e2c), // wbtc-1.tornadocash.eth
      bytes32(0x82c57bf2f80547b5e31b92c1f92c4f8bc02ad0df3d27326373e9f55adda5bd15) //  wbtc-10.tornadocash.eth
    ];
  }

  function getInstances() public view returns (TornadoProxy.Tornado[] memory instances) {
    bytes32[4] memory miningInstances = getEthInstances();
    bytes32[15] memory allowedInstances = getErc20Instances();
    instances = new TornadoProxy.Tornado[](allowedInstances.length + miningInstances.length);

    for (uint256 i = 0; i < miningInstances.length; i++) {
      // Enable mining for ETH instances
      instances[i] = TornadoProxy.Tornado(
        ITornadoInstance(resolve(miningInstances[i])),
        TornadoProxy.Instance({ isERC20: false, token: IERC20(address(0)), state: TornadoProxy.InstanceState.MINEABLE })
      );
    }
    for (uint256 i = 0; i < allowedInstances.length; i++) {
      // ERC20 are only allowed on proxy without enabling mining for them
      ITornadoInstance instance = ITornadoInstance(resolve(allowedInstances[i]));
      instances[miningInstances.length + i] = TornadoProxy.Tornado({
        addr: instance,
        instance: TornadoProxy.Instance({
          isERC20: true,
          token: IERC20(instance.token()),
          state: TornadoProxy.InstanceState.ENABLED
        })
      });
    }
  }
}
