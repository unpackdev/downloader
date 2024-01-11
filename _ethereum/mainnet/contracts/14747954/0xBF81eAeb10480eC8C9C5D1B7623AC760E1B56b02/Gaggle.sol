
/*








 ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄            ▄▄▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌          ▐░░░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌          ▐░█▀▀▀▀▀▀▀▀▀ 
▐░▌          ▐░▌       ▐░▌▐░▌          ▐░▌          ▐░▌          ▐░▌          
▐░▌ ▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄█░▌▐░▌ ▄▄▄▄▄▄▄▄ ▐░▌ ▄▄▄▄▄▄▄▄ ▐░▌          ▐░█▄▄▄▄▄▄▄▄▄ 
▐░▌▐░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌▐░░░░░░░░▌▐░▌▐░░░░░░░░▌▐░▌          ▐░░░░░░░░░░░▌
▐░▌ ▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░▌ ▀▀▀▀▀▀█░▌▐░▌ ▀▀▀▀▀▀█░▌▐░▌          ▐░█▀▀▀▀▀▀▀▀▀ 
▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌          ▐░▌          
▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌











*/














// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract GAGGLE is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address public tokenPairAddress;
    address public teamAddress = 0x02D7E6bC55Bcf210bc7f79F4e15F7E439FF2425d;
    address public treasuryAddress = 0x1534854fE07d619ce3A2c4c5c03eb35A49A9E652;
    address public psWallet = 0x5Fcb81060feeA737902033F0411AcFd0aCE1448C;
    address public cmoAddress = 0xed564EF21C2A46FcA92fB9fF29cb5b53a10C90B0;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) private _reserveTokenBalance;
    mapping(address => uint256) private _circulatingTokenBalance;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    // The highest possible number.
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _totalSupply = 20000000000 * 10**9;
    uint256 private _totalReserve = (MAX - (MAX % _totalSupply));
    uint256 private _transactionFeeTotal;

    bool private initialSellTaxActive = false;
    bool private initialSellTaxSet = false;

    uint8 private _decimals = 9;
    string private _symbol = "$GAG";
    string private _name = "Gaggle";


       struct ReserveValues {
        uint256 reserveAmount;
        uint256 reserveTransferAmountMarketing;
        uint256 reserveTransferAmount;
        uint256 reserveTransferAmountTeam;
        uint256 reserveTransferAmountBurnEm;
    }

        struct TransactionValues {
        uint256 transactionFee;
        uint256 transferAmount;
        uint256 netTransferAmount;
        uint256 marketingFee;
        uint256 teamTax;
        uint256 burnEm;
    }


            ////////////////////////////////////
            //  ____  ____   ____  ______ 
            // |    ||    \ |    ||      |
            //  |  | |  _  | |  | |      |
            //  |  | |  |  | |  | |_|  |_|
            //  |  | |  |  | |  |   |  |  
            //  |  | |  |  | |  |   |  |  
            // |____||__|__||____|  |__|  
            //
            ////////////////////////////////////

    constructor() {
        uint256 blackHole = _totalSupply.div(2);
        uint256 presale = blackHole.mul(23).div(100);
        uint256 lp = blackHole.mul(30).div(100);
        uint256 treasury = blackHole.mul(28).div(100);
        uint256 team = blackHole.mul(18).div(100);
        uint256 cmo = blackHole.mul(10).div(1000);

         uint256 rate = getRate();

        _reserveTokenBalance[burnAddress] = blackHole.mul(rate);
        _reserveTokenBalance[_msgSender()] = presale.mul(rate) + lp.mul(rate);
        _reserveTokenBalance[treasuryAddress] = treasury.mul(rate);
        _reserveTokenBalance[teamAddress] = team.mul(rate);
        _reserveTokenBalance[cmoAddress] = cmo.mul(rate);

        emit Transfer(address(0), burnAddress, blackHole);
        emit Transfer(address(0), _msgSender(), presale);
        emit Transfer(address(0), _msgSender(), lp);
        emit Transfer(address(0), treasuryAddress, treasury);
        emit Transfer(address(0), teamAddress, team);
        emit Transfer(address(0), cmoAddress, cmo);
    }

    ///////////////////////////////////////
    //           _   _                
    //          | | | |               
    //  ___  ___| |_| |_ ___ _ __ ___ 
    // / __|/ _ \ __| __/ _ \ '__/ __|
    // \__ \  __/ |_| ||  __/ |  \__ \
    // |___/\___|\__|\__\___|_|  |___/
    //
    //
    ///////////////////////////////////////

                               

    function deathTaxOn() public onlyOwner {
        initialSellTaxActive = true;
    }
    function deathTaxOff() public onlyOwner {
        initialSellTaxActive = false;
    }
    function setTeamAddress(address _teamAddress) public onlyOwner {
        teamAddress = _teamAddress;
    }
    function setTreasuryAddress(address _treasuryAddress) public onlyOwner {
        treasuryAddress = _treasuryAddress;
    }
    function setpsWallet(address _psWallet) public onlyOwner {
        psWallet = _psWallet;
    }
    function setCmoAddress(address _cmoAddress) public onlyOwner {
        cmoAddress = _cmoAddress;
    }
    function setTokenPairAddress(address _tokenPairAddress) public onlyOwner {
        tokenPairAddress = _tokenPairAddress;
    }
 
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
 
    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _circulatingTokenBalance[account];
        return tokenBalanceFromReserveAmount(_reserveTokenBalance[account]);
    }

    function transfer(address recipient, uint256 amount)
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
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
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
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

 
    function getOwner() external view override returns (address) {
        return owner();
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _transactionFeeTotal;
    }

    function distributeToAllHolders(uint256 transferAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (, ReserveValues memory reserveValues, ) = _getValues(transferAmount);
        _reserveTokenBalance[sender] = _reserveTokenBalance[sender].sub(
            reserveValues.reserveAmount
        );
        _totalReserve = _totalReserve.sub(reserveValues.reserveAmount);
        _transactionFeeTotal = _transactionFeeTotal.add(transferAmount);
    }

    function reserveBalanceFromTokenAmount(
        uint256 transferAmount,
        bool deductTransferReserveFee
    ) public view returns (uint256) {
        (, ReserveValues memory reserveValues, ) = _getValues(transferAmount);
        require(
            transferAmount <= _totalSupply,
            "Amount must be less than supply"
        );
        if (!deductTransferReserveFee) {
            return reserveValues.reserveAmount;
        } else {
            return reserveValues.reserveTransferAmount;
        }
    }

    function tokenBalanceFromReserveAmount(uint256 reserveAmount)
        public
        view
        returns (uint256)
    {
        require(
            reserveAmount <= _totalReserve,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = getRate();
        return reserveAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_reserveTokenBalance[account] > 0) {
            _circulatingTokenBalance[account] = tokenBalanceFromReserveAmount(
                _reserveTokenBalance[account]
            );
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner {
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _circulatingTokenBalance[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function applyExternalTransactionTax(
        ReserveValues memory reserveValues,
        TransactionValues memory transactionValues,
        address sender
    ) private {
        _reserveTokenBalance[teamAddress] = _reserveTokenBalance[teamAddress]
            .add(reserveValues.reserveTransferAmountTeam);
        _reserveTokenBalance[treasuryAddress] = _reserveTokenBalance[
            treasuryAddress
        ].add(reserveValues.reserveTransferAmountMarketing);
        _reserveTokenBalance[burnAddress] = _reserveTokenBalance[burnAddress]
            .add(reserveValues.reserveTransferAmountBurnEm);

        emit Transfer(sender, teamAddress, transactionValues.teamTax);
        emit Transfer(sender, treasuryAddress, transactionValues.teamTax);
        emit Transfer(sender, burnAddress, transactionValues.burnEm);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    /////////////////////////////////////////////////////  :) --->
    //   _____      ____ _ _ __  _ __   ___ _ __ ___ 
    //  / __\ \ /\ / / _` | '_ \| '_ \ / _ \ '__/ __|
    //  \__ \\ V  V / (_| | |_) | |_) |  __/ |  \__ \
    //  |___/ \_/\_/ \__,_| .__/| .__/ \___|_|  |___/
    //                    | |   | |                  
    //                    |_|   |_|                  
    //////////////////////////////////////////////////////   :-O  <----- 

    function _transferStandard(
        address sender,
        address recipient,
        uint256 transferAmount
    ) private {
        (
            TransactionValues memory transactionValues,
            ReserveValues memory reserveValues,

        ) = _getValues(transferAmount);
        _reserveTokenBalance[sender] = _reserveTokenBalance[sender].sub(
            reserveValues.reserveAmount
        );
        _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient].add(
            reserveValues.reserveTransferAmount
        );
        emit Transfer(sender, recipient, transactionValues.netTransferAmount);
        applyExternalTransactionTax(reserveValues, transactionValues, sender);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 transferAmount
    ) private {
        (
            TransactionValues memory transactionValues,
            ReserveValues memory reserveValues,

        ) = _getValues(transferAmount);

        _reserveTokenBalance[sender] = _reserveTokenBalance[sender].sub(
            reserveValues.reserveAmount
        );

        if (recipient == tokenPairAddress) {
            _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient]
                .add(reserveValues.reserveAmount);
            _circulatingTokenBalance[recipient] = _circulatingTokenBalance[
                recipient
            ].add(transferAmount);

            emit Transfer(sender, recipient, transferAmount);
        } else {
            _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient]
                .add(reserveValues.reserveTransferAmount);
            _circulatingTokenBalance[recipient] = _circulatingTokenBalance[
                recipient
            ].add(transactionValues.netTransferAmount);
            emit Transfer(
                sender,
                recipient,
                transactionValues.netTransferAmount
            );
            applyExternalTransactionTax(
                reserveValues,
                transactionValues,
                sender
            );
        }
    }

/////////////////////////////////////////////////////////////////////////////////////////
    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 transferAmount
    ) private {
        (
            TransactionValues memory transactionValues,
            ReserveValues memory reserveValues,

        ) = _getValues(transferAmount);
        _circulatingTokenBalance[sender] = _circulatingTokenBalance[sender].sub(
            transferAmount
        );
        _reserveTokenBalance[sender] = _reserveTokenBalance[sender].sub(
            reserveValues.reserveAmount
        );

   
        if (!initialSellTaxActive) {
            _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient]
                .add(reserveValues.reserveTransferAmount);
            emit Transfer(
                sender,
                recipient,
                transactionValues.netTransferAmount
            );
            applyExternalTransactionTax(
                reserveValues,
                transactionValues,
                sender
            );
           
        } else {

            /////////////////////////////////////
            //  | |__  ___| |_   / _|_  _| |__
            //  | '_ \/ _ \  _| |  _| || | / /
            //  |_.__/\___/\__| |_|  \_,_|_\_\
            ////////////////////////////////////                     

            // this is where we pump one in the bots!!  ///
            _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient]
                .add(reserveValues.reserveAmount.div(10));
            emit Transfer(sender, recipient, transferAmount.div(10));
        }
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 transferAmount
    ) private {
        (
            TransactionValues memory transactionValues,
            ReserveValues memory reserveValues,

        ) = _getValues(transferAmount);
        _circulatingTokenBalance[sender] = _circulatingTokenBalance[sender].sub(
            transferAmount
        );
        _reserveTokenBalance[sender] = _reserveTokenBalance[sender].sub(
            reserveValues.reserveAmount
        );
        _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient].add(
            reserveValues.reserveTransferAmount
        );
        _circulatingTokenBalance[recipient] = _circulatingTokenBalance[
            recipient
        ].add(transactionValues.netTransferAmount);

        emit Transfer(sender, recipient, transactionValues.netTransferAmount);
        applyExternalTransactionTax(reserveValues, transactionValues, sender);
 
    }
    
    function _getValues(uint256 transferAmount)
        private
        view
        returns (
            TransactionValues memory,
            ReserveValues memory,
            uint256
        )
    {
        TransactionValues memory transactionValues = _getTValues(
            transferAmount
        );
        uint256 currentRate = getRate();
        ReserveValues memory reserveValues = _getRValues(
            transferAmount,
            transactionValues,
            currentRate
        );

        return (transactionValues, reserveValues, currentRate);
    }

    function _getTValues(uint256 transferAmount)
        private
        pure
        returns (TransactionValues memory)
    {
        TransactionValues memory transactionValues;

        transactionValues.transactionFee = transferAmount.mul(2).div(100);

        transactionValues.teamTax = transferAmount.mul(2).div(100);

        transactionValues.burnEm = transferAmount.mul(10).div(1000);

        transactionValues.netTransferAmount = transferAmount
            .sub(transactionValues.transactionFee)
            .sub(transactionValues.teamTax)
            .sub(transactionValues.burnEm);

        return transactionValues;
    }

    function _getRValues(
        uint256 transferAmount,
        TransactionValues memory transactionValues,
        uint256 currentRate
    ) private pure returns (ReserveValues memory) {
        ReserveValues memory reserveValues;
        reserveValues.reserveAmount = transferAmount.mul(currentRate);
        reserveValues.reserveTransferAmountMarketing = transactionValues
            .transactionFee
            .mul(currentRate);
        reserveValues.reserveTransferAmountTeam = transactionValues.teamTax.mul(
            currentRate
        );
        reserveValues.reserveTransferAmountBurnEm = transactionValues
            .burnEm
            .mul(currentRate);

        reserveValues.reserveTransferAmount = reserveValues
            .reserveAmount
            .sub(reserveValues.reserveTransferAmountMarketing)
            .sub(reserveValues.reserveTransferAmountTeam)
            .sub(reserveValues.reserveTransferAmountBurnEm);

        return reserveValues;
    }

    function getRate() public view returns (uint256) {
        (uint256 reserveSupply, uint256 totalTokenSupply) = getCurrentSupply();
        return reserveSupply.div(totalTokenSupply);
    }

    function getCurrentSupply() public view returns (uint256, uint256) {
        uint256 reserveSupply = _totalReserve;
        uint256 totalTokenSupply = _totalSupply;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _reserveTokenBalance[_excluded[i]] > reserveSupply ||
                _circulatingTokenBalance[_excluded[i]] > totalTokenSupply
            ) return (_totalReserve, _totalSupply);
            reserveSupply = reserveSupply.sub(
                _reserveTokenBalance[_excluded[i]]
            );
            totalTokenSupply = totalTokenSupply.sub(
                _circulatingTokenBalance[_excluded[i]]
            );
        }
        if (reserveSupply < _totalReserve.div(_totalSupply))
            return (_totalReserve, _totalSupply);
        return (reserveSupply, totalTokenSupply);
    }
}





                     
// ___  __ ____ ___  ___
// \  \/ // __ \\  \/  /
//  \   /\  ___/ >    < 
//   \_/  \___  >__/\_ \
//            \/      \/
//
/// vexcooler.eth /// anonX


