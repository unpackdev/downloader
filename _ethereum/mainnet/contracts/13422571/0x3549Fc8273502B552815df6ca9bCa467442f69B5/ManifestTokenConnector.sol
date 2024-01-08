// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./ManifestAdmin.sol";

contract ManifestTokenConnector is ManifestAdmin {
    address private _manifestTokenAddress;
    IERC20 private _manifestToken;

    uint256 private _manifestBalance = 0;

    event TokenPayment(address indexed _payer, uint256 indexed _amount);

    constructor(address manifestTokenAddress) {
        _updateManifestTokenAddress(manifestTokenAddress);
    }

    function withdraw(uint256 _amount) external onlyAdmin {
        _manifestToken.transfer(_msgSender(), _amount);
    }

    function _approveTokenBalanceToAddress(address _address, uint256 _amount)
        internal
    {
        _manifestToken.approve(_address, _amount);
    }

    function _pay(uint256 _amount) internal {
        _transferTokenBalanceFromMsgSender(_amount);
    }

    function _transferTokenBalanceFromMsgSender(uint256 _amount)
        internal
        allowedAmount(_amount)
    {
        _manifestToken.transferFrom(_msgSender(), address(this), _amount);
        _manifestBalance += _amount;

        emit TokenPayment(_msgSender(), _amount);
    }

    function _hasAllowedAmount(uint256 amount) internal view returns (bool) {
        uint256 allowance = _manifestToken.allowance(
            _msgSender(),
            address(this)
        );
        return allowance >= amount;
    }

    modifier allowedAmount(uint256 amount) {
        require(
            _hasAllowedAmount(amount),
            "Required amount is not allowed yet!"
        );
        _;
    }

    function updateManifestTokenAddress(address manifestTokenAddress_)
        external
        onlyAdmin
    {
        _updateManifestTokenAddress(manifestTokenAddress_);
    }

    function _updateManifestTokenAddress(address manifestTokenAddress_)
        internal
    {
        _manifestTokenAddress = manifestTokenAddress_;
        _manifestToken = IERC20(manifestTokenAddress_);
    }

    function checkContractBalance() external view onlyAdmin returns (uint256) {
        return _manifestBalance;
    }
}
