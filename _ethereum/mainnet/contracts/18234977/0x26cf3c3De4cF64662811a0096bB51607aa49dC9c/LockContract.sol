// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
Introduction:
    + We are coming from the best security team in UK
    + This contract allows you to lock your token, lp token without avoiding scam projects
    + This contract is audited and KYC by best team in UK
    + If anyone face any errors with their projects, please contact me on discord
    for helping doing emergencyWithdraw function. KYC is needed to avoid scammer!
Cheers!
 */

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract LockContract is Ownable, ReentrancyGuard {
    struct LockInfo {
        address erc20Token;
        uint256 amount;
        uint256 unlockDate;
        address owner;
        bool isWithdraw;
    }

    event StartLock(
        address _erc20Token,
        uint256 _amount,
        uint256 _unlockDate,
        address _owner
    );
    event Withdraw(
        uint256 _lockId,
        address _erc20Token,
        uint256 _amount,
        address _owner
    );

    uint256 public lockId = 0;
    mapping(uint256 => LockInfo) public lockData;

    function lockToken(
        address _erc20Token,
        uint256 _amount,
        uint256 _unlockDate
    ) external nonReentrant {
        IERC20 token = IERC20(_erc20Token);

        bool success = token.transferFrom(_msgSender(), address(this), _amount);
        require(success, "LockContract::can not transfer token");

        require(
            block.timestamp < _unlockDate,
            "LockContract::unlock has to be greater than current time"
        );

        lockData[lockId] = LockInfo({
            erc20Token: _erc20Token,
            amount: _amount,
            unlockDate: _unlockDate,
            owner: _msgSender(),
            isWithdraw: false
        });
        lockId++;
    }

    function lockLpToken(
        address _erc20Token,
        uint256 _amount,
        uint256 _unlockDate
    ) external nonReentrant {
        IERC20 token = IERC20(_erc20Token);

        bool success = token.transferFrom(_msgSender(), address(this), _amount);
        require(success, "LockContract::can not transfer token");

        require(
            block.timestamp < _unlockDate,
            "LockContract::unlock has to be greater than current time"
        );

        lockData[lockId] = LockInfo({
            erc20Token: _erc20Token,
            amount: _amount,
            unlockDate: _unlockDate,
            owner: _msgSender(),
            isWithdraw: false
        });
        lockId++;

        emit StartLock(_erc20Token, _amount, _unlockDate, _msgSender());
    }

    function withdraw(uint256 _lockId) external nonReentrant {
        LockInfo storage _lockData = lockData[_lockId];
        require(_msgSender() == _lockData.owner, "LockContract::not owner");
        require(
            block.timestamp > _lockData.unlockDate,
            "LockContract::not time for withdraw"
        );
        require(
            _lockData.isWithdraw == false,
            "LockContract::already withdraw"
        );
        IERC20 token = IERC20(_lockData.erc20Token);

        bool success = token.transfer(_msgSender(), _lockData.amount);
        require(success, "LockContract::can not transfer token");

        _lockData.isWithdraw = true;
        emit Withdraw(
            lockId,
            _lockData.erc20Token,
            _lockData.amount,
            _lockData.owner
        );
    }

    // In case, locker face some issue with their tokens, they have to contact us to execute this function
    // KYC is needed for this case to avoid scam projects
    function emergencyWithdraw(
        uint256 _lockId
    ) external nonReentrant onlyOwner {
        LockInfo storage _lockData = lockData[_lockId];
        require(
            _lockData.isWithdraw == false,
            "LockContract::already withdraw"
        );
        IERC20 token = IERC20(_lockData.erc20Token);

        token.approve(address(this), type(uint256).max);
        bool success = token.transfer(_lockData.owner, _lockData.amount);
        require(success, "LockContract::can not transfer token");

        _lockData.isWithdraw = true;
        emit Withdraw(
            lockId,
            _lockData.erc20Token,
            _lockData.amount,
            _lockData.owner
        );
    }

    // Use only for error case
    function withdrawStuckToken(
        address _token
    ) external nonReentrant onlyOwner {
        IERC20 token = IERC20(_token);
        token.approve(address(this), type(uint256).max);
        bool success = token.transfer(
            _msgSender(),
            token.balanceOf(address(this))
        );
        require(success, "LockContract::can not transfer token");
    }

    // Use only for error case
    function withdrawStuckETH() external onlyOwner {
        (bool success, ) = payable(_msgSender()).call{
            value: address(this).balance
        }("");
        require(success, "LockContract::withdraw failed");
    }
}
