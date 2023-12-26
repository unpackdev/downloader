// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./ERC20.sol";
import "./Ownable2Step.sol";

/**
 * @title WrappedElon
 * @dev This contract provides a way to wrap and unwrap ELON tokens into a new ERC20 token.
 *      It allows users to deposit ELON tokens and receive an equivalent amount of WrappedElon tokens,
 *      and vice versa. The new token uses a lower precision, which is useful for bridging the asset
 *      to other chains that don't support token amounts higher than max uint64.
 */
contract WrappedElon is ERC20, Ownable2Step {
    // The original ELON token contract address.
    ERC20 private constant ELON = ERC20(0x761D38e5ddf6ccf6Cf7c55759d5210750B5D60F3);

    // The minimum amount of ELON that can be wrapped
    uint256 private constant MIN_ELON_AMOUNT = 100_000_000_000_000;

    // Flags to control the wrap and unwrap functionality.
    bool public wrapEnabled = true;
    bool public unwrapEnabled = true;

    // Events for logging wrap and unwrap actions.
    event Wrap(address addr, uint256 elonAmount, uint256 wrappedAmount);
    event Unwrap(address addr, uint256 elonAmount, uint256 wrappedAmount);

    // Events for changing enabled states
    event WrapEnabled(bool enabled);
    event UnwrapEnabled(bool enabled);

    /**
     * @dev Sets the name and symbol for the WrappedElon token.
     */
    constructor() ERC20("Dogelon", "ELON") {}

    /**
     * @dev Overrides the decimals function to set a fixed decimal count.
     * @return uint8 The number of decimals used to get its user representation.
     */
    function decimals() public view virtual override returns (uint8) {
        return 4;
    }

    /**
     * @dev Allows users to wrap their ELON tokens into WrappedElon tokens.
     * @param elonAmount The amount of ELON tokens to be wrapped.
     */
    function wrap(uint256 elonAmount) external {
        require(wrapEnabled, "Wrapping currently disabled");
        require(elonAmount >= MIN_ELON_AMOUNT, "Can only wrap 0.0001 ELON or greater");
        uint256 wrappedAmount = elonAmount / MIN_ELON_AMOUNT;
        uint256 wrappableElon = wrappedAmount * MIN_ELON_AMOUNT;
        ELON.transferFrom(msg.sender, address(this), wrappableElon);
        _mint(msg.sender, wrappedAmount);
        emit Wrap(msg.sender, wrappableElon, wrappedAmount);
    }

    /**
     * @dev Allows users to unwrap their WrappedElon tokens back into the original ELON tokens.
     * @param wrappedAmount The amount of WrappedElon tokens to be unwrapped.
     */
    function unwrap(uint256 wrappedAmount) external {
        require(unwrapEnabled, "Unwrapping currently disabled");
        require(wrappedAmount > 0, "Cannot unwrap zero tokens");
        uint256 elonAmount = wrappedAmount * MIN_ELON_AMOUNT;
        _burn(msg.sender, wrappedAmount);
        ELON.transfer(msg.sender, elonAmount);
        emit Unwrap(msg.sender, elonAmount, wrappedAmount);
    }

    /**
     * @dev Allows the contract owner to enable or disable the wrap and unwrap functionality.
     * @param _wrapEnabled The new state of the wrap functionality.
     * @param _unwrapEnabled The new state of the unwrap functionality.
     */
    function setEnabledState(bool _wrapEnabled, bool _unwrapEnabled) external onlyOwner {
        if (wrapEnabled != _wrapEnabled) {
            wrapEnabled = _wrapEnabled;
            emit WrapEnabled(_wrapEnabled);
        }
        if (unwrapEnabled != _unwrapEnabled) {
            unwrapEnabled = _unwrapEnabled;
            emit UnwrapEnabled(_unwrapEnabled);
        }
    }
}
