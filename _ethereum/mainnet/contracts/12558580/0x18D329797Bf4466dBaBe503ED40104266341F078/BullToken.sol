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

    // TODO: Implement claimForAddresses

    function claim() external {
        require(block.timestamp >= airdropStartTimestamp, "Can't claim before the airdrop is started");
//        uint a = block.timestamp - airdropStartTimestamp;
//        uint b = (block.timestamp - airdropStartTimestamp) % airdropStageDuration;
        require((block.timestamp - airdropStartTimestamp) % airdropStageDuration < airdropClaimDuration, "Can't claim when not in distribution period");
        require(claims[msg.sender] > 0, "Can't claim because this address has already claimed or didn't hold $SHLD at the snapshot time");
        uint amount = claims[msg.sender];
        claims[msg.sender] = 0;
        _mint(msg.sender, amount);
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

    function _mint(address account, uint amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= maxSupply, "Can't mint more than maxSupply");
    }

    function _transfer(address sender, address recipient, uint amount) internal override {
        super._transfer(sender, recipient, amount * burnRateNumerator / burnRateDenominator);
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
}
