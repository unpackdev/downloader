// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IAddressBook.sol";
import "./IGammaController.sol";
import "./IWhitelist.sol";
import "./IMarginCalculator.sol";
import "./OpynActions.sol";
import "./OpynVault.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IOtoken.sol";

/// @author Willy Shen
/// @title Gamma Operator
/// @notice Opyn Gamma protocol adapter for redeeming otokens and settling vaults
contract GammaOperator is Ownable {
    using SafeERC20 for IERC20;

    // Gamma Protocol contracts
    IAddressBook public addressBook;
    IGammaController public controller;
    IWhitelist public whitelist;
    IMarginCalculator public calculator;

    /**
     * @dev fetch Gamma contracts from address book
     * @param _addressBook Gamma Address Book address
     */
    constructor(address _addressBook) {
        setAddressBook(_addressBook);
        refreshConfig();
    }

    /**
     * @notice redeem otoken on behalf of user
     * @param _owner owner address
     * @param _otoken otoken address
     * @param _amount amount of otoken
     * @param _fee fee in 1/10.000
     */
    function redeemOtoken(
        address _owner,
        address _otoken,
        uint256 _amount,
        uint256 _fee
    ) internal {
        uint256 actualAmount = getRedeemableAmount(_owner, _otoken, _amount);

        IERC20(_otoken).safeTransferFrom(_owner, address(this), actualAmount);

        Actions.ActionArgs memory action;
        action.actionType = Actions.ActionType.Redeem;
        action.secondAddress = address(this);
        action.asset = _otoken;
        action.amount = _amount;

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);
        actions[0] = action;

        IERC20 collateral = IERC20(IOtoken(_otoken).collateralAsset());
        uint256 startAmount = collateral.balanceOf(address(this));

        controller.operate(actions);

        uint256 endAmount = collateral.balanceOf(address(this));
        uint256 difference = endAmount - startAmount;
        uint256 finalAmount = difference - ((_fee * difference) / 10000);
        collateral.safeTransfer(_owner, finalAmount);
    }

    /**
     * @notice settle vault on behalf of user
     * @param _owner owner address
     * @param _vaultId vaultId to settle
     * @param _fee fee in 1/10.000
     */
    function settleVault(
        address _owner,
        uint256 _vaultId,
        uint256 _fee
    ) internal {
        Actions.ActionArgs memory action;
        action.actionType = Actions.ActionType.SettleVault;
        action.owner = _owner;
        action.vaultId = _vaultId;
        action.secondAddress = address(this);

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);
        actions[0] = action;
        (MarginVault.Vault memory vault, , ) = getVaultWithDetails(
            _owner,
            _vaultId
        );
        address otoken = getVaultOtoken(vault);

        IERC20 collateral = IERC20(IOtoken(otoken).collateralAsset());
        uint256 startAmount = collateral.balanceOf(address(this));

        controller.operate(actions);

        uint256 endAmount = collateral.balanceOf(address(this));
        uint256 difference = endAmount - startAmount;
        uint256 finalAmount = difference - ((_fee * difference) / 10000);
        collateral.safeTransfer(_owner, finalAmount);
    }

    /**
     * @notice return if otoken should be redeemed
     * @param _owner owner address
     * @param _otoken otoken address
     * @param _amount amount of otoken
     * @return true if otoken has expired and payout is greater than zero
     */
    function shouldRedeemOtoken(
        address _owner,
        address _otoken,
        uint256 _amount
    ) public view returns (bool) {
        uint256 actualAmount = getRedeemableAmount(_owner, _otoken, _amount);
        try this.getRedeemPayout(_otoken, actualAmount) returns (
            uint256 payout
        ) {
            if (payout == 0) return false;
        } catch {
            return false;
        }

        return true;
    }

    /**
     * @notice return if vault should be settled
     * @param _owner owner address
     * @param _vaultId vaultId to settle
     * @return true if vault can be settled, contract is operator of owner,
     *          and excess collateral is greater than zero
     */
    function shouldSettleVault(address _owner, uint256 _vaultId)
        public
        view
        returns (bool)
    {
        (
            MarginVault.Vault memory vault,
            uint256 typeVault,

        ) = getVaultWithDetails(_owner, _vaultId);

        (uint256 payout, bool isValidVault) = getExcessCollateral(
            vault,
            typeVault
        );
        if (!isValidVault || payout == 0) return false;

        return true;
    }

    /**
     * @notice set Gamma Address Book
     * @param _address Address Book address
     */
    function setAddressBook(address _address) public onlyOwner {
        require(
            _address != address(0),
            "GammaOperator::setAddressBook: Address must not be zero"
        );
        addressBook = IAddressBook(_address);
    }

    /**
     * @notice transfer operator profit
     * @param _token address token to transfer
     * @param _amount amount of token to transfer
     * @param _to transfer destination
     */
    function harvest(
        address _token,
        uint256 _amount,
        address _to
    ) public onlyOwner {
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            (bool success, ) = _to.call{value: _amount}("");
            require(success, "GammaOperator::harvest: ETH transfer failed");
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    /**
     * @notice refresh Gamma contracts' addresses
     */
    function refreshConfig() public {
        address _controller = addressBook.getController();
        controller = IGammaController(_controller);

        address _whitelist = addressBook.getWhitelist();
        whitelist = IWhitelist(_whitelist);

        address _calculator = addressBook.getMarginCalculator();
        calculator = IMarginCalculator(_calculator);
    }

    /**
     * @notice get an oToken's payout in the collateral asset
     * @param _otoken otoken address
     * @param _amount amount of otoken to redeem
     */
    function getRedeemPayout(address _otoken, uint256 _amount)
        public
        view
        returns (uint256)
    {
        return controller.getPayout(_otoken, _amount);
    }

    /**
     * @notice get amount of otoken that can be redeemed
     * @param _owner owner address
     * @param _otoken otoken address
     * @param _amount amount of otoken
     * @return amount of otoken the contract can transferFrom owner
     */
    function getRedeemableAmount(
        address _owner,
        address _otoken,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 ownerBalance = IERC20(_otoken).balanceOf(_owner);
        uint256 allowance = IERC20(_otoken).allowance(_owner, address(this));
        uint256 spendable = min(ownerBalance, allowance);
        return min(_amount, spendable);
    }

    /**
     * @notice return details of a specific vault
     * @param _owner owner address
     * @param _vaultId vaultId
     * @return vault struct and vault type and the latest timestamp when the vault was updated
     */
    function getVaultWithDetails(address _owner, uint256 _vaultId)
        public
        view
        returns (
            MarginVault.Vault memory,
            uint256,
            uint256
        )
    {
        return controller.getVaultWithDetails(_owner, _vaultId);
    }

    /**
     * @notice return the otoken from specific vault
     * @param _vault vault struct
     * @return otoken address
     */
    function getVaultOtoken(MarginVault.Vault memory _vault)
        public
        pure
        returns (address)
    {
        bool hasShort = isNotEmpty(_vault.shortOtokens);
        bool hasLong = isNotEmpty(_vault.longOtokens);

        assert(hasShort || hasLong);

        return hasShort ? _vault.shortOtokens[0] : _vault.longOtokens[0];
    }

    /**
     * @notice return amount of collateral that can be removed from a vault
     * @param _vault vault struct
     * @param _typeVault vault type
     * @return excess amount and true if excess is greater than zero
     */
    function getExcessCollateral(
        MarginVault.Vault memory _vault,
        uint256 _typeVault
    ) public view returns (uint256, bool) {
        return calculator.getExcessCollateral(_vault, _typeVault);
    }

    /**
     * @notice return if otoken is ready to be settled
     * @param _otoken otoken address
     * @return true if settlement is allowed
     */
    function isSettlementAllowed(address _otoken) public view returns (bool) {
        return controller.isSettlementAllowed(_otoken);
    }

    /**
     * @notice return if this contract is Gamma operator of an address
     * @param _owner owner address
     * @return true if address(this) is operator of _owner
     */
    function isOperatorOf(address _owner) public view returns (bool) {
        return controller.isOperator(_owner, address(this));
    }

    /**
     * @notice return if otoken is whitelisted on Gamma
     * @param _otoken otoken address
     * @return true if isWhitelistedOtoken returns true for _otoken
     */
    function isWhitelistedOtoken(address _otoken) public view returns (bool) {
        return whitelist.isWhitelistedOtoken(_otoken);
    }

    /**
     * @param _otoken otoken address
     * @return true if otoken has expired and settlement is allowed
     */
    function hasExpiredAndSettlementAllowed(address _otoken)
        public
        view
        returns (bool)
    {
        bool hasExpired = block.timestamp >= IOtoken(_otoken).expiryTimestamp();
        if (!hasExpired) return false;

        bool isAllowed = isSettlementAllowed(_otoken);
        if (!isAllowed) return false;

        return true;
    }

    /**
     * @notice return if specific vault exist
     * @param _owner owner address
     * @param _vaultId vaultId to check
     * @return true if vault exist for owner
     */
    function isValidVaultId(address _owner, uint256 _vaultId)
        public
        view
        returns (bool)
    {
        uint256 vaultCounter = controller.getAccountVaultCounter(_owner);
        return ((_vaultId > 0) && (_vaultId <= vaultCounter));
    }

    /**
     * @notice return if array is not empty
     * @param _array array of address to check
     * @return true if array length is grreater than zero & first element isn't address zero
     */
    function isNotEmpty(address[] memory _array) private pure returns (bool) {
        return (_array.length > 0) && (_array[0] != address(0));
    }

    /**
     * @notice return the lowest number
     * @param a first number
     * @param b second number
     * @return the lowest uint256
     */
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? b : a;
    }

    receive() external payable {}
}
