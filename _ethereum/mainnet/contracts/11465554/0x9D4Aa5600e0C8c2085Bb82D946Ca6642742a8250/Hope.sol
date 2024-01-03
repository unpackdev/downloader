// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./EnumerableSet.sol";

import "./IHopeNonTradable.sol";
import "./IHopeLiquidityInitializer.sol";

contract Hope is Ownable, ERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _whitelisted;

    IHopeNonTradable public hopeNonTradable;

    IHopeLiquidityInitializer initializer;

    // Whether HopeNonTradable can be upgraded for Hope or not
    bool public isUpgradeActive = true;
    bool public isLiquidityInitialized = false;

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    constructor(IHopeNonTradable _hopeNonTradable, bool _isLiquidityInitialized) public ERC20("HOPE", "HOPE") {
        hopeNonTradable = _hopeNonTradable;
        isLiquidityInitialized = _isLiquidityInitialized; // For testing
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    ///////////////
    // Modifiers //
    ///////////////

    modifier onlyWhitelisted() {
        require(_whitelisted.contains(msg.sender), "Address not whitelisted");
        _;
    }

    ///////////
    // Admin //
    ///////////

    function addWhitelisted(address _toAdd) public onlyOwner {
        _whitelisted.add(_toAdd);
    }

    function removeWhitelisted(address _toRemove) public onlyOwner {
        _whitelisted.add(_toRemove);
    }

    function setUpgradeActive(bool _state) public onlyOwner {
        isUpgradeActive = _state;
    }

    function setLiquidityInitializer(IHopeLiquidityInitializer _initializer) public onlyOwner {
        require(isLiquidityInitialized == false, "Liquidity already initialized");
        initializer = _initializer;
    }

    /////////////////
    // Whitelisted //
    /////////////////

    function burn(address _account, uint256 _amount) public onlyWhitelisted {
        _burn(_account, _amount);
    }

    function mint(address _account, uint256 _amount) public onlyWhitelisted {
        _mint(_account, _amount);
    }

    //////////
    // View //
    //////////

    function getWhitelisted() external view returns(address[] memory) {
        uint256 length = _whitelisted.length();
        address[] memory result = new address[](length);

        for (uint256 i=0; i < length; i++) {
            result[i] = _whitelisted.at(i);
        }

        return result;
    }

    ///////////
    // Other //
    ///////////

    function setLiquidityInitialized() public {
        require(msg.sender == address(initializer));
        isLiquidityInitialized = true;
    }

    function upgradeHopeNonTradable(uint256 _amount) public {
        require(owner() == msg.sender || isLiquidityInitialized, "Liquidity is not initialized");
        require(isUpgradeActive, "Upgrade is disabled");
        hopeNonTradable.burn(msg.sender, _amount);
        _mint(msg.sender, _amount);
    }
}