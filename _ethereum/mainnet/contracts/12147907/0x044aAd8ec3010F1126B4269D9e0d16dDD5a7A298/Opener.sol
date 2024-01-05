// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import "./Ownable.sol";

interface TransferFromAndBurnFrom {
    function burnFrom(address account, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
}

contract Opener is Ownable {
    TransferFromAndBurnFrom private _pmonToken;
    address public _stakeAddress;
    address public _feeAddress;
    address public _swapBackAddress;

    event Opening(address indexed from, uint256 amount, uint256 openedBoosters);

    uint256 public _burnShare = 75;
    uint256 public _stakeShare = 0;
    uint256 public _feeShare = 25;
    uint256 public _swapBackShare = 0;

    bool public _closed = false;

    uint256 public _openedBoosters = 0;

    constructor(
        TransferFromAndBurnFrom pmonToken,
        address stakeAddress,
        address feeAddress,
        address swapBackAddress
    ) public {
        _pmonToken = pmonToken;
        _stakeAddress = stakeAddress;
        _feeAddress = feeAddress;
        _swapBackAddress = swapBackAddress;
    }

    function openBooster(uint256 amount) public {
        require(!_closed, "Opener is locked");
        address from = msg.sender;
        require(
            _numOfBoosterIsInteger(amount),
            "Only integer numbers of booster allowed"
        );
        _distributeBoosterShares(from, amount);

        emit Opening(from, amount, _openedBoosters);
        _openedBoosters = _openedBoosters + (amount / 10**uint256(18));
    }

    function _numOfBoosterIsInteger(uint256 amount) private returns (bool) {
        return (amount % 10**uint256(18) == 0);
    }

    function _distributeBoosterShares(address from, uint256 amount) private {
        //transfer of fee share
        _pmonToken.transferFrom(from, _feeAddress, (amount * _feeShare) / 100);

        //transfer of stake share
        _pmonToken.transferFrom(
            from,
            _stakeAddress,
            (amount * _stakeShare) / 100
        );

        //transfer of swapBack share
        _pmonToken.transferFrom(
            from,
            _swapBackAddress,
            (amount * _swapBackShare) / 100
        );

        //burning of the burn share
        _pmonToken.burnFrom(from, (amount * _burnShare) / 100);
    }

    function setShares(
        uint256 burnShare,
        uint256 stakeShare,
        uint256 feeShare,
        uint256 swapBackShare
    ) public onlyOwner {
        require(
            burnShare + stakeShare + feeShare + swapBackShare == 100,
            "Doesn't add up to 100"
        );

        _burnShare = burnShare;
        _stakeShare = stakeShare;
        _feeShare = feeShare;
        _swapBackShare = swapBackShare;
    }

    function setStakeAddress(address stakeAddress) public onlyOwner {
        _stakeAddress = stakeAddress;
    }

    function setFeeAddress(address feeAddress) public onlyOwner {
        _feeAddress = feeAddress;
    }

    function setSwapBackAddress(address swapBackAddress) public onlyOwner {
        _swapBackAddress = swapBackAddress;
    }

    function lock() public onlyOwner {
        _closed = true;
    }

    function unlock() public onlyOwner {
        _closed = false;
    }
}
