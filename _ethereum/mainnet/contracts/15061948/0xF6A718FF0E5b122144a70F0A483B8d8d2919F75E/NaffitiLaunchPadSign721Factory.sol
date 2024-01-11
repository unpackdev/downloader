// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ECDSA.sol";
import "./NaffitiLaunchPadSign721.sol";

/**
 *  @title  Naffiti Launchpad NFTs Factory
 *  @author Naffiti
 *  @dev    Using EIP-712 standard for creating collection
 */
contract NaffitiLaunchPadSign721Factory is Initializable, OwnableUpgradeable, EIP712Upgradeable {
    struct AuthTicket {
        string name;
        string symbol;
        string baseURI;
        string contractURILink;
        uint256 maxSupply;
        address contractSigner;
        address receiveCommissionAddress;
        uint256 commissionPercentage;
        address receiveRoyaltyAddress;
        uint256 royaltyPercentage;
        address contractOwner;
        uint256 deployFee;
        uint256 nonce;
    }

    address public SIGNER;
    bytes32 public constant AUTH_TICKET_TYPE =
        keccak256(
            "AuthTicket(string name,"
            "string symbol,"
            "string baseURI,"
            "string contractURILink,"
            "uint256 maxSupply,"
            "address contractSigner,"
            "address receiveCommissionAddress,"
            "uint256 commissionPercentage,"
            "address receiveRoyaltyAddress,"
            "uint256 royaltyPercentage,"
            "address contractOwner,"
            "uint256 deployFee,"
            "uint256 nonce)"
        );

    event CollectionCreated(string identifier, address contractAddress);

    error InvalidSignature();
    error InsufficientFunds();
    error FailedETHTransfer();

    function initialize(address _signer) public initializer {
        SIGNER = _signer;
        __Ownable_init();
        __EIP712_init("NaffitiLaunchPadSign721Factory", "v1.2.0");
    }

    function createCollection(
        bytes calldata _data,
        bytes calldata _signature,
        string calldata _identifier
    ) public payable returns (address) {
        AuthTicket memory params = abi.decode(_data, (AuthTicket));

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    AUTH_TICKET_TYPE,
                    keccak256(bytes(params.name)),
                    keccak256(bytes(params.symbol)),
                    keccak256(bytes(params.baseURI)),
                    keccak256(bytes(params.contractURILink)),
                    params.maxSupply,
                    params.contractSigner,
                    params.receiveCommissionAddress,
                    params.commissionPercentage,
                    params.receiveRoyaltyAddress,
                    params.royaltyPercentage,
                    params.contractOwner,
                    params.deployFee,
                    params.nonce
                )
            )
        );

        address recoverAddress = ECDSA.recover(digest, _signature);
        if (recoverAddress != SIGNER) revert InvalidSignature();

        if (msg.value < params.deployFee) revert InsufficientFunds();
        NaffitiLaunchPadSign721 collectionAddress = new NaffitiLaunchPadSign721(
            params.name,
            params.symbol,
            params.baseURI,
            params.contractURILink,
            params.maxSupply,
            params.contractSigner,
            params.receiveCommissionAddress,
            params.commissionPercentage,
            params.receiveRoyaltyAddress,
            params.royaltyPercentage,
            params.contractOwner
        );

        emit CollectionCreated(_identifier, address(collectionAddress));
        return address(collectionAddress);
    }

    function withdraw() public onlyOwner {
        (bool cs, ) = payable(owner()).call{ value: address(this).balance }("");
        if (!cs) revert FailedETHTransfer();
    }

    function setSigner(address _signer) public onlyOwner {
        SIGNER = _signer;
    }
}
