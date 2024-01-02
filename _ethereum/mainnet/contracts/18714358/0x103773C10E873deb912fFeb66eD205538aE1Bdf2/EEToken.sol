// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./SafeMathUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ICollateralManager.sol";
import "./IEToken.sol";
import "./Errors.sol";

contract EEToken is ERC20Upgradeable, OwnableUpgradeable, IEToken {
    using SafeMathUpgradeable for uint256;

    ICollateralManager internal collateralManager;
    address public tokenAddress;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name_,
        string memory symbol_
    ) public initializer {
        __Ownable_init();
        __ERC20_init(name_, symbol_);
    }

    function setAddresses(
        address _collateralManagerAddress,
        address _tokenAddress
    ) external onlyOwner {
        _requireIsContract(_collateralManagerAddress);
        _requireIsContract(_tokenAddress);
        collateralManager = ICollateralManager(_collateralManagerAddress);
        tokenAddress = _tokenAddress;

        emit CollateralManagerAddressChanged(_collateralManagerAddress);
        emit TokenAddressChanged(_tokenAddress);
    }

    function mint(
        address _account,
        uint256 _amount
    ) external override returns (uint256) {
        _requireIsCollateralManager();
        uint256 share = getShare(_amount);
        _mint(_account, share);
        return share;
    }

    function burn(
        address _account,
        uint256 _amount
    ) external override returns (uint256) {
        _requireIsCollateralManager();
        uint256 share = getShare(_amount);
        _burn(_account, share);
        return share;
    }

    function clear(address _account) external override {
        _requireIsCollateralManager();
        uint256 share = super.balanceOf(_account);
        _burn(_account, share);
    }

    function reset(
        address _account,
        uint256 _amount
    ) external override returns (uint256) {
        _requireIsCollateralManager();
        uint256 oldShare = super.balanceOf(_account);
        uint256 newShare = getShare(_amount);
        if (oldShare > newShare) {
            _burn(_account, oldShare.sub(newShare));
        } else {
            _mint(_account, newShare.sub(oldShare));
        }
        return newShare;
    }

    function transfer(
        address _recipient,
        uint256 _amount
    )
        public
        virtual
        override(IERC20Upgradeable, ERC20Upgradeable)
        returns (bool)
    {
        _recipient;
        _amount;
        revert Errors.ET_NotSupported();
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        public
        virtual
        override(IERC20Upgradeable, ERC20Upgradeable)
        returns (bool)
    {
        _sender;
        _recipient;
        _amount;
        revert Errors.ET_NotSupported();
    }

    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        virtual
        override(IERC20Upgradeable, ERC20Upgradeable)
        returns (uint256)
    {
        _owner;
        _spender;
        revert Errors.ET_NotSupported();
    }

    function approve(
        address _spender,
        uint256 _amount
    )
        public
        virtual
        override(IERC20Upgradeable, ERC20Upgradeable)
        returns (bool)
    {
        _spender;
        _amount;
        revert Errors.ET_NotSupported();
    }

    function increaseAllowance(
        address _spender,
        uint256 _addedValue
    ) public virtual override(ERC20Upgradeable) returns (bool) {
        _spender;
        _addedValue;
        revert Errors.ET_NotSupported();
    }

    function decreaseAllowance(
        address _spender,
        uint256 _subtractedValue
    ) public virtual override(ERC20Upgradeable) returns (bool) {
        _spender;
        _subtractedValue;
        revert Errors.ET_NotSupported();
    }

    function sharesOf(address _account) public view override returns (uint256) {
        return super.balanceOf(_account);
    }

    function getShare(uint256 _amount) public pure override returns (uint256) {
        return _amount;
    }

    function getAmount(uint256 _share) public pure override returns (uint256) {
        return _share;
    }

    function balanceOf(
        address _account
    )
        public
        view
        virtual
        override(IERC20Upgradeable, ERC20Upgradeable)
        returns (uint256)
    {
        return getAmount(sharesOf(_account));
    }

    function totalSupply()
        public
        view
        virtual
        override(IERC20Upgradeable, ERC20Upgradeable)
        returns (uint256)
    {
        return getAmount(totalShareSupply());
    }

    function totalShareSupply() public view override returns (uint256) {
        return super.totalSupply();
    }

    function _requireIsContract(address _contract) internal view {
        if (_contract.code.length == 0) {
            revert Errors.NotContract();
        }
    }

    function _requireIsCollateralManager() internal view {
        if (msg.sender != address(collateralManager)) {
            revert Errors.Caller_NotCM();
        }
    }
}
