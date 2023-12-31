//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./NameWrapperDelegate.sol";

/**
 * @title Namespace Mint Controller
 * @author namespace.ninja
 * @notice Provides functionality for minting subnames.
 */
contract NameMintingController is Controllable {
    event SubdomainMinted(
        string label,
        bytes32 indexed parentNode,
        uint256 price,
        address subnameOwner,
        address paymentRecepient,
        address minter
    );

    NameWrapperDelegate public nameWrapperDelegate;

    address[] public registries;
    address public registryCalls;
    address[] public validationCalls;
    address public paymentCall;

    address public wethAddress;
    address public feeWallet;
    address public withdrawalWallet;
    uint8 public mintFeePct;
    uint8 MAX_FEE_PCT = 10;

    uint256 public minCommitmentAge;
    uint256 public maxCommitmentAge;
    mapping(bytes32 => uint256) public commitments;

    constructor(
        NameWrapperDelegate _nameWrapperDelegate,
        address _feeWallet,
        address _nameRegistry,
        address _whitelistRegistry,
        address _reservedRegistry,
        address _registryCalls,
        address _validation,
        address _paymentCall,
        address _wethAddress
    ) {
        nameWrapperDelegate = _nameWrapperDelegate;
        feeWallet = _feeWallet;
        withdrawalWallet = _feeWallet;
        mintFeePct = 5;
        registries.push(_nameRegistry);
        registries.push(_whitelistRegistry);
        registries.push(_reservedRegistry);
        registryCalls = _registryCalls;
        validationCalls.push(_validation);
        paymentCall = _paymentCall;
        minCommitmentAge = 30;
        maxCommitmentAge = 86400;
        wethAddress = _wethAddress;
    }

    function commit(bytes32 commitment) external {
        require(
            commitments[commitment] + maxCommitmentAge < block.timestamp,
            "Commitment already exists"
        );
        commitments[commitment] = block.timestamp;
    }

    /**
     * @dev Mints the subname, while validating the registration data and processing the payment.
     * @param label Subname label to register
     * @param parentNode .eth domain node
     * @param addresses Address list - [0]: subnameOwner, [1]: resolver
     * @param extraData Any additional data needed during minting
     */
    function mintSubdomain(
        string calldata label,
        bytes32 parentNode,
        address[] calldata addresses,
        bytes calldata extraData,
        bytes32 secret
    ) external payable {
        _consumeCommitment(
            keccak256(
                abi.encode(label, parentNode, addresses, extraData, secret)
            )
        );

        // 1. update and get the data from the registries
        bytes memory response = _delegateCall(
            registryCalls,
            abi.encodeWithSignature(
                "callRegistries(bytes,address[])",
                abi.encode(parentNode, label, extraData, addresses),
                registries
            ),
            "Registry call error"
        );

        (
            uint256 price,
            address paymentRecevier,
            bytes memory registryData
        ) = abi.decode(response, (uint256, address, bytes));

        // 2. validate the data
        _validate(registryData, extraData, parentNode, label, addresses);

        // 3. mint subname (set the subdomain record) for the new owner
        _mintSubname(parentNode, label, addresses[0], addresses[1]);

        // 4. complete the payment
        _delegateCall(
            paymentCall,
            abi.encodeWithSignature(
                "transfer(bytes)",
                abi.encode(
                    wethAddress,
                    paymentRecevier,
                    feeWallet,
                    price,
                    mintFeePct,
                    registryData,
                    extraData
                )
            ),
            "Payment error"
        );

        emit SubdomainMinted(
            label,
            parentNode,
            price,
            addresses[0],
            paymentRecevier,
            msg.sender
        );
    }

    function _consumeCommitment(bytes32 commitment) internal {
        require(
            commitments[commitment] + minCommitmentAge <= block.timestamp,
            "Commitment not valid yet"
        );

        require(
            commitments[commitment] + maxCommitmentAge >= block.timestamp,
            "Commitment has expired"
        );

        delete (commitments[commitment]);
    }

    function _validate(
        bytes memory registryData,
        bytes memory extraData,
        bytes32 parentNode,
        string calldata label,
        address[] calldata addresses
    ) private {
        bytes memory listingData = abi.encode(
            registryData,
            extraData,
            parentNode,
            label,
            addresses
        );
        for (uint256 i = 0; i < validationCalls.length; i++) {
            _delegateCall(
                validationCalls[i],
                abi.encodeWithSignature("validate(bytes)", listingData),
                "Validation error"
            );
        }
    }

    function _delegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) private returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function _mintSubname(
        bytes32 parentNode,
        string calldata label,
        address subnameOwner,
        address resolver
    ) private {
        nameWrapperDelegate.setSubnodeRecord(
            parentNode,
            label,
            subnameOwner,
            resolver,
            type(uint64).max,
            CAN_EXTEND_EXPIRY | PARENT_CANNOT_CONTROL,
            type(uint64).max
        );
    }

    function setMintFeePct(uint8 pct) external onlyController {
        require(pct <= MAX_FEE_PCT, "Fee percentage too high");
        mintFeePct = pct;
    }

    function setFeeWallet(address wallet) external onlyController {
        feeWallet = wallet;
    }

    function addRegistry(address registry) external onlyController {
        registries.push(registry);
    }

    function setRegistries(
        address[] calldata _registries
    ) external onlyController {
        registries = _registries;
    }

    function setRegistryCalls(address call) external onlyController {
        registryCalls = call;
    }

    function addValidationCall(address call) external onlyController {
        validationCalls.push(call);
    }

    function setValidationCalls(
        address[] calldata _validationCalls
    ) external onlyController {
        validationCalls = _validationCalls;
    }

    function setPaymentCall(address call) external onlyController {
        paymentCall = call;
    }

    function setNameWrapperDelegate(
        NameWrapperDelegate _nameWrapperDelegate
    ) external onlyController {
        nameWrapperDelegate = _nameWrapperDelegate;
    }

    function withdraw() external onlyController {
        payable(withdrawalWallet).transfer(address(this).balance);
    }

    function setWithdrawalWallet(address wallet) external onlyController {
        withdrawalWallet = wallet;
    }

    function setMinCommitmentAge(uint256 minAge) external onlyController {
        minCommitmentAge = minAge;
    }

    function setMaxCommitmentAge(uint256 maxAge) external onlyController {
        maxCommitmentAge = maxAge;
    }

    function setWethAddress(address _wethAddress) external onlyController {
        wethAddress = _wethAddress;
    }
}
