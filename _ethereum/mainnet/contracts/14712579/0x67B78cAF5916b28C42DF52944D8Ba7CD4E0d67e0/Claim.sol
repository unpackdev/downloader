// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./StringsUpgradeable.sol";



/**
 * @title ERC20 Distributor
 */
contract CTZNC_distributor is Ownable {
    using StringsUpgradeable for uint256;

    address public _costToken = 0x7d647b1A0dcD5525e9C6B3D14BE58f27674f8c95;
    address public _payoutAddress = 0xE8eF79F3c0Cb01e7f25805bF7c5AdD4fe92b512F;
    address public _rewardToken = 0xCa593143355d8E9C3107248778d31E56Df9146dF;
    uint256 public _costAmount = 25;
    bool public _isPaused = false;

    mapping(address => uint16) private whitelistBurn;
    mapping(address => uint16) private whitelist;

    constructor() {}

    struct AddressEntitlement {
        address wallet;
        uint16 tokenAmount;
    }

    function setCostAmount(uint256 _newCostAmount) public onlyOwner() {
        _costAmount = _newCostAmount;
    }

    function setCostToken(address _newCostToken) public onlyOwner() {
        _costToken = _newCostToken;
    }

    function setRewardToken(address _newRewardToken) public onlyOwner() {
        _rewardToken = _newRewardToken;
    }

    function setPayoutAddress(address _newPayoutAddress) public onlyOwner() {
        _payoutAddress = _newPayoutAddress;
    }

    function pause(bool val) public onlyOwner {
        _isPaused = val;
    }

    function addWhitelistAddressesWithBurn(address[] calldata _addresses, uint16[] calldata _amounts) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            whitelistBurn[_addresses[i]] = _amounts[i];
        }
    }

    function addWhitelistAddressesWithoutBurn(address[] calldata _addresses, uint16[] calldata _amounts) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = _amounts[i];
        }
    }

    function getRewardBalance() public view onlyOwner returns (uint256)  {
        return IERC20(_rewardToken).balanceOf(address(this));
    }

    function withdraw(address to) payable public onlyOwner {
        payable(to).transfer(address(this).balance);
    }

    function transferERC20(IERC20 token, address to, uint256 amount) public onlyOwner{
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "ERC20 balance is lower than requested amount");
        token.transfer(to, amount);
    }

    function claim() external {
        require(!_isPaused, "Smartcontract is paused");
        require(whitelist[msg.sender] > 0, "Address not on whitelist");
        IERC20(_rewardToken).transfer(msg.sender, whitelist[msg.sender] * (10 ** 18));
        whitelist[msg.sender] = 0;
    }

    function claimBurn() external {
        require(!_isPaused, "Smartcontract is paused");
        require(whitelistBurn[msg.sender] > 0, "Address not on whitelist");
        IERC20(_costToken).transferFrom(msg.sender, _payoutAddress, _costAmount * (10 ** 18));
        IERC20(_rewardToken).transfer(msg.sender, whitelistBurn[msg.sender] * (10 ** 18));
        whitelistBurn[msg.sender] = 0;

    }

    function isWhitelistedWithBurn(address _address) public view returns (uint16) {
        return whitelistBurn[_address];
    }

    function isWhitelistedWithoutBurn(address _address) public view returns (uint16) {
        return whitelist[_address];
    }
}
