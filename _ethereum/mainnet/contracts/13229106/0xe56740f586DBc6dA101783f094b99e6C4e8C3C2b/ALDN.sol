// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";

interface ISwapAndLiquify{
    function inSwapAndLiquify() external returns(bool);
    function swapAndLiquify(uint256 tokenAmount) external;
}

contract ALDN is IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isExcludedFromMaxTxAmount;

    address[] private _excluded;

    uint256 private constant MAX = type(uint256).max;
    uint256 private _tTotal = 1000000000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "MagicLamp Governance Token";
    string private _symbol = "ALDN";
    uint8 private _decimals = 9;

    // fee factors
    uint256 public taxFee = 5;
    uint256 private _previousTaxFee;

    uint256 public liquidityFee = 5;
    uint256 private _previousLiquidityFee;

    bool public swapAndLiquifyEnabled = true;

    uint256 public maxTxAmount = 5000000 * 10**6 * 10**9;
    uint256 private _numTokensSellToAddToLiquidity = 500000 * 10**6 * 10**9;

	ISwapAndLiquify public swapAndLiquify;

    // @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    // @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    // @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    // @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    // @notice A checkpoint for marking number of votes from a given block
    struct VotesCheckpoint {
        uint32 fromBlock;
        uint96 tOwned;
        uint256 rOwned;
    }

    // @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => VotesCheckpoint)) public votesCheckpoints;

    // @notice The number of votes checkpoints for each account
    mapping (address => uint32) public numVotesCheckpoints;

    // @notice A checkpoint for marking rate from a given block
    struct RateCheckpoint {
        uint32 fromBlock;
        uint256 rate;
    }

    // @notice A record of rates, by index
    mapping (uint32 => RateCheckpoint) public rateCheckpoints;

    // @notice The number of rate checkpoints
    uint32 public numRateCheckpoints;

    // @notice An event thats emitted when swap and liquidify address is changed
    event SwapAndLiquifyAddressChanged(address priviousAddress, address newAddress);

    // @notice An event thats emitted when swap and liquidify enable is changed
    event SwapAndLiquifyEnabledChanged(bool enabled);

    // @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    // @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousROwned, uint previousTOwned, uint newROwned, uint newTOwned);

    // @notice An event thats emitted when reflection rate changes
    event RateChanged(uint previousRate, uint newRate);

    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        
        // excludes
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromMaxTxAmount[owner()] = true;
        _isExcluded[address(this)] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromMaxTxAmount[address(this)] = true;
        _isExcluded[0x000000000000000000000000000000000000dEaD] = true;

        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 spenderAllowance = _allowances[sender][_msgSender()];
        if (sender != _msgSender() && spenderAllowance != type(uint256).max) {
            _approve(sender, _msgSender(), spenderAllowance.sub(amount,"ERC20: transfer amount exceeds allowance"));
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue,"ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function _getOwns(address account) private view returns (uint256, uint256) {
        uint256 rOwned = _isExcluded[account] ? 0 : _rOwned[account];
        uint256 tOwned = _isExcluded[account] ? _tOwned[account] : 0;

        return (rOwned, tOwned);
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "ALDN::deliver: excluded addresses cannot call this function");

        (uint256 oldROwned, uint256 oldTOwned) = _getOwns(sender);

        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);

        (uint256 newROwned, uint256 newTOwned) = _getOwns(sender);

        _moveDelegates(delegates[sender], delegates[sender], oldROwned, oldTOwned, newROwned, newTOwned);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "ALDN::reflectionFromToken: amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function _tokenFromReflection(uint256 rAmount, uint256 rate) private pure returns (uint256) {
        return rAmount.div(rate);
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "ALDN::tokenFromReflection: amount must be less than total reflections");
        
        return _tokenFromReflection(rAmount, _getCurrentRate());
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "ALDN::excludeFromReward: account is already excluded");
        
        (uint256 oldROwned, uint256 oldTOwned) = _getOwns(account);

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);

        (uint256 newROwned, uint256 newTOwned) = _getOwns(account);

        _moveDelegates(delegates[account], delegates[account], oldROwned, oldTOwned, newROwned, newTOwned);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "ALDN::includeInReward: account is already included");
        
        (uint256 oldROwned, uint256 oldTOwned) = _getOwns(account);

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
        
        (uint256 newROwned, uint256 newTOwned) = _getOwns(account);

        _moveDelegates(delegates[account], delegates[account], oldROwned, oldTOwned, newROwned, newTOwned);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function excludeFromMaxTxAmount(address account) public onlyOwner {
        _isExcludedFromMaxTxAmount[account] = true;
    }

    function includeInMaxTxAmount(address account) public onlyOwner {
        _isExcludedFromMaxTxAmount[account] = false;
    }

    function setTaxFeePercent(uint256 newFee) external onlyOwner {
        taxFee = newFee;
    }

    function setLiquidityFeePercent(uint256 newFee) external onlyOwner {
        liquidityFee = newFee;
    }

    function setMaxTxPercent(uint256 newPercent) external onlyOwner {
        maxTxAmount = _tTotal.mul(newPercent).div(10**2);
    }

	function setSwapAndLiquifyAddress(address newAddress) public onlyOwner {
        address priviousAddress = address(swapAndLiquify);        
        require(priviousAddress != newAddress, "ALDN::setSwapAndLiquifyAddress: same address");
        
        _approve(address(this), address(newAddress), type(uint256).max);
        swapAndLiquify = ISwapAndLiquify(newAddress);

        emit SwapAndLiquifyAddressChanged(priviousAddress, newAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;

        emit SwapAndLiquifyEnabledChanged(_enabled);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getCurrentRate());

        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);

        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        
        return (rAmount, rTransferAmount, rFee);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        
        return (rSupply, tSupply);
    }

    /**
     * @notice Gets the current rate
     * @return The current rate
     */
    function _getCurrentRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        
        return rSupply.div(tSupply);
    }

    /**
     * @notice Gets the rate at a block number
     * @param blockNumber The block number to get the rate at
     * @return The rate at the given block
     */
    function _getPriorRate(uint blockNumber) private view returns (uint256) {
        if (numRateCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (rateCheckpoints[numRateCheckpoints - 1].fromBlock <= blockNumber) {
            return rateCheckpoints[numRateCheckpoints - 1].rate;
        }

        // Next check implicit zero balance
        if (rateCheckpoints[0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = numRateCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            RateCheckpoint memory rcp = rateCheckpoints[center];
            if (rcp.fromBlock == blockNumber) {
                return rcp.rate;
            } else if (rcp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return rateCheckpoints[lower].rate;
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getCurrentRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(taxFee).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(liquidityFee).div(10**2);
    }

    function removeAllFee() private {
        if (taxFee == 0 && liquidityFee == 0) return;

        _previousTaxFee = taxFee;
        _previousLiquidityFee = liquidityFee;

        taxFee = 0;
        liquidityFee = 0;
    }

    function restoreAllFee() private {
        taxFee = _previousTaxFee;
        liquidityFee = _previousLiquidityFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedFromMaxTxAmount(address account) public view returns (bool) {
        return _isExcludedFromMaxTxAmount[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ALDN::_approve: approve from the zero address");
        require(spender != address(0), "ALDN::_approve: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ALDN::_transfer: transfer from the zero address");
        require(to != address(0), "ALDN::_transfer: transfer to the zero address");
        require(amount > 0, "ALDN::_transfer: amount must be greater than zero");
        require(_isExcludedFromMaxTxAmount[from] || _isExcludedFromMaxTxAmount[to] || amount <= maxTxAmount, "ALDN::_transfer: transfer amount exceeds the maxTxAmount.");
        
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= maxTxAmount) {
            contractTokenBalance = maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
        if (overMinTokenBalance && from != owner() && from != address(swapAndLiquify) 
        && !swapAndLiquify.inSwapAndLiquify() && swapAndLiquifyEnabled) {
            contractTokenBalance = _numTokensSellToAddToLiquidity;
            // add liquidity
            swapAndLiquify.swapAndLiquify(contractTokenBalance);
        }

        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (sender == recipient) {
            emit Transfer(sender, recipient, amount);
            return;
        }

        (uint256 oldSenderROwned, uint256 oldSenderTOwned) = _getOwns(sender);
        (uint256 oldRecipientROwned, uint256 oldRecipientTOwned) = _getOwns(recipient);
        {
            if (!takeFee) {
                removeAllFee();
            }

            bool isExcludedSender = _isExcluded[sender];
            bool isExcludedRecipient = _isExcluded[recipient];
            if (isExcludedSender && !isExcludedRecipient) {
                _transferFromExcluded(sender, recipient, amount);
            } else if (!isExcludedSender && isExcludedRecipient) {
                _transferToExcluded(sender, recipient, amount);
            } else if (!isExcludedSender && !isExcludedRecipient) {
                _transferStandard(sender, recipient, amount);
            } else if (isExcludedSender && isExcludedRecipient) {
                _transferBothExcluded(sender, recipient, amount);
            } else {
                _transferStandard(sender, recipient, amount);
            }

            if (!takeFee) {
                restoreAllFee();
            }
        }
        (uint256 newSenderROwned, uint256 newSenderTOwned) = _getOwns(sender);
        (uint256 newRecipientROwned, uint256 newRecipientTOwned) = _getOwns(recipient);

        _moveDelegates(delegates[sender], delegates[recipient], oldSenderROwned.sub(newSenderROwned), oldSenderTOwned.sub(newSenderTOwned), newRecipientROwned.sub(oldRecipientROwned), newRecipientTOwned.sub(oldRecipientTOwned));
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function burn(uint256 burnQuantity) external override pure returns (bool) {
        burnQuantity;
        return false;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(_msgSender(), delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(_name)), _getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "ALDN::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "ALDN::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "ALDN::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the votes balance of `checkpoint` with `rate`
     * @param rOwned The reflection value to get votes balance
     * @param tOwned The balance value to get votes balance
     * @param rate The rate to get votes balance
     * @return The number of votes with params
     */
    function _getVotes(uint256 rOwned, uint256 tOwned, uint256 rate) private pure returns (uint96) {
        uint256 votes = 0;
        votes = votes.add(_tokenFromReflection(rOwned, rate));
        votes = votes.add(tOwned);
        return uint96(votes);
    }

    /**
     * @notice Gets the votes balance of `checkpoint` with `rate`
     * @param checkpoint The checkpoint to get votes balance
     * @param rate The rate to get votes balance
     * @return The number of votes of `checkpoint` with `rate`
     */
    function _getVotes(VotesCheckpoint memory checkpoint, uint256 rate) private pure returns (uint96) {
        return _getVotes(checkpoint.rOwned, checkpoint.tOwned, rate);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numVotesCheckpoints[account];
        return nCheckpoints > 0 ? _getVotes(votesCheckpoints[account][nCheckpoints - 1], _getCurrentRate()) : 0;
    }

     /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "ALDN::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numVotesCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        uint256 rate = _getPriorRate(blockNumber);

        // First check most recent balance
        if (votesCheckpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return _getVotes(votesCheckpoints[account][nCheckpoints - 1], rate);
        }

        // Next check implicit zero balance
        if (votesCheckpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            if (votesCheckpoints[account][center].fromBlock == blockNumber) {
                return _getVotes(votesCheckpoints[account][center], rate);
            } else if (votesCheckpoints[account][center].fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return _getVotes(votesCheckpoints[account][lower], rate);
    }

    function _delegate(address delegator, address delegatee) private {
        address currentDelegate = delegates[delegator];
        (uint256 delegatorROwned, uint256 delegatorTOwned) = _getOwns(delegator);
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorROwned, delegatorTOwned, delegatorROwned, delegatorTOwned);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 subROwned, uint256 subTOwned, uint256 addROwned, uint256 addTOwned) private {
        if (srcRep != dstRep) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numVotesCheckpoints[srcRep];
                uint256 srcRepOldR = srcRepNum > 0 ? votesCheckpoints[srcRep][srcRepNum - 1].rOwned : 0;
                uint256 srcRepOldT = srcRepNum > 0 ? votesCheckpoints[srcRep][srcRepNum - 1].tOwned : 0;
                uint256 srcRepNewR = srcRepOldR.sub(subROwned);
                uint256 srcRepNewT = srcRepOldT.sub(subTOwned);
                if (srcRepOldR != srcRepNewR || srcRepOldT != srcRepNewT) {
                    _writeCheckpoint(srcRep, srcRepNum, srcRepOldR, srcRepOldT, srcRepNewR, srcRepNewT);
                }
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numVotesCheckpoints[dstRep];
                uint256 dstRepOldR = dstRepNum > 0 ? votesCheckpoints[dstRep][dstRepNum - 1].rOwned : 0;
                uint256 dstRepOldT = dstRepNum > 0 ? votesCheckpoints[dstRep][dstRepNum - 1].tOwned : 0;
                uint256 dstRepNewR = dstRepOldR.add(addROwned);
                uint256 dstRepNewT = dstRepOldT.add(addTOwned);
                if (dstRepOldR != dstRepNewR || dstRepOldT != dstRepNewT) {
                    _writeCheckpoint(dstRep, dstRepNum, dstRepOldR, dstRepOldT, dstRepNewR, dstRepNewT);
                }
            }
        } else if (dstRep != address(0)) {
            uint32 dstRepNum = numVotesCheckpoints[dstRep];
            uint256 dstRepOldR = dstRepNum > 0 ? votesCheckpoints[dstRep][dstRepNum - 1].rOwned : 0;
            uint256 dstRepOldT = dstRepNum > 0 ? votesCheckpoints[dstRep][dstRepNum - 1].tOwned : 0;
            uint256 dstRepNewR = dstRepOldR.add(addROwned).sub(subROwned);
            uint256 dstRepNewT = dstRepOldT.add(addTOwned).sub(subTOwned);
            if (dstRepOldR != dstRepNewR || dstRepOldT != dstRepNewT) {
                _writeCheckpoint(dstRep, dstRepNum, dstRepOldR, dstRepOldT, dstRepNewR, dstRepNewT);
            }
        }

        uint256 rate = _getCurrentRate();
        uint256 rateOld = numRateCheckpoints > 0 ? rateCheckpoints[numRateCheckpoints - 1].rate : 0;
        if (rate != rateOld) {
            _writeRateCheckpoint(numRateCheckpoints, rateOld, rate);
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldROwned, uint256 oldTOwned, uint256 newROwned, uint256 newTOwned) private {
        uint32 blockNumber = safe32(block.number, "ALDN::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && votesCheckpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            votesCheckpoints[delegatee][nCheckpoints - 1].tOwned = uint96(newTOwned);
            votesCheckpoints[delegatee][nCheckpoints - 1].rOwned = newROwned;
        } else {
            votesCheckpoints[delegatee][nCheckpoints] = VotesCheckpoint(blockNumber, uint96(newTOwned), newROwned);
            numVotesCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldROwned, oldTOwned, newROwned, newTOwned);
    }

    function _writeRateCheckpoint(uint32 nCheckpoints, uint256 oldRate, uint256 newRate) private {
        uint32 blockNumber = safe32(block.number, "ALDN::_writeRateCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && rateCheckpoints[nCheckpoints - 1].fromBlock == blockNumber) {
            rateCheckpoints[nCheckpoints - 1].rate = newRate;
        } else {
            rateCheckpoints[nCheckpoints].fromBlock = blockNumber;
            rateCheckpoints[nCheckpoints].rate = newRate;
            numRateCheckpoints = nCheckpoints + 1;
        }

        emit RateChanged(oldRate, newRate);
    }

    function safe32(uint n, string memory errorMessage) private pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function _getChainId() private view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}
