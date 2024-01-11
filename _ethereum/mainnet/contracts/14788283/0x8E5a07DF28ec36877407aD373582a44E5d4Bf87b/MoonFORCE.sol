// SPDX-License-Identifier: MIT
// requires compiler ver of 0.8.1 or higher to recognize imports
pragma solidity =0.8.1;
pragma experimental ABIEncoderV2;

// the most recent ^0.8.0 compatible SafeMath library is implmented to preserve existing logic reliant upon SafeMath syntax.
// erc20 + erc20 snapshot imports to utilize the shapshot functionality to pull balances at any time. Ownable for modifier function call control.
import "./SafeMath.sol";
import "./ERC20.sol";
import "./ERC20Snapshot.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Address.sol";
import "./IPYE.sol";
import "./IWETH.sol";
import "./IPYESwapFactory.sol";
import "./IPYESwapPair.sol";
import "./IPYESwapRouter.sol";
import "./IMoonshotMechanism.sol";
import "./IStakingContract.sol";
import "./MoonshotMechanism.sol";

contract MoonFORCE is IPYE, Context, ERC20, ERC20Snapshot, Ownable {

    // allows easy determination of actual msg.sender in meta-transactions
    using Address for address;
    // declare SafeMath useage so compiler recognizes SafeMath syntax
    using SafeMath for uint256;

//--------------------------------------BEGIN FEE INFO---------|

     // Fees
    struct Fees {
        uint256 reflectionFee;
        uint256 marketingFee;
        uint256 moonshotFee;
        uint256 buybackFee;
        uint256 liquifyFee;
        address marketingAddress;
        address liquifyAddress;
    }

    // Transaction fee values
    struct FeeValues {
        uint256 transferAmount;
        uint256 reflection;
        uint256 marketing;
        uint256 moonshots;
        uint256 buyBack;
        uint256 liquify;
    }

    // instantiating new Fees structs (see struct Fees above)
    Fees public _defaultFees;
    Fees public _defaultSellFees;
    Fees private _previousFees;
    Fees private _emptyFees;
    Fees private _sellFees;
    Fees private _outsideBuyFees;
    Fees private _outsideSellFees;

//--------------------------------------BEGIN MAPPINGS---------|

    // user mappings for token balances and spending allowances. 
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    // user states governing fee exclusion, blacklist status, Reward exempt (meaning no reflection entitlement)
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isBlacklisted;

    // Pair Details
    mapping (uint256 => address) private pairs;
    mapping (uint256 => address) private tokens;
    uint256 private pairsLength;
    mapping (address => bool) public _isPairAddress;
    // Outside Swap Pairs
    mapping (address => bool) private _includeSwapFee;
    // Staking Contracts
    mapping (address => bool) isStakingContract;

//--------------------------------------BEGIN TOKEN PARAMS---------|

    // token details.
    // tTotal is the total token supply (10 bil with 9 decimals)
    string constant _name = "MoonForce";
    string constant _symbol = "FORCE";
    uint8 constant _decimals = 9;
    uint256 private constant _tTotal = 10 * 10**9 * 10**9;


//--------------------------------------BEGIN TOKEN HOLDER INFO---------|

    struct Staked {
        uint256 amount;
    }

    address[] holders;
    mapping (address => uint256) holderIndexes;
    mapping (address => Staked) public staked;

    uint256 public totalStaked;

//--------------------------------------BEGIN ROUTER, WETH, BURN ADDRESS INFO---------|

    IPYESwapRouter public pyeSwapRouter;
    address public pyeSwapPair;
    address public WETH;
    address public constant _burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public _maxTxAmount = 5 * 10**8 * 10**9;

//--------------------------------------BEGIN BUYBACK VARIABLES---------|

    // auto set buyback to false. additional buyback params. blockPeriod acts as a time delay in the shouldAutoBuyback(). Last uint represents last block for buyback occurance.
    bool public autoBuybackEnabled = false;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;
    uint256 minimumBuyBackThreshold = _tTotal / 1000000; // 0.0001%

//--------------------------------------BEGIN MOONSHOT MECH. AND STAKING CONT. INSTANCES---------|

    // instantiate a moonshot from the Moonshot Mechanism contract, which handles moonshot generation and disbursal value logic.
    MoonshotMechanism moonshot;
    address public moonshotAddress;

    IStakingContract public StakingContract;
    address public stakingContract;

    uint256 distributorGas = 500000;

//--------------------------------------BEGIN SWAP INFO---------|

    // swap state variables
    bool inSwap;

    // function modifiers handling swap status
    modifier swapping() { inSwap = true; _; inSwap = false; }
    modifier onlyExchange() {
        bool isPair = false;
        for(uint i = 0; i < pairsLength; i++) {
            if(pairs[i] == msg.sender) isPair = true;
        }
        require(
            msg.sender == address(pyeSwapRouter)
            || isPair
            , "PYE: NOT_ALLOWED"
        );
        _;
    }

//--------------------------------------BEGIN CONSTRUCTOR AND RECEIVE FUNCITON---------|    

    constructor() ERC20("MoonForce", "FORCE") {
        _balances[_msgSender()] = _tTotal;

        pyeSwapRouter = IPYESwapRouter(0x4F71E29C3D5934A15308005B19Ca263061E99616);
        WETH = pyeSwapRouter.WETH();
        pyeSwapPair = IPYESwapFactory(pyeSwapRouter.factory())
        .createPair(address(this), WETH, true);

        moonshot = new MoonshotMechanism();
        moonshotAddress = address(moonshot);

        tokens[pairsLength] = WETH;
        pairs[pairsLength] = pyeSwapPair;
        pairsLength += 1;
        _isPairAddress[pyeSwapPair] = true;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[pyeSwapPair] = true;
        _isExcludedFromFee[moonshotAddress] = true;
        _isExcludedFromFee[stakingContract] = true;

        isTxLimitExempt[_msgSender()] = true;
        isTxLimitExempt[pyeSwapPair] = true;
        isTxLimitExempt[address(pyeSwapRouter)] = true;
        isTxLimitExempt[moonshotAddress] = true;
        isTxLimitExempt[stakingContract] = true;

        _defaultFees = Fees(
            800,
            300,
            200,
            100,
            0,
            0xdfc2aeD317d8ef2bC90183FD0e365BFE190bFCBD,
            0x8539a0c8D96610527140E97A9ae458F6A5bb1F86
        );

        _defaultSellFees = Fees(
            800,
            300,
            200,
            100,
            0,
            0xdfc2aeD317d8ef2bC90183FD0e365BFE190bFCBD,
            0x8539a0c8D96610527140E97A9ae458F6A5bb1F86
        );

        _sellFees = Fees(
            0,
            0,
            0,
            0,
            0,
            0xdfc2aeD317d8ef2bC90183FD0e365BFE190bFCBD,
            0x8539a0c8D96610527140E97A9ae458F6A5bb1F86
        );

        _outsideBuyFees = Fees(
            800,
            300,
            200,
            100,
            0,
            0xdfc2aeD317d8ef2bC90183FD0e365BFE190bFCBD,
            0x8539a0c8D96610527140E97A9ae458F6A5bb1F86
        );

        _outsideSellFees = Fees(
            800,
            300,
            200,
            100,
            0,
            0xdfc2aeD317d8ef2bC90183FD0e365BFE190bFCBD,
            0x8539a0c8D96610527140E97A9ae458F6A5bb1F86
        );

        IPYESwapPair(pyeSwapPair).updateTotalFee(1400);
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    //to receive ETH from pyeRouter when swapping
    receive() external payable {}

//--------------------------------------BEGIN SNAPSHOT FUNCTIONS---------|

    // this function generates a snapshot of the total token supply as well as the balances of all the holders. This is accomplished
    // by the mapping in the ERC20 snapshot contract which links an address to an individual snapshot balance which can be called arbitrarily any time. Calling
    // snapshot() also generates a snapshot ID (a uint) which can be used in the balanceOfAt() fxn in combination with any holder address to get a holders balance at
    // the time the entered shapshotID was generated (i.e. historic balance functionality) 
    function snapshot() public onlyOwner {
        _snapshot();
    }

    // simple getter function which returns the number (or ID) of the most recent snapshot taken. Useful to call if attempting to use totalSupplyAt() or balanceOfAt() and you 
    // need to know what the last snapshot ID is to pass it as an argument.
    function getCurrentSnapshot() public view onlyOwner returns (uint256) {
        return _getCurrentSnapshotId();
    }

    // the original totalSupplyAt() function in ERC20-snapshot only uses totalSupply (in our case, _tTotal) to determine the total supply at a given snapshot. As a result,
    // it won't reflect the token balances of the burn wallet, ..
    function totalSupplyAt(uint256 snapshotId) public view onlyOwner override returns (uint256) {
        return super.totalSupplyAt(snapshotId).sub(balanceOfAt(_burnAddress, snapshotId));
    }

    // The following functions are overrides required by Solidity. "super" provides access directly to the beforeTokenTransfer fxn in ERC20 snapshot. Update balance 
    // and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

//--------------------------------------BEGIN BLACKLIST FUNCTIONS---------|

    // enter an address to blacklist it. This blocks transfers TO that address. Balcklisted members can still sell.
    function blacklistAddress(address addressToBlacklist) public onlyOwner {
        require(!isBlacklisted[addressToBlacklist] , "Address is already blacklisted!");
        isBlacklisted[addressToBlacklist] = true;
    }

    // enter a currently blacklisted address to un-blacklist it.
    function removeFromBlacklist(address addressToRemove) public onlyOwner {
        require(isBlacklisted[addressToRemove] , "Address has not been blacklisted! Enter an address that is on the blacklist.");
        isBlacklisted[addressToRemove] = false;
    }

//--------------------------------------BEGIN TOKEN GETTER FUNCTIONS---------|

    // decimal return fxn is explicitly stated to override the std. ERC-20 decimals() fxn which is programmed to return uint 18, but
    // MoonForce has 9 decimals.
    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    // totalSupply return fxn is explicitly stated to override the std. ERC-20 totalSupply() fxn which is programmed to return a uint "totalSupply", but
    // MoonForce uses "_tTotal" variable to define total token supply, 
    function totalSupply() public pure override(ERC20, IPYE) returns (uint256) {
        return _tTotal;
    }

    // balanceOf function is identical to ERC-20 balanceOf fxn.
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // returns the owned amount of tokens, including tokens that are staked in main pool. Balance qualifies for tier privileges.
    function getOwnedBalance(address account) public view returns (uint256){
        return staked[account].amount.add(_balances[account]);
    }

    // returns the circulating token supply minus the balance in the burn address (0x00..dEAD) and the balance in address(0) (0x00...00)
    function getCirculatingSupply() public view returns (uint256) {
        return _tTotal.sub(balanceOf(_burnAddress)).sub(balanceOf(address(0)));
    }

//--------------------------------------BEGIN TOKEN PAIR FUNCTIONS---------|

    // returns the index of paired tokens
    function _getTokenIndex(address _token) internal view returns (uint256) {
        uint256 index = pairsLength + 1;
        for(uint256 i = 0; i < pairsLength; i++) {
            if(tokens[i] == _token) index = i;
        }

        return index;
    }

    // check if a pair of tokens are paired
    function _checkPairRegistered(address _pair) internal view returns (bool) {
        bool isPair = false;
        for(uint i = 0; i < pairsLength; i++) {
            if(pairs[i] == _pair) isPair = true;
        }

        return isPair;
    }

    function addPair(address _pair, address _token) public {
        address factory = pyeSwapRouter.factory();
        require(
            msg.sender == factory
            || msg.sender == address(pyeSwapRouter)
            || msg.sender == address(this)
        , "PYE: NOT_ALLOWED"
        );

        if(!_checkPairRegistered(_pair)) {
            _isExcludedFromFee[_pair] = true;
            _isPairAddress[_pair] = true;
            isTxLimitExempt[_pair] = true;

            pairs[pairsLength] = _pair;
            tokens[pairsLength] = _token;

            pairsLength += 1;

            IPYESwapPair(_pair).updateTotalFee(getTotalFee());
        }
    }

    function addOutsideSwapPair(address account) public onlyOwner {
        _includeSwapFee[account] = true;
    }

    function removeOutsideSwapPair(address account) public onlyOwner {
        _includeSwapFee[account] = false;
    }

    // set an address as a staking contract
    function setIsStakingContract(address account, bool set) external onlyOwner {
        isStakingContract[account] = set;
    }

//--------------------------------------BEGIN RESCUE FUNCTIONS---------|

    // Rescue eth that is sent here by mistake
    function rescueETH(uint256 amount, address to) external onlyOwner {
        payable(to).transfer(amount);
      }

    // Rescue tokens that are sent here by mistake
    function rescueToken(IERC20 token, uint256 amount, address to) external onlyOwner {
        if( token.balanceOf(address(this)) < amount ) {
            amount = token.balanceOf(address(this));
        }
        token.transfer(to, amount);
    }

//--------------------------------------BEGIN APPROVAL & ALLOWANCE FUNCTIONS---------|

     // allowance fxn is identical to ERC-20 allowance fxn. As per tommy's request, function is still explicity declared.
    function allowance(address owner, address spender) public view override(ERC20, IPYE) returns (uint256) {
        return _allowances[owner][spender];
    }
    
    // approve fxn overrides std. ERC-20 approve() fxn which declares address owner = _msgSender(), whereas MoonForce approve() fxn does not.
    function approve(address spender, uint256 amount) public override(ERC20, IPYE) returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // added override tag, see same explanation for approve() function above.
    function increaseAllowance(address spender, uint256 addedValue) public override virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    // added override tag, see same explanation for approve() function above.
    function decreaseAllowance(address spender, uint256 subtractedValue) public override virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    // added override tag for error message clarity (BEP vs ERC), changed visibility from private to internal to avoid compiler errors.
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

//--------------------------------------BEGIN FEE FUNCTIONS---------|

    // get sum of all fees
    function getTotalFee() internal view returns (uint256) {
        return _defaultFees.reflectionFee
            .add(_defaultFees.marketingFee)
            .add(_defaultFees.moonshotFee)
            .add(_defaultFees.buybackFee)
            .add(_defaultFees.liquifyFee);
    }

    // takes fees
    function _takeFees(FeeValues memory values) private {
        _takeFee(values.reflection.add(values.moonshots), moonshotAddress);
        _takeFee(values.marketing, _defaultFees.marketingAddress);
        _takeFee(values.buyBack, _burnAddress);
        if(values.liquify > 0) {
             _takeFee(values.liquify, _defaultFees.liquifyAddress);
        }
    }

    // collects fees
    function _takeFee(uint256 tAmount, address recipient) private {
        if(recipient == address(0)) return;
        if(tAmount == 0) return;

        _balances[recipient] = _balances[recipient].add(tAmount);
    }

    // calculates the fee
    function calculateFee(uint256 _amount, uint256 _fee) private pure returns (uint256) {
        if(_fee == 0) return 0;
        return _amount.mul(_fee).div(
            10**4
        );
    }

    // restores all fees
    function restoreAllFee() private {
        _defaultFees = _previousFees;
    }

    // removes all fees
    function removeAllFee() private {
        _previousFees = _defaultFees;
        _defaultFees = _emptyFees;
    }

    function setSellFee() private {
        _previousFees = _defaultFees;
        _defaultFees = _sellFees;
    }

    function setOutsideBuyFee() private {
        _previousFees = _defaultFees;
        _defaultFees = _outsideBuyFees;
    }

    function setOutsideSellFee() private {
        _previousFees = _defaultFees;
        _defaultFees = _outsideSellFees;
    }

    // shows whether or not an account is excluded from fees
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    // allows Owner to make an address exempt from fees
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    // allows Owner to make an address incur fees
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    // allows Owner to change max TX percent
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**4
        );
    }

    // set an address to be tx limit exempt
    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    // safety check for set tx limit
    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    // returns the specified values
    function _getValues(uint256 tAmount) private view returns (FeeValues memory) {
        FeeValues memory values = FeeValues(
            0,
            calculateFee(tAmount, _defaultFees.reflectionFee),
            calculateFee(tAmount, _defaultFees.marketingFee),
            calculateFee(tAmount, _defaultFees.moonshotFee),
            calculateFee(tAmount, _defaultFees.buybackFee),
            calculateFee(tAmount, _defaultFees.liquifyFee)
        );

        values.transferAmount = tAmount.sub(values.reflection).sub(values.marketing).sub(values.moonshots).sub(values.buyBack).sub(values.liquify);
        return values;
    }

    
    function depositLPFee(uint256 amount, address token) public onlyExchange {
        uint256 tokenIndex = _getTokenIndex(token);
        if(tokenIndex < pairsLength) {
            uint256 allowanceT = IERC20(token).allowance(msg.sender, address(this));
            if(allowanceT >= amount) {
                IERC20(token).transferFrom(msg.sender, address(this), amount);

                if(token != WETH) {
                    uint256 balanceBefore = IERC20(address(WETH)).balanceOf(address(this));
                    swapToWETH(amount, token);
                    uint256 fAmount = IERC20(address(WETH)).balanceOf(address(this)).sub(balanceBefore);
                    
                    // All fees to be declared here in order to be calculated and sent
                    uint256 totalFee = getTotalFee();
                    uint256 marketingFeeAmount = fAmount.mul(_defaultFees.marketingFee).div(totalFee);
                    uint256 reflectionFeeAmount = fAmount.mul(_defaultFees.reflectionFee).div(totalFee);
                    uint256 moonshotFeeAmount = fAmount.mul(_defaultFees.moonshotFee).div(totalFee);
                    uint256 liquifyFeeAmount = fAmount.mul(_defaultFees.liquifyFee).div(totalFee);

                    IERC20(WETH).transfer(_defaultFees.marketingAddress, marketingFeeAmount);
                    if(stakingContract != address(0)) {
                        IERC20(WETH).transfer(stakingContract, reflectionFeeAmount);
                        try StakingContract.depositWETHToStakingContract(reflectionFeeAmount) {} catch {}
                    } else {
                        IERC20(WETH).transfer(_defaultFees.liquifyAddress, reflectionFeeAmount);
                    }
                    IERC20(WETH).transfer(moonshotAddress, moonshotFeeAmount);
                    if(liquifyFeeAmount > 0) {IERC20(token).transfer(_defaultFees.liquifyAddress, liquifyFeeAmount);}
                } else {
                    // All fees to be declared here in order to be calculated and sent
                    uint256 totalFee = getTotalFee();
                    uint256 marketingFeeAmount = amount.mul(_defaultFees.marketingFee).div(totalFee);
                    uint256 reflectionFeeAmount = amount.mul(_defaultFees.reflectionFee).div(totalFee);
                    uint256 moonshotFeeAmount = amount.mul(_defaultFees.moonshotFee).div(totalFee);
                    uint256 liquifyFeeAmount = amount.mul(_defaultFees.liquifyFee).div(totalFee);

                    IERC20(token).transfer(_defaultFees.marketingAddress, marketingFeeAmount);
                    if(stakingContract != address(0)) {
                        IERC20(token).transfer(stakingContract, reflectionFeeAmount);
                        try StakingContract.depositWETHToStakingContract(reflectionFeeAmount) {} catch {}
                    } else {
                        IERC20(token).transfer(_defaultFees.liquifyAddress, reflectionFeeAmount);
                    }
                    IERC20(token).transfer(moonshotAddress, moonshotFeeAmount);
                    if(liquifyFeeAmount > 0) {IERC20(token).transfer(_defaultFees.liquifyAddress, liquifyFeeAmount);}
                }
            }
        }
    }

    function swapToWETH(uint256 amount, address token) internal {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = WETH;

        IERC20(token).approve(address(pyeSwapRouter), amount);
        pyeSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _updatePairsFee() internal {
        for (uint j = 0; j < pairsLength; j++) {
            IPYESwapPair(pairs[j]).updateTotalFee(getTotalFee());
        }
    }

    // set the reflection fee
    function setReflectionPercent(uint256 _reflectionFee) external onlyOwner {
        _defaultFees.reflectionFee = _reflectionFee;
        _defaultSellFees.reflectionFee = _reflectionFee;
        _outsideBuyFees.reflectionFee = _reflectionFee;
        _outsideSellFees.reflectionFee = _reflectionFee;
        _updatePairsFee();
    }

    // set liquify fee
    function setLiquifyPercent(uint256 _liquifyFee) external onlyOwner {
        _defaultFees.liquifyFee = _liquifyFee;
        _defaultSellFees.liquifyFee = _liquifyFee;
        _outsideBuyFees.liquifyFee = _liquifyFee;
        _outsideSellFees.liquifyFee = _liquifyFee;
        _updatePairsFee();
    }

    // set moonshot fee
    function setMoonshotPercent(uint256 _moonshotFee) external onlyOwner {
        _defaultFees.moonshotFee = _moonshotFee;
        _defaultSellFees.moonshotFee = _moonshotFee;
        _outsideBuyFees.moonshotFee = _moonshotFee;
        _outsideSellFees.moonshotFee = _moonshotFee;
        _updatePairsFee();
    }

    // set marketing fee
    function setMarketingPercent(uint256 _marketingFee) external onlyOwner {
        _defaultFees.marketingFee = _marketingFee;
        _defaultSellFees.marketingFee = _marketingFee;
        _outsideBuyFees.marketingFee = _marketingFee;
        _outsideSellFees.marketingFee = _marketingFee;
        _updatePairsFee();
    }

    // set buyback fee
    function setBuyBackPercent(uint256 _burnFee) external onlyOwner {
        _defaultFees.buybackFee = _burnFee;
        _defaultSellFees.buybackFee = _burnFee;
        _outsideBuyFees.buybackFee = _burnFee;
        _outsideSellFees.buybackFee = _burnFee;
        _updatePairsFee();
    }

//--------------------------------------BEGIN SET ADDRESS FUNCTIONS---------|

    // manually set marketing address
    function setMarketingAddress(address _marketing) external onlyOwner {
        require(_marketing != address(0), "PYE: Address Zero is not allowed");
        _defaultFees.marketingAddress = _marketing;
        _defaultSellFees.marketingAddress = _marketing;
        _sellFees.marketingAddress = _marketing;
        _outsideBuyFees.marketingAddress = _marketing;
        _outsideSellFees.marketingAddress = _marketing;
    }

    // manually set liquify address
    function setLiquifyAddress(address _liquify) external onlyOwner {
        require(_liquify != address(0), "PYE: Address Zero is not allowed");
        _defaultFees.liquifyAddress = _liquify;
        _defaultSellFees.liquifyAddress = _liquify;
        _sellFees.liquifyAddress = _liquify;
        _outsideBuyFees.liquifyAddress = _liquify;
        _outsideSellFees.liquifyAddress = _liquify;
    }

    // manually set moonshot mechanism address
    function updateMoonshotAddress(address payable newAddress) public onlyOwner {
        require(newAddress != address(moonshot), "The moonshot already has that address");

        MoonshotMechanism newMoonshot = MoonshotMechanism(newAddress);
        moonshot = newMoonshot;

        isTxLimitExempt[newAddress] = true;
        _isExcludedFromFee[newAddress] = true;

        moonshotAddress = newAddress;
    }

    function setNewStakingContract(address _newStakingContract) external onlyOwner {
        stakingContract = (_newStakingContract);
        StakingContract = IStakingContract(_newStakingContract);

        isTxLimitExempt[_newStakingContract] = true;
        _isExcludedFromFee[_newStakingContract] = true;
        isStakingContract[_newStakingContract] = true;
    }

//--------------------------------------BEGIN SHARE FUNCTIONS---------|

    function setStaked(address holder, uint256 amount) internal  {
        if(amount > 0 && staked[holder].amount == 0){
            addHolder(holder);
        }else if(amount == 0 && staked[holder].amount > 0){
            removeHolder(holder);
        }

        totalStaked = totalStaked.sub(staked[holder].amount).add(amount);
        staked[holder].amount = amount;
    }

    function addHolder(address holder) internal {
        holderIndexes[holder] = holders.length;
        holders.push(holder);
    }

    function removeHolder(address holder) internal {
        holders[holderIndexes[holder]] = holders[holders.length-1];
        holderIndexes[holders[holders.length-1]] = holderIndexes[holder];
        holders.pop();
    }

//--------------------------------------BEGIN BUYBACK FUNCTIONS---------|

    // runs check to see if autobuyback should trigger
    function shouldAutoBuyback(uint256 amount) internal view returns (bool) {
        return msg.sender != pyeSwapPair
        && !inSwap
        && autoBuybackEnabled
        && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number // After N blocks from last buyback
        && IERC20(address(WETH)).balanceOf(address(this)) >= autoBuybackAmount
        && amount >= minimumBuyBackThreshold;
    }

    // triggers auto buyback
    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, _burnAddress);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
        if(autoBuybackAccumulator > autoBuybackCap){ autoBuybackEnabled = false; }
    }

    // logic to purchase moonforce tokens
    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        IERC20(WETH).approve(address(pyeSwapRouter), amount);
        pyeSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    // manually adjust the buyback settings to suit your needs
    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external onlyOwner {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }

    // manually adjust minimumBuyBackThreshold Denominator. Threshold will be tTotal divided by Denominator. default 1000000 or .0001%
    function setBuyBackThreshold(uint8 thresholdDenominator) external onlyOwner {
        minimumBuyBackThreshold = _tTotal / thresholdDenominator;
    }

