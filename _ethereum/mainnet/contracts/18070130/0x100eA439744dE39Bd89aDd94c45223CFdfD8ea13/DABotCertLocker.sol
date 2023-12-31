// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./Errors.sol";
import "./IInitializable.sol";
import "./IDABot.sol";
import "./IDABotCertToken.sol";
import "./IDABotComponent.sol";
import "./DABotCommon.sol";


abstract contract DABotCertLocker is IInitializable {

    using SafeERC20 for IERC20;

    LockerData internal _info;

    modifier onlyBot() {
        require(msg.sender == _info.bot, Errors.LOCKER_CALLER_IS_NOT_OWNER_BOT);
        _;
    }

    function init(bytes calldata data) external virtual payable override {
        require(address(_info.owner) == address(0), Errors.CM_CONTRACT_HAS_BEEN_INITIALIZED);
        (_info) = abi.decode(data, (LockerData));
    }

    function lockedBalance() public view returns(uint) {
        return IDABotCertToken(_info.token).balanceOf(address(this));
    }

    function asset() external view returns(IERC20) {
        return IDABotCertToken(_info.token).asset();
    }

    function owner() external view returns(address) {
        return _info.owner;
    }

    function detail() public view returns(LockerInfo memory result) {
        result.locker = address(this);
        result.info = _info;
        result.amount = IDABotCertToken(_info.token).balanceOf(address(this));
        result.asset = address(IDABotCertToken(_info.token).asset());
    }

    function unlockable() public view returns(bool) {
        return block.timestamp >= _info.release_at;
    }

    /**
    @dev Tries to unlock this locker if the time condition meets, otherise skipping the action.
     */
    function tryUnlock() public onlyBot returns(bool _unlockable, uint _amount)  {
        _unlockable = unlockable();
        _amount = 0;
        if (_unlockable) 
            _amount = _unlock();  
    }

    function _unlock() internal virtual returns(uint);

    function finalize() external payable onlyBot {
        selfdestruct(payable(_info.owner));
    }
}

/**
@dev This contract provides support for staking warmup feature. 
When users stake into a DABot, user will not immediately receive the certificate token.
Instead, these tokens will be locked inside an instance of this contract for a predefined
period, the warm-up period. 

During the warm-up period, certificate tokens will not generate any reward, no matter rewards
are added to the DABot or not. After the warm-up period, users can claim these tokens to 
their wallet.

If users do not claim tokens after warm-up period, the tokens are still kept securedly inside
the contract. Locked tokens will also entitle to receive rewards. When users claim the tokens, 
rewards will be distributed automatically to users' wallet. 
 */
contract WarmupLocker is DABotCertLocker {

    event Release(address bot, address indexed owner, address indexed certToken, uint256 certAmount, 
                    address indexed asset);

    function _unlock() internal override returns(uint unlockAmount) {

        IDABotCertToken token = IDABotCertToken(_info.token);
        
        require(_info.token != address(0), "CertToken: null token address");
        require(address(token.asset()) != address(0), "CertToken: null asset address");

        IERC20 asset = token.asset();
        unlockAmount = token.balanceOf(address(this));
        token.transfer(_info.owner, unlockAmount);
        emit Release(_info.bot, _info.owner, _info.token, unlockAmount, address(asset));
    }
}


contract CooldownLocker is DABotCertLocker, IDABotComponent {

    using SafeERC20 for IERC20;

    event Release(address bot, address indexed owner, address indexed certToken, uint certAmount, 
                    address indexed asset, uint256 assetAmount);

    function moduleInfo() external pure override
        returns(string memory name, string memory version, bytes32 moduleId)
    {
        name = "CooldownLocker";
        version = "v0.1.20220401";
        moduleId = BOT_CERT_TOKEN_COOLDOWN_HANDLER_ID;
    }

    function _unlock() internal override returns(uint assetAmount) {
        IDABotCertToken token = IDABotCertToken(_info.token);
        IERC20 asset = token.asset();
        uint256 certAmount = token.balanceOf(address(this));
        assetAmount = token.burn(certAmount);
        asset.safeTransfer(_info.owner, assetAmount);
        emit Release(_info.bot, _info.owner, _info.token, certAmount, address(asset), assetAmount);
    }
}