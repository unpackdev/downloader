// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

/**
 * @title acBTCx token contract. Collects and distributes acBTC income
 * to all acBTCx holders.
 * 
 * Credit: https://github.com/acBTCswap/acBTCswap/blob/master/contracts/acBTCBar.sol
 */
contract ACoconutMaker is ERC20Upgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event Minted(address indexed account, uint256 share, uint256 amount);
    event Redeemed(address indexed account, uint256 share, uint256 amount);

    uint256 public constant WAD = 10**18;
    IERC20Upgradeable public acBTC;

    /**
     * @dev Initializes acBTCx contract.
     */
    function initialize(IERC20Upgradeable _acBTC) public initializer {
        __ERC20_init("ACoconut Maker", "acBTCx");
        __ReentrancyGuard_init();
        acBTC = _acBTC;
    }

    /**
     * @dev Returns the amount of acBTC for each acBTCx.
     */
    function exchangeRate() public view returns (uint256) {
        uint256 _totalAmount = acBTC.balanceOf(address(this));
        uint256 _totalShare = totalSupply();

        return _totalShare == 0 ? WAD : _totalAmount.mul(WAD).div(_totalShare);
    }

    /**
     * @dev Mints acBTCx with acBTC.
     * @param _amount Amount of acBTC used to mint acBTCx.
     */
    function mint(uint256 _amount) public nonReentrant {
        uint256 _totalAmount = acBTC.balanceOf(address(this));
        uint256 _totalShare = totalSupply();

        uint256 _share = 0;
        if (_totalAmount == 0 || _totalShare == 0) {
            _share = _amount;
        } 
        else {
            _share = _amount.mul(_totalShare).div(_totalAmount);
        }
        _mint(msg.sender, _amount);
        acBTC.safeTransferFrom(msg.sender, address(this), _amount);

        emit Minted(msg.sender, _share, _amount);
    }

    /**
     * @dev Redeems acBTCx to acBTC.
     * @param _share Amount of acBTCx to redeem.
     */
    function redeem(uint256 _share) public nonReentrant {
        uint256 _totalAmount = acBTC.balanceOf(address(this));
        uint256 _totalShare = totalSupply();
        uint256 _amount = _share.mul(_totalAmount).div(_totalShare);
        _burn(msg.sender, _share);
        acBTC.safeTransfer(msg.sender, _amount);

        emit Redeemed(msg.sender, _share, _amount);
    }
}