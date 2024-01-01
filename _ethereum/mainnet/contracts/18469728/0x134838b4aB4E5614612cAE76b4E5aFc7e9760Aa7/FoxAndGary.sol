// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./ERC20.sol";
import "./Owned.sol";

contract FoxAndGary is ERC20, Owned {

    uint256 constant public INITIAL_SUPPLY = 10_000_000_000_000 * (10 ** 18);
    uint256 constant public MAX_FEE = 2_00;
    mapping(address => uint256) public fee;
    address public treasury;

    constructor() ERC20("FoxAndGary", "FNG", 18) Owned(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function transfer(address _to, uint256 _amount) public override returns (bool) {
        return ERC20.transfer(
            _to,
            _processFee(msg.sender, _amount)
        );
    }

    function transferFrom(address _from, address _to, uint256 _amount) public override returns (bool) {
        return ERC20.transferFrom(
            _from,
            _to,
            _processFee(_from, _amount)
        );
    }

    function _processFee(address _from, uint256 _amount) private returns (uint256) {
        uint256 feeAmount = _amount * fee[_from] / 100_00;
        if (feeAmount > 0) {
            _amount -= feeAmount;
            ERC20.balanceOf[_from] -= feeAmount;
            ERC20.balanceOf[treasury] += feeAmount;
        }
        return _amount;
    }

    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }

    function setFee(address _for, uint256 _fee) public onlyOwner {
        require(_fee <= MAX_FEE, "fee too high");
        fee[_for] = _fee;
    }

    function setTreasury(address payable _treasury) public onlyOwner {
        treasury = _treasury;
    }
}
