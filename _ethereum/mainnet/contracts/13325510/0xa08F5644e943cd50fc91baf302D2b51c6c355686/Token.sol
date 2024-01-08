// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./ICountable.sol";
import "./IMintable.sol";
import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./Initializable.sol";

contract Token is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable, ICountable, IMintable {

    uint256 private _holderCount;
    address private _bridgeContractAddress;

    uint256 private _max_supply;
    address private _owner;

    function holderCount() external view override returns (uint256) {
        return _holderCount;
    }

    function initialize(string memory _name, string memory _symbol) initializer public {
        _max_supply = 208_000_000 * 10**18;
        __ERC20_init(_name, _symbol);
        __UUPSUpgradeable_init();
        __Ownable_init();
        _bridgeContractAddress = msg.sender;
     }

    function mint(address account, uint256 amount) external override onlyBridge() {
        require(_max_supply > totalSupply() + amount, "Cap has been reached");
        mintWithCount(account, amount);
    }           

    function mintWithCount(address to, uint256 amount) private {
        require(to != address(0) && amount > 0, "Invalid arguments");
        _updateCountOnTransfer(address(0), to, amount);
        _mint(to, amount);
    }

    /**
     * @dev ERC20 transfer function. Overridden to maintain holder count variable.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _updateCountOnTransfer(_msgSender(), recipient, amount);
        return super.transfer(recipient, amount);
    }

    /**
     * @dev ERC20 transferFrom function. Overridden to maintain holder count variable.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _updateCountOnTransfer(sender, recipient, amount);
        return super.transferFrom(sender, recipient, amount);
    }

    function burn(uint256 amount) public {
        require(amount > 0, "Invalid arguments");
        _burn(msg.sender, amount);
    }

    function updateBridgeContractAddress(address bridgeContractAddress) public onlyOwner() {
        require(bridgeContractAddress != address(0), "Bridge address is invalid");
        _bridgeContractAddress = bridgeContractAddress;
    }

    /** @dev Protected UUPS upgrade authorization fuction */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev Internal function to manage the holderCount variable that should be called
     *      BEFORE transfers alter balances.
     */
    function _updateCountOnTransfer(address from, address to, uint256 amount) private {
        // Transfers from and to the same address don't change the holder count ever.
        if (from == to) return;

        if (balanceOf(to) == 0 && amount > 0) {
            _holderCount++;
        }

        if (balanceOf(from) == amount && amount > 0) {
            _holderCount--;
        }
    }

    modifier onlyBridge {
        require(msg.sender == _bridgeContractAddress, "Can be called only by bridge contract");   
        _;
    }
}
