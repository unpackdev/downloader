//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";
import "./Counters.sol";
import "./WrappedToken.sol";
import "./IERC2612Permit.sol";
import "./IRouter.sol";
import "./LibFeeCalculator.sol";
import "./LibRouter.sol";
import "./LibGovernance.sol";

contract RouterFacet is IRouter {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    /**
     *  @notice Constructs the Router contract instance and deploys the wrapped ALBT token if not on the Ethereum network
     *  @param _chainId The chainId of the chain where this contract is deployed on
     *  @param _albtToken The address of the original ALBT token in the Ethereum chain
     */
    function initRouter(
        uint8 _chainId,
        address _albtToken
    )
        external override
    {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        require(!rs.initialized, "Router: already initialized");
        rs.initialized = true;
        rs.chainId = _chainId;
        
        // If we're deployed on a network other than Ethereum, deploy a wrapped version of the ALBT token
        // otherwise use the native ALBT token for fees
        if(_chainId != 1) {
            bytes memory nativeAlbt = abi.encodePacked(_albtToken);
            WrappedToken wrappedAlbt = new WrappedToken("Wrapped AllianceBlock Token", "WALBT", 18);
            rs.albtToken = address(wrappedAlbt);
            rs.nativeToWrappedToken[1][nativeAlbt] = rs.albtToken;
            rs.wrappedToNativeToken[rs.albtToken].chainId = 1;
            rs.wrappedToNativeToken[rs.albtToken].token = nativeAlbt;
            emit WrappedTokenDeployed(1, nativeAlbt, rs.albtToken);
        } else {
            rs.albtToken = _albtToken;
        }
    }

    /// @notice Accepts number of signatures in the range (n/2; n] where n is the number of members
    modifier onlyValidSignatures(uint256 _n) {
        uint256 members = LibGovernance.membersCount();
        require(_n <= members, "Governance: Invalid number of signatures");
        require(_n > members / 2, "Governance: Invalid number of signatures");
        _;
    }

    /**
     *  @param _chainId The chainId of the chain where `nativeToken` was originally created
     *  @param _nativeToken The address of the token
     *  @return The address of the wrapped counterpart of `nativeToken` in the current chain
     */
    function nativeToWrappedToken(uint8 _chainId, bytes memory _nativeToken) external view override returns (address) {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        return rs.nativeToWrappedToken[_chainId][_nativeToken];
    }

    /**
     *  @param _wrappedToken The address of the wrapped token
     *  @return The chainId and address of the original token
     */
    function wrappedToNativeToken(address _wrappedToken) external view override returns (LibRouter.NativeTokenWithChainId memory) {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        return rs.wrappedToNativeToken[_wrappedToken];
    }

    /**
     *  @param _chainId The chainId of the source chain
     *  @param _ethHash The ethereum signed message hash
     *  @return Whether this hash has already been used for a mint/unlock transaction
     */
    function hashesUsed(uint8 _chainId, bytes32 _ethHash) external view override returns (bool) {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        return rs.hashesUsed[_chainId][_ethHash];
    }

    /// @return The address of the ALBT token in the current chain
    function albtToken() external view override returns (address) {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        return rs.albtToken;
    }

    /**
     *  @notice Transfers `amount` native tokens to the router contract.
                The router must be authorised to transfer both the native token and the ALBT tokens for the fee.
     *  @param _targetChain The target chain for the bridging operation
     *  @param _nativeToken The token to be bridged
     *  @param _amount The amount of tokens to bridge
     *  @param _receiver The address of the receiver in the target chain
     */
    function lock(uint8 _targetChain, address _nativeToken, uint256 _amount, bytes memory _receiver) public override {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        LibFeeCalculator.Storage storage fcs = LibFeeCalculator.feeCalculatorStorage();
        LibFeeCalculator.distributeRewards();
        IERC20(rs.albtToken).safeTransferFrom(msg.sender, address(this), fcs.serviceFee);
        IERC20(_nativeToken).safeTransferFrom(msg.sender, address(this), _amount);
        emit Lock(_targetChain, _nativeToken, _receiver, _amount, fcs.serviceFee);
    }

    /**
     *  @notice Locks the provided amount of nativeToken using an EIP-2612 permit and initiates a bridging transaction
     *  @param _targetChain The chain to bridge the tokens to
     *  @param _nativeToken The native token to bridge
     *  @param _amount The amount of nativeToken to lock and bridge
     *  @param _deadline The deadline for the provided permit
     *  @param _v The recovery id of the permit's ECDSA signature
     *  @param _r The first output of the permit's ECDSA signature 
     *  @param _s The second output of the permit's ECDSA signature
     */
    function lockWithPermit(
        uint8 _targetChain,
        address _nativeToken,
        uint256 _amount,
        bytes memory _receiver,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        IERC2612Permit(_nativeToken).permit(msg.sender, address(this), _amount, _deadline, _v, _r, _s);
        lock(_targetChain, _nativeToken, _amount, _receiver);
    }

    /**
     *  @notice Transfers `amount` native tokens to the `receiver` address.
                Must be authorised by a supermajority of `signatures` from the `members` set.
                The router must be authorised to transfer the ABLT tokens for the fee.
     *  @param _sourceChain The chainId of the chain that we're bridging from
     *  @param _transactionId The transaction ID + log index in the source chain
     *  @param _nativeToken The address of the native token
     *  @param _amount The amount to transfer
     *  @param _receiver The address reveiving the tokens
     *  @param _signatures The array of signatures from the members, authorising the operation
     */
    function unlock(
        uint8 _sourceChain,
        bytes memory _transactionId,
        address _nativeToken,
        uint256 _amount,
        address _receiver,
        bytes[] calldata _signatures
    )
        external override
        onlyValidSignatures(_signatures.length)
    {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        bytes32 ethHash =
            computeUnlockMessage(_sourceChain, rs.chainId, _transactionId, abi.encodePacked(_nativeToken), _receiver, _amount);

        require(!rs.hashesUsed[_sourceChain][ethHash], "Router: transaction already submitted");

        validateAndStoreTx(_sourceChain, ethHash, _signatures);

        IERC20(_nativeToken).safeTransfer(_receiver, _amount);
        
        emit Unlock(_nativeToken, _amount, _receiver);
    }

    /**
     *  @notice Calls burn on the given wrapped token contract with `amount` wrapped tokens from `msg.sender`.
                The router must be authorised to transfer the ABLT tokens for the fee.
     *  @param _wrappedToken The wrapped token to burn
     *  @param _amount The amount of wrapped tokens to be bridged
     *  @param _receiver The address of the user in the original chain for this wrapped token
     */
    function burn(address _wrappedToken, uint256 _amount, bytes memory _receiver) public override {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        LibFeeCalculator.Storage storage fcs = LibFeeCalculator.feeCalculatorStorage();
        LibFeeCalculator.distributeRewards();
        IERC20(rs.albtToken).safeTransferFrom(msg.sender, address(this), fcs.serviceFee);
        WrappedToken(_wrappedToken).burnFrom(msg.sender, _amount);
        emit Burn(_wrappedToken, _amount, _receiver);
    }

    /**
     *  @notice Burns `amount` of `wrappedToken` using an EIP-2612 permit and initializes a bridging transaction to the original chain
     *  @param _wrappedToken The address of the wrapped token to burn
     *  @param _amount The amount of `wrappedToken` to burn
     *  @param _receiver The receiving address in the original chain for this wrapped token
     *  @param _deadline The deadline of the provided permit
     *  @param _v The recovery id of the permit's ECDSA signature
     *  @param _r The first output of the permit's ECDSA signature 
     *  @param _s The second output of the permit's ECDSA signature
     */
    function burnWithPermit(
        address _wrappedToken,
        uint256 _amount,
        bytes memory _receiver,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        WrappedToken(_wrappedToken).permit(msg.sender, address(this), _amount, _deadline, _v, _r, _s);
        burn(_wrappedToken, _amount, _receiver);
    }

    /**
     *  @notice Mints `amount` wrapped tokens to the `receiver` address.
                Must be authorised by a supermajority of `signatures` from the `members` set.
                The router must be authorised to transfer the ABLT tokens for the fee.
     *  @param _sourceChain ID of the source chain
     *  @param _nativeToken The address of the native token in the source chain
     *  @param _transactionId The source transaction ID + log index
     *  @param _amount The desired minting amount
     *  @param _receiver The address receiving the tokens
     *  @param _signatures The array of signatures from the members, authorising the operation
     */
    function mint(
        uint8 _sourceChain,
        bytes memory _nativeToken,
        bytes memory _transactionId,
        uint256 _amount,
        address _receiver,
        bytes[] calldata _signatures,
        WrappedTokenParams memory _tokenParams
    )
        external override
        onlyValidSignatures(_signatures.length)
    {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        bytes32 ethHash =
            computeMintMessage(_sourceChain, rs.chainId, _transactionId, _nativeToken, _receiver, _amount, _tokenParams);

        require(!rs.hashesUsed[_sourceChain][ethHash], "Router: transaction already submitted");

        validateAndStoreTx(_sourceChain, ethHash, _signatures);

        if(rs.nativeToWrappedToken[_sourceChain][_nativeToken] == address(0)) {
            deployWrappedToken(_sourceChain, _nativeToken, _tokenParams);
        }

        WrappedToken(rs.nativeToWrappedToken[_sourceChain][_nativeToken]).mint(_receiver, _amount);

        emit Mint(rs.nativeToWrappedToken[_sourceChain][_nativeToken], _amount, _receiver);
    }

    /**
     *  @notice Deploys a wrapped version of `nativeToken` to the current chain
     *  @param _sourceChain The chain where `nativeToken` is originally deployed to
     *  @param _nativeToken The address of the token
     *  @param _tokenParams The name/symbol/decimals to use for the wrapped version of `nativeToken`
     */
    function deployWrappedToken(
        uint8 _sourceChain,
        bytes memory _nativeToken,
        WrappedTokenParams memory _tokenParams
    )
        internal
    {
        require(bytes(_tokenParams.name).length > 0, "Router: empty wrapped token name");
        require(bytes(_tokenParams.symbol).length > 0, "Router: empty wrapped token symbol");
        require(_tokenParams.decimals > 0, "Router: invalid wrapped token decimals");

        LibRouter.Storage storage rs = LibRouter.routerStorage();
        WrappedToken t = new WrappedToken(_tokenParams.name, _tokenParams.symbol, _tokenParams.decimals);
        rs.nativeToWrappedToken[_sourceChain][_nativeToken] = address(t);
        rs.wrappedToNativeToken[address(t)].chainId = _sourceChain;
        rs.wrappedToNativeToken[address(t)].token = _nativeToken;

        emit WrappedTokenDeployed(_sourceChain, _nativeToken, address(t));
    }

    /**
     *  @notice Computes the bytes32 ethereum signed message hash of the unlock signatures
     *  @param _sourceChain The chain where the bridge transaction was initiated from
     *  @param _targetChain The target chain of the bridge transaction.
                           Should always be the current chainId.
     *  @param _transactionId The transaction ID of the bridge transaction
     *  @param _nativeToken The token that is being bridged
     *  @param _receiver The receiving address in the current chain
     *  @param _amount The amount of `nativeToken` that is being bridged
     */
    function computeUnlockMessage(
        uint8 _sourceChain,
        uint8 _targetChain,
        bytes memory _transactionId,
        bytes memory _nativeToken,
        address _receiver,
        uint256 _amount
    ) internal pure returns (bytes32) {
        bytes32 hashedData =
            keccak256(
                abi.encode(_sourceChain, _targetChain, _transactionId, _receiver, _amount, _nativeToken)
            );
        return ECDSA.toEthSignedMessageHash(hashedData);
    }

    /**
     *  @notice Computes the bytes32 ethereum signed message hash of the mint signatures
     *  @param _sourceChain The chain where the bridge transaction was initiated from
     *  @param _targetChain The target chain of the bridge transaction.
                           Should always be the current chainId.
     *  @param _transactionId The transaction ID of the bridge transaction
     *  @param _nativeToken The token that is being bridged
     *  @param _receiver The receiving address in the current chain
     *  @param _amount The amount of `nativeToken` that is being bridged
     *  @param _tokenParams Wrapped token name/symbol/decimals
     */
    function computeMintMessage(
        uint8 _sourceChain,
        uint8 _targetChain,
        bytes memory _transactionId,
        bytes memory _nativeToken,
        address _receiver,
        uint256 _amount,
        WrappedTokenParams memory _tokenParams
    ) internal pure returns (bytes32) {
        bytes32 hashedData =
            keccak256(
                abi.encode(
                    _sourceChain,
                    _targetChain,
                    _transactionId,
                    _receiver,
                    _amount,
                    _nativeToken,
                    _tokenParams.name,
                    _tokenParams.symbol,
                    _tokenParams.decimals
                )
            );
        return ECDSA.toEthSignedMessageHash(hashedData);
    }

    /**
     *  @notice Validates the signatures and the data and saves the transaction
     *  @param _chainId The source chain for this transaction
     *  @param _ethHash The hashed data
     *  @param _signatures The array of signatures from the members, authorising the operation
     */
    function validateAndStoreTx(
        uint8 _chainId,
        bytes32 _ethHash,
        bytes[] calldata _signatures
    ) internal {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        LibGovernance.validateSignatures(_ethHash, _signatures);
        rs.hashesUsed[_chainId][_ethHash] = true;
    }
}
