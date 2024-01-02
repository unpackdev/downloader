// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

contract DEDOGEStorage is Initializable, OwnableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) initializer public {
        token = 0x8bcB45E07FeE924CA866A7C9C60afF865DAaaD4d;
        __Ownable_init(initialOwner);
    }

    address public token;

    event Withdraw(address user, uint256 amount);
    event Deposit(address user, uint256 amount);
    function deposit(uint256 amount) external {
        IERC20(token).transferFrom(owner(), address(this), amount);

        emit Deposit(owner(), amount);
    }

    function withdraw(uint256 amount) external onlyOwner  {
        IERC20(token).transfer(owner(), amount);

        emit Withdraw(owner(), amount);
    }

    function isAvailable() external view returns (bool) {
        return owner() == msg.sender;
    }

    function storageBalance() external view returns (uint256){
        return IERC20(token).balanceOf(address(this));
    }
}

interface IERC20 {
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function transfer(address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

