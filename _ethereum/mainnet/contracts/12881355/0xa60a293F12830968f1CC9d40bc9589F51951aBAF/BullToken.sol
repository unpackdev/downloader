// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.4;

import "./ERC20PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./console.sol";

/* mythx-disable SWC-103 */
/* mythx-disable SWC-116 */

contract BullToken is OwnableUpgradeable, ERC20PausableUpgradeable {
    mapping(address => uint) public claims;
    uint public airdropStartTimestamp;
    uint public airdropClaimDuration;
    uint public airdropStageDuration;
    uint public maxSupply;
    uint public burnRateNumerator;
    uint public burnRateDenominator;
    bool public rollbackManyDisabled;

    function initialize(uint _airdropStartTimestamp, uint _airdropClaimDuration, uint _airdropStageDuration, uint _burnRateNumerator, uint _burnRateDenominator) public initializer {
        // https://docs.openzeppelin.com/contracts/4.x/upgradeable#multiple-inheritance
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC20_init_unchained("Bull Token", "BULL");
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();

        airdropStartTimestamp = _airdropStartTimestamp;
        airdropClaimDuration = _airdropClaimDuration;
        airdropStageDuration = _airdropStageDuration;

        maxSupply = 10000 * 969_163_000 * 10 ** 18;
        burnRateNumerator = _burnRateNumerator;
        burnRateDenominator = _burnRateDenominator;
    }

    function setClaims(address[] calldata _claimers, uint[] calldata _amounts) public onlyOwner {
        require(_claimers.length == _amounts.length, "_claimers.length must be equal to _amounts.length");
        for (uint i = 0; i < _claimers.length; i++) {
            claims[_claimers[i]] = _amounts[i];
        }
    }

    // TODO: Implement claimMany (aka claimForAddresess)

    function claim() external {
        require(block.timestamp >= airdropStartTimestamp, "Can't claim before the airdrop is started");
        require((block.timestamp - airdropStartTimestamp) % airdropStageDuration < airdropClaimDuration, "Can't claim when not in distribution period");
        bool result = _claim(msg.sender);
        require(result, "Can't claim because this address has already claimed or didn't hold $SHLD at the snapshot time");
    }

    function claimMany(address[] calldata addresses) external {
        require(block.timestamp >= airdropStartTimestamp, "Can't claim before the airdrop is started");
        require((block.timestamp - airdropStartTimestamp) % airdropStageDuration < airdropClaimDuration, "Can't claim when not in distribution period");
        for (uint i = 0; i < addresses.length; i++) {
            _claim(addresses[i]);
        }
        // This function allows to process addresses which don't have any $BULL to claim
    }

    function _claim(address _address) internal returns (bool) {
        uint amount = claims[_address];
        if (amount > 0) {
            claims[_address] = 0;
            _mint(_address, amount);
            return true;
        }
        return false;
    }

    function transferMany(address[] calldata recipients, uint[] calldata amounts) external onlyOwner {
        uint amountsLength = amounts.length;
        uint recipientsLength = recipients.length;

        require(recipientsLength == amountsLength, "Wrong array length");

        uint total = 0;
        for (uint i = 0; i < amountsLength; i++) {
            total = total + amounts[i];
        }

        require(balanceOf(msg.sender) >= total, "ERC20: transfer amount exceeds balance");

        for (uint i = 0; i < recipientsLength; i++) {
            address recipient = recipients[i];
            uint amount = amounts[i];
            require(recipient != address(0), "ERC20: transfer to the zero address");

            super._transfer(msg.sender, recipient, amount);
        }
    }

    function rollbackMany(address[] calldata burnAddresses, address[] calldata mintAddresses, uint[] calldata amounts) public onlyOwner {
        // WARN: this function doesn't refund fee-on-transfer, because it was not active during latest airdrop
        require(rollbackManyDisabled == false, "rollbackMany is disabled");
        require(burnAddresses.length == amounts.length, "Wrong array length (burnAddresses, amounts)");
        require(mintAddresses.length == amounts.length, "Wrong array length (mintAddresses, amounts)");

        bool _paused = paused();
        if (_paused) _unpause();
        for (uint i = 0; i < amounts.length; i++) {
            if (burnAddresses[i] != address(0)) _burn(burnAddresses[i], amounts[i]);
            if (mintAddresses[i] != address(0)) _mint(mintAddresses[i], amounts[i]);
        }
        if (_paused) _pause();
    }

    function finishRollbackMany() public onlyOwner {
        rollbackManyDisabled = true;
        if (paused()) _unpause();
    }

    function _mint(address account, uint amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= maxSupply, "Can't mint more than maxSupply");
    }

    function _transfer(address sender, address recipient, uint amount) internal override {
        uint receivedAmount = toReceivedAmount(amount, burnRateNumerator, burnRateDenominator);
        uint burntAmount = amount - receivedAmount;
        _burn(sender, burntAmount);
        super._transfer(sender, recipient, receivedAmount);
    }

    function withdraw(uint amount) public onlyOwner {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = _msgSender().call{value : amount}("");
        require(success, "Unable to send value");
    }

    function withdrawToken(address token, uint amount) public onlyOwner {
        IERC20Upgradeable(token).transfer(msg.sender, amount);
    }

    function pause(bool status) public onlyOwner {
        if (status) {
            _pause();
        } else {
            _unpause();
        }
    }

    function fromReducedAmount(uint _amount, uint _burnRateNumerator, uint _burnRateDenominator) internal pure returns (uint) {
        return _amount * _burnRateDenominator / _burnRateNumerator;
    }

    function toReceivedAmount(uint _amount, uint _burnRateNumerator, uint _burnRateDenominator) internal pure returns (uint) {
        return _amount * _burnRateNumerator / _burnRateDenominator;
    }
}
