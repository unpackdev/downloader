// SPDX-License-Identifier: MIT

/*
                    ████████╗██╗  ██╗███████╗
                    ╚══██╔══╝██║  ██║██╔════╝
                       ██║   ███████║█████╗
                       ██║   ██╔══██║██╔══╝
                       ██║   ██║  ██║███████╗
                       ╚═╝   ╚═╝  ╚═╝╚══════╝
██╗  ██╗██╗   ██╗███╗   ███╗ █████╗ ███╗   ██╗ ██████╗ ██╗██████╗ ███████╗
██║  ██║██║   ██║████╗ ████║██╔══██╗████╗  ██║██╔═══██╗██║██╔══██╗██╔════╝
███████║██║   ██║██╔████╔██║███████║██╔██╗ ██║██║   ██║██║██║  ██║███████╗
██╔══██║██║   ██║██║╚██╔╝██║██╔══██║██║╚██╗██║██║   ██║██║██║  ██║╚════██║
██║  ██║╚██████╔╝██║ ╚═╝ ██║██║  ██║██║ ╚████║╚██████╔╝██║██████╔╝███████║
╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═════╝ ╚══════╝


The Humanoids $ION swap

*/

pragma solidity =0.8.11;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";


interface IERC20Burn is IERC20Upgradeable {
    function burnFrom(address account, uint256 amount) external;
}

contract IONCredits is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev price has 18 decimals of precision
    struct SwapOption {
        bool enabled;
        bool burn;
        uint128 price;
    }

    mapping(address => SwapOption) private _tokenSwapOptions;
    bool private _enabled;


    /// @dev Emitted when `account` adds `amount` of credits.
    event CreditsChanged(address indexed account, int256 amount, address indexed source, uint256 price);

    /// @dev Emitted when the swapping options for `tokenContract` have changed.
    event SwapOptionChanged(address indexed tokenContract, bool enabled, bool burn, uint256 price);


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}



    modifier isEnabled() {
        require(_enabled, "Swapping credits not enabled");
        _;
    }

    modifier validAmount(int256 amount) {
        require(amount > 0, "Amount must be greater than zero");
        _;
    }


    function tokenSwapOption(address tokenContract) external view returns (SwapOption memory) {
        return _tokenSwapOptions[tokenContract];
    }

    function swapTokensForCredits(int256 amount, address tokenContract) external isEnabled validAmount(amount) {
        SwapOption storage option = _tokenSwapOptions[tokenContract];
        require(option.enabled, "Swapping this token for credits not enabled");
        uint256 value = (uint256(amount) * option.price) / 10**18;
        address account = _msgSender();
        if (option.burn) {
            IERC20Burn(tokenContract).burnFrom(account, value);
        }
        else {
            IERC20Upgradeable(tokenContract).safeTransferFrom(account, address(this), value);
        }
        emit CreditsChanged(account, amount, tokenContract, option.price);
    }


    function giftCredits(address account, int256 amount) external onlyOwner validAmount(amount) {
        emit CreditsChanged(account, amount, _msgSender(), 0);
    }


    function setTokenSwapOption(address tokenContract, bool enabled, bool burn, uint256 price) external onlyOwner {
        require(price <= type(uint128).max, "Price too high");
        require(price > 0, "Price cannot be zero");
        _tokenSwapOptions[tokenContract].price = uint128(price);
        _tokenSwapOptions[tokenContract].enabled = enabled;
        _tokenSwapOptions[tokenContract].burn = burn;

        emit SwapOptionChanged(tokenContract, enabled, burn, price);
    }

    function withdrawTokens(address tokenContract, uint256 amount) external onlyOwner {
        IERC20Upgradeable(tokenContract).safeTransferFrom(address(this), _msgSender(), amount);
    }


    function setEnabled(bool enabled) external onlyOwner {
        _enabled = enabled;
    }
}
