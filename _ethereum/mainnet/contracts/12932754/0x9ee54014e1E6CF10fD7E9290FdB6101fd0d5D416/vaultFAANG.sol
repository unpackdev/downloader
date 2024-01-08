//SPDX-License-Identifier: MIT" 
pragma solidity 0.7.6;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./BaseRelayRecipient.sol";
import "./IUniswapV2Router02.sol";

interface IStrategy {
    function deposit(uint _amount, IERC20 _token) external;
    function getTotalValueInPool() external view returns (uint256);
    function withdraw(uint256 amount, address token) external;
    function withdrawAllFunds(IERC20 _token) external;
    function yield() external ;
    function setCommunityWallet(address) external;
    function setTreasuryWallet(address) external;
    function setStrategist(address) external;
}

contract FAANGVault is ERC20("DAO Vault Stonks", "daoSTO"), Ownable, BaseRelayRecipient{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    IERC20 public constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IUniswapV2Router02 public constant Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IStrategy public strategy;

    mapping(address => uint256)public depositedAmount;
    
    address public treasuryWallet;
    address public admin;
    address public pendingStrategy;
    address public communityWallet;
    address public strategist;
    
    uint256 public unlockTime;
    uint256 public constant LOCKTIME = 2 days;
    uint256 public fee = 20; //20%
    uint256 usdcPercInVault = 5; //5%
    uint256 daiPercInVault = 5 ; //5%
    uint256 usdtPercInVault = 5; //5%
    
    uint256[] public networkFeeTier2 = [50000*1e18+1, 100000*1e18];
    uint256 public customNetworkFeeTier = 1000000*1e18;
    uint256[] public networkFeePerc = [100, 75, 50];
    uint256 public customNetworkFeePerc = 25;
    
    bool public canSetPendingStrategy = true;
    
    bool public isEmergency;
    IERC20 tokenWithdrawnInEmergency;
    
    event Deposit(address indexed from, address indexed token, uint amount, uint sharesMinted);
    event Withdraw(address indexed from, address indexed token, uint amount, uint sharesBurned);
    event migrateFunds(address indexed newStrategy, uint amount);
    event SetAdmin(address oldAdmin, address newAdmin);
    event SetTreasuryWallet(address oldTreasury, address newTreasury);
    event SetPendingStrategy(address newStrategy);
    event UnlockMigrateFunds(uint unlockTime);
    event EmergencyWithdraw(address admin);
    event SetBiconomy(address biconomy);
    event SetCommunityWallet(address oldCommunityWallet, address newcommunityWallet);
    event SetStrategistWallet(address oldStrategistWallet, address newStrategistWallet);
    event SetWithdrawlFee(uint fee);
    event SetNetworkFeePerc(uint256[] oldNetworkFeePerc, uint256[] newNetworkFeePerc);
    event SetCustomNetworkFeePerc(uint256 oldCustomNetworkFeePerc, uint256 newCustomNetworkFeePerc);


    constructor(address _treasuryWallet, address _admin, address _strategy, address _biconomy, address _communityWallet, address _strategist) {
        admin = _admin;
        treasuryWallet = _treasuryWallet;        
        strategy = IStrategy(_strategy);
        trustedForwarder = _biconomy;
        communityWallet = _communityWallet;
        strategist = _strategist;

        DAI.safeApprove(_strategy, type(uint).max);
        USDC.safeApprove(_strategy, type(uint).max);
        USDT.safeApprove(_strategy, type(uint).max);


        DAI.safeApprove(address(Router), type(uint).max);
        USDC.safeApprove(address(Router), type(uint).max);
        USDT.safeApprove(address(Router), type(uint).max);
    }

    modifier onlyEOA {
        require(msg.sender == tx.origin, "Only EOA");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin");
        _;
    }
    
    function _msgSender() internal override(Context, BaseRelayRecipient) view returns (address payable) {
        return BaseRelayRecipient._msgSender();
    }
    
    
    function versionRecipient() external pure override returns (string memory) {
        return "1";
    }

    function setPendingStrategy(address _strategy) external onlyOwner{
        require(_strategy != address(0), "Invalid address");
        require(canSetPendingStrategy, "Cannot set new strategy");  

        pendingStrategy = _strategy;
        emit SetPendingStrategy(_strategy);
    }

    function setAmountToKeepInVaultPerc(uint _daiPercentage, uint _usdcPercentage, uint usdtPercentage) external onlyAdmin{
        usdcPercInVault = _usdcPercentage;
        daiPercInVault = _daiPercentage;
        usdtPercInVault = usdtPercentage;
    }

    function setAdmin(address _newAdmin) external onlyOwner{
        require(_newAdmin != address(0), "ZERO_ADDRESS");
        address oldAdmin = admin;
        admin = _newAdmin;        

        emit SetAdmin(oldAdmin, _newAdmin);
    }

    function setTreasuryWallet(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "ZERO_ADDRESS");
        
        address oldTreasury = treasuryWallet;
        treasuryWallet = _newTreasury;
        strategy.setTreasuryWallet(_newTreasury);

        emit SetTreasuryWallet(oldTreasury, _newTreasury);
    }

    function setCommunityWallet(address _newCommunityWallet) external onlyOwner {
        require(_newCommunityWallet != address(0), "ZERO_ADDRESS");
        
        address oldCommunityWallet = communityWallet;
        communityWallet = _newCommunityWallet;
        strategy.setCommunityWallet(_newCommunityWallet);

        emit SetCommunityWallet(oldCommunityWallet, _newCommunityWallet);
    }

    function setStrategistWallet(address _strategist) external onlyOwner {
        require(msg.sender == owner() || msg.sender == strategist, "Only owner or strategist");
        require(_strategist != address(0), "ZERO_ADDRESS");
        
        address oldStrategistWallet = strategist;
        strategist = _strategist;
        strategy.setStrategist(_strategist);

        emit SetStrategistWallet(oldStrategistWallet, _strategist);
    }


    function setWithdrawalFee(uint _fee) external onlyOwner{
        fee = _fee;
        emit SetWithdrawlFee(_fee);
    }
    
    function setNetworkFeePerc(uint256[] calldata _networkFeePerc) external onlyOwner {
        require(
            _networkFeePerc[0] < 3000 &&
                _networkFeePerc[1] < 3000 &&
                _networkFeePerc[2] < 3000,
            "Network fee percentage cannot be more than 30%"
        );
        /**
         * _networkFeePerc content a array of 3 element, representing network fee of tier 1, tier 2 and tier 3
         * For example networkFeePerc is [100, 75, 50]
         * which mean network fee for Tier 1 = 1%, Tier 2 = 0.75% and Tier 3 = 0.5%
         */
        uint256[] memory oldNetworkFeePerc = networkFeePerc;
        networkFeePerc = _networkFeePerc;
        emit SetNetworkFeePerc(oldNetworkFeePerc, _networkFeePerc);
    }

    /// @notice Function to set new custom network fee percentage
    /// @param _percentage Percentage of new custom network fee
    function setCustomNetworkFeePerc(uint256 _percentage) public onlyOwner {
        require(_percentage < networkFeePerc[2], "Custom network fee percentage cannot be more than tier 2");

        uint256 oldCustomNetworkFeePerc = customNetworkFeePerc;
        customNetworkFeePerc = _percentage;
        emit SetCustomNetworkFeePerc(oldCustomNetworkFeePerc, _percentage);
    }

    function setBiconomy(address _biconomy) external onlyOwner {
        trustedForwarder = _biconomy;
        emit SetBiconomy(_biconomy);
    }

    function deposit(uint256 _amount, IERC20 _token) external {
        require(msg.sender == tx.origin || isTrustedForwarder(msg.sender), "Only EOA or Biconomy");
        require(isEmergency == false, "Cannot call when in emergencyMode");
        require(_amount > 0, "Invalid amount");
        uint256 shares;
        address _sender = _msgSender();
        if (_token == DAI) {
            (uint amountAfterFee, uint _fee) = _calcNetworkFee(_amount);

            shares = totalSupply() == 0
                ? amountAfterFee
                : amountAfterFee.mul(totalSupply()).div(getTotalValueInPool());
            DAI.safeTransferFrom(_sender, address(this), _amount);

            uint _treasuryFee =  _fee.mul(2).div(5); // 40%
            
            DAI.safeTransfer(treasuryWallet, _treasuryFee);
            DAI.safeTransfer(communityWallet, _treasuryFee);
            DAI.safeTransfer(strategist, _fee.sub(_treasuryFee).sub(_treasuryFee));
            depositedAmount[_sender] = depositedAmount[_sender].add(amountAfterFee);
            
        } else if (_token == USDC) {
            
            // uint _amountMagnified = _amount.mul(1e12);
            (uint amountAfterFee, uint _fee) = _calcNetworkFee(_amount.mul(1e12));
            shares = totalSupply() == 0
                ? amountAfterFee
                : amountAfterFee.mul(totalSupply()).div(
                    getTotalValueInPool());

            USDC.safeTransferFrom(_sender, address(this), _amount);
            
            uint feeReduced = _fee.div(1e12);
            uint _treasuryFee =  feeReduced.mul(2).div(5); // 40%
            
            USDC.safeTransfer(treasuryWallet, _treasuryFee);
            USDC.safeTransfer(communityWallet, _treasuryFee);
            USDC.safeTransfer(strategist, feeReduced.sub(_treasuryFee).sub(_treasuryFee));
            
            depositedAmount[_sender] = depositedAmount[_sender].add(amountAfterFee);
        } else if (_token == USDT) {

            (uint amountAfterFee, uint _fee) = _calcNetworkFee(_amount.mul(1e12));
            
            shares = totalSupply() == 0
                ? amountAfterFee
                : amountAfterFee.mul(totalSupply()).div(getTotalValueInPool());
            
            USDT.safeTransferFrom(_sender, address(this), _amount);

            uint feeReduced = _fee.div(1e12);
            uint _treasuryFee =  feeReduced.mul(2).div(5); // 40%
            
            USDT.safeTransfer(treasuryWallet, _treasuryFee);
            USDT.safeTransfer(communityWallet, _treasuryFee);
            USDT.safeTransfer(strategist, feeReduced.sub(_treasuryFee).sub(_treasuryFee));
            depositedAmount[_sender] = depositedAmount[_sender].add(amountAfterFee);
        } else {
            revert("Invalid deposit Token");
        }

        
        
        _mint(_sender, shares);
        emit Deposit(_sender, address(_token), _amount, shares);
    }

    function withdraw(uint256 _shares, IERC20 _token) external onlyEOA {
        require(_token == DAI || _token == USDC || _token == USDT, "Invalid token");
        require(_shares > 0, "Invalid amount");
        uint256 _totalShares = balanceOf(msg.sender);
        require(_totalShares >= _shares, "Insuffient funds");

        uint256 amountDeposited = depositedAmount[msg.sender].mul(_shares).div(_totalShares);
        depositedAmount[msg.sender] = depositedAmount[msg.sender].sub(amountDeposited);
        
        uint256 amountToWithdraw = getTotalValueInPool().mul(_shares).div(totalSupply());
        
        
        
        uint balanceInContract = _token == DAI ? _token.balanceOf(address(this)) : _token.balanceOf(address(this)).mul(1e12);
        
        if(balanceInContract < amountToWithdraw) {

            if(isEmergency == true && _token != tokenWithdrawnInEmergency) {
                //value in strategy is zero during emergency
                //balanceInContract is less means emergencyWithdraw() was called with a different token. 
                //so convert to user's token
                address[] memory path = new address[](2);
                path[0] = address(tokenWithdrawnInEmergency);
                path[1] = address(_token);

                //using amountToWithdraw as first parameter because, in normal case `amountToWithdraw` is removed from the contract.
                Router.swapExactTokensForTokens(_token == DAI ? amountToWithdraw.sub(balanceInContract) : amountToWithdraw.sub(balanceInContract).div(1e12), 0, path, address(this), block.timestamp);
            } 

            if(isEmergency == false) {
                strategy.withdraw(amountToWithdraw.sub(balanceInContract), address(_token));
            }
            
            
        }

        if (amountToWithdraw > amountDeposited) {
            uint256 _profit = amountToWithdraw.sub(amountDeposited);
            uint256 _feeTotal = _profit.mul(fee).div(100); //20% fee
            amountToWithdraw = amountToWithdraw.sub(_feeTotal);

            if(_token != DAI) {
                uint _feeReduced = _feeTotal.div(1e12);
                uint _fee = _feeReduced.mul(2).div(5);
                _token.safeTransfer(treasuryWallet, _fee);    
                _token.safeTransfer(communityWallet, _fee);    
                _token.safeTransfer(strategist, _feeReduced.sub(_fee).sub(_fee));    
            } else {
                uint _fee = _feeTotal.mul(2).div(5);
                _token.safeTransfer(treasuryWallet, _fee);
                _token.safeTransfer(communityWallet, _fee);    
                _token.safeTransfer(strategist, _feeTotal.sub(_fee).sub(_fee));    
            }
            
        }

        if(_token != DAI) {
            amountToWithdraw = amountToWithdraw.div(1e12);
        }

        _burn(msg.sender, _shares);
        
        balanceInContract = _token.balanceOf(address(this));
        amountToWithdraw = amountToWithdraw > balanceInContract ? balanceInContract : amountToWithdraw;
        _token.safeTransfer(msg.sender, amountToWithdraw);        
        emit Withdraw(msg.sender, address(_token), amountToWithdraw, _shares);
    }
    /**
        @notice harvests from farms
     */
    function yield() external onlyAdmin {
        require(isEmergency == false, "Cannot call when in emergencyMode");
        strategy.yield();
    }

    /**
        @notice Move funds to strategy and add to farms
     */
    function invest() external onlyAdmin {
        require(isEmergency == false, "Cannot call when in emergencyMode");
        uint daiBalance = DAI.balanceOf(address(this));

        uint ValueInPool = getTotalValueInPool();

        if(daiBalance > 0) {
            uint daiAmountToKeep = ValueInPool.mul(daiPercInVault).div(100);
            
            if(daiBalance > daiAmountToKeep) {
                strategy.deposit(daiBalance.sub(daiAmountToKeep), DAI);
            }
        }

        uint usdcBalance = USDC.balanceOf(address(this));
        if(usdcBalance > 0) {
            uint usdcAmountToKeep = ValueInPool.mul(usdcPercInVault).div(100).div(1e12);

            if(usdcBalance > usdcAmountToKeep) {
                strategy.deposit(usdcBalance.sub(usdcAmountToKeep), USDC);    
            }
        }

        uint usdtBalance = USDT.balanceOf(address(this));
        if(usdtBalance > 0) {
            uint usdtAmountToKeep = ValueInPool.mul(usdtPercInVault).div(100).div(1e12);

            if(usdtBalance > usdtAmountToKeep) {
                strategy.deposit(usdtBalance.sub(usdtAmountToKeep), USDT);
            }
        }
    }
    /**
        @notice This function reinvests the funds withdrawn during emergency to same strategy
     */
    function reInvest() external onlyAdmin {
        isEmergency = false; 

        uint daiBalance = DAI.balanceOf(address(this));

        uint ValueInPool = getTotalValueInPool();

        if(daiBalance > 0) {
            uint daiAmountToKeep = ValueInPool.mul(daiPercInVault).div(100);
            
            if(daiBalance > daiAmountToKeep) {
                strategy.deposit(daiBalance.sub(daiAmountToKeep), DAI);
            }
        }

        uint usdcBalance = USDC.balanceOf(address(this));
        if(usdcBalance > 0) {
            uint usdcAmountToKeep = ValueInPool.mul(usdcPercInVault).div(100).div(1e12);

            if(usdcBalance > usdcAmountToKeep) {
                strategy.deposit(usdcBalance.sub(usdcAmountToKeep), USDC);    
            }
        }

        uint usdtBalance = USDT.balanceOf(address(this));
        if(usdtBalance > 0) {
            uint usdtAmountToKeep = ValueInPool.mul(usdtPercInVault).div(100).div(1e12);

            if(usdtBalance > usdtAmountToKeep) {
                strategy.deposit(usdtBalance.sub(usdtAmountToKeep), USDT);
            }
        }
    }

    function migrateFund(IERC20 _token) external onlyOwner{
        require(unlockTime <= block.timestamp && unlockTime.add(1 days) >= block.timestamp, "Function locked");
        require(_token == DAI || _token == USDC || _token == USDT, "Invalid token");
        require(isEmergency == false, "Cannot call when in emergencyMode");

        uint balanceBefore = _token.balanceOf(address(this));

        strategy.withdrawAllFunds(_token);

        uint balanceAfter = _token.balanceOf(address(this));

        strategy = IStrategy(pendingStrategy);

        DAI.safeApprove(pendingStrategy, type(uint).max);
        USDC.safeApprove(pendingStrategy, type(uint).max);
        USDT.safeApprove(pendingStrategy, type(uint).max);

        //deposit only the withdrawn amount to new strategy
        strategy.deposit(balanceAfter.sub(balanceBefore), _token);

        canSetPendingStrategy = true;

        emit migrateFunds(pendingStrategy, balanceAfter.sub(balanceBefore));

    }

    function unlockMigrateFunds() external onlyOwner{
        unlockTime = block.timestamp.add(LOCKTIME);
        canSetPendingStrategy = false;

        emit UnlockMigrateFunds(unlockTime);
    }

    function emergencyWithdraw(IERC20 _token) external onlyAdmin {
        require(_token == DAI || _token == USDC || _token == USDT, "Invalid token");

        strategy.withdrawAllFunds(_token);
        isEmergency = true;
        tokenWithdrawnInEmergency = _token;


        emit EmergencyWithdraw(admin);
    }

    function _calcNetworkFee(uint _amount) internal view returns (uint _amountAfterFee, uint _fee) {
        uint256 _networkFeePerc;
        if (_amount < networkFeeTier2[0]) {
            // Tier 1
            _networkFeePerc = networkFeePerc[0];
        } else if (_amount <= networkFeeTier2[1]) {
            // Tier 2
            _networkFeePerc = networkFeePerc[1];
        } else if (_amount < customNetworkFeeTier) {
            // Tier 3
            _networkFeePerc = networkFeePerc[2];
        } else {
            // Custom Tier
            _networkFeePerc = customNetworkFeePerc;
        }
        _fee = _amount.mul(_networkFeePerc).div(10000);
        
        _amountAfterFee = _amount.sub(_fee);
    }

    function getTotalValueInPool() public view returns (uint) {
        return strategy.getTotalValueInPool().add(DAI.balanceOf(address(this)))
        .add(USDC.balanceOf(address(this)).mul(1e12))
        .add(USDT.balanceOf(address(this)).mul(1e12));
    }


}
