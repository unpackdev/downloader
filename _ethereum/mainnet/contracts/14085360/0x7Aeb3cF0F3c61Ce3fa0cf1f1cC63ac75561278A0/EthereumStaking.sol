// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC20Upgradeable.sol";

contract EthereumStaking is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    address public erc20Address;
    address public gateway;
    uint256 public handlingFee;

    function initialize(
        address _erc20Address,
        address _gateway,
        uint256 _handlingFee
    ) public initializer {
        erc20Address = _erc20Address;
        gateway = _gateway;
        handlingFee = _handlingFee;
        __Ownable_init();
        _pause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /* STAKING MECHANICS */

    event ClaimRewards(address account);
    event SendRewards(address account, uint256 amount);

    function setErc20Address(address _erc20Address) public onlyOwner {
        erc20Address = _erc20Address;
    }

    function setGateway(address _gateway) public onlyOwner {
        gateway = _gateway;
    }

    function setHandlingFee(uint256 _handlingFee) public onlyOwner {
        handlingFee = _handlingFee;
    }

    function claimRewards() public payable {
        require(msg.value >= handlingFee, "insufficient handling fee");
        payable(gateway).transfer(msg.value);
        emit ClaimRewards(msg.sender);
    }

    function sendRewards(address account, uint256 amount) external {
        require(msg.sender == gateway, "only gateway");
        require(amount > 0, "invalid amount");
        IERC20Upgradeable(erc20Address).transfer(account, amount);
        emit SendRewards(account, amount);
    }

    //withdrawal function
    function withdrawTokens() external onlyOwner {
        uint256 tokenSupply = IERC20Upgradeable(erc20Address).balanceOf(
            address(this)
        );
        IERC20Upgradeable(erc20Address).transfer(msg.sender, tokenSupply);
    }
}
