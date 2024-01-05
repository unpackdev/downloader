pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./RedButton.sol";
import "./IBridge.sol";
import "./IProxy.sol";

import "./WrappedTON.sol";


contract ProxyTokenMint is Initializable, RedButton {
    struct Configuration {
        address token;
        address bridge;
        bool active;
        uint16 requiredConfirmations;
        Fee fee;
    }

    struct Fee {
        uint128 numerator;
        uint128 denominator;
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

        // Deploy wTON
        configuration.token = address(new WrappedTON());
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


    function _setConfiguration(
        Configuration memory _configuration
    ) internal {
        configuration = _configuration;
    }


    event TokenBurn(uint128 amount, int8 wid, uint256 addr, uint256 pubkey);
    event TokenMint(uint256 indexed eventTransaction, uint128 amount, address addr);

    modifier onlyActive() {
        require(configuration.active, 'Configuration not active');
        _;
    }

    /*
        Burn tokens. Emit event that leads to the token minting on TON
        @param amount Amount of tokens to lock
        @param wid Workchain id of the receiver TON address
        @param addr Body of the receiver TON address
        @param pubkey TON pubkey, alternative way to receive
    */
    function burnTokens(
        uint128 amount,
        int8 wid,
        uint256 addr,
        uint256 pubkey
    ) public onlyActive {
        // Burn user tokens
        WrappedTON(configuration.token).burn(
            msg.sender,
            amount
        );

        emit TokenBurn(amount, wid, addr, pubkey);
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

        (IProxy.TONEvent memory _event) = abi.decode(
            payload,
            (IProxy.TONEvent)
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

        WrappedTON(configuration.token).mint(addr, amount - fee);
        WrappedTON(configuration.token).mint(address(this), fee);

        emit TokenMint(_event.eventTransaction, amount - fee, addr);
    }
}
