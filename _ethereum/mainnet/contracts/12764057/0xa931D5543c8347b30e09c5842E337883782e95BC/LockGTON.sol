//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ILockGTON.sol";

/// @title LockGTON
/// @author Artemij Artamonov - <array.clean@gmail.com>
/// @author Anton Davydov - <fetsorn@gmail.com>
contract LockGTON is ILockGTON {
    /// @inheritdoc ILockGTON
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc ILockGTON
    IERC20 public override governanceToken;

    /// @inheritdoc ILockGTON
    bool public override canLock;

    constructor(IERC20 _governanceToken) {
        owner = msg.sender;
        governanceToken = _governanceToken;
    }

    /// @inheritdoc ILockGTON
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc ILockGTON
    function setCanLock(bool _canLock) external override isOwner {
        canLock = _canLock;
        emit SetCanLock(owner, _canLock);
    }

    /// @inheritdoc ILockGTON
    function migrate(address newLock) external override isOwner {
        uint256 amount = governanceToken.balanceOf(address(this));
        governanceToken.transfer(newLock, amount);
        emit Migrate(newLock, amount);
    }

    /// @inheritdoc ILockGTON
    function lock(uint256 amount) external override {
        require(canLock, "LG1");
        governanceToken.transferFrom(msg.sender, address(this), amount);
        emit LockGTON(address(governanceToken), msg.sender, msg.sender, amount);
    }
}
