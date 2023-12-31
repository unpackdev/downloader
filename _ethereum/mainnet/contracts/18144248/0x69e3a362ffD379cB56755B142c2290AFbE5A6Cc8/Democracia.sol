// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

/// @title Democracia DAO Contract 🕊️

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./ERC4626.sol";

interface IMetaPoolETH {
    function previewDeposit(uint256 assets) external view returns (uint256 shares); 
}

contract Democracia is ERC4626, Ownable {

    using SafeERC20 for IERC20;

    // *******************
    // * Errors & events *
    // *******************

    error DonationPeriodStillOpen();
    error DonationsNotAvailable();
    error ERC4626DepositMoreThanMax();
    error ERC4626MintMoreThanMax();
    error FundsAlreadyDelivered();
    error FundsWillBeReturnedToContributors();
    error InvalidTimeInput();
    error InvalidZeroAccount();
    error NotEnoughETH();
    error NotSuccessfulOperation();
    error Unauthorized();
    error WithdrawNotAvailable();
    event DonationsSuccessfullyDelivered(address _receiver, uint256 _amount);

    /// Account in charge of distributing the donations.
    address public paymentsAccount;

    /// Epoch timestamp: 1711940400
    /// Date and time (GMT): Monday, April 1, 2024 3:00:00 AM
    uint256 immutable public returnDonationsTimestamp;

    /// Receiving donations will be stopped.
    /// Epoch timestamp: 1703991600
    /// Date and time (GMT): Sunday, December 31, 2023 3:00:00 AM
    uint256 immutable public stopDonationsTimestamp;

    modifier donationsAvailable() {
        if (block.timestamp > stopDonationsTimestamp) { revert DonationsNotAvailable(); }
        _;
    }

    modifier withdrawAvailable() {
        if (block.timestamp < returnDonationsTimestamp) {
            revert WithdrawNotAvailable();
        }
        _;
    }

    modifier betweenStopNReturn() {
        if (block.timestamp < stopDonationsTimestamp) { revert DonationPeriodStillOpen(); }
        if (block.timestamp > returnDonationsTimestamp) { revert FundsWillBeReturnedToContributors(); }
        _;
    }

    /// @param _asset is expected to be mpETH
    constructor(
        IERC20 _asset,
        string memory _dDaoName,
        string memory _dDaoSymbol,
        uint256 _stopDonationsTimestamp,
        uint256 _returnDonationsTimestamp
    ) ERC4626(_asset) ERC20(_dDaoName, _dDaoSymbol) {
        if (block.timestamp >= _returnDonationsTimestamp) { revert InvalidTimeInput(); }
        if (_returnDonationsTimestamp <= _stopDonationsTimestamp) {
            revert InvalidTimeInput();
        }
        stopDonationsTimestamp = _stopDonationsTimestamp;
        returnDonationsTimestamp = _returnDonationsTimestamp;
    }

    function updatePaymentsAccount(address _account) public onlyOwner {
        paymentsAccount = _account;
    }

    receive() external payable { depositETH(msg.sender); }

    /// @notice Used to deposit ETH.
    function depositETH(
        address _receiver
    ) public payable donationsAvailable returns (uint256) {
        uint256 assets = IMetaPoolETH(asset()).previewDeposit(msg.value);
        if (assets > maxDeposit(_receiver)) { revert ERC4626DepositMoreThanMax(); }

        uint256 shares = previewDeposit(assets);
        (bool success, ) = asset().call{value: msg.value}(
            abi.encodeWithSignature("depositETH(address)", address(this))
        );
        if (!success) { revert NotSuccessfulOperation(); }

        _deposit(address(this), _receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(
        uint256 assets,
        address receiver
    ) public override donationsAvailable returns (uint256) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-mint}.
     *
     * As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share is zero.
     * In this case, the shares will be minted without requiring any assets to be deposited.
     */
    function mint(
        uint256 shares,
        address receiver
    ) public override donationsAvailable returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override withdrawAvailable returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override withdrawAvailable returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    function transferDonations(uint256 _assets) public onlyOwner betweenStopNReturn {
        address _account = paymentsAccount;
        if (_account == address(0)) { revert InvalidZeroAccount(); }
        if (_assets > totalAssets()) { revert NotEnoughETH(); }

        IERC20(asset()).safeTransfer(_account, _assets);

        emit DonationsSuccessfullyDelivered(_account, _assets);
    }

    // **********************
    // * Internal functions *
    // **********************

    function _deposit(
        address _caller,
        address _receiver,
        uint256 _assets,
        uint256 _shares
    ) internal override {
        if (_caller != address(this)) {
            IERC20(asset()).safeTransferFrom(_caller, address(this), _assets);
        }
        _mint(_receiver, _shares);

        emit Deposit(_caller, _receiver, _assets, _shares);
    }
}
