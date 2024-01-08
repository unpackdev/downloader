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

    function count() external view override returns (uint256) {
        return _holderCount;
    }

    function initialize(string memory _name, string memory _symbol) initializer public {
        _max_supply = 208_000_000 * 10**18;
        __ERC20_init(_name, _symbol);
        __UUPSUpgradeable_init();
        __Ownable_init();
     }

    function mint(address account, uint256 amount) external override onlyBridge() {
        require(_max_supply > totalSupply() + amount, "Cap has been reached");
        mintWithCount(account, amount);
    }           

    function mintWithCount(address account, uint256 amount) private {
        require(account != address(0) && amount > 0, "Invalid arguments");
        if (balanceOf(account) == 0) {
            _holderCount++;
        }

        _mint(account, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0) && amount > 0, "Invalid arguments");
        
        if (balanceOf(recipient) == 0 && balanceOf(msg.sender) - amount > 0) {
            _holderCount++;
        }

        transfer(recipient, amount);
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

    modifier onlyBridge {
        require(msg.sender == _bridgeContractAddress, "Can be called only by bridge contract");   
        _;
    }
}
