pragma solidity 0.6.4;
pragma experimental ABIEncoderV2;

import "./Pausable.sol";
import "./SafeMath.sol";
import "./UpgradableOwnable.sol";
import "./IDepositExecute.sol";
import "./IBridge.sol";
import "./IERCHandler.sol";

/**
    @title Facilitates deposits, creation and votiing of deposit proposals, and deposit executions.
 */
contract Bridge is Pausable, SafeMathContract, UpgradableOwnable {
    bytes8 public _chainID;
    uint256 public _fee;
    address public _backendSrvAddress;

    enum ProposalStatus {
        Inactive,
        Active,
        Passed,
        Executed,
        Cancelled
    }

    bytes32 public _nativeResourceID;

    // destinationChainID => number of deposits
    mapping(bytes8 => uint64) public _depositCounts;
    // resourceID => handler address
    mapping(bytes32 => address) public _resourceIDToHandlerAddress;
    // depositNonce => destinationChainID => bytes
    mapping(uint64 => mapping(bytes8 => bytes)) public _depositRecords;
    // destinationChainID + depositNonce => dataHash => bool
    mapping(bytes32 => mapping(bytes32 => bool)) public _executedProposals;

    mapping(address => bool) public handlers;

    event Deposit(
        bytes8 originChainID,
        bytes8 indexed destinationChainID,
        bytes32 indexed resourceID,
        uint64 indexed depositNonce,
        address depositor,
        address recipientAddress,
        address tokenAddress,
        uint256 amount,
        bytes32 dataHash
    );
    event ProposalEvent(
        bytes8 indexed originChainID,
        bytes8 indexed destinationChainID,
        address indexed recipientAddress,
        uint256 amount,
        uint64 depositNonce,
        ProposalStatus status,
        bytes32 resourceID,
        bytes32 dataHash
    );
    event ExtraFeeSupplied(
        bytes8 originChainID,
        bytes8 destinationChainID,
        uint64 depositNonce,
        bytes32 resourceID,
        address recipientAddress,
        uint256 amount
    );

    modifier onlyBackendSrv() {
        _onlyBackendSrv();
        _;
    }

    function _onlyBackendSrv() private view {
        require(
            _backendSrvAddress == msg.sender,
            "sender is not a backend service"
        );
    }

    modifier onlyHandler() {
        require(handlers[msg.sender], "sender is not a handler" );
        _;
    }

    function setHandler(address _handler, bool value) external onlyBackendSrv {
        handlers[_handler] = value;
    }

    /**
        @notice Initializes Bridge, creates and grants {msg.sender} the admin role,
        Sets deposit fee
        @param chainID ID of chain the Bridge contract exists on.
     */
    function initialize(
        bytes8 chainID,
        uint256 fee,
        address initBackendSrvAddress
    ) public {
        _chainID = chainID;
        _fee = fee;
        _backendSrvAddress = initBackendSrvAddress;
        ownableInit(msg.sender);
    }

    /**
        @notice sets new backend srv.
        @notice Only callable by an address that currently has the admin role.
        @param newBackendSrv Address of new backend srv.
     */
    function setBackendSrv(address newBackendSrv) external onlyBackendSrv {
        _backendSrvAddress = newBackendSrv;
    }

    /**
        @notice Pauses deposits, proposal creation and voting, and deposit executions.
        @notice Only callable by an address that currently has the admin role.
     */
    function adminPauseTransfers() external onlyOwner {
        _pause();
    }

    /**
        @notice Unpauses deposits, proposal creation and voting, and deposit executions.
        @notice Only callable by an address that currently has the admin role.
     */
    function adminUnpauseTransfers() external onlyOwner {
        _unpause();
    }

    /**
        @notice Sets a new resource for handler contracts that use the IERCHandler interface,
        and maps the {handlerAddress} to {resourceID} in {_resourceIDToHandlerAddress}.
        @notice Only callable by an address that currently has the admin role.
        @param handlerAddress Address of handler resource will be set for.
        @param resourceID ResourceID to be used when making deposits.
        @param tokenAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
    function setResource(
        address handlerAddress,
        bytes32 resourceID,
        address tokenAddress
    ) external onlyBackendSrv {
        _resourceIDToHandlerAddress[resourceID] = handlerAddress;
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.setResource(resourceID, tokenAddress);
        handlers[handlerAddress] = true;
    }

    /**
        @notice sets resourceID for native token
        @dev can only be called through admin address
        @param resourceID resourceID for native token
     */
    function setNativeResourceID(bytes32 resourceID) external onlyBackendSrv {
        _nativeResourceID = resourceID;
    }

    /**
        @notice Sets a resource as burnable for handler contracts that use the IERCHandler interface.
        @notice Only callable by an address that currently has the admin role.
        @param handlerAddress Address of handler resource will be set for.
        @param tokenAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
    function setBurnable(address handlerAddress, address tokenAddress)
        external
        onlyBackendSrv
    {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.setBurnable(tokenAddress);
    }

    /**
        @notice Changes deposit fee.
        @notice Only callable by admin.
        @param newFee Value {_fee} will be updated to.
     */
    function changeFee(uint256 newFee) external onlyBackendSrv {
        require(_fee != newFee, "Current fee is equal to new fee");
        _fee = newFee;
    }

    /**
        @notice Used to manually withdraw funds from ERC safes.
        @param handlerAddress Address of handler to withdraw from.
        @param tokenAddress Address of token to withdraw.
        @param recipient Address to withdraw tokens to.
        @param amountOrTokenID Either the amount of ERC20 tokens or the ERC721 token ID to withdraw.
     */
    function adminWithdraw(
        address handlerAddress,
        address tokenAddress,
        address recipient,
        uint256 amountOrTokenID
    ) external onlyOwner {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.withdraw(tokenAddress, recipient, amountOrTokenID);
    }

    /**
        @notice Used to approve spending tokens by another handler.
        @param resourceIDOwner ID of owner handler.
        @param resourceIDSpender ID of spender handler.
        @param amountOrTokenID Either the amount of ERC20 tokens or the ERC721 token ID to approve.
     */
    function approveSpending(
        bytes32 resourceIDOwner,
        bytes32 resourceIDSpender,
        uint256 amountOrTokenID
    ) external onlyBackendSrv {
        address handlerOwner = _resourceIDToHandlerAddress[resourceIDOwner];
        require(handlerOwner != address(0), "resourceIDOwner not mapped to handler");

        address handlerSpender = _resourceIDToHandlerAddress[resourceIDSpender];
        require(handlerSpender != address(0), "resourceIDSpender not mapped to handler");

        IERCHandler handler = IERCHandler(handlerOwner);
        handler.approve(resourceIDOwner, handlerSpender, amountOrTokenID);
    }

    /**
        @notice Initiates a transfer using a specified handler contract.
        @notice Only callable when Bridge is not paused.
        @param destinationChainID ID of chain deposit will be bridged to.
        @param resourceID ResourceID used to find address of handler to be used for deposit.
        @param amountToLA to be converted to LA with bridge swap.
        @notice Emits {Deposit} event.
     */
    function deposit(
        bytes8 destinationChainID,
        bytes32 resourceID,
        uint256 amount,
        address recipientAddress,
        uint256 amountToLA,
        bytes calldata params
    ) external payable whenNotPaused {
        uint64 depositNonce = ++_depositCounts[destinationChainID];
        bytes memory data = abi.encode(amount, recipientAddress);
        bytes32 dataHash = keccak256(abi.encode(resourceID, data));
        _depositRecords[depositNonce][destinationChainID] = data;

        address tokenAddress;
        uint256 totalAmount = amount + amountToLA;
        if (resourceID == _nativeResourceID) {
            require(
                msg.value >= (totalAmount + _fee),
                "Incorrect fee/amount supplied"
            );

            tokenAddress = address(0);

        } else {
            require(msg.value >= _fee, "Incorrect fee supplied");

            address handler = _resourceIDToHandlerAddress[resourceID];
            require(handler != address(0), "resourceID not mapped to handler");

            tokenAddress = IDepositExecute(handler).deposit(
                resourceID,
                destinationChainID,
                depositNonce,
                msg.sender,
                recipientAddress,
                totalAmount,
                params
            );
        }
            if (amountToLA > 0) {
                emit ExtraFeeSupplied(
                    _chainID,
                    destinationChainID,
                    depositNonce,
                    resourceID,
                    recipientAddress,
                    amountToLA
                );
            }

        uint256 stackAmount = amount;

        emit Deposit(
            _chainID,
            destinationChainID,
            resourceID,
            depositNonce,
            msg.sender,
            recipientAddress,
            tokenAddress,
            stackAmount,
            dataHash
        );
    }
    
    // Deposit for AAVE amTokens
    function internalDeposit(
        bytes8 destinationChainID,
        bytes32 resourceID,
        uint256 amount,
        address recipientAddress
    ) public whenNotPaused onlyHandler {
        uint64 depositNonce = ++_depositCounts[destinationChainID];
        bytes memory data = abi.encode(amount, recipientAddress);
        bytes32 dataHash = keccak256(abi.encode(resourceID, data));
        _depositRecords[depositNonce][destinationChainID] = data;

        address handler = _resourceIDToHandlerAddress[resourceID];
        address tokenAddress = IDepositExecute(handler).getAddressFromResourceId(resourceID);
        
        emit Deposit(
            _chainID,
            destinationChainID,
            resourceID,
            depositNonce,
            msg.sender,
            recipientAddress,
            tokenAddress,
            amount,
            dataHash
        );
    }

    /**
        @notice Executes a deposit proposal that is considered passed using a specified handler contract.
        @notice Only callable by relayers when Bridge is not paused.
        @param destinationChainID ID of chain where proposal is executed.
        @param resourceID ResourceID to be used when making deposits.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @notice Proposal must not have executed before.
        @notice Emits {ProposalEvent} event with status {Executed}.
     */
    function executeProposal(
        bytes8 originChainID,
        bytes8 destinationChainID,
        uint64 depositNonce,
        bytes32 resourceID,
        address payable recipientAddress,
        uint256 amount,
        bytes calldata params
    ) external onlyBackendSrv whenNotPaused {
        bytes memory data = abi.encode(amount, recipientAddress);
        bytes32 nonceAndID = keccak256(
            abi.encode(depositNonce, originChainID, destinationChainID)
        );
        bytes32 dataHash = keccak256(abi.encode(resourceID, data));

        require(
            !_executedProposals[nonceAndID][dataHash],
            "proposal already executed"
        );
        require(destinationChainID == _chainID, "ChainID Incorrect");

        _executedProposals[nonceAndID][dataHash] = true;

        if (resourceID == _nativeResourceID) {
            recipientAddress.transfer(amount);
        } else {
            address handler = _resourceIDToHandlerAddress[resourceID];
            require(handler != address(0), "resourceID not mapped to handler");

            IDepositExecute depositHandler = IDepositExecute(handler);
            depositHandler.executeProposal(
                resourceID,
                recipientAddress,
                amount,
                params
            );
        }

        emit ProposalEvent(
            originChainID,
            destinationChainID,
            recipientAddress,
            amount,
            depositNonce,
            ProposalStatus.Executed,
            resourceID,
            dataHash
        );
    }

    /**
        @notice to be called if owner wants to collect fees
        @dev can only be called by owner
        @param amount will be trasnfered to owner if contract balace is higher or equal to amount
    */
    function adminCollectFees(address payable recipient, uint256 amount) external onlyOwner {
        uint256 amountToTransfer = amount < address(this).balance
            ? amount
            : address(this).balance;
        recipient.transfer(amountToTransfer);
    }

    /** 
        @notice to deposit native token to the contract
        @dev to be called by admin
    */
    function depositFunds() external payable onlyOwner {}
}
