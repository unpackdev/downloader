// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./ERC165Checker.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./Errors.sol";
import "./IConfigurator.sol";
import "./Ownable.sol";
import "./ITreasuryAsset.sol";
import "./ITreasuryManager.sol";
import "./ICEXFundManagerModule.sol";
import "./IFundManager.sol";
import "./ICEXDABotCertToken.sol";

struct FundingRequest {
    bytes4 requestType; 
    address requester;
    address botToken; 
    uint amount;
}

contract FundManager is Context, Ownable, Initializable, IFundManagerEvent {

    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    IConfigurator internal _config;

    bytes4 constant REQ_LOCK = bytes4(keccak256('lock'));       // 0x6168652c
    bytes4 constant REQ_UNLOCK = bytes4(keccak256('unlock'));   // 0xa1dfce33
    bytes4 constant REQ_AWARD = bytes4(keccak256('award'));     // 0x2c955cd5

    uint8 constant REQ_CANCELED = 2;

    mapping(uint => FundingRequest) private _requests;

    modifier validRequestId(uint requestId) {
        FundingRequest storage request = _requests[requestId];
        require(request.botToken != address(0), Errors.CFM_INVALID_REQUEST_ID);
        _;
    }

    modifier approverOnly() {
        require(_config.hasRole(Roles.ROLE_FUND_APPROVER, _msgSender()), Errors.CFM_CALLER_IS_NOT_APPROVER);
        _;
    }

    modifier requireTreasuryAssetCertificate(address token) {
        require(token.supportsInterface(type(ICEXDABotCertToken).interfaceId), Errors.CFM_CEX_CERTIFICATE_IS_REQUIRED);
        require(address(ICEXDABotCertToken(token).asset()).supportsInterface(type(ITreasuryAsset).interfaceId), 
            Errors.CFM_TREASURY_ASSET_CERTIFICATE_IS_REQUIRED);
        _;
    }

    function initialize(IConfigurator config) external payable initializer {
        _config = config;
        _transferOwnership(_msgSender());
    }

    receive() external payable {

    }

    function configProvider() external view returns(IConfigurator) {
        return _config;
    }

    function setConfigProvider(IConfigurator config) external onlyOwner {
        _config = config;
    }

    function requestOf(uint requestId) external view returns(FundingRequest memory) {
        return _requests[requestId];
    }

    function createLockingRequest(address botToken, uint assetAmount) external requireTreasuryAssetCertificate(botToken) returns(uint) {
        require(_msgSender() == botToken, Errors.CFM_CALLER_IS_NOT_BOT_TOKEN);
        return _createFundingRequest(REQ_LOCK, botToken, assetAmount);
    }

    function createUnlockingRequest(address botToken, uint assetAmount) external requireTreasuryAssetCertificate(botToken) returns(uint) {
        require(_msgSender() == botToken, Errors.CFM_CALLER_IS_NOT_BOT_TOKEN);
        return _createFundingRequest(REQ_UNLOCK, botToken, assetAmount);
    }

    function createAwardingRequest(address bot, AwardingDetail[] calldata data) external  returns(uint requestId) {
        requestId = _createFundingRequest(REQ_AWARD, bot, 0);
        emit AwardingRequestDetail(data);
    }

    function closeRequest(uint requestId, uint8 closeType, bytes calldata requestData) external validRequestId(requestId) approverOnly {
        require(closeType <= 1, Errors.CFM_CLOSE_TYPE_VALUE_IS_NOT_SUPPORTED);
        if (closeType == 0) {
            FundingRequest storage request = _requests[requestId];
            if (request.requestType == REQ_LOCK)
                _approveLockingRequest(request);
            else if (request.requestType == REQ_UNLOCK)
                _approveUnlockingRequest(request);
            else if (request.requestType == REQ_AWARD) 
                _approveAwardingRequest(request, requestData);
            else revert(Errors.CFM_UNKNOWN_REQUEST_TYPE);
        }
        _closeRequest(requestId, closeType); 
    }

    function cancelRequest(uint requestId) external validRequestId(requestId) {
        FundingRequest storage request = _requests[requestId];
        require(request.requester == _msgSender(), Errors.CFM_CALLER_IS_NOT_REQUESTER);
        _closeRequest(requestId, REQ_CANCELED);
    }

    function masterAccount(address) public view returns(address) {
        address reciever = _config.addressOf(AddressBook.ADDR_CEX_DEFAULT_MASTER_ACCOUNT);
        require(reciever != address(0), Errors.CM_CEX_DEFAULT_MASTER_ACCOUNT_IS_NOT_CONFIGURED);
        return reciever;
    }

    function _createFundingRequest(bytes4 req, address botToken, uint assetAmount) private returns(uint requestId) {
        requestId = _requestId(req, botToken);
        FundingRequest storage request = _requests[requestId];
        if (request.botToken == address(0)) {
            request.requester = tx.origin;
            request.requestType = req;
            request.botToken = botToken;
        }
        require(request.requestType == req, Errors.CFM_REQ_TYPE_IS_MISMATCHED);
        request.amount += assetAmount;
        emit NewRequest(req, requestId, botToken, request.amount, request.requester);
    }

    function _closeRequest(uint requestId, uint8 closeType) internal {
        delete _requests[requestId];
        emit CloseRequest(requestId, closeType, _msgSender());
    }

    function _approveLockingRequest(FundingRequest storage request) internal {
        ICEXDABotCertToken token = ICEXDABotCertToken(request.botToken);
        token.cexLock(request.amount);
        _safeTransfer(token, masterAccount(token.owner()), request.amount);
    }

    function _approveUnlockingRequest(FundingRequest storage request) internal {
        ICEXDABotCertToken token = ICEXDABotCertToken(request.botToken);
        bool isNative = ITreasuryAsset(address(token.asset())).isNativeAsset();
        if (isNative)
            token.cexUnlock{value: request.amount}(request.amount);
        else {
            _safeTransfer(token, request.botToken, request.amount);
            token.cexUnlock(request.amount);
        }
    }

    function _approveAwardingRequest(FundingRequest storage request, bytes calldata requestData) internal {
        (AwardingDetail[] memory data) = abi.decode(requestData, (AwardingDetail[]));
        ICEXFundManagerModule bot = ICEXFundManagerModule(request.botToken);
        for (uint i = 0; i < data.length; i++) {
            _convertTreasuryAsset(request.botToken, data[i]);
        }
        bot.distributeReward(data);
    }

    function _convertTreasuryAsset(address bot, AwardingDetail memory data) private {
        ITreasuryAsset treasuryAsset = _toITreasuryAsset(data.asset);
        bool isNative = treasuryAsset.isNativeAsset();
        IRoboFiERC20 underlyingAsset = treasuryAsset.asset();

        uint amount = data.reward;
        if (data.compoundMode == 0)
            amount += data.compound;
        if (amount == 0)
            return;
        if (isNative) {
            require(address(this).balance >= amount, Errors.CFM_INSUFFIENT_ASSET_TO_MINT_STOKEN);
            treasuryAsset.mint{ value: amount }(address(this), amount);
        } else {
            require(underlyingAsset.balanceOf(address(this)) >= amount, Errors.CFM_INSUFFIENT_ASSET_TO_MINT_STOKEN);
            if (underlyingAsset.allowance(address(this), address(treasuryAsset)) < amount)
                underlyingAsset.approve(address(treasuryAsset), type(uint).max);
            treasuryAsset.mint(address(this), amount);
        }
        
        if (treasuryAsset.allowance(address(this), bot) < amount)
            treasuryAsset.approve(bot, amount);
    }

    function _requestId(bytes4 req, address botToken) private view returns(uint) {
        return uint256(keccak256(abi.encodePacked(req, block.number + 1, botToken)));
    }

    function _toITreasuryAsset(address account) private view returns (ITreasuryAsset) {
        require(account.supportsInterface(type(ITreasuryAsset).interfaceId), Errors.CFM_AWARDED_ASSET_IS_NOT_TREASURY);
        return ITreasuryAsset(account);
    }

    function _safeTransfer(ICEXDABotCertToken token, address to, uint amount) internal {
        ITreasuryAsset treasury = ITreasuryAsset(address(token.asset()));
        bool isNative = treasury.isNativeAsset();
        if (isNative) {
            require(payable(to).send(amount), Errors.CFM_FAIL_TO_TRANSFER_VALUE);
        } else {
            IERC20(address(treasury.asset())).safeTransfer(to, amount);
        }
    }
}
