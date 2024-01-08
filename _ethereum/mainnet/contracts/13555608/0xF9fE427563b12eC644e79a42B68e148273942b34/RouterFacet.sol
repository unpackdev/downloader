// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./SafeERC20.sol";
import "./WrappedToken.sol";
import "./IERC2612Permit.sol";
import "./IRouter.sol";
import "./LibDiamond.sol";
import "./LibFeeCalculator.sol";
import "./LibRouter.sol";
import "./LibGovernance.sol";

contract RouterFacet is IRouter {
    using SafeERC20 for IERC20;

    /// @notice Constructs the Router contract instance
    function initRouter() external override {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        require(!rs.initialized, "RouterFacet: already initialized");
        rs.initialized = true;
    }

    /// @param _ethHash The ethereum signed message hash
    /// @return Whether this hash has already been used for a mint/unlock transaction
    function hashesUsed(bytes32 _ethHash)
        external
        view
        override
        returns (bool)
    {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        return rs.hashesUsed[_ethHash];
    }

    /// @return The count of native tokens in the set
    function nativeTokensCount() external view override returns (uint256) {
        return LibRouter.nativeTokensCount();
    }

    /// @return The address of the native token at a given index
    function nativeTokenAt(uint256 _index)
        external
        view
        override
        returns (address)
    {
        return LibRouter.nativeTokenAt(_index);
    }

    /// @notice Transfers `amount` native tokens to the router contract.
    ///        The router must be authorised to transfer the native token.
    /// @param _targetChain The target chain for the bridging operation
    /// @param _nativeToken The token to be bridged
    /// @param _amount The amount of tokens to bridge
    /// @param _receiver The address of the receiver on the target chain
    function lock(
        uint256 _targetChain,
        address _nativeToken,
        uint256 _amount,
        bytes memory _receiver
    ) public override whenNotPaused onlyNativeToken(_nativeToken) {
        IERC20(_nativeToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        uint256 serviceFee = LibFeeCalculator.distributeRewards(
            _nativeToken,
            _amount
        );
        emit Lock(_targetChain, _nativeToken, _receiver, _amount, serviceFee);
    }

    /// @notice Locks the provided amount of nativeToken using an EIP-2612 permit and initiates a bridging transaction
    /// @param _targetChain The chain to bridge the tokens to
    /// @param _nativeToken The native token to bridge
    /// @param _amount The amount of nativeToken to lock and bridge
    /// @param _deadline The deadline for the provided permit
    /// @param _v The recovery id of the permit's ECDSA signature
    /// @param _r The first output of the permit's ECDSA signature
    /// @param _s The second output of the permit's ECDSA signature
    function lockWithPermit(
        uint256 _targetChain,
        address _nativeToken,
        uint256 _amount,
        bytes memory _receiver,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        IERC2612Permit(_nativeToken).permit(
            msg.sender,
            address(this),
            _amount,
            _deadline,
            _v,
            _r,
            _s
        );
        lock(_targetChain, _nativeToken, _amount, _receiver);
    }

    /// @notice Transfers `amount` native tokens to the `receiver` address.
    ///         Must be authorised by the configured supermajority threshold of `signatures` from the `members` set.
    /// @param _sourceChain The chainId of the chain that we're bridging from
    /// @param _transactionId The transaction ID + log index in the source chain
    /// @param _nativeToken The address of the native token
    /// @param _amount The amount to transfer
    /// @param _receiver The address reveiving the tokens
    /// @param _signatures The array of signatures from the members, authorising the operation
    function unlock(
        uint256 _sourceChain,
        bytes memory _transactionId,
        address _nativeToken,
        uint256 _amount,
        address _receiver,
        bytes[] calldata _signatures
    ) external override whenNotPaused onlyNativeToken(_nativeToken) {
        LibGovernance.validateSignaturesLength(_signatures.length);
        bytes32 ethHash = computeMessage(
            _sourceChain,
            block.chainid,
            _transactionId,
            _nativeToken,
            _receiver,
            _amount
        );
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        require(
            !rs.hashesUsed[ethHash],
            "RouterFacet: transaction already submitted"
        );
        validateAndStoreTx(ethHash, _signatures);

        uint256 serviceFee = LibFeeCalculator.distributeRewards(
            _nativeToken,
            _amount
        );
        uint256 transferAmount = _amount - serviceFee;

        IERC20(_nativeToken).safeTransfer(_receiver, transferAmount);

        emit Unlock(
            _sourceChain,
            _transactionId,
            _nativeToken,
            transferAmount,
            _receiver,
            serviceFee
        );
    }

    /// @notice Burns `amount` of `wrappedToken` initializes a bridging transaction to the target chain
    /// @param _targetChain The target chain to which the wrapped asset will be transferred
    /// @param _wrappedToken The address of the wrapped token
    /// @param _amount The amount of `wrappedToken` to burn
    /// @param _receiver The address of the receiver on the target chain
    function burn(
        uint256 _targetChain,
        address _wrappedToken,
        uint256 _amount,
        bytes memory _receiver
    ) public override whenNotPaused {
        WrappedToken(_wrappedToken).burnFrom(msg.sender, _amount);
        emit Burn(_targetChain, _wrappedToken, _amount, _receiver);
    }

    /// @notice Burns `amount` of `wrappedToken` using an EIP-2612 permit and initializes a bridging transaction to the target chain
    /// @param _targetChain The target chain to which the wrapped asset will be transferred
    /// @param _wrappedToken The address of the wrapped token
    /// @param _amount The amount of `wrappedToken` to burn
    /// @param _receiver The address of the receiver on the target chain
    /// @param _deadline The deadline of the provided permit
    /// @param _v The recovery id of the permit's ECDSA signature
    /// @param _r The first output of the permit's ECDSA signature
    /// @param _s The second output of the permit's ECDSA signature
    function burnWithPermit(
        uint256 _targetChain,
        address _wrappedToken,
        uint256 _amount,
        bytes memory _receiver,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        WrappedToken(_wrappedToken).permit(
            msg.sender,
            address(this),
            _amount,
            _deadline,
            _v,
            _r,
            _s
        );
        burn(_targetChain, _wrappedToken, _amount, _receiver);
    }

    /// @notice Mints `amount` wrapped tokens to the `receiver` address.
    ///         Must be authorised by the configured supermajority threshold of `signatures` from the `members` set.
    /// @param _sourceChain ID of the source chain
    /// @param _transactionId The source transaction ID + log index
    /// @param _wrappedToken The address of the wrapped token on the current chain
    /// @param _amount The desired minting amount
    /// @param _receiver The address of the receiver on this chain
    /// @param _signatures The array of signatures from the members, authorising the operation
    function mint(
        uint256 _sourceChain,
        bytes memory _transactionId,
        address _wrappedToken,
        address _receiver,
        uint256 _amount,
        bytes[] calldata _signatures
    ) external override whenNotPaused {
        LibGovernance.validateSignaturesLength(_signatures.length);
        bytes32 ethHash = computeMessage(
            _sourceChain,
            block.chainid,
            _transactionId,
            _wrappedToken,
            _receiver,
            _amount
        );

        LibRouter.Storage storage rs = LibRouter.routerStorage();
        require(
            !rs.hashesUsed[ethHash],
            "RouterFacet: transaction already submitted"
        );
        validateAndStoreTx(ethHash, _signatures);

        WrappedToken(_wrappedToken).mint(_receiver, _amount);

        emit Mint(
            _sourceChain,
            _transactionId,
            _wrappedToken,
            _amount,
            _receiver
        );
    }

    /// @notice Deploys a wrapped version of `nativeToken` to the current chain
    /// @param _sourceChain The chain where `nativeToken` is originally deployed to
    /// @param _nativeToken The address of the token
    /// @param _tokenParams The name/symbol/decimals to use for the wrapped version of `nativeToken`
    function deployWrappedToken(
        uint256 _sourceChain,
        bytes memory _nativeToken,
        WrappedTokenParams memory _tokenParams
    ) external override {
        require(
            bytes(_tokenParams.name).length > 0,
            "RouterFacet: empty wrapped token name"
        );
        require(
            bytes(_tokenParams.symbol).length > 0,
            "RouterFacet: empty wrapped token symbol"
        );
        require(
            _tokenParams.decimals > 0,
            "RouterFacet: invalid wrapped token decimals"
        );
        LibDiamond.enforceIsContractOwner();

        WrappedToken t = new WrappedToken(
            _tokenParams.name,
            _tokenParams.symbol,
            _tokenParams.decimals
        );

        emit WrappedTokenDeployed(_sourceChain, _nativeToken, address(t));
    }

    /// @notice Updates a native token, which will be used for lock/unlock.
    /// @param _nativeToken The native token address
    /// @param _serviceFee The amount of fee, which will be taken upon lock/unlock execution
    /// @param _status Whether the token will be added or removed
    function updateNativeToken(
        address _nativeToken,
        uint256 _serviceFee,
        bool _status
    ) external override {
        require(_nativeToken != address(0), "RouterFacet: zero address");
        LibDiamond.enforceIsContractOwner();

        LibRouter.updateNativeToken(_nativeToken, _status);
        LibFeeCalculator.setServiceFee(_nativeToken, _serviceFee);

        emit NativeTokenUpdated(_nativeToken, _serviceFee, _status);
    }

    /// @notice Validates the signatures and the data and saves the transaction
    /// @param _ethHash The hashed data
    /// @param _signatures The array of signatures from the members, authorising the operation
    function validateAndStoreTx(bytes32 _ethHash, bytes[] calldata _signatures)
        internal
    {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        LibGovernance.validateSignatures(_ethHash, _signatures);
        rs.hashesUsed[_ethHash] = true;
    }

    /// @notice Computes the bytes32 ethereum signed message hash for signatures
    /// @param _sourceChain The chain where the bridge transaction was initiated from
    /// @param _targetChain The target chain of the bridge transaction.
    ///                     Should always be the current chainId.
    /// @param _transactionId The transaction ID of the bridge transaction
    /// @param _token The address of the token on this chain
    /// @param _receiver The receiving address on the current chain
    /// @param _amount The amount of `_token` that is being bridged
    function computeMessage(
        uint256 _sourceChain,
        uint256 _targetChain,
        bytes memory _transactionId,
        address _token,
        address _receiver,
        uint256 _amount
    ) internal pure returns (bytes32) {
        bytes32 hashedData = keccak256(
            abi.encode(
                _sourceChain,
                _targetChain,
                _transactionId,
                _token,
                _receiver,
                _amount
            )
        );
        return ECDSA.toEthSignedMessageHash(hashedData);
    }

    modifier onlyNativeToken(address _nativeToken) {
        require(
            LibRouter.containsNativeToken(_nativeToken),
            "RouterFacet: native token not found"
        );
        _;
    }

    /// Modifier to make a function callable only when the contract is not paused
    modifier whenNotPaused() {
        LibGovernance.enforceNotPaused();
        _;
    }
}
