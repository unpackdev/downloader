pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
import "./Operations.sol";
import "./ReentrancyGuard.sol";

import "./Storage.sol";
import "./Events.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./PairTokenManager.sol";

contract ZKSea is PairTokenManager, Storage, Config, Events, ReentrancyGuard, IERC721Receiver {

    bytes32 public constant EMPTY_STRING_KECCAK = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    /// @notice Deposit ERC721 token to Layer 2 - transfer ERC721 tokens from user into contract, validate it, register deposit
    /// @param _token ERC721 Token address
    /// @param _tokenId ERC721 token id
    /// @param _franklinAddr Receiver Layer 2 address
    function depositNFT(IERC721 _token, uint256 _tokenId, address _franklinAddr)  external nonReentrant {
        requireActive();
        address tokenOwner = msg.sender;
        require(_token.ownerOf(_tokenId) == tokenOwner, "ZKSea: only be able to deposit your own NFT");
        Operations.DepositNFT memory op = zkSeaNFT.onDeposit(_token, _tokenId, _franklinAddr);
        if (op.creatorId == 0) {
            _token.safeTransferFrom(tokenOwner, address(this), _tokenId);
            require(_token.ownerOf(_tokenId) == address(this), "ZKSea: depositNFT failed");
        }
        bytes memory pubData = Operations.writeDepositNFTPubdata(op);
        addPriorityRequest(Operations.OpType.DepositNFT, pubData, "");
        emit OnchainDepositNFT(
            tokenOwner,
            address(_token),
            _tokenId,
            _franklinAddr
        );
    }

    /// @notice Withdraw NFT to Layer 1 - register withdrawal and transfer nft to receiver
    /// @param _globalId nft id amount to withdraw
    /// @param _addr withdraw ntf receiver
    function withdrawNFT(uint64 _globalId, address _addr) external nonReentrant {
        require(_addr != address(0));
        (address token, uint256 tokenId) = zkSeaNFT.onWithdraw(msg.sender, _globalId);
        require(token != address(0));
        IERC721(token).safeTransferFrom(address(this), _addr, tokenId);
    }

    /// @notice Register full exit nft request - pack pubdata, add priority request
    /// @param _accountId Numerical id of the account
    /// @param _globalId layer2 nft id
    function fullExitNFT(uint32 _accountId, uint64 _globalId) external nonReentrant {
        requireActive();
        require(_accountId <= MAX_ACCOUNT_ID, "fee11");
        require(_globalId > 0 && _globalId <= MAX_NFT_ID, "ZKSea: invalid exit id");
        bytes memory pubData = Operations.writeFullExitNFTPubdata(Operations.FullExitNFT({
            accountId: _accountId,
            globalId: _globalId,
            creatorId: 0,
            seqId: 0,
            uri: 0,
            owner: msg.sender,
            success: 0
        }));
        addPriorityRequest(Operations.OpType.FullExitNFT, pubData, "");
        emit OnchainFullExitNFT(_accountId, msg.sender, _globalId);
    }

    /// @notice executes pending withdrawals
    /// @param _n The number of withdrawals NFT to complete starting from oldest
    function completeWithdrawalsNFT(uint32 _n) external nonReentrant {
        IZKSeaNFT.WithdrawItem[] memory withdrawItem = zkSeaNFT.genWithdrawItems(_n);
        for (uint32 i = 0; i < withdrawItem.length; ++i) {
            address to = withdrawItem[i].to;
            address token = withdrawItem[i].tokenContract;
            uint256 tokenId = withdrawItem[i].tokenId;
            uint64 globalId = withdrawItem[i].globalId;
            bool sent = false;
            /// external token
            // we can just check that call not reverts because it wants to withdraw all amount
            (sent,) = (token).call.gas(withdrawNFTGasLimit)(
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", address(this), to, tokenId));
            if (!sent) {
                zkSeaNFT.withdrawBalanceUpdate(to, globalId);
            }
        }
    }

    /// @notice return the num of pending nft withdrawals
    function numOfPendingWithdrawalsNFT() external view returns(uint32) {
        return zkSeaNFT.numOfPendingWithdrawals();
    }

    /// @notice Checks that current state not is exodus mode
    function requireActive() internal view {
        require(!exodusMode, "fre11"); // exodus mode activated
    }

    // Priority queue
    /// @notice Saves priority request in storage
    /// @dev Calculates expiration block for request, store this request and emit NewPriorityRequest event
    /// @param _opType Rollup operation type
    /// @param _pubData Operation pubdata
    function addPriorityRequest(
        Operations.OpType _opType,
        bytes memory _pubData,
        bytes memory _userData
    ) internal {
        // Expiration block is: current block number + priority expiration delta
        uint256 expirationBlock = block.number + PRIORITY_EXPIRATION;

        uint64 nextPriorityRequestId = firstPriorityRequestId + totalOpenPriorityRequests;

        priorityRequests[nextPriorityRequestId] = PriorityOperation({
            opType : _opType,
            pubData : _pubData,
            expirationBlock : expirationBlock
        });

        emit NewPriorityRequest(
            msg.sender,
            nextPriorityRequestId,
            _opType,
            _pubData,
            _userData,
            expirationBlock
        );

        totalOpenPriorityRequests++;
    }

    // The contract is too large. Break some functions to zkSyncCommitBlockAddress
    function() external payable {
        address nextAddress = zkSyncCommitBlockAddress;
        require(nextAddress != address(0), "zkSyncCommitBlockAddress should be set");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), nextAddress, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
        }
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
