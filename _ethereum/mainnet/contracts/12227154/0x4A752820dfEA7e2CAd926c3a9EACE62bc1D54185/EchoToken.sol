// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./ERC20Upgradeable.sol";
import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract EchoToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {

    // Use safemath lib for arthmetic operations
    using SafeMathUpgradeable for uint256;

    // Address to send 1% of all transactions to (community owned Gnosis Safe address)
    // mainnet safe - 0x32cD2c588D61410bAABB55b005f2C0ae520f8Aa5
    // rinkeby safe - 0xA38C495Fe2abc067C87FA2E65C406B598EbE6df8
    address payable private constant redistAddress = payable(0x32cD2c588D61410bAABB55b005f2C0ae520f8Aa5);

    // Token Version
    string public constant version = '1.0.0';

    // Constructor equivalent for upgradeable ERC20
    function initialize(string memory _name, string memory _symbol, uint256 initialSupply) initializer public {
        __ERC20_init(_name, _symbol);
        __Ownable_init();
        _mint(_msgSender(), initialSupply);
    }


    // Override the transfer function by redistributing the amount
    function transfer(address to, uint256 amount) public override returns (bool) {

        uint256 remainder;
        uint256 distAmount;

        (remainder, distAmount) = _calculateRedistributionAmount(to, amount);
        _transfer(_msgSender(), redistAddress, distAmount);
        return super.transfer(to, remainder);
    }

    // Override the transferFrom function by redistributing the amount
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {

        uint256 remainder;
        uint256 distAmount;

        (remainder, distAmount) = _calculateRedistributionAmount(to, amount);
        _transfer(from, redistAddress, distAmount);
        return super.transferFrom(from, to, remainder);
    }

    // Calculate an amount to redistribute, return the subtracted amount as that to transfer
    function _calculateRedistributionAmount(address to, uint256 amount) internal view returns (uint256 remainder, uint256 distAmount) {

        // 1% transaction to redistribute to community safe
        uint256 redistAmount = amount.div(100);

        // Do not apply transaction fee on contract owner
        if (_msgSender() == this.owner() || to == this.owner()) {
            redistAmount = 0;
        }
        
        return (amount.sub(redistAmount), redistAmount);
    }
}