// Thunderhead: https://github.com/thunderhead-labs

// Author(s)
// Addison Spiegel: https://addison.is
// Pierre Spiegel: https://pierre.wtf

pragma solidity 0.8.20;
import "./IERC20.sol";
import "./stFlip.sol";
import "./Ownership.sol";
import "./console.sol";
import "./Initializable.sol";
import "./ProxyAdmin.sol";


/**
 * @title Minter contract for stFLIP
 * @notice Allows users to mint stFLIP 1:1 with native FLIP
 * Allows the rebaser to mint stFLIP fee
 */
contract MinterV1 is Initializable, Ownership {

    address public output;
    uint256 constant MINIMUM_MINT_AMOUNT = 1000;
    stFlip public stflip;
    IERC20 public flip;

    error BelowMinimumMintAmount();

    constructor() {
        _disableInitializers();
    }

    function initialize(address stflip_, address output_, address gov_, address flip_) initializer public {
        stflip = stFlip(stflip_);
        output = output_;
        __AccessControlDefaultAdminRules_init(0, gov_);

        flip = IERC20(flip_);
    }

    /** Public mint function. Takes FLIP from users and returns stFLIP 1:1
     * @param to The address to mint stFLIP to
     * @param amount The amount of stFLIP to mint
     */
    function mint(address to, uint256 amount) external returns (bool) {
        if (amount < MINIMUM_MINT_AMOUNT) revert BelowMinimumMintAmount();

        flip.transferFrom(msg.sender, output, amount);

        _mint(to, amount);
        return true;
    }

    /** Calls mint on stFLIP contract and emits event
     * @param to Address to mint stflip to
     * @param amount Amount of stflip to mint
     */
    function _mint(address to, uint256 amount) internal {
      stflip.mint(to, amount);
    }
}
