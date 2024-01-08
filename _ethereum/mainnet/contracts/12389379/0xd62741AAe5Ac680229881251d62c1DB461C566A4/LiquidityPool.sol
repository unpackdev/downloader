// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.7.4;

import "./Interf.sol";
import "./CanReclaimTokens.sol";
import "./BorrowerProxy.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./console.sol";

contract LiquidityPoolV3 is ILiquidityPool, CanReclaimTokens, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    mapping (address=>IKToken) public kTokens;
    mapping (address=>bool) public registeredKTokens;
    mapping (address=>uint256) public loanedAmount;

    uint256 public depositFeeInBips;
    uint256 public poolFeeInBips;
    uint256 public FEE_BASE = 10000;

    address[] public registeredTokens;
    address public ETHEREUM = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address payable feePool;
    BorrowerProxy public borrower;

    event Deposited(address indexed _depositor, address indexed _token, uint256 _amount, uint256 _mintAmount);
    event Withdrew(address indexed _reciever, address indexed _withdrawer, address indexed _token, uint256 _amount, uint256 _burnAmount);
    event Borrowed(address indexed _borrower, address indexed _token, uint256 _amount, uint256 _fee);
    event EtherReceived(address indexed _from, uint256 _amount);

    receive () external override payable {
        emit EtherReceived(_msgSender(), msg.value);
    }

    constructor() CanReclaimTokens(_msgSender()) {
        borrower = new BorrowerProxy();
    }

    /// @notice updates the deposit fee.
    ///
    /// @dev fee is in bips so it should 
    ///     satisfy [0 <= fee <= FEE_BASE]
    /// @param _depositFeeInBips The new deposit fee.
    function updateDepositFee(uint256 _depositFeeInBips) external onlyOperator {
        require(_depositFeeInBips >= 0 && _depositFeeInBips <= FEE_BASE, "LiquidityPoolV1: fee should be between 0 and FEE_BASE");
        depositFeeInBips = _depositFeeInBips;
    }

    /// @notice updates the pool fee.
    ///
    /// @dev fee is in bips so it should 
    ///     satisfy [0 <= fee <= FEE_BASE]
    /// @param _poolFeeInBips The new pool fee.
    function updatePoolFee(uint256 _poolFeeInBips) external onlyOperator {
        require(_poolFeeInBips >= 0 && _poolFeeInBips <= FEE_BASE, "LiquidityPoolV1: fee should be between 0 and FEE_BASE");
        poolFeeInBips = _poolFeeInBips;
    }

    /// @notice updates the fee pool.
    ///
    /// @param _newFeePool The new fee pool.
    function updateFeePool(address payable _newFeePool) external onlyOperator {
        require(_newFeePool != address(0), "LiquidityPoolV2: feepool cannot be 0x0");
        feePool = _newFeePool;        
    }

    /// @notice pauses this contract.
    function pause() external onlyOperator {
        _pause();
    }

    /// @notice unpauses this contract.
    function unpause() external onlyOperator {
        _unpause();
    }

    /// @notice register a token on this Keeper.
    ///
    /// @param _kToken The keeper ERC20 token.
    function register(IKToken _kToken) external override onlyOperator {
        require(address(kTokens[_kToken.underlying()]) == address(0x0), "Underlying asset should not have been registered");
        require(!registeredKTokens[address(_kToken)], "kToken should not have been registered");

        kTokens[_kToken.underlying()] = _kToken;
        registeredKTokens[address(_kToken)] = true;
        registeredTokens.push(address(_kToken.underlying()));
        blacklistRecoverableToken(_kToken.underlying());
    }

    /// @notice Deposit funds to the Keeper Protocol.
    ///
    /// @param _token The address of the token contract.
    /// @param _amount The value of deposit.
    function deposit(address _token, uint256 _amount) external payable override nonReentrant whenNotPaused returns (uint256) {
        IKToken kTok = kTokens[_token];
        require(address(kTok) != address(0x0), "Token is not registered");
        require(_amount > 0, "Deposit amount should be greater than 0");
        if (_token != ETHEREUM) {
            require(msg.value == 0, "LiquidityPoolV2: Should not allow ETH deposits during ERC20 token deposits");
            ERC20(_token).safeTransferFrom(_msgSender(), address(this), _amount);
        } else {
            require(_amount == msg.value, "Incorrect eth amount");
        }

        uint256 mintAmount = calculateMintAmount(kTok, _token, _amount);
        kTok.mint(_msgSender(), mintAmount);
        emit Deposited(_msgSender(), _token, _amount, mintAmount);

        return mintAmount;
    }

    /// @notice Withdraw funds from the Compound Protocol.
    ///
    /// @param _to The address of the amount receiver.
    /// @param _kToken The address of the kToken contract.
    /// @param _kTokenAmount The value of the kToken amount to be burned.
    function withdraw(address payable _to, IKToken _kToken, uint256 _kTokenAmount) external override nonReentrant whenNotPaused {
        require(registeredKTokens[address(_kToken)], "kToken is not registered");
        require(_kTokenAmount > 0, "Withdraw amount should be greater than 0");
        address token = _kToken.underlying();
        uint256 amount = calculateWithdrawAmount(_kToken, token, _kTokenAmount);
        _kToken.burnFrom(_msgSender(), _kTokenAmount);
        if (token != ETHEREUM) {
            ERC20(token).safeTransfer(_to, amount);
        } else {
            (bool success,) = _to.call{ value: amount }("");
            require(success, "Transfer Failed");
        }
        emit Withdrew(_to, _msgSender(), token, amount, _kTokenAmount);
    }

    /// @notice borrow assets from this LP, and return them within the same transaction.
    ///
    /// @param _token The address of the token contract.
    /// @param _amount The amont of token.
    /// @param _data The implementation specific data for the Borrower.
    function borrow(address _token, uint256 _amount, bytes calldata _data) external nonReentrant whenNotPaused {
        require(address(kTokens[_token]) != address(0x0), "Token is not registered");
        uint256 initialBalance = borrowableBalance(_token);
        if (_token != ETHEREUM) {
            ERC20(_token).safeTransfer(_msgSender(), _amount);
        } else {
            (bool success,) = _msgSender().call{ value: _amount }("");
            require(success, "LiquidityPoolV1: failed to send funds to the borrower");
        }
        borrower.lend(_msgSender(), _data);
        uint256 finalBalance = borrowableBalance(_token);
        require(finalBalance >= initialBalance, "Borrower failed to return the borrowed funds");

        uint256 fee = finalBalance.sub(initialBalance);
        uint256 poolFee = calculateFee(poolFeeInBips, fee);
        emit Borrowed(_msgSender(), _token, _amount, fee);
        if (_token != ETHEREUM) {
            ERC20(_token).safeTransfer(feePool, poolFee);
        } else {
            (bool success,) = feePool.call{value: poolFee}("");
            require(success, "LiquidityPoolV1: failed to send funds to the fee pool");
        }
    }

    /// @notice Calculate the given token's outstanding balance of this contract.
    ///
    /// @param _token The address of the token contract.
    ///
    /// @return Outstanding balance of the given token.
    function borrowableBalance(address _token) public view override returns (uint256) {
        if (_token == ETHEREUM) {
            return address(this).balance;
        }
        return ERC20(_token).balanceOf(address(this));
    }

    /// @notice Calculate the given owner's outstanding balance for the given token on this contract.
    ///
    /// @param _token The address of the token contract.
    /// @param _owner The address of the token contract.
    ///
    /// @return Owner's outstanding balance of the given token.
    function underlyingBalance(address _token, address _owner) public view override returns (uint256) {
        uint256 kBalance = kTokens[_token].balanceOf(_owner);
        uint256 kSupply = kTokens[_token].totalSupply();
        if (kBalance == 0) {
            return 0;
        }
        return borrowableBalance(_token).add(loanedAmount[_token]).mul(kBalance).div(kSupply);
    }

    /// @notice Migrate funds to the new liquidity provider.
    ///
    /// @param _newLP The address of the new LiquidityPool contract.
    function migrate(ILiquidityPool _newLP) public onlyOperator {
        for (uint256 i = 0; i < registeredTokens.length; i++) {
            address token = registeredTokens[i];
            kTokens[token].addMinter(address(_newLP));
            kTokens[token].renounceMinter();
            _newLP.register(kTokens[token]);
            if (token != ETHEREUM) {
                ERC20(token).safeTransfer(address(_newLP), borrowableBalance(token));
            } else {
                (bool success,) = address(_newLP).call{value: borrowableBalance(token)}("");
                require(success, "Transfer Failed");
            }
        }
        _newLP.renounceOperator();
    }

    // returns the corresponding kToken for the given underlying token if it exists.
    function kToken(address _token) external view override returns (IKToken) {
        return kTokens[_token];
    }

    /// Calculates the amount that will be withdrawn when the given amount of kToken 
    /// is burnt.
    /// @dev used in the withdraw() function to calculate the amount that will be
    ///      withdrawn. 
    function calculateWithdrawAmount(IKToken _kToken, address _token, uint256 _kTokenAmount) internal view returns (uint256) {
        uint256 kTokenSupply = _kToken.totalSupply();
        require(kTokenSupply != 0, "No KTokens to be burnt");
        uint256 initialBalance = borrowableBalance(_token).add(loanedAmount[_token]);
        return _kTokenAmount.mul(initialBalance).div(_kToken.totalSupply());
    }

    /// Calculates the amount of kTokens that will be minted when the given amount 
    /// is deposited.
    /// @dev used in the deposit() function to calculate the amount of kTokens that
    ///      will be minted.
    function calculateMintAmount(IKToken _kToken, address _token, uint256 _depositAmount) internal view returns (uint256) {
        // The borrow balance includes the deposit amount, which is removed here.        
        uint256 initialBalance = borrowableBalance(_token).sub(_depositAmount).add(loanedAmount[_token]);
        uint256 kTokenSupply = _kToken.totalSupply();
        if (kTokenSupply == 0) {
            return _depositAmount;
        }

        // mintAmoount = amountDeposited * (1-fee) * kPool /(pool + amountDeposited * fee)
        return (applyFee(depositFeeInBips, _depositAmount).mul(kTokenSupply))
            .div(initialBalance.add(
                calculateFee(depositFeeInBips, _depositAmount)
            ));
    }

    /// Applies the fee by subtracting fees from the amount and returns  
    /// the amount after deducting the fee.
    /// @dev it calculates (1 - fee) * amount
    function applyFee(uint256 _feeInBips, uint256 _amount) internal view returns (uint256) {
        return _amount.mul(FEE_BASE.sub(_feeInBips)).div(FEE_BASE); 
    }

    /// Calculates the fee amount. 
    /// @dev it calculates fee * amount
    function calculateFee(uint256 _feeInBips, uint256 _amount) internal view returns (uint256) {
        return _amount.mul(_feeInBips).div(FEE_BASE); 
    }

    /// Renounces operatorship of this contract 
    function renounceOperator() public override(ILiquidityPool, KRoles) {
        KRoles.renounceOperator();
    }
}