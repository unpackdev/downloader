// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.4;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./IFeeExchanger.sol";

/**
 * @author Asaf Silman
 * @title FeeExchanger Implementation
 * @notice This contract should be inherited by contracts specific to a DEX or exchange strategy for protocol fees.
 * @dev This contract implmenents the basic requirements for a feeExchanger.
 * @dev Contracts which inherit this are required to implmenent the `exchange` function.
 */
abstract contract FeeExchanger is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, IFeeExchanger {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable internal _inputToken;
    IERC20Upgradeable internal _outputToken;

    address internal _outputAddress;

    // Keep an internal mapping of which addresses can exchange fees
    mapping(address => bool) private _canExchange;

    /**
     * @notice Initialises the FeeExchanger.
     * @dev Also intitalises Ownable and ReentrancyGuard 
     * @param inputToken_ The input ERC20 token representing fees.
     * @param outputToken_ The output ERC20 token, fees will be exchanged into this currency.
     * @param outputAddress_ Exchanged fees will be transfered to this address.
     */
    function __FeeExchanger_init(
        IERC20Upgradeable inputToken_, 
        IERC20Upgradeable outputToken_,
        address outputAddress_
    ) internal initializer {       
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        
        _inputToken = inputToken_;
        _outputToken = outputToken_;

        _outputAddress = outputAddress_;

        emit OutputAddressUpdated(address(0), _outputAddress);
    }

    /**
     * @notice Modifier to check if msg.sender can exchange.
     */
    modifier onlyExchanger() {
        require(_canExchange[msg.sender], "FE: NOT EXCHANGER");
        _;
    }

    /**
     * @notice Adds an address as an exchanger.
     * @dev Exchangers have permission to exchange funds via the `exchange` function.
     * @dev This method can only be called by the owner.
     * @param exchanger The address of the exchanger.
     */
    function addExchanger(address exchanger) onlyOwner external override {
        require(!_canExchange[exchanger], "FE: ALREADY EXCHANGER");

        _canExchange[exchanger] = true;

        emit ExchangerUpdated(exchanger, true);
    }

    /**
     * @notice Removed an address as an exchanger.
     * @dev This method can only be called by the owner.
     * @param exchanger The address of the exchanger.
     */
    function removeExchanger(address exchanger) onlyOwner external override {
        require(_canExchange[exchanger], "FE: NOT EXCHANGER");

        _canExchange[exchanger] = false;

        emit ExchangerUpdated(exchanger, false);
    }
    
    /**
     * @notice Check if an address is an exchanger.
     * @dev This is a view method to use with tools such as etherscan.
     * @dev address(0) is not checked for exchanger.
     * @param exchanger The address of the exchanger.
     * @return Boolean whether address is exchanger
     */
    function canExchange(address exchanger) external view override returns (bool) {
        return _canExchange[exchanger];
    }

    /**
     * @notice Update the ouput address.
     * @dev Fees which have been swapped will be sent to the new address after this has been called.
     * @dev address(0) is not checked for newOutputAddress.
     * @param newOutputAddress The new address to send swapped fees to.
     */
    function updateOutputAddress(address newOutputAddress) onlyOwner external override {
        address previousAddress = _outputAddress;
        _outputAddress = newOutputAddress;

        emit OutputAddressUpdated(previousAddress, newOutputAddress);
    }

    /**
     * @notice Return the input token address.
     * @return Input token address.
     */
    function inputToken() external view override returns (IERC20Upgradeable) { return _inputToken; }

    /**
     * @notice Return the ouput token address.
     * @return Output token address.
     */
    function outputToken() external view override returns (IERC20Upgradeable) { return _outputToken; }

    /**
     * @notice Return the output address.
     * @return Output address.
     */
    function outputAddress() external view override returns (address) { return _outputAddress; }
}
