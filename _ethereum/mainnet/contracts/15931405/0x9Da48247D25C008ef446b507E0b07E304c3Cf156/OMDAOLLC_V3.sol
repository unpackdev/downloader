// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IERC20.sol";
import "./ERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./Initializable.sol";

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

contract OMDAOLLC_V3 is Initializable, ERC20Upgradeable, PausableUpgradeable, OwnableUpgradeable, ERC20PermitUpgradeable {
    address private addrUSDT;
    address private addrStake;
    address private addrRewardTeam;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // function initialize() initializer public {
    //     addrUSDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    //     __ERC20_init("OM DAO LLC", "OMD");
    //     __Pausable_init();
    //     __Ownable_init();
    //     __ERC20Permit_init("OM DAO LLC");
    // }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function setAddressUSDT(address _addrUSDT) external onlyOwner{
        require(_addrUSDT != address(0), "ERC20: contract is the zero address");
        addrUSDT = _addrUSDT;
    }

    function setAddressStake(address _addrStake) external onlyOwner{
        addrStake = _addrStake;
    }

    function setAddressReward(address _addrReward) external onlyOwner{
        addrRewardTeam = _addrReward;
    }

    function _moneyRouter(uint256 _amount) internal {
        IERC20Upgradeable usdt = IERC20Upgradeable(addrUSDT);
        uint256 amount = _amount;
        address addrReward = addrRewardTeam;
        if (addrStake != address(0)) {
            amount = _amount*5/10;
            _mint(addrStake, amount);
        }
        if (addrRewardTeam == address(0)) addrReward = owner();
        usdt.safeTransfer(addrReward, amount);
    }

    function buyToken(uint256 _amount) external{
        require(_amount >= 1 * 10**decimals(),"Amount must be greater than or equal to 1 USDT.");
        IERC20Upgradeable usdt = IERC20Upgradeable(addrUSDT);
        usdt.safeTransferFrom(_msgSender(), address(this), _amount);
        _moneyRouter(_amount*1/10);
        _mint(_msgSender(), _amount);
    }

    function sellToken(uint256 _amount) external{
        require(_amount >= 1 * 10**decimals(),"Amount must be greater than or equal to 1 token.");
        _burn(_msgSender(), _amount);
        IERC20Upgradeable usdt = IERC20Upgradeable(addrUSDT);
        usdt.safeTransfer(_msgSender(), _amount*9/10);
    }

    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner{
        require(_tokenContract != address(0), "ERC20: contract is the zero address");
        IERC20Upgradeable tokenContract = IERC20Upgradeable(_tokenContract);
        tokenContract.safeTransfer(_msgSender(), _amount);
    }

}
