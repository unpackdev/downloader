// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.11;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20UpgradeSafe.sol";
import "./Lockable.sol";

contract AETH_R7 is OwnableUpgradeSafe, ERC20UpgradeSafe, Lockable {
    using SafeMath for uint256;

    event RatioUpdate(uint256 newRatio);

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address private _globalPoolContract;

    // ratio should be base on 1 ether
    // if ratio is 0.9, this variable should be  9e17
    uint256 private _ratio;

    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == _operator, "Operator: not allowed");
        _;
    }

    modifier onlyGlobalPoolContract() {
        require(_globalPoolContract == _msgSender(), "Ownable: caller is not the micropool contract");
        _;
    }

    function initialize(string memory name, string memory symbol) public initializer {
        OwnableUpgradeSafe.__Ownable_init();
        __ERC20_init(name, symbol);
        _totalSupply = 0;

        _ratio = 1e18;
    }

    function mint(address account, uint256 amount) external onlyGlobalPoolContract returns(uint256 _amount) {
        _mint(account, amount);
    }

    function updateRatio(uint256 newRatio) public onlyOperator {
        // 0.001 * ratio
        uint256 threshold = _ratio.div(1000);
        require(newRatio < _ratio.add(threshold) || newRatio > _ratio.sub(threshold), "New ratio should be in limits");
        _ratio = newRatio;
        emit RatioUpdate(_ratio);
    }

    function ratio() public view returns (uint256) {
        return _ratio;
    }

    function updateGlobalPoolContract(address globalPoolContract) external onlyOwner {
        _globalPoolContract = globalPoolContract;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function symbol() public view override returns (string memory)  {
        return _symbol;
    }

    function name() public view override returns (string memory)  {
        return _name;
    }

    function setNewNameAndSymbol() public onlyOperator {
        _name = "Ankr Eth2 Reward Bearing Bond";
        _symbol = "aETH";
    }

    function changeOperator(address operator) public onlyOwner {
        _operator = operator;
    }

    uint256[50] private __gap;

    address private _operator;
}
