// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./Initializable.sol";

import "./UniversalERC20.sol";
import "./IBridge.sol";
import "./IProxy.sol";
import "./RedButton.sol";


/*
    This is an example of Ethereum Proxy contract, which allows to implement
    token transfers between Ethereum and TON with Broxus bridge.
    Each ProxyToken corresponds to a single token contract.
    Token has an admin, which can do whatever he want.
*/
contract ProxyTokenLock is Initializable, IProxy, RedButton {
    using UniversalERC20 for IERC20;

    struct Fee {
        uint128 numerator;
        uint128 denominator;
    }

    struct Configuration {
        address token;
        address bridge;
        bool active;
        uint16 requiredConfirmations;
        Fee fee;
    }

    Configuration public configuration;
    mapping(uint256 => bool) public alreadyProcessed;

    /*
        Calculate the fee amount
        @dev Fee takes when calling broxusBridgeCallback
        @param amount Input amount of tokens
        @return Fee amount
    */
    function getFeeAmount(uint128 amount) public view returns(uint128) {
        return configuration.fee.numerator * amount / configuration.fee.denominator;
    }

    function initialize(
        Configuration memory _configuration,
        address _admin
    ) public initializer {
        _setConfiguration(_configuration);
        _setAdmin(_admin);
    }

    function _setConfiguration(
        Configuration memory _configuration
    ) internal {
        configuration = _configuration;
    }

    /*
        Update proxy configuration
        @dev Only admin may call
    */
    function setConfiguration(
        Configuration memory _configuration
    ) public onlyAdmin {
        _setConfiguration(_configuration);
    }

    event TokenLock(uint128 amount, int8 wid, uint256 addr, uint256 pubkey);
    event TokenUnlock(uint256 indexed eventTransaction, uint128 amount, address addr);

    modifier onlyActive() {
        require(configuration.active, 'Configuration not active');
        _;
    }

    /*
        Lock tokens. Emit event that leads to the token minting on TON
        @param amount AMount of tokens to lock
        @param wid Workchain id of the receiver TON address
        @param addr Body of the receiver TON address
        @param pubkey TON pubkey, alternative way to receive
    */
    function lockTokens(
        uint128 amount,
        int8 wid,
        uint256 addr,
        uint256 pubkey
    ) public onlyActive {
        require(
            IERC20(configuration.token).allowance(
                msg.sender,
                address(this)
            ) >= amount,
            "Allowance insufficient"
        );

        // Transfer tokens from user to the
        IERC20(configuration.token).universalTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        emit TokenLock(amount, wid, addr, pubkey);
    }

    /*
        Unlock tokens from the bridge
        @param payload Bytes encoded TONEvent structure
        @param signatures List of payload signatures
    */
    function broxusBridgeCallback(
        bytes memory payload,
        bytes[] memory signatures
    ) public onlyActive {
        require(
            IBridge(configuration.bridge).countRelaysSignatures(
                payload,
                signatures
            ) >= configuration.requiredConfirmations,
            'Not enough relays signed'
        );

        (TONEvent memory _event) = abi.decode(
            payload,
            (TONEvent)
        );

        require(address(this) == _event.proxy, 'Wrong proxy');
        require(!alreadyProcessed[_event.eventTransaction], 'Already processed');
        alreadyProcessed[_event.eventTransaction] = true;

        (int8 ton_wid, uint256 ton_addr, uint128 amount, uint160 addr_n) = abi.decode(
            _event.eventData,
            (int8, uint256, uint128, uint160)
        );

        address addr = address(addr_n);

        uint128 fee = getFeeAmount(amount);

        IERC20(configuration.token).universalTransfer(addr, amount - fee);

        emit TokenUnlock(_event.eventTransaction, amount - fee, addr);
    }
}
