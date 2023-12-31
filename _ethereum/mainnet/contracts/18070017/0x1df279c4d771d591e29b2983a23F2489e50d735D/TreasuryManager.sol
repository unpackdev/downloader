// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./Factory.sol";
import "./ITreasuryAsset.sol";
import "./ITreasuryManager.sol";

contract TreasuryManager is Ownable, Initializable, ITreasuryManager {

    using EnumerableSet for EnumerableSet.AddressSet;

    address public defaultFundManager;

    EnumerableSet.AddressSet private _tokens;
    mapping(address => address) private _assetToTokens;
    mapping(address => address) private _fundManagers;

    constructor() {
    }

    function initialize() external payable initializer {
        defaultFundManager = _msgSender();
        _transferOwnership(_msgSender());
    }

    function isTreasury(address treasuryToken) external view override returns(bool) {
        return _tokens.contains(treasuryToken);
    }

    function treasuryOf(address asset) external view override returns(address) {
        return _assetToTokens[asset];
    }

    function setFundManager(address treasury, address account) external onlyOwner {
        if (treasury == address(0)) {
            require(account != address(0), 'FundManager: default fund manager is zero');
            defaultFundManager = account;
        } else {
            _fundManagers[treasury] = account;
        }
        emit FundManager(treasury, account);
    }

    function fundManager(address treasury) external view override returns(address account) {
        account = _fundManagers[treasury];
        if (account == address(0))
            account = defaultFundManager;
    }

    function treasuryAssets() external view returns(TreasuryInfo[] memory result) {
        uint len = _tokens.length();
        result = new TreasuryInfo[](len);
        for(uint i = 0; i < len; i++) {
            result[i].token = _tokens.at(i);
            ITreasuryAsset treasury = ITreasuryAsset(result[i].token);
            IRoboFiERC20 asset = treasury.asset();

            result[i].asset = address(asset); 
            result[i].fundManager = _fundManagers[result[i].token];
            result[i].active = _assetToTokens[result[i].asset] == result[i].token;

            result[i].totalMinted = treasury.totalSupply();
            result[i].totalLocked = treasury.totalLocked();
            if (treasury.isNativeAsset())  
                result[i].liquidity = result[i].token.balance;
            else result[i].liquidity = asset.balanceOf(address(treasury));
        }
    }

    function treasuryCount() external view returns(uint) {
        return _tokens.length();
    }

    function addTreasury(address token) public override onlyOwner {
        if (_tokens.contains(token))
            return;
        address asset = address(ITreasuryAsset(token).asset());
        _tokens.add(token);
        _assetToTokens[asset] = token;
        emit AddTreasury(asset, token);
    }

    function removeTreasury(address token) external override onlyOwner {
        address asset = address(ITreasuryAsset(token).asset());
        _tokens.remove(token);
        if (_assetToTokens[asset] == token) 
            delete _assetToTokens[asset];
        emit RemoveTreasury(token);
    }

}