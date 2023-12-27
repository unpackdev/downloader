// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//@openzeppelin = https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master
import "./ERC20.sol";
import "./ERC20Pausable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract CCPToken is ERC20, ERC20Pausable, Ownable {
    uint8 public cooldownTimerInterval = 60 seconds;
    uint256 public maxTxAmount;
    mapping (address => uint) private cooldownTimer;
    bool public buyCooldownEnabled = true;
    mapping (uint => string) private info;

    constructor() ERC20("CCP", "CCP") Ownable(msg.sender) {
        _mint(msg.sender, 20_000_000 * 10 ** decimals());
        maxTxAmount = (20_000_000 * 2 / 1000) * (10 ** decimals());
        _pause();
    }

    function cooldownEnabled(bool _status, uint8 _interval) public onlyOwner {
        buyCooldownEnabled = _status;
        cooldownTimerInterval = _interval;
    }

    function setTxLimit(uint256 amount) external onlyOwner() {
        maxTxAmount = amount;
    }

    function pause(bool _state) public onlyOwner {
        if (_state) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
    @dev Get the info for a specific option.
    @param option The option to get. 
        - Option 0: Website.
        - Option 1: Twitter.
        - Option 2: Discord.
        - Option 3: Telegram.
        - Option 4: Instagram.
        - Option 5+: Additional Info If Needed.
    */
    function _infoPage(uint256 option) external view returns(string memory) {
        return info[option];
    }

    function setInfo(uint256 _infoID, string calldata _info) external onlyOwner() {
        info[_infoID] = _info;
    }

    function isContract(address _address) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }

    /**
    * @dev Hook that is called for any token transfer. 
    * This includes transfers, minting, and burning.
    */
    function _update(address from, address to, uint256 value) internal virtual override(ERC20, ERC20Pausable) whenNotPaused {
        // ... before action here ...
        if (isContract(from) && buyCooldownEnabled){
            require(value <= maxTxAmount, "TX Limit Exceeded");
            require(cooldownTimer[to] < block.timestamp,"Please wait for cooldown");
            cooldownTimer[to] = block.timestamp + cooldownTimerInterval;
        }
        super._update(from, to, value);
        // ... after action here ...   
    }
}