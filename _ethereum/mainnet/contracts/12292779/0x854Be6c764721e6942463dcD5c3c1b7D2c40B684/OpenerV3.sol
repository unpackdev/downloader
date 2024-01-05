// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

interface ITransferFromAndBurnFrom {
    function burnFrom(address account, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
}

interface ICanMint {
    function mint(address to, uint256 tokenId) external;
}

interface ISoftMinter {
    function registeredHashes(address to, bytes32 openingHash)
        external
        returns (bool);

    function alreadyMinted(uint256 nftId) external returns (bool);
}

contract OpenerV3 is Initializable, OwnableUpgradeable {
    ITransferFromAndBurnFrom private _pmonToken;
    ICanMint private _nftContract;
    ISoftMinter private _oldSoftMinter;
    address public _stakeAddress;
    address public _feeAddress;
    address public _swapBackAddress;

    event Opening(address indexed from, uint256 amount, uint256 openedBoosters);

    uint256 public _burnShare;
    uint256 public _stakeShare;
    uint256 public _feeShare;
    uint256 public _swapBackShare;

    uint256 private _decimalMultiplier;

    bool public _closed;

    uint256 public _openedBoosters;

    mapping(address => mapping(uint256 => bool)) public registeredIds;

    function initialize(
        ITransferFromAndBurnFrom pmonToken,
        ICanMint nftContract,
        address stakeAddress,
        address feeAddress,
        address swapBackAddress,
        uint256 openedBoosters
    ) public initializer {
        _pmonToken = pmonToken;
        _stakeAddress = stakeAddress;
        _feeAddress = feeAddress;
        _swapBackAddress = swapBackAddress;
        _openedBoosters = openedBoosters;
        _nftContract = nftContract;

        _burnShare = 75;
        _stakeShare = 0;
        _feeShare = 25;
        _swapBackShare = 0;

        _decimalMultiplier = 10**uint256(18);

        _closed = false;
    }

    function openBooster(uint256 amount) public {
        require(!_closed, "Opener is locked");
        require(amount > 0, "Amount has to be larger than 0");
        require(
            _numOfBoosterIsInteger(amount),
            "Only integer numbers of booster allowed"
        );
        _distributeBoosterShares(msg.sender, amount);
        _addIds(amount, _openedBoosters, msg.sender);
        emit Opening(msg.sender, amount, _openedBoosters);
        _openedBoosters = _openedBoosters + (amount / _decimalMultiplier);
    }

    function _addIds(
        uint256 amount,
        uint256 openedBoosters,
        address userAddress
    ) private {
        uint256 startingId = openedBoosters * 3 + 1 + 1000000000;
        for (uint256 i = 0; i < (amount / _decimalMultiplier) * 3; i++) {
            registeredIds[userAddress][startingId + i] = true;
        }
    }

    function mintById(address to, uint256 id) public {
        require(registeredIds[to][id], "Id not registered");
        _nftContract.mint(to, id);
    }

    function _numOfBoosterIsInteger(uint256 amount) private returns (bool) {
        return (amount % _decimalMultiplier == 0);
    }

    function _distributeBoosterShares(address from, uint256 amount) private {
        //transfer of fee share
        if (_feeShare > 0) {
            _pmonToken.transferFrom(
                from,
                _feeAddress,
                (amount * _feeShare) / 100
            );
        }

        //transfer of stake share
        if (_stakeShare > 0) {
            _pmonToken.transferFrom(
                from,
                _stakeAddress,
                (amount * _stakeShare) / 100
            );
        }

        //transfer of swapBack share
        if (_swapBackShare > 0) {
            _pmonToken.transferFrom(
                from,
                _swapBackAddress,
                (amount * _swapBackShare) / 100
            );
        }

        //burning of the burn share
        if (_burnShare > 0) {
            _pmonToken.burnFrom(from, (amount * _burnShare) / 100);
        }
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
