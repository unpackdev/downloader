// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IFundManager.sol";
import "./ICEXDABotCertToken.sol";
import "./IBCertToken.sol";

contract IBCEXCertToken is IBCertToken {
    constructor(IConfigurator config) IBCertToken(config) {

    }

    function moduleInfo() external pure override virtual
        returns(string memory, string memory, bytes32)
    {
        return ("IBCEXCertToken", "v0.1.20220301", BOT_CERT_TOKEN_TEMPLATE_ID);
    }

    modifier fundManagerOnly() {
        require(_msgSender() == address(fundManager()), Errors.CBCT_CALLER_IS_NOT_FUND_MANAGER);
        _;
    }

    function fundManager() internal view returns(IFundManager manager) {
        manager = IFundManager(_config.addressOf(AddressBook.ADDR_CEX_FUND_MANAGER));
        require(address(manager) != address(0), Errors.CM_CEX_FUND_MANAGER_IS_NOT_CONFIGURED);
    }

    function _lock(uint assetAmount) internal override {
        fundManager().createLockingRequest(address(this), assetAmount);
    }

    function _unlock(uint assetAmount) internal override {
        fundManager().createUnlockingRequest(address(this), assetAmount); 
    }

    function cexLock(uint assetAmount) external fundManagerOnly {
        super._lock(assetAmount);
    }

    function cexUnlock(uint assetAmount) external payable fundManagerOnly {
        super._unlock(assetAmount);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return (interfaceId == type(ICEXDABotCertToken).interfaceId) ||
                super.supportsInterface(interfaceId);  
    }
}