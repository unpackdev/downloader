// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// modified version from @author thirdweb

// $$\   $$\                               $$\
// $$$\  $$ |                              \__|
// $$$$\ $$ |$$\   $$\  $$$$$$\   $$$$$$\  $$\  $$$$$$\   $$$$$$$\
// $$ $$\$$ |$$ |  $$ |$$  __$$\ $$  __$$\ $$ |$$  __$$\ $$  _____|
// $$ \$$$$ |$$ |  $$ |$$ /  $$ |$$ /  $$ |$$ |$$$$$$$$ |\$$$$$$\
// $$ |\$$$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |$$   ____| \____$$\
// $$ | \$$ |\$$$$$$  |\$$$$$$$ |\$$$$$$$ |$$ |\$$$$$$$\ $$$$$$$  |
// \__|  \__| \______/  \____$$ | \____$$ |\__| \_______|\_______/
//                     $$\   $$ |$$\   $$ |
//                     \$$$$$$  |\$$$$$$  |
//                      \______/  \______/

// Token
import "./IERC721.sol";
import "./ERC165Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";

// Reward
import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";

// Utils
import "./CurrencyTransferLib.sol";
import "./OwnableAdminUpgradeable.sol";

//  ==========  Features    ==========
import "./Staking721Upgradeable.sol";

contract NuggiesStake is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    Staking721Upgradeable,
    ERC165Upgradeable,
    IERC721ReceiverUpgradeable,
    OwnableAdminUpgradeable
{
    error InsufficientFunds();

    uint256 private constant VERSION = 1;

    function initialize() external initializer {
        __Staking721_init(address(0x980679133F381D9368C876131D97149059626bCA));
        _setStakingCondition(86400, 1);

        __ERC20_init("NuggiesStake", "NUG");
        __ERC20Burnable_init();
        __OwnableAdmin_init();
    }

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 721 logic
    //////////////////////////////////////////////////////////////*/

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external view override returns (bytes4) {
        require(isStaking == 2, "Direct transfer");
        return this.onERC721Received.selector;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return
            interfaceId == type(IERC721ReceiverUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*///////////////////////////////////////////////////////////////
                        Transfer Staking Rewards
    //////////////////////////////////////////////////////////////*/

    /// @dev Mint/Transfer ERC20 rewards to the staker.
    function _mintRewards(address _staker, uint256 _rewards) internal override {
        _mint(_staker, _rewards);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether staking related restrictions can be set in the given execution context.
    function _canSetStakeConditions()
        internal
        view
        override
        onlyOwnerAdmin
        returns (bool)
    {
        return true;
    }

    /*///////////////////////////////////////////////////////////////
                            Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function _stakeMsgSender()
        internal
        view
        virtual
        override
        returns (address)
    {
        return _msgSender();
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

}
