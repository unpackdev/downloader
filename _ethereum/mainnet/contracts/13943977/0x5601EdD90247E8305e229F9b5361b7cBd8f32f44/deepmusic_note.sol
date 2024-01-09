pragma solidity 0.8.6;
import "./Initializable.sol";
import "./ERC20CappedUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract DeepMusicNote is
    Initializable,
    ERC20CappedUpgradeable,
    OwnableUpgradeable
{
    function initialize(
        string memory name,
        string memory symbol,
        uint256 cap
    ) public virtual initializer {
        __ERC20_init(name, symbol);
        __ERC20Capped_init(cap);
        __Ownable_init();
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
}
