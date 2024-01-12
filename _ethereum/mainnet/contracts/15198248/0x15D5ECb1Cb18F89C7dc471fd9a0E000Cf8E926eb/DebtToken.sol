// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./WrapperToken.sol";
import "./IBSLendingPair.sol";
import "./IDebtToken.sol";
import "./ERC20Permit.sol";
import "./IERC20Details.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title DebtToken
/// @author @samparsky
////////////////////////////////////////////////////////////////////////////////////////////

contract DebtToken is IDebtToken, WrapperTokenBase {
    /// @dev debt token version
    uint256 constant public VERSION = 0x1;

    /// @dev for introspection
    bool constant isDebtToken = true;

    /// @dev debt token delegate borrow message digest
    bytes32 internal constant _DEBT_BORROW_DELEGATE_SIGNATURE_TYPE_HASH =
        keccak256(
            "BorrowDelegate(bytes32 warning,address from,address to,uint amount,uint256 nonce)"
        );

    /// @dev user delegated borrow allowances
    mapping(address => mapping(address => uint256)) private _borrowAllowances;

    /// @notice mapping of user to approval nonce
    mapping(address => uint256) public userBorrowAllowanceNonce;

    /// @notice initialize
    function initialize(
        address __owner,
        address _underlying,
        string memory _tokenName,
        string memory _tokenSymbol,
        IRewardDistributorManager _manager
    ) external virtual override initializer {
        require(__owner != address(0), "invalid owner");
        require(_underlying != address(0), "invalid underlying");

        _owner = __owner;
        uint8 underlyingDecimal = IERC20Details(_underlying).decimals();
        initializeERC20(_tokenName, _tokenSymbol, underlyingDecimal);
        initializeERC20Permit(_tokenName);
        underlying = _underlying;
        rewardManager = _manager;
    }

    function principal(address _account) external view override returns (uint256) {
        return _balances[_account];
    }

    /// @dev calculates the debt balance of account
    function balanceOf(address _account) public view override(IERC20, ERC20) returns (uint256) {
        return IBSLendingPair(_owner).borrowBalancePrior(_account);
    }

    /// @dev mint debt tokens to the debtOwner address
    /// @param _debtOwner the address to mint the debt tokens to
    /// @param _to the address requesting the debt, when (_to != _debtOwner) debtOwner must have 
    /// delegated some borrow allowance to the _to address
    /// @param _amount the amount of debt tokens to mint
    function mint(address _debtOwner, address _to, uint256 _amount) external override onlyLendingPair {
        require(_debtOwner != address(0), "INVALID_DEBT_OWNER");
        if(_debtOwner != _to) {
            _decreaseBorrowAllowance(_debtOwner, _to, _amount);
        }
        _rewardHook(address(0), _debtOwner);
        _mint(_debtOwner, _amount);
    }

    function _mint(address _account, uint256 _amount) internal virtual override {
        require(_account != address(0), "ERC20: mint to the zero address");

        _totalSupply += _amount;
        _balances[_account] = balanceOf(_account) + _amount;
        emit Transfer(address(0), _account, _amount);
    }


    function owner() external view override returns (address) {
        return _owner;
    }

    /**
     * @notice burn is an only owner function that allows the owner to burn  tokens from an input account
     * @param _from is the address where the tokens will be burnt
     * @param _amount is the amount of token to be burnt
     **/
    function burn(address _from, uint256 _amount)
        external
        override(IBSWrapperTokenBase)
        onlyLendingPair
    {
        _rewardHook(_from, address(0));
        _balances[_from] = balanceOf(_from) - _amount;
        if (_amount > _totalSupply) {
            _totalSupply = 0;
        } else {
            _totalSupply -= _amount;
        }
    }

    function borrowAllowance(address _from, address _to) external view returns(uint256) {
        return _borrowAllowances[_from][_to];
    }

    function delegateBorrow(address _to, uint256 _amount) external {
        _delegateBorrowInternal(msg.sender, _to, _amount);
    }

    function _delegateBorrowInternal(address _from, address _to, uint256 _amount) internal {
        require(_to != address(0), "INVALID_TO");

        _borrowAllowances[_from][_to] = _amount;
        emit DelegateBorrow(_from, _to, _amount, block.timestamp);
    }

    function delegateBorrowWithSignedMessage(
        address _from,
        address _to,
        uint256 _amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(_to != address(0), "INVALID_TO");

         bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _domainSeparatorV4(),
                    keccak256(
                        abi.encode(
                            _DEBT_BORROW_DELEGATE_SIGNATURE_TYPE_HASH,
                            keccak256(
                                "You are delegating borrow to user, read more here: https://warp.finance/delegate"
                            ),
                            _from,
                            _to,
                            _amount,
                            userBorrowAllowanceNonce[_from]++
                        )
                    )
                )
            );
        
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == _from, "INVALID_SIGNATURE");

        _delegateBorrowInternal(_from, _to, _amount);
    }

    function _decreaseBorrowAllowance(address _from, address _to, uint256 _amount) internal {
        _borrowAllowances[_from][_to] =  _borrowAllowances[_from][_to] - _amount;
    }
    
    /// @notice used to increase the debt of the system
    /// @param _amount is the amount to increase
    function increaseTotalDebt(uint256 _amount) external override onlyLendingPair {
        _totalSupply = _totalSupply + _amount;
    }

    function transfer(
        address, /*recipient*/
        uint256 /*amount*/
    ) public pure override(ERC20, IERC20) returns (bool) {
        revert("TRANSFER_NOT_SUPPORTED");
    }

    function approve(
        address, /*spender*/
        uint256 /*amount*/
    ) public virtual override(ERC20, IERC20) returns (bool) {
        revert("APPROVAL_NOT_SUPPORTED");
    }

    function allowance(
        address, /*owner*/
        address /*spender*/
    ) public view virtual override(ERC20, IERC20) returns (uint256) {
        revert("ALLOWANCE_NOT_SUPPORTED");
    }

    function transferFrom(
        address, /*sender*/
        address, /*recipient*/
        uint256 /*amount*/
    ) public virtual override(ERC20, IERC20) returns (bool) {
        revert("TRANSFER_NOT_SUPPORTED");
    }

    function increaseAllowance(
        address, /*spender*/
        uint256 /*addedValue*/
    ) public virtual override returns (bool) {
        revert("ALLOWANCE_NOT_SUPPORTED");
    }

    function decreaseAllowance(
        address, /*spender*/
        uint256 /*subtractedValue*/
    ) public virtual override returns (bool) {
        revert("ALLOWANCE_NOT_SUPPORTED");
    }

    function permit(
        address /* owner */,
        address /* spender */,
        uint256 /* amount */,
        uint256 /* deadline */,
        uint8 /* v */,
        bytes32 /* r */,
        bytes32 /* s */
    ) public virtual override {
        revert("PERMIT_NOT_SUPPORTED");
    }
}
