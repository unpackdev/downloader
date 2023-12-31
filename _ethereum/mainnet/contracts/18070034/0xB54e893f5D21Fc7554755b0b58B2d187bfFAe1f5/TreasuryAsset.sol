// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./SafeERC20.sol";
import "./IERC165.sol";
import "./Ownable.sol";
import "./Errors.sol";
import "./RoboFiToken.sol";
import "./ITreasuryAsset.sol";
import "./ITreasuryManager.sol";

contract TreasuryAsset is ITreasuryAssetEvent, RoboFiToken, Ownable, Initializable, IERC165 {  

    using SafeERC20 for IRoboFiERC20;

    address constant BNB_ADDRESS = NATIVE_ASSET_ADDRESS;

    IRoboFiERC20 public asset; 

    mapping(address => uint256) private _lockedBalance;
    uint public totalLocked;

    constructor() RoboFiToken("", "", 0, address(0)) {
    }

    function initialize(IRoboFiERC20 asset_, ITreasuryManager owner_) external payable initializer {
        asset = asset_;
        _transferOwnership(address(owner_));
    }

    function symbol() public view override returns(string memory) {
        if (isNativeAsset())
            return "sBNB";
        return string(abi.encodePacked("s", asset.symbol()));
    }

    function name() public view override returns(string memory) {
        if (isNativeAsset())
            return "RoboFi Stakable Binance Coin";
        return string(abi.encodePacked("RoboFi Stakable ", asset.name()));
    }

    function decimals() public view override returns (uint8) {
        if (isNativeAsset())
            return 18;
        return asset.decimals();
    }

    /**
    @dev Deposits `amount` of original asset, and gets back an equivalent amount of token.
    **/
    function mint(address to, uint256 amount) public payable virtual {
        if (isNativeAsset()) {
            amount = msg.value;
        }
        require(amount > 0, Errors.TA_MINT_ZERO_AMOUNT);

        _assetSafeTransferFrom(_msgSender(), address(this), amount);
        _mint(to, amount);
    }

    /**
    @dev Burns `amount` of sToken WITHOUT get back the original tokens (this is for trading loss). 
    This function should only called from the bot token. Calling from an external account will
    cause fund loss.
     */
    function slash(uint256 amount) external {
        address account = _msgSender();
        _internalBurn(account, amount); 
        emit Slash(account, amount); 
    }

    /**
    @dev Locks `amount` of token from the caller's account (caller). An equivalent amount of 
    original asset will transfer to the fund manager.
    **/    
    function lock(uint256 amount) public virtual {
        if (amount == 0) return;
        
        address _caller = _msgSender();
        require(_lockedBalance[_caller] + amount <= balanceOf(_caller), Errors.TA_LOCK_AMOUNT_EXCEED_BALANCE);

        _lockedBalance[_caller] += amount;
        totalLocked += amount;
        address fundManager = ITreasuryManager(owner()).fundManager(address(this));
        require(fundManager != address(0), Errors.TA_FUND_MANAGER_IS_NOT_SET); 

        _assetSafeTransfer(payable(fundManager), amount);

        emit Lock(_caller, amount);
    }

    /**
    @dev Get the locked amounts of sToken for `user`
    **/
    function lockedBalanceOf(address account) public view virtual returns (uint256) {
        return _lockedBalance[account];
    }

    /**
    @dev Gets `amount` of tocken from the caller account, and decrease the locked balance of `receipient`. 
    **/
    function unlock(address receipient, uint256 amount) public payable virtual { 
        if (isNativeAsset()) {
            require(amount == msg.value, Errors.TA_UNLOCK_AMOUNT_AND_PASSED_VALUE_IS_MISMATCHED);
        }
        uint256 _amount = _lockedBalance[receipient] > amount ? amount : _lockedBalance[receipient];

        _lockedBalance[receipient] -= _amount;
        totalLocked -= _amount;
        _assetSafeTransferFrom(_msgSender(), address(this), _amount);

        emit Unlock(_msgSender(), _amount, receipient);
    }

    /**
    @dev Burns `amount` of sToken to get back original  tokens
     */
    function burn(uint256 amount) public virtual {
        address _caller = _msgSender();
        _burn(_caller, amount);
        _assetSafeTransfer(payable(_caller), amount);
    }

    function _beforeTokenTransfer(address from, address, uint256 amount) internal virtual override {
        if (from == address(0)) // do nothing for minting
            return;
        uint256 _available = balanceOf(from) - _lockedBalance[from];
        require(_available >= amount, Errors.TA_AMOUNT_EXCEED_AVAILABLE_BALANCE);
    }


    function isNativeAsset() public view returns(bool) {
        return (address(asset) == BNB_ADDRESS);
    }

    function _assetSafeTransfer(address payable receiver, uint amount) private {
        if (isNativeAsset()) {
            require(address(this).balance >= amount, Errors.TA_AMOUNT_EXCEED_VALUE_BALANCE);
            require(receiver.send(amount), Errors.TA_FAIL_TO_TRANSFER_VALUE); 
            return;
        }
        asset.safeTransfer(receiver, amount);
    }

    function _assetSafeTransferFrom(address from, address to, uint amount) private {
        if (isNativeAsset())
            return;
        asset.safeTransferFrom(from, to, amount);
    }

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return (interfaceId == type(IERC165).interfaceId) ||
                (interfaceId == type(ITreasuryAsset).interfaceId)
        ;
    }
}