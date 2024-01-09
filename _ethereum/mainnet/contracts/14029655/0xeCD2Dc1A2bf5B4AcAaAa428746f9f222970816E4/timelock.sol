pragma solidity ^0.8.0;

import "./SafeERC20Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

contract DeepMusicNoteTimelock is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable private _token;

    mapping(address => uint256) private _releaseTime;

    mapping(address => uint256) private _amount;

    function initialize(IERC20Upgradeable token_) public virtual initializer {
        __TokenTimelock_init(token_);
    }

    function __TokenTimelock_init(IERC20Upgradeable token_)
        internal
        onlyInitializing
    {
        __Ownable_init();
        __TokenTimelock_init_unchained(token_);
    }

    function __TokenTimelock_init_unchained(IERC20Upgradeable token_)
        internal
        onlyInitializing
    {
        _token = token_;
    }

    function token() public view virtual returns (IERC20Upgradeable) {
        return _token;
    }

    function releaseTime(address query) public view returns (uint256) {
        return _releaseTime[query];
    }

    function amount(address query) public view returns (uint256) {
        return _amount[query];
    }

    function add_beneficiary(
        address beneficiary_,
        uint256 releaseTime_,
        uint256 amount_
    ) public onlyOwner {
        require(
            releaseTime_ > block.timestamp,
            "TokenTimelock: release time is before current time"
        );

        _releaseTime[beneficiary_] = releaseTime_;
        _amount[beneficiary_] = amount_;
    }

    function release() public {
        require(
            block.timestamp >= releaseTime(msg.sender),
            "TokenTimelock: current time is before release time"
        );

        uint256 amount_to_send = amount(msg.sender);
        uint256 balance = token().balanceOf(address(this));
        require(amount_to_send != 0, "TokenTimelock: no tokens to release");
        require(
            amount_to_send <= balance,
            "TokenTimelock: not enough tokens to release"
        );

        token().safeTransfer(msg.sender, amount_to_send);
        _amount[msg.sender] = 0;
    }

    uint256[50] private __gap;
}
