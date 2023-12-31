// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./DABotCommon.sol";

interface IFundManagerEvent {
    /**
    @dev Triggered when a new request has been created
    @param reqType the type of the request.
                        0x1f8a3e92 - locking request
                        0xeaef5f92 - unlocking request
                        0x467503a0 - awarding request
    @param requestId the uniqude id for the generated request
    @param botOrToken the address of the certificate token (lock/unlock request), or bot address (awarding request).
    @param amount the amount of token associated with the request. For awarding request, amount is always 0.
    @param requester the account who initiates the request. 
     */
    event NewRequest(bytes4 reqType, uint requestId, address indexed botOrToken, uint amount, address indexed requester);

    /**
    @dev Triggered subsequently after an awarding request, which denotes the detail information of the request.
    @param data the details of the awarding request.
     */
    event AwardingRequestDetail(AwardingDetail[] data);
    
    /**
    @dev Triggered when a request has been closed
    @param requestId the unique identifier of the request
    @param closeType determines how request is closed: 0 - approved, 1 - rejected, 2 - canceled
    @param approver the account closing this request
     */
    event CloseRequest(uint requestId, uint8 closeType, address indexed approver);
}

interface IFundManager is IFundManagerEvent {
    /**
    @dev Creates a locking request, for internal call only.
     */
    function createLockingRequest(address botToken, uint assetAmount) external returns(uint requestId);

    /**
    @dev Creates an unlocking request, for internal call only.
     */
    function createUnlockingRequest(address botToken, uint assetAmount) external returns(uint requestId);

    /**
    @dev Creates an awarding request, for internal call only.
     */
    function createAwardingRequest(address bot, AwardingDetail[] calldata data) external returns(uint requestId);

    /**
    @dev Canceled a funding request, should be called by the request creator.
    @param requestId the identifier of the request to cancel. Transaction reverts if no such request found.
     */
    function cancelRequest(uint requestId) external;

    /**
    @dev Closes a funding request. Could be either approve or reject the given request.
    @param requestId the identifier of the request to close.
    @param closeType determins whether to request is approved or rejected.
                    0 - approved, 1 - rejected.
    @param requestData the extra data when approving a request. For locking/unlock requests, this parameter
            should be empty. For awarding request, this parameter should be exactly the same data passed to 
            the createAwardingRequest function. Otherwise, the transaction may be reverted.
     */
    function closeRequest(uint requestId, uint8 closeType, bytes calldata requestData) external;
}