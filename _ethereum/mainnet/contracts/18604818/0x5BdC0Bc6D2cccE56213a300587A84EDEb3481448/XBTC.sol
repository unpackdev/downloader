//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

//import "./console.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./utils.sol";

contract XBTC is ERC20, Ownable, Utils {

    uint256 constant maxSupply = 21 * 10 ** 6 * 10 ** 18;
    uint256 constant blocksWithoutFee = 200000;
    uint256 public immutable lastBlockWithoutFee;
    address private immutable multiSignWithdrawAddress;

    address public taxRecipient;
    mapping(address => bool) public excludedFromFee;
    mapping(address => uint256) public userSpendXBTC;

    constructor(
        address _initialOwner, string memory _name, string memory _symbol,
        address _multiSignWithdrawAddress
    )
    ERC20(_name, _symbol)
    Ownable(_initialOwner)
    {
        lastBlockWithoutFee = block.number + blocksWithoutFee;
        multiSignWithdrawAddress = _multiSignWithdrawAddress;

        _mint(msg.sender, maxSupply);
    }

    function exclude(address _addr, bool _status)
    external
    onlyOwner
    {
        excludedFromFee[_addr] = _status;
    }

    function setTaxRecipient(address _addr)
    external
    onlyOwner
    {
        taxRecipient = _addr;
    }

    function _update(address _from, address _to, uint256 _value)
    internal
    override(ERC20)
    {
        if (_to == multiSignWithdrawAddress) {
            userSpendXBTC[_from] += _value;
        }

        if (excludedFromFee[_from] || excludedFromFee[_to] || (block.number < lastBlockWithoutFee)) {
            super._update(_from, _to, _value);
            return;
        }
        uint256 _tax = _value * 21 / 100000; // 0.021 %
        super._update(_from, taxRecipient, _tax);
        super._update(_from, _to, _value - _tax);
    }
}


