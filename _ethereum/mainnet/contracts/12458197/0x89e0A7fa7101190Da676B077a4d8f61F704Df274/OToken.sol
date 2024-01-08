pragma solidity 0.6.6;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./IStrategiesWhitelist.sol";
import "./IAllocationStrategy.sol";
import "./Ownable.sol";
import "./OTokenStorage.sol";

/**
    @title oToken contract
    @author Overall Finance
    @notice Core oToken contract
*/
contract OToken is OTokenStorage, IERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // MAX fee on interest is 10%
    uint256 public constant MAX_FEE = 10**18 / 10;
    uint256 public constant INITIAL_EXCHANGE_RATE = 50 ether;

    event FeeChanged(address indexed owner, uint256 oldFee, uint256 newFee);
    event AllocationStrategyChanged(address indexed owner, address indexed oldAllocationStrategy, address indexed newAllocationStrategy);
    event Withdrawn(address indexed from, address indexed receiver, uint256 amount);
    event Deposited(address indexed from, address indexed receiver, uint256 amount);
    event AdminChanged(address newAdmin);
    event TreasuryChanged(address newTreasury);
    event WhitelistChanged(address newWhitelist);

    /**
        @notice Initializer
        @dev Replaces the constructor so it can be used together with a proxy contract
        @param _initialAllocationStrategy Address of the initial allocation strategy
        @param _name Token name
        @param _symbol Token symbol
        @param _decimals Amount of decimals the token has
        @param _underlying Address of the underlying token
        @param _admin Address of the OToken admin
        @param _treasury Address of the OToken treasury
        @param _strategiesWhitelist Address of the StrategiesWhitelist Contract
    */
    function init(
        address _initialAllocationStrategy,
        string memory _name,
        string memory _symbol,
        uint256 _decimals,
        address _underlying,
        address _admin,
        address _treasury,
        address _strategiesWhitelist
    ) public  {
        ots storage s = lots();
        require(!s.initialised, "Already initialised");
        s.initialised = true;
        s.allocationStrategy = IAllocationStrategy(_initialAllocationStrategy);
        s.name = _name;
        s.symbol = _symbol;
        s.underlying = IERC20(_underlying);
        s.decimals = uint8(_decimals);
        s.admin = _admin;
        s.treasury = _treasury;
        s.strategiesWhitelist = IStrategiesWhitelist(_strategiesWhitelist);
        _setOwner(msg.sender);
    }

    /**
        @notice Deposit Underlying token in return for oTokens
        @param _amount Amount of the underlying token
        @param _receiver Address receiving the oToken
    */

    function depositUnderlying(uint256 _amount, address _receiver) external nonReentrant {
        ots storage s = lots();
        handleFeesInternal();
        uint256 strategyUnderlyingBalanceBefore = s.allocationStrategy.balanceOfUnderlying();
        s.underlying.safeTransferFrom(msg.sender, address(s.allocationStrategy), _amount);
        uint256 amount = s.allocationStrategy.investUnderlying(_amount);
        _deposit(amount, _receiver, strategyUnderlyingBalanceBefore);
    }

    function _deposit(uint256 _amount, address _receiver, uint256 _strategyUnderlyingBalanceBefore) internal {
        ots storage s = lots();

        if(s.internalTotalSupply == 0) {
            uint256 internalToMint = _amount.mul(INITIAL_EXCHANGE_RATE).div(10**18);
            s.internalBalanceOf[_receiver] = internalToMint;
            s.internalTotalSupply = internalToMint;
            emit Transfer(address(0), _receiver, _amount);
            emit Deposited(msg.sender, _receiver, _amount);
            // Set last total underlying to keep track of interest
            s.lastTotalUnderlying = s.allocationStrategy.balanceOfUnderlying();
            return;
        } else {
            // Calculates proportional internal balance from deposit
            uint256 internalToMint = s.internalTotalSupply.mul(_amount).div(_strategyUnderlyingBalanceBefore);
            s.internalBalanceOf[_receiver] = s.internalBalanceOf[_receiver].add(internalToMint);
            s.internalTotalSupply = s.internalTotalSupply.add(internalToMint);
            emit Transfer(address(0), _receiver, _amount);
            emit Deposited(msg.sender, _receiver, _amount);
            // Set last total underlying to keep track of interest
            s.lastTotalUnderlying = s.allocationStrategy.balanceOfUnderlying();
            return;
        }
    }

    /**
        @notice Burns oTokens and returns the underlying asset
        @param _redeemAmount Amount of oTokens to burn
        @param _receiver Address receiving the underlying asset
    */
    function withdrawUnderlying(uint256 _redeemAmount, address _receiver) external nonReentrant {
        ots storage s = lots();
        handleFeesInternal();
        uint256 internalAmount = s.internalTotalSupply.mul(_redeemAmount).div(s.allocationStrategy.balanceOfUnderlying());
        s.internalBalanceOf[msg.sender] = s.internalBalanceOf[msg.sender].sub(internalAmount);
        s.internalTotalSupply = s.internalTotalSupply.sub(internalAmount);
        uint256 redeemedAmount = s.allocationStrategy.redeemUnderlying(_redeemAmount, _receiver);
        s.lastTotalUnderlying = s.allocationStrategy.balanceOfUnderlying();
        emit Transfer(msg.sender, address(0), redeemedAmount);
        emit Withdrawn(msg.sender, _receiver, redeemedAmount);
    }

    /**
        @notice Get the allowance
        @param _owner Address that set the allowance
        @param _spender Address allowed to spend
        @return Amount allowed to spend
    */
    function allowance(address _owner, address _spender) external view override returns (uint256) {
        ots storage s = lots();
        return s.internalAllowances[_owner][_spender];
    }

    /**
        @notice Approve an address to transfer tokens on your behalf
        @param _spender Address allowed to spend
        @param _amount Amount allowed to spend
        @return success
    */
    function approve(address _spender, uint256 _amount) external override returns (bool) {
        ots storage s = lots();
        s.internalAllowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
        @notice Get the balance of an address
        @dev Balance goes up when interest is earned
        @param _account Address to query balance of
        @return Balance of the account
    */
    function balanceOf(address _account) external view override returns (uint256) {
        // Returns proportional share of the underlying asset
        ots storage s = lots();
        if(s.internalTotalSupply == 0) {
            return 0;
        }
        return s.allocationStrategy.balanceOfUnderlyingView().mul(s.internalBalanceOf[_account]).div(s.internalTotalSupply.add(calcFeeMintAmount()));
    }

    /**
        @notice Get the total amount of tokens
        @return totalSupply
    */
    function totalSupply() external view override returns (uint256) {
        ots storage s = lots();
        return s.allocationStrategy.balanceOfUnderlyingView();
    }

    /**
        @notice Transfer tokens
        @param _to Address to send the tokens to
        @param _amount Amount of tokens to send
        @return success
    */
    function transfer(address _to, uint256 _amount) external override returns(bool) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    /**
        @notice Transfer tokens from
        @param _from Address to transfer the tokens from
        @param _to Address to send the tokens to
        @param _amount Amount of tokens to transfer
        @return success
    */
    function transferFrom(address _from, address _to, uint256 _amount) external override returns(bool) {
        ots storage s = lots();
        require(
            msg.sender == _from ||
            s.internalAllowances[_from][_to] >= _amount,
            "OToken.transferFrom: Insufficient allowance"
        );

        // DO not update balance if it is set to max uint256
        if(s.internalAllowances[_from][msg.sender] != uint256(-1)) {
            s.internalAllowances[_from][msg.sender] = s.internalAllowances[_from][msg.sender].sub(_amount);
        }
        _transfer(_from, _to, _amount);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _amount) internal {
        ots storage s = lots();
        handleFeesInternal();

        // internal amount = internalTotalSupply * amount / underlying total balance
        uint256 internalAmount = s.internalTotalSupply.mul(_amount).div(s.allocationStrategy.balanceOfUnderlyingView());
        uint256 sanityAmount = internalAmount.mul(s.allocationStrategy.balanceOfUnderlyingView()).div(s.internalTotalSupply);

        // If there is a rounding issue add one wei
        if(_amount != sanityAmount) {
            internalAmount = internalAmount.add(1);
        }

        s.internalBalanceOf[_from] = s.internalBalanceOf[_from].sub(internalAmount);
        s.internalBalanceOf[_to] = s.internalBalanceOf[_to].add(internalAmount);
        emit Transfer(_from, _to, _amount);

        s.lastTotalUnderlying = s.allocationStrategy.balanceOfUnderlyingView();
    }

    /**
        @notice Pulls fees to owner
    */
    function handleFees() public {
        handleFeesInternal();
    }

    function handleFeesInternal() internal {
        ots storage s = lots();
        uint256 mintAmount = calcFeeMintAmount();
        if(mintAmount == 0) {
            return;
        }

        s.internalBalanceOf[s.treasury] = s.internalBalanceOf[s.treasury].add(mintAmount);
        s.internalTotalSupply = s.internalTotalSupply.add(mintAmount);

        s.lastTotalUnderlying = s.allocationStrategy.balanceOfUnderlyingView();
    }

    /**
        @notice Calculate internal balance to mint for fees
        @return Amount to mint
    */
    function calcFeeMintAmount() public view returns (uint256) {
        ots storage s = lots();
        // If interest is 0 or negative
        uint256 newUnderlyingAmount = s.allocationStrategy.balanceOfUnderlyingView();
        if(newUnderlyingAmount <= s.lastTotalUnderlying) {
            return 0;
        }
        uint256 interestEarned = newUnderlyingAmount.sub(s.lastTotalUnderlying);
        if(interestEarned == 0) {
            return 0;
        }
        uint256 feeAmount = interestEarned.mul(s.fee).div(10**18);

        return s.internalTotalSupply.mul(feeAmount).div(newUnderlyingAmount.sub(feeAmount));
    }

    /**
        @notice Set the fee, can only be called by the owner
        @param _newFee The new fee. 1e18 == 100%
    */
    function setFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= MAX_FEE, "OToken.setFee: Fee too high");
        ots storage s = lots();
        emit FeeChanged(msg.sender, s.fee, _newFee);
        s.fee = _newFee;
    }

    /**
        @notice Set the new admin
        @param _newAdmin address of the new admin
    */
    function setAdmin(address _newAdmin) external onlyOwner {
        ots storage s = lots();
        emit AdminChanged(_newAdmin);
        s.admin = _newAdmin;
    }

    /**
        @notice Set the new treasury
        @param _newTreasury address of the new treasury
    */
    function setTreasury(address _newTreasury) external onlyOwner {
        ots storage s = lots();
        emit TreasuryChanged(_newTreasury);
        s.treasury = _newTreasury;
    }

    /**
        @notice Set the new strategiesWhitelist
        @param _newStrategiesWhitelist address of the new whitelist
    */
    function setWhitelist(address _newStrategiesWhitelist) external onlyOwner {
        ots storage s = lots();
        emit WhitelistChanged(_newStrategiesWhitelist);
        s.strategiesWhitelist = IStrategiesWhitelist(_newStrategiesWhitelist);
    }

    /**
        @notice Change the allocation strategy. Can only be called by the owner
        @param _newAllocationStrategy Address of the allocation strategy
    */
    function changeAllocationStrategy(address _newAllocationStrategy) external {
        ots storage s = lots();
        require(msg.sender == s.admin, "OToken.changeAllocationStrategy: msg.sender not admin");
        require(s.strategiesWhitelist.isWhitelisted(_newAllocationStrategy) == 1, "OToken.changeAllocationStrategy: allocations strategy not whitelisted");

        emit AllocationStrategyChanged(msg.sender, address(s.allocationStrategy), _newAllocationStrategy);

        // redeem all from old allocation strategy
        s.allocationStrategy.redeemAll();

        // change allocation strategy
        s.allocationStrategy = IAllocationStrategy(_newAllocationStrategy);

        uint256 balance = s.underlying.balanceOf(address(this));

        // transfer underlying to new allocation strategy
        s.underlying.safeTransfer(_newAllocationStrategy, balance);
        // deposit in new allocation strategy
        s.allocationStrategy.investUnderlying(balance);
    }

    /**
        @notice Withdraw accidentally acquired tokens by OToken
        @param _token Address of the token to withdraw
    */
    function withdrawLockedERC20(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }
}
