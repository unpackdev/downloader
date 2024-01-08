// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "./ChainlinkClient.sol";
import "./BaseUpgradeabililtyProxy.sol";

contract ChainlinkDollarSpendingConsumer is ChainlinkClient, BaseUpgradeabililtyProxy {
  using Chainlink for Chainlink.Request;

  uint256 public volume;

  address internal _wallet;
  address internal _walletOracle;
  address internal _admin;

  address internal oracle;
  bytes32 internal jobId;
  uint256 internal fee;
  mapping(address => bool) internal implementations;

  function initialize() public virtual override {
    revert("Should not call");
  }

  function implement(address implementation) external onlyAllowed {
    upgradeTo(implementation);
  }

  function isInitialized(address _implementation) public view returns (bool) {
    return implementations[_implementation];
  }

  function initialized(address _implementation) internal {
    implementations[_implementation] = true;
  }

  modifier initializer() {
    require(!isInitialized(implementation()), "Initializable: contract is already initialized");

    initialized(implementation());

    _;
  }

  function oracleAddress() external view returns (address) {
    return oracle;
  }

  function jobIdData() external view returns (bytes32) {
    return jobId;
  }

  function setup(address walletOracle, address wallet) external onlyAllowed() {
    require(_walletOracle == address(0), "ChainlinkDollarSpendingConsumer: Oracle already stored");

    _walletOracle = walletOracle;
    _wallet = wallet;
  }

  /**
   * Create a Chainlink request to retrieve API response, find the target
   * data, then multiply by 1000000000000000000 (to remove decimal places from data).
   */
  function requestVolumeData() public returns (bytes32 requestId)
  {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    require(link.balanceOf(address(this)) >= fee, "ChainlinkDollarSpendingConsumer: Not link enough balance");

    Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

    return sendChainlinkRequestTo(oracle, request, fee);
  }

  /**
   * Receive the response in the form of uint256
   */
  function fulfill(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId)
  {
    volume = _volume;
  }

  function withdrawLink(address owner) public onlyAllowed() {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());

    require(link.transfer(owner, link.balanceOf(address(this))), "Unable to transfer");
  }

  function setNewOracle(address _oracle, bytes32 _jobId) public onlyAllowed() {
    oracle = _oracle;
    jobId = _jobId;
  }

  modifier onlyAllowed() {
    require(
      msg.sender == _wallet || msg.sender == _walletOracle || msg.sender == _admin,
      "ChainlinkDollarSpendingConsumer: Not allowed"
    );

    _;
  }
}