//--------------------------------------BEGIN ROUTER FUNCTIONS---------|

    function updateRouterAndPair(address _router, address _pair) public onlyOwner {
        _isExcludedFromFee[address(pyeSwapRouter)] = false;
        _isExcludedFromFee[pyeSwapPair] = false;
        pyeSwapRouter = IPYESwapRouter(_router);
        pyeSwapPair = _pair;
        WETH = pyeSwapRouter.WETH();

        _isExcludedFromFee[address(pyeSwapRouter)] = true;
        _isExcludedFromFee[pyeSwapPair] = true;

        _isPairAddress[pyeSwapPair] = true;
        

        isTxLimitExempt[pyeSwapPair] = true;
        isTxLimitExempt[address(pyeSwapRouter)] = true;

        pairs[0] = pyeSwapPair;
        tokens[0] = WETH;

        IPYESwapPair(pyeSwapPair).updateTotalFee(getTotalFee());
    }

//--------------------------------------BEGIN TRANSFER FUNCTIONS---------|

    // transfer fxn is explicitly stated to override the std. ERC-20 transfer fxn which uses "to" param, but
    // MoonForce uses "recipient" param.
    function transfer(address recipient, uint256 amount) public override(ERC20, IPYE) returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    // transferFrom explicitly stated and overrides ERC-20 std becasue of variable name differences.
    function transferFrom(address sender, address recipient, uint256 amount) public override(ERC20, IPYE) returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

   function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isBlacklisted[to]);
        _beforeTokenTransfer(from, to, amount);
        
        checkTxLimit(from, amount);

        if(shouldAutoBuyback(amount)){ triggerAutoBuyback(); }
        if(_isPairAddress[to] && moonshot.shouldLaunchMoon(to, from)){ try moonshot.launchMoonshot() {} catch {} }

        //indicates if fee should be deducted from transfer
        uint8 takeFee = 0;
        if(_isPairAddress[to] && from != address(pyeSwapRouter) && !isExcludedFromFee(from)) {
            takeFee = 1;
        } else if(_includeSwapFee[from] && !isExcludedFromFee(to)) {
            takeFee = 2;
        } else if(_includeSwapFee[to] && !isExcludedFromFee(from)) {
            takeFee = 3;
        }

        //transfer amount, it will take tax
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, uint8 takeFee) private {
        if(takeFee == 0) {
            removeAllFee();
        } else if(takeFee == 1) {
            setSellFee();
        } else if(takeFee == 2) {
            setOutsideBuyFee();
        } else if(takeFee == 3) {
            setOutsideSellFee();
        }

        FeeValues memory _values = _getValues(amount);
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(_values.transferAmount);
        _takeFees(_values);

        if(isStakingContract[recipient]) { 
            uint256 newAmountAdd = staked[sender].amount.add(amount);
            setStaked(sender, newAmountAdd);
        }

        if(isStakingContract[sender]) {
            uint256 newAmountSub = staked[recipient].amount.sub(amount);
            setStaked(recipient, newAmountSub);
        }

        emit Transfer(sender, recipient, _values.transferAmount);

        if(takeFee == 0 || takeFee == 1) {
            restoreAllFee();
        } else if(takeFee == 2 || takeFee == 3) {
            restoreAllFee();
            emit Transfer(sender, moonshotAddress, _values.reflection.add(_values.moonshots));
            emit Transfer(sender, _defaultFees.marketingAddress, _values.marketing);
            emit Transfer(sender, _burnAddress, _values.buyBack);
            if(_values.liquify > 0) {
                emit Transfer(sender, _defaultFees.liquifyAddress, _values.liquify);
            }
        }   
    }
}
