// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IABBLegacy.sol";
import "./LibMintpass.sol";

/** This contract is used as a Proxy for FIAT Payments on Bowline.app.
 * Most projects can directly interact with the contract also for FIAT Payments,
 * however, if you as a creator want to cover the Conversion and Payment Fees
 * for a minter partly this is a required intermediary Contract.
 *
 * However, the rationale behind this contract is: A different wallet could verify
 * while the sender address is a cold wallet for example. 
 *
 * If you have further question on this contract feel Free to contact us on support[at]bowline.app.
 *
 */
contract BowlineFiatForwarder {
    address internal receivingContract =
        0xF15c6caDb081DD7C951E71065e653b8c8Cc39956;

    address internal VERIFIER_WALLET =
        0x212BCFE60f8e71AEcBd490c141Eb6973e7b6B251;

    address internal TRANSACTION_WALLET =
        0xC16157e00b1bFf1522C6F01246B4Fb621dA048d0;

    bool internal providerCheckEnabled = false;

    address internal OWNER_WALLET;

    /**
     * @dev ERC721A Constructor
     */
    constructor() {
        OWNER_WALLET = msg.sender;
    }

    function mint(address _minter, uint256 _quantity)
        public
        payable
        onlyFiatWallets
    {
        IABBLegacy(receivingContract).mint{value: msg.value}(
            _minter,
            _quantity
        );
    }

    function allowlistMint(
        uint256 quantity,
        LibMintpass.Mintpass memory mintpass,
        bytes memory mintpassSignature
    ) public payable onlyFiatWallets {
        IABBLegacy(receivingContract).allowlistMint{value: msg.value}(
            quantity,
            mintpass,
            mintpassSignature
        );
    }

    function setFiatWallets(
        address _VERIFIER_WALLET,
        address _TRANSACTION_WALLET
    ) external onlyOwner {
        TRANSACTION_WALLET = _TRANSACTION_WALLET;
        VERIFIER_WALLET = _VERIFIER_WALLET;
    }

    function setPaymentProviderCheck(bool _providerCheckEnabled)
        external
        onlyOwner
    {
        providerCheckEnabled = _providerCheckEnabled;
    }

    function setReceivingContract(address _receivingContract)
        external
        onlyOwner
    {
        receivingContract = _receivingContract;
    }

    modifier onlyFiatWallets() {
        if (providerCheckEnabled) {
            require(
                (msg.sender == VERIFIER_WALLET ||
                    msg.sender == TRANSACTION_WALLET),
                "Bowline Fiat Forwarder: Payment Provider is unkown."
            );
        }
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == OWNER_WALLET,
            "Bowline Fiat Forwarder: You need to be Owner to call this function."
        );

        _;
    }
}

/** created with bowline.app **/
