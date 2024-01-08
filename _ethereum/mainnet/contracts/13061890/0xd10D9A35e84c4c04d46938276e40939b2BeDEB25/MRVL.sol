pragma solidity 0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";
import "./Context.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract MRVL is Context, IERC20, Ownable {

    mapping(address => uint) private _reflectionOwned;
    mapping(address => mapping(address => uint)) private _allowances;

    mapping(address => Excluded) private _isExcluded;

    uint constant public divider = 1e5; // 100.000

    string constant private _name = 'Marvel Geek';
    string constant private _symbol = 'MarGeek';
    uint8 constant private _decimals = 18;

    uint private constant MAX = type(uint160).max;
    uint128 private _actualTotal = uint128(100000 * (10 ** _decimals));
    uint128 private _actualExcludedTotal;
    uint private _reflectionTotal = (MAX - (MAX % _actualTotal));

    struct Excluded {
        uint128 actualOwned;
        bool fromFee;
        bool fromReward;
    }

    struct Fees {
        uint32 socialFee;
        uint32 previousSocialFee;
        uint32 lotteryFee;
        uint32 previousLotteryFee;
        uint32 burnFee;
    }

    Fees public fees;

    event SentToWinner(address _winner, uint amount);
    event SocialFeeSet(uint fee);
    event LotteryFeeSet(uint fee);
    event BurnFeeSet(uint fee);
    event ExcludedFromFee(address account);
    event IncludedInFee(address account);

    constructor(uint _lotteryFee, address _router) {
        // 5%
        setSocialFeePercent(5000);
        // 0,001%
        setBurnFeePercent(1);
        setLotteryFeePercent(_lotteryFee);

        _reflectionOwned[_msgSender()] = _reflectionTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcluded[owner()].fromFee = true;
        _isExcluded[address(this)].fromFee = true;
        _isExcluded[_router].fromFee = true;
        excludeFromReward(address(this));
        excludeFromReward(_router);
        excludeFromReward(_uniswapV2Pair);

        emit Transfer(address(0), _msgSender(), _actualTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint) {
        return _actualTotal;
    }

    function balanceOf(address account) public view override returns (uint) {
        if (_isExcluded[account].fromReward) return _isExcluded[account].actualOwned;
        return tokenFromReflection(_reflectionOwned[account]);
    }

    function transfer(address recipient, uint amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        require(_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function deliver(uint actualAmount) external {
        address sender = _msgSender();
        require(
            !_isExcluded[sender].fromReward,
            "Excluded addresses cannot call this function"
        );
        (uint reflectionAmount, , , , ,) = _getValues(actualAmount);
        _reflectionOwned[sender] = _reflectionOwned[sender] - reflectionAmount;
        _reflectionTotal = _reflectionTotal - reflectionAmount;
    }

    function reflectionFromToken(uint actualAmount, bool deductTransferFee)
        external
        view
        returns (uint)
    {
        require(actualAmount <= _actualTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint reflectionAmount, , , , ,) = _getValues(actualAmount);
            return reflectionAmount;
        } else {
            (, uint reflectionTransferAmount, , , ,) = _getValues(actualAmount);
            return reflectionTransferAmount;
        }
    }

    function tokenFromReflection(uint reflectionAmount)
        public
        view
        returns (uint)
    {
        require(
            reflectionAmount <= _reflectionTotal,
            "Amount must be less than total reflections"
        );
        uint currentRate = _getRate();
        return reflectionAmount / currentRate;
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account].fromReward;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account].fromReward, "Account is already excluded");
        if (_reflectionOwned[account] > 0) {
            _isExcluded[account].actualOwned = uint128(tokenFromReflection(_reflectionOwned[account]));
            _actualExcludedTotal = _actualExcludedTotal + _isExcluded[account].actualOwned;
            _reflectionTotal = _reflectionTotal - _reflectionOwned[account];
            _reflectionOwned[account] = 0;
        }
        _isExcluded[account].fromReward = true;
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account].fromReward, "Account is already excluded");
        _isExcluded[account].fromReward = false;
        _reflectionOwned[account] = _isExcluded[account].actualOwned * _getRate();
        _isExcluded[account].actualOwned = 0;
        _actualExcludedTotal = _actualExcludedTotal - _isExcluded[account].actualOwned;
        _reflectionTotal = _reflectionTotal + _reflectionOwned[account];
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcluded[account].fromFee;
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcluded[account].fromFee = true;
        emit ExcludedFromFee(account);
    }

    function includeInFee(address account) external onlyOwner {
        _isExcluded[account].fromFee = false;
        emit IncludedInFee(account);
    }

    function setSocialFeePercent(uint _socialFee) public onlyOwner {
        require(_socialFee <= divider, 'Fee can not be more than 100%');
        fees.socialFee = uint32(_socialFee);
        emit SocialFeeSet(fees.socialFee);
    }

    function setBurnFeePercent(uint _burnFee) public onlyOwner {
        require(_burnFee <= divider, 'Fee can not be more than 100%');
        fees.burnFee = uint32(_burnFee);
        emit BurnFeeSet(fees.burnFee);
    }


    function setLotteryFeePercent(uint _lotteryFee) public onlyOwner {
        require(_lotteryFee <= divider, 'Fee can not be more than 100%');
        fees.lotteryFee = uint32(_lotteryFee);
        emit LotteryFeeSet(fees.lotteryFee);
    }

    function _takeSocialFee(uint reflectionSocialFee) private {
        _reflectionTotal = _reflectionTotal - reflectionSocialFee;
    }

    function _takeLotteryFee(uint actualLottery, uint reflectionLottery) private {
        if (_isExcluded[address(this)].fromReward) {
            _isExcluded[address(this)].actualOwned = _isExcluded[address(this)].actualOwned + uint128(actualLottery);
            _actualExcludedTotal = _actualExcludedTotal + uint128(actualLottery);
            _reflectionTotal = _reflectionTotal - reflectionLottery;
        } else {
            _reflectionOwned[address(this)] = _reflectionOwned[address(this)] + reflectionLottery;
        }
    }

    function _calculateSocialFee(uint _amount) private view returns (uint) {
        return _amount * fees.socialFee / divider;
    }

    function _calculateLotteryFee(uint _amount) private view returns (uint) {
        return _amount * fees.lotteryFee / divider;
    }



    function _getValues(uint actualAmount)
        private
        view
        returns (
            uint,
            uint,
            uint,
            uint,
            uint,
            uint
        )
    {
        (uint actualTransferAmount, uint actualSocialFee, uint actualLottery) =
            _getActualValues(actualAmount);
        (uint reflectionAmount, uint reflectionTransferAmount, uint reflectionSocialFee, uint reflectionLottery) =
            _getReflectedValues(actualAmount, actualSocialFee, actualLottery, _getRate());
        return (
            reflectionAmount,
            reflectionTransferAmount,
            reflectionSocialFee,
            actualTransferAmount,
            actualLottery,
            reflectionLottery
        );
    }

    function _getActualValues(uint actualAmount)
        private
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        uint actualSocialFee = _calculateSocialFee(actualAmount);
        uint actualLottery = _calculateLotteryFee(actualAmount);
        uint actualTransferAmount = actualAmount - actualSocialFee - actualLottery;
        return (actualTransferAmount, actualSocialFee, actualLottery);
    }

    function _getReflectedValues(
        uint actualAmount,
        uint actualSocialFee,
        uint actualLottery,
        uint currentRate
    )
        private
        pure
        returns (
            uint,
            uint,
            uint,
            uint
        )
    {
        uint reflectionAmount = actualAmount * currentRate;
        uint reflectionSocialFee = actualSocialFee * currentRate;
        uint reflectionLottery = actualLottery * currentRate;
        uint reflectionTransferAmount = reflectionAmount - reflectionSocialFee - reflectionLottery;
        return (reflectionAmount, reflectionTransferAmount, reflectionSocialFee, reflectionLottery);
    }

    function _getRate() private view returns (uint) {
        (uint reflectionSupply, uint actualSupply) = _getCurrentSupply();
        return reflectionSupply / actualSupply;
    }

    function _getCurrentSupply() private view returns (uint, uint) {
        if (_actualExcludedTotal >= _actualTotal) return (_reflectionTotal, _actualTotal);
        return (_reflectionTotal, _actualTotal - _actualExcludedTotal);
    }


    function sendToWinner(address _winner) external onlyOwner {
        uint amount = balanceOf(address(this));

        _transfer(address(this), _winner, amount);
        emit SentToWinner(_winner, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;

        if (_isExcluded[from].fromFee || _isExcluded[to].fromFee) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint amount,
        bool takeFee
    ) private {
        if (!takeFee) _removeAllFee();

        bool isSenderExcluded = _isExcluded[sender].fromReward;
        bool isRecipientExcluded = _isExcluded[recipient].fromReward;

        if (!isSenderExcluded && !isRecipientExcluded) {
            _transferStandard(sender, recipient, amount);
        } else if (!isSenderExcluded && isRecipientExcluded) {
            _transferToExcluded(sender, recipient, amount);
        } else if (isSenderExcluded && !isRecipientExcluded) {
            _transferFromExcluded(sender, recipient, amount);
        } else {
            _transferBothExcluded(sender, recipient, amount);
        }

        if (!takeFee) _restoreAllFee();
        _burn();
    }

    function _burn() private {
        (, uint includedOwned) = _getCurrentSupply();
        uint excludedOwned = _actualTotal - includedOwned;
        _actualTotal = uint128(excludedOwned + includedOwned * (divider - fees.burnFee) / divider);
    }


    function _removeAllFee() private {
        if (fees.socialFee == 0 && fees.lotteryFee == 0) return;

        fees.previousSocialFee = fees.socialFee;
        fees.previousLotteryFee = fees.lotteryFee;

        fees.socialFee = 0;
        fees.lotteryFee = 0;
    }

    function _restoreAllFee() private {
        fees.socialFee = fees.previousSocialFee;
        fees.lotteryFee = fees.previousLotteryFee;
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint actualAmount
    ) private {
        (
            uint reflectionAmount,
            uint reflectionTransferAmount,
            uint reflectionSocialFee,
            uint actualTransferAmount,
            uint actualLottery,
            uint reflectionLottery
        ) = _getValues(actualAmount);
        _reflectionOwned[sender] = _reflectionOwned[sender] - reflectionAmount;
        _reflectionOwned[recipient] = _reflectionOwned[recipient] + reflectionTransferAmount;
        _takeLotteryFee(actualLottery, reflectionLottery);
        _takeSocialFee(reflectionSocialFee);
        emit Transfer(sender, recipient, actualTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint actualAmount
    ) private {
        (
            uint reflectionAmount,
            uint reflectionTransferAmount,
            uint reflectionSocialFee,
            uint actualTransferAmount,
            uint actualLottery,
            uint reflectionLottery
        ) = _getValues(actualAmount);
        _reflectionOwned[sender] = _reflectionOwned[sender] - reflectionAmount;
        _reflectionTotal = _reflectionTotal - reflectionTransferAmount;
        _isExcluded[recipient].actualOwned = _isExcluded[recipient].actualOwned + uint128(actualTransferAmount);
        _actualExcludedTotal = _actualExcludedTotal + uint128(actualTransferAmount);
        _takeLotteryFee(actualLottery, reflectionLottery);
        _takeSocialFee(reflectionSocialFee);
        emit Transfer(sender, recipient, actualTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint actualAmount
    ) private {
        (
            uint reflectionAmount,
            uint reflectionTransferAmount,
            uint reflectionSocialFee,
            uint actualTransferAmount,
            uint actualLottery,
            uint reflectionLottery
        ) = _getValues(actualAmount);
        _isExcluded[sender].actualOwned = _isExcluded[sender].actualOwned - uint128(actualAmount);
        _actualExcludedTotal = _actualExcludedTotal - uint128(actualAmount);
        _reflectionOwned[recipient] = _reflectionOwned[recipient] + reflectionTransferAmount;
        _reflectionTotal = _reflectionTotal + reflectionAmount;
        _takeLotteryFee(actualLottery, reflectionLottery);
        _takeSocialFee(reflectionSocialFee);
        emit Transfer(sender, recipient, actualTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint actualAmount
    ) private {
        (
            uint reflectionAmount,
            uint reflectionTransferAmount,
            uint reflectionSocialFee,
            uint actualTransferAmount,
            uint actualLottery,
            uint reflectionLottery
        ) = _getValues(actualAmount);
        _isExcluded[sender].actualOwned = _isExcluded[sender].actualOwned - uint128(actualAmount);
        _reflectionTotal = _reflectionTotal - reflectionTransferAmount;
        _isExcluded[recipient].actualOwned = _isExcluded[recipient].actualOwned + uint128(actualTransferAmount);
        _actualExcludedTotal = _actualExcludedTotal + uint128(actualTransferAmount) - uint128(actualAmount);
        _reflectionTotal = _reflectionTotal + reflectionAmount;
        _takeLotteryFee(actualLottery, reflectionLottery);
        _takeSocialFee(reflectionSocialFee);
        emit Transfer(sender, recipient, actualTransferAmount);
    }
}