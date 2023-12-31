pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./T2BApproval.sol";
import "./IT2BRequest.sol";
import "./SafeTransferLib.sol";
import "./ERC20.sol";
import "./ECDSA.sol";

contract T2BRouter is Ownable {
    using SafeTransferLib for ERC20;

    // Errors
    error VerificationCallFailed();
    error InvalidTokenAddress();
    error BalanceMismatch();
    error BridgingFailed();
    error UnsupportedBridge();
    error ZeroAddress();
    error SignerMismatch();
    error InvalidNonce();

    /**
     * @dev The address used to identify ETH.
     */
    address public constant ETH_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // Socket Gateway.
    address public immutable socketGateway;

    address public feeTakerAddress;

    address[] public supportedTokens;

    address public signerAddress;

    // mapping of routeids against verifier contracts
    mapping(uint32 => address) public bridgeVerifiers;

    // nonce used in fee update signatures
    mapping(address => uint256) public nextNonce;

    // Constructor
    constructor(
        address _owner,
        address _socketGateway,
        address _feeTakerAddress
    ) Ownable(_owner) {
        socketGateway = _socketGateway;
        feeTakerAddress = _feeTakerAddress;
    }

    // Set the t2b factory address
    function setFeeTakerAddress(address _feeTakerAddress) external onlyOwner {
        feeTakerAddress = _feeTakerAddress;
    }

    // Set the signer address
    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    // Set bridge verifier contract address against routeId
    function setBridgeVerifier(
        uint32 routeId,
        address bridgeVerifier
    ) external onlyOwner {
        bridgeVerifiers[routeId] = bridgeVerifier;
    }

    // function to add tokens to supportedTokens
    function setSupportedTokens(address[] memory _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            supportedTokens.push(_tokens[i]);
        }
        supportedTokens.push(address(0));
    }

    // function to empty supported tokens array
    function emptyTokenList() external onlyOwner {
        address[] memory emptyList;
        supportedTokens = emptyList;
    }

    // Function that bridges taking amount from the t2bAddress where the user funds are parked.
    function bridgeERC20(
        uint256 fees,
        uint256 nonce,
        bytes calldata bridgeData,
        bytes calldata signature
    ) external {
        // recovering signer.
        address recoveredSigner = ECDSA.recover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(
                        abi.encode(
                            address(this),
                            nonce,
                            block.chainid, // uint256
                            fees,
                            bridgeData
                        )
                    )
                )
            ),
            signature
        );

        if (signerAddress != recoveredSigner) revert SignerMismatch();
        // nonce is used by gated roles and we don't expect nonce to reach the max value of uint256
        unchecked {
            if (nonce != nextNonce[signerAddress]++) revert InvalidNonce();
        }

        if (bridgeVerifiers[uint32(bytes4(bridgeData[0:4]))] == address(0))
            revert UnsupportedBridge();
        (bool parseSuccess, bytes memory parsedData) = bridgeVerifiers[
            uint32(bytes4(bridgeData[0:4]))
        ].call(bridgeData[4:bridgeData.length - 1]);

        if (!parseSuccess) revert VerificationCallFailed();

        IT2BRequest.T2BRequest memory t2bRequest = abi.decode(
            parsedData,
            (IT2BRequest.T2BRequest)
        );
        address t2bAddress = getAddressFor(
            t2bRequest.recipient,
            t2bRequest.toChainId
        );
        if (
            ERC20(t2bRequest.token).allowance(t2bAddress, address(this)) <
            t2bRequest.amount
        ) {
            bytes32 uniqueSalt = keccak256(
                abi.encode(t2bRequest.recipient, t2bRequest.toChainId)
            );
            new T2BApproval{salt: uniqueSalt}(address(this));
        }

        ERC20(t2bRequest.token).safeTransferFrom(
            t2bAddress,
            address(this),
            t2bRequest.amount + fees
        );

        if (fees > 0)
            ERC20(t2bRequest.token).safeTransfer(feeTakerAddress, fees);

        if (
            t2bRequest.amount >
            ERC20(t2bRequest.token).allowance(address(this), socketGateway)
        ) {
            ERC20(t2bRequest.token).safeApprove(
                address(socketGateway),
                type(uint256).max
            );
        }

        (bool bridgeSuccess, ) = socketGateway.call(bridgeData);

        if (!bridgeSuccess) revert BridgingFailed();
    }

    function deployApprovalContract(
        address receiver,
        uint256 toChainId
    ) public returns (address approvalAddress) {
        bytes32 uniqueSalt = keccak256(abi.encode(receiver, toChainId));
        approvalAddress = address(new T2BApproval{salt: uniqueSalt}(address(this)));
    }

    function getAddressFor(
        address receiver,
        uint256 toChainId
    ) public view returns (address) {
        bytes32 salt = keccak256(abi.encode(receiver, toChainId));
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                salt,
                                keccak256(
                                    abi.encodePacked(
                                        type(T2BApproval).creationCode,
                                        abi.encode(address(this))
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }

    /*******************************************
     *          RESTRICTED RESCUE FUNCTION    *
     *******************************************/

    /**
     * @dev Rescues funds from a contract.
     * @param token_ The address of the token contract.
     * @param userAddress_ The address of the user.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) external onlyOwner {
        if (userAddress_ == address(0)) revert ZeroAddress();

        if (token_ == ETH_ADDRESS) {
            SafeTransferLib.safeTransferETH(userAddress_, amount_);
        } else {
            if (token_.code.length == 0) revert InvalidTokenAddress();
            SafeTransferLib.safeTransfer(ERC20(token_), userAddress_, amount_);
        }
    }

    function rescueFromT2BReceiver(
        address t2bReceiver_,
        address token_,
        address userAddress_,
        uint256 amount_
    ) external onlyOwner {
        if (userAddress_ == address(0)) revert ZeroAddress();
        if (token_.code.length == 0) revert InvalidTokenAddress();
        SafeTransferLib.safeTransferFrom(
            ERC20(token_),
            t2bReceiver_,
            userAddress_,
            amount_
        );
    }
}
