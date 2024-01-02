// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

/// Core /////
import "./CloneFactory.sol";
import "./ProxyRouter.sol";

/// Structs /////
import "./Structs.sol";

/// Interfaces /////
import "./IERC20Metadata.sol";
import "./IFyde.sol";
import "./IRelayer.sol";
import "./ITRSY.sol";
import "./IUserProxy.sol";

///@title GovernanceModule
///@notice Contains the governance functionalities of the Fyde protocol
///        deploys UserProxies, keeps track of assets in governance, allows users to vote,
///        upgrades the user proxy, rebalances assets in proxies
contract GovernanceModule is ProxyRouter, CloneFactory {
  /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

  ///@notice address of fyde
  address public fyde;

  ///@notice address of relayer
  address public relayer;

  ///@notice total amount of trsy staked for governance
  uint256 public totalStrsy;

  ///@notice all registered governance users
  address[] private govUsers;

  ///@notice assets which are currently allowed to be deposited into governance pool
  ///@dev asset => isOnWhitelist
  mapping(address => bool) public isOnGovernanceWhitelist;

  ///@notice mapping from asset address to strsy-asset interface
  mapping(address => ITRSY) public assetToStrsy;

  ///@notice mapping from strsy address to asset address
  ///@dev strsy => asset
  mapping(address => address) public strsyToAsset;

  ///@notice mapping from user address to proxy address
  ///@dev user => proxy
  mapping(address => address) public userToProxy;

  ///@notice mapping from proxy address to user address
  ///@dev proxy => user
  mapping(address => address) public proxyToUser;

  ///@notice internal accounting of assets in proxy
  ///@dev user => asset => balance
  mapping(address => mapping(address => uint256)) public proxyBalance;

  ///@notice the last version of the proxy that is approved for a given user
  ///@dev user => version
  mapping(address => uint256) public approvedProxyVersion;

  /*//////////////////////////////////////////////////////////////
                                ERROR
    //////////////////////////////////////////////////////////////*/

  error InvalidProxy();
  error ProxyBalanceInsufficient(uint256 amountInProxy, uint256 amountToWithdraw);
  error NotEnoughTrsyStaked();
  error SlippageExceed();
  error ProxyUpgradeNotApproved();
  error AssetQuarantined();

  /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

  event VoteProxyDeployed(address indexed proxyAddress);
  event UnstakedGovernance(uint256 amounttrsy, address asset);
  event Rebalanced(address user, address asset);

  /*//////////////////////////////////////////////////////////////
                                 OWNER
    //////////////////////////////////////////////////////////////*/

  ///@notice sets the address of fyde contract
  ///@param _fyde address of fyde
  function setFyde(address _fyde) external onlyOwner {
    fyde = _fyde;
  }

  ///@notice sets the address of relayer contract
  ///@param _relayer address of relayer
  function setRelayer(address _relayer) external onlyOwner {
    relayer = _relayer;
  }

  ///@notice adds asset to governance whitelists and deploys strsy contract
  ///@param _asset Asset to whitelist
  function addAssetToGovWhitelist(address[] calldata _asset) external onlyOwner {
    for (uint256 i; i < _asset.length; i++) {
      // checks if asset has a corresponding strsy and deploys if not
      if (address(assetToStrsy[_asset[i]]) == address(0x0)) {
        string memory name = string.concat("sTRSY-", IERC20Metadata(_asset[i]).symbol());
        ITRSY strsyGT = ITRSY(_createToken(name, name));
        assetToStrsy[_asset[i]] = strsyGT;
        strsyToAsset[address(strsyGT)] = _asset[i];
      }
      isOnGovernanceWhitelist[_asset[i]] = true;
    }
  }

  ///@notice deletes asset from the governance whitelist
  ///@param _asset Address of the asset
  function removeAssetFromGovWhitelist(address _asset) external onlyOwner {
    isOnGovernanceWhitelist[_asset] = false;
  }

  /*//////////////////////////////////////////////////////////////
                            AUTHORIZED EXTERNAL
    //////////////////////////////////////////////////////////////*/

  ///@notice keeps track of governance assets and stakes trsy. Called by Fyde if user uses
  /// govDeposit
  ///@param _depositor User of govDeposit
  ///@param _asset Assets deposited
  ///@param _amount Amount of assets deposited denominated in token
  ///@param _amountTrsy Amount of assets deposited denominated in TRSY
  ///@param _totalTrsy Total amount of trsy
  function govDeposit(
    address _depositor,
    address[] calldata _asset,
    uint256[] calldata _amount,
    uint256[] calldata _amountTrsy,
    uint256 _totalTrsy
  ) external onlyFyde returns (address) {
    address proxy = userToProxy[_depositor];
    if (proxy == address(0x0)) proxy = _createVoteProxy(_depositor);

    for (uint256 i; i < _asset.length; i++) {
      assetToStrsy[_asset[i]].mint(_depositor, _amountTrsy[i]);
      _increaseProxyBalance(_depositor, _asset[i], _amount[i]);
    }

    totalStrsy += _totalTrsy;

    return proxy;
  }

  ///@notice Burns strsy to withdraw equivalent value of governance asset from user proxy.
  ///        Called by Fyde upon governance withdraw.
  ///@param _user User who withdraws assets
  ///@param _asset Array of assets to withdraw
  ///@param _amountToWithdraw Array of amount to withdraw
  ///@param _trsyToBurn sTRSY that is burned
  function govWithdraw(
    address _user,
    address _asset,
    uint256 _amountToWithdraw,
    uint256 _trsyToBurn
  ) external onlyFyde {
    address proxy = userToProxy[_user];
    uint256 amountInProxy = proxyBalance[_user][_asset];

    if (amountInProxy < _amountToWithdraw) {
      revert ProxyBalanceInsufficient(amountInProxy, _amountToWithdraw);
    }

    if (strsyBalance(_user, _asset) < _trsyToBurn) revert NotEnoughTrsyStaked();

    _decreaseProxyBalance(_user, _asset, _amountToWithdraw);

    assetToStrsy[_asset].burn(_user, _trsyToBurn);
    totalStrsy -= _trsyToBurn;

    IUserProxy(proxy).transferAssetToFyde(_asset, _amountToWithdraw);
  }

  ///@notice transfer governance assets into new strsy owners's proxy. Called upon strsy.transfer()
  ///@param _sender Previous owner of strsy
  ///@param _recipient New owner of strsy
  function onStrsyTransfer(address _sender, address _recipient) external {
    // only strsy ERC20 contract can call this function
    address asset = strsyToAsset[msg.sender];
    if (asset == address(0x0)) revert Unauthorized();

    if (userToProxy[_recipient] == address(0x0)) _createVoteProxy(_recipient);

    _rebalanceProxy(_sender, asset, new address[](0));
    _rebalanceProxy(_recipient, asset, new address[](0));
  }

  /*//////////////////////////////////////////////////////////////
                    EXTERNAL USER ENTRY POINT
    //////////////////////////////////////////////////////////////*/

  ///@notice User approves upgrades to the governance proxy which are done by the Fyde team.
  ///@dev    Without approval, proxy cannot be used. Prevents malicious upgrades.
  function approveCurrentProxyVersion() external {
    approvedProxyVersion[msg.sender] = proxyVersion;
  }

  ///@notice converts strsy to standard trsy - THIS IS IRREVERSIBLE
  ///@param _amount Amount of trsy that should be unstaked
  ///@param _asset Asset for which the trsy is currently staked
  function unstakeGov(uint256 _amount, address _asset) external {
    if (IRelayer(relayer).isQuarantined(_asset)) revert AssetQuarantined();
    if (strsyBalance(msg.sender, _asset) < _amount) revert NotEnoughTrsyStaked();
    totalStrsy -= _amount;
    assetToStrsy[_asset].burn(msg.sender, _amount);
    ITRSY(fyde).transfer(msg.sender, _amount);
    _rebalanceProxy(msg.sender, _asset, new address[](0));
    emit UnstakedGovernance(_amount, _asset);
  }

  ///@notice Rebalances amount of asset in proxy to correspond to value of staked trsy
  ///@param _user User to rebalance
  ///@param _asset Asset for which the balance is updated
  ///@param _usersToRebalance array of most overweight users to take assets from
  ///@dev admin can rebalance any proxy, normal users only their own proxy
  function rebalanceProxy(address _user, address _asset, address[] memory _usersToRebalance)
    external
  {
    if (userToProxy[_user] == address(0x0)) revert InvalidProxy();
    if (msg.sender != _user && msg.sender != owner) revert Unauthorized();
    if (strsyBalance(_user, _asset) == 0) revert NotEnoughTrsyStaked();
    _rebalanceProxy(_user, _asset, _usersToRebalance);
  }

  /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

  ///@notice get array of all governance users
  ///@dev this might become quite long - intended for off-chain use
  function getAllGovUsers() public view returns (address[] memory) {
    return govUsers;
  }

  ///@notice checks if any assets it not whitelisted for governance
  ///@return address of not whitelisted asset or zero address if all are whitelisted
  function isAnyNotOnGovWhitelist(address[] calldata _assets) public view returns (address) {
    for (uint256 i; i < _assets.length; i++) {
      if (!isOnGovernanceWhitelist[_assets[i]]) return _assets[i];
    }
    return address(0x0);
  }

  ///@notice Get amount of token allowance from amount of strsy
  ///@param _user User to get allowance of
  ///@param _asset Asset address
  ///@dev When enough token of the asset exists in the protocol, the function makes a conversion
  /// based on
  ///     price of trsy and the asset. If not enough token are available, allowance corresponds to
  /// faire share
  ///     of available token
  function getUserGTAllowance(address _user, address _asset) public view returns (uint256) {
    return _getUserGTAllowance(_user, _getRebalanceParams(_asset));
  }

  ///@notice Difference between a users allowance and actual proxy balance
  ///@param _user User to get unbalance of
  ///@param _asset Asset address
  ///@return int value is the missing token amount, i.e. allowance minus actual balance.
  ///        Overweight users have a negative unbalance
  function getTokenUnbalance(address _user, address _asset) public view returns (int256) {
    return _getTokenUnbalance(_user, _getRebalanceParams(_asset));
  }

  ///@notice get the strsy balance of user for asset
  ///@param _user User
  ///@param _asset Asset to get strsy balance for
  function strsyBalance(address _user, address _asset) public view returns (uint256) {
    ITRSY strsyToken = assetToStrsy[_asset];
    if (address(strsyToken) == address(0x0)) return 0;
    return assetToStrsy[_asset].balanceOf(_user);
  }

  /*//////////////////////////////////////////////////////////////
                            INTERNAL
    //////////////////////////////////////////////////////////////*/

  ///@dev Deploys proxy for user and updates registry
  function _createVoteProxy(address _user) internal returns (address) {
    address proxy = _createProxy();

    userToProxy[_user] = proxy;
    proxyToUser[proxy] = _user;
    approvedProxyVersion[_user] = proxyVersion;
    govUsers.push(_user);

    emit VoteProxyDeployed(proxy);

    return proxy;
  }

  ///@dev Redistributes token according to allowance.
  function _rebalanceProxy(address _user, address _asset, address[] memory _usersToRebalance)
    internal
  {
    RebalanceParam memory params = _getRebalanceParams(_asset);

    int256 amountMissing = _getTokenUnbalance(_user, params);

    if (amountMissing == 0) return;

    if (amountMissing > 0) {
      // if underweight, check how much to take from other proxies and how much from standard pool
      int256 toTakeFromProxies = amountMissing - _toTakeFromStandardPool(params);
      uint256 proxyAmountOld = params.assetProxyAmount;
      // transfer overweight from proxies to fyde
      for (uint256 i = 0; i < _usersToRebalance.length; i++) {
        if (toTakeFromProxies <= int256(proxyAmountOld - params.assetProxyAmount)) break;
        int256 proxyUnderweight = _getTokenUnbalance(_usersToRebalance[i], params);
        if (proxyUnderweight < 0) {
          params = _rebalance(_usersToRebalance[i], proxyUnderweight, params);
        }
      }
    }

    // transfer missing asset from fyde to user proxy
    params = _rebalance(_user, amountMissing, params);

    IFyde(fyde).updateAssetProxyAmount(params.asset, params.assetProxyAmount);
  }

  ///@dev overweight tokens are transferred to fyde standard pool and underweight tokens from
  /// standard pool into proxy
  function _rebalance(address _user, int256 _amountToTransfer, RebalanceParam memory _params)
    internal
    returns (RebalanceParam memory)
  {
    address proxy = userToProxy[_user];
    uint256 standardPoolBalance = _params.assetTotalAmount - _params.assetProxyAmount;

    uint256 amountAsUint =
      _amountToTransfer < 0 ? uint256(-_amountToTransfer) : uint256(_amountToTransfer);
    if (_amountToTransfer < 0) {
      IUserProxy(proxy).transferAssetToFyde(_params.asset, amountAsUint);
      //accounting
      _params.assetProxyAmount -= amountAsUint;
      _decreaseProxyBalance(_user, _params.asset, amountAsUint);
    } else if (amountAsUint > standardPoolBalance) {
      IFyde(fyde).transferAsset(_params.asset, proxy, standardPoolBalance);
      //accounting
      _params.assetProxyAmount += standardPoolBalance;
      _increaseProxyBalance(_user, _params.asset, standardPoolBalance);
    } else {
      IFyde(fyde).transferAsset(_params.asset, proxy, amountAsUint);
      //accounting
      _params.assetProxyAmount += amountAsUint;
      _increaseProxyBalance(_user, _params.asset, amountAsUint);
    }

    emit Rebalanced(_user, _params.asset);

    return _params;
  }

  ///@dev All variables from fyde needed for rebalancing. Put in one struct and one external call
  /// for gas optimization
  function _getRebalanceParams(address _asset) internal view returns (RebalanceParam memory params) {
    params = IFyde(fyde).getRebalanceParams(_asset);
    params.sTrsyTotalSupply = assetToStrsy[_asset].totalSupply();
  }

  ///@dev Convert trsy to token amount of equal USD value
  function _trsyToTokenAmount(uint256 _amount, RebalanceParam memory _params)
    internal
    pure
    returns (uint256)
  {
    return _params.trsyPrice * _amount / (_params.assetPrice);
  }

  ///@dev Allowance of governance rights based on users sTRSY balance
  function _getUserGTAllowance(address _user, RebalanceParam memory _params)
    internal
    view
    returns (uint256)
  {
    uint256 govAmount = _trsyToTokenAmount(_params.sTrsyTotalSupply, _params);
    uint256 sTrsyBalance = strsyBalance(_user, _params.asset);

    if (_params.assetTotalAmount >= govAmount) return _trsyToTokenAmount(sTrsyBalance, _params);
    else return _params.assetTotalAmount * sTrsyBalance / _params.sTrsyTotalSupply;
  }

  ///@dev gets the token amount that should be taken from standard pool when rebalancing user proxy.
  ///     Difference between token equivalent of all strsy (= amount of assets that should be in
  /// governance)
  ///     and the amount that currently is in all proxies
  function _toTakeFromStandardPool(RebalanceParam memory _params) internal pure returns (int256) {
    uint256 totalStrsyInToken = _trsyToTokenAmount(_params.sTrsyTotalSupply, _params);

    // if theres not enough asset in the protocol, take all there is
    totalStrsyInToken =
      totalStrsyInToken > _params.assetTotalAmount ? _params.assetTotalAmount : totalStrsyInToken;

    // difference between how much should be in governance and actually is
    return int256(totalStrsyInToken) - int256(_params.assetProxyAmount);
  }

  ///@dev Difference between a users allowance and actual proxy balance
  function _getTokenUnbalance(address _user, RebalanceParam memory _params)
    internal
    view
    returns (int256)
  {
    return int256(_getUserGTAllowance(_user, _params)) - int256(proxyBalance[_user][_params.asset]);
  }

  function _increaseProxyBalance(address _user, address _asset, uint256 _amount) internal {
    proxyBalance[_user][_asset] += _amount;
  }

  function _decreaseProxyBalance(address _user, address _asset, uint256 _amount) internal {
    proxyBalance[_user][_asset] -= _amount;
  }

  ///@dev fallback that forwards calls to the user proxy. Users can call arbitrary governance
  /// functions on the
  ///     governance module which will be executed by their proxy if functions are implemented on
  /// the user proxy
  function _forwardToProxy() internal {
    address proxy = userToProxy[msg.sender];
    if (proxy == address(0x0)) revert InvalidProxy();
    if (approvedProxyVersion[msg.sender] != proxyVersion) revert ProxyUpgradeNotApproved();

    assembly {
      // copy function selector and any arguments
      calldatacopy(0, 0, calldatasize())
      // execute function call using the facet
      let result := call(gas(), proxy, callvalue(), 0, calldatasize(), 0, 0)
      // get any return value
      returndatacopy(0, 0, returndatasize())
      // return any return value or error back to the caller
      switch result
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }

  /*//////////////////////////////////////////////////////////////
                            FALLBACK
  //////////////////////////////////////////////////////////////*/

  ///@dev If called from external, forwards to msg.sender's proxy. If delegate called from the
  /// proxy, delegates to implementation of proxy
  fallback() external {
    if (msg.sender != GOVERNANCE_MODULE) _forwardToProxy();
    else _delegateToImplementation();
  }

  /*//////////////////////////////////////////////////////////////
                                MODIFIERS
  //////////////////////////////////////////////////////////////*/

  modifier onlyFyde() {
    if (msg.sender != fyde) revert Unauthorized();
    _;
  }
}
