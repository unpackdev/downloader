// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC20Upgradeable as IERC20} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./TwoStepOwnable.sol";
import "./IERC20Mintable.sol";

contract HourBlast is TwoStepOwnable, UUPSUpgradeable {
    address internal constant _USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal constant _USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant _FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address internal constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant _FRXETH = 0x5E8422345238F34275888049021821E8E08CAa1f;

    address public hblUSD;
    address public hblETH;

    function initialize() public initializer {
        _setInitialOwner(msg.sender);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setReceipts(address _hblUSD, address _hblETH) public onlyOwner {
        if (hblUSD != address(0) || hblETH != address(0)) {
            revert CannotBeChanged();
        }
        if (_hblUSD == address(0) || _hblETH == address(0)) {
            revert CannotBeZero();
        }

        // set addresses
        hblUSD = _hblUSD;
        hblETH = _hblETH;

        emit HourBlastReceiptsSet(hblUSD, hblETH);
    }

    receive() external payable {
        depositETH();
    }

    function depositETH() public payable {
        uint256 amount = msg.value;

        // send ETH to vault multisig
        AddressUpgradeable.sendValue(payable(owner()), amount);

        // mint BLASTETH to sender
        IERC20Mintable(hblETH).mint(msg.sender, amount);

        emit HBLETHMinted(amount, msg.sender);
    }

    function depositFRXETH(uint256 amount) public {
        IERC20(_FRXETH).transferFrom(msg.sender, owner(), amount);

        // mint blFRXETH to user
        IERC20Mintable(hblETH).mint(msg.sender, amount);

        emit HBLETHMinted(amount, msg.sender);
    }

    function depositWETH(uint256 amount) public {
        IERC20(_WETH).transferFrom(msg.sender, owner(), amount);

        // mint blSTETH to user
        IERC20Mintable(hblETH).mint(msg.sender, amount);

        emit HBLETHMinted(amount, msg.sender);
    }

    function depositUSDC(uint256 amount) public {
        IERC20(_USDC).transferFrom(msg.sender, owner(), amount);

        // increase the decimals from 6 to 18
        uint256 scaledAmount = amount * 1e12;

        // mint blUSDC to user
        IERC20Mintable(hblUSD).mint(msg.sender, scaledAmount);

        emit HBLUSDMintedByUSDC(amount, scaledAmount, msg.sender);
    }

    function depositUSDT(uint256 amount) public {
        IERC20(_USDT).transferFrom(msg.sender, owner(), amount);

        // mint blUSDT to user
        IERC20Mintable(hblUSD).mint(msg.sender, amount);

        emit HBLUSDMinted(amount, msg.sender);
    }

    function depositFRAX(uint256 amount) public {
        IERC20(_FRAX).transferFrom(msg.sender, owner(), amount);

        // mint blFRAX to user
        IERC20Mintable(hblUSD).mint(msg.sender, amount);

        emit HBLUSDMinted(amount, msg.sender);
    }

    error CannotBeChanged();
    error CannotBeZero();

    event HBLUSDMintedByUSDC(uint256 amount, uint256 scaledAmount, address sender);
    event HBLETHMinted(uint256 amount, address sender);
    event HBLUSDMinted(uint256 amount, address sender);
    event HourBlastReceiptsSet(address hblUSD, address hblETH);
}
