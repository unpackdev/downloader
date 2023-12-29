// SPDX-License-Identifier: MIT
/*
GAME: https://pignomic.com/
DOCS: https://pignomic.gitbook.io/a-fence-game/
TWITTER: https://twitter.com/PigNomics
TELEGRAM: https://t.me/+NQ81KyTN_lM2ODVh
     .....::::.......                                                 .......::::.....    
   ---:::::::::......:::..                                       .::::.....:::::::::----  
   =*********++==--::...::-:                                  .::::..:::-==+++*********:  
    -***#########*+=-::...::-:                               --::..::--=+##%#######**+:   
    .=++++++++***##*=--::..::--     ....:::::::::::....    .--::::::-=+*##**+++++++++=    
     :=+=----====++**=--:::::---:----::::::::::::::::-----:---:::::--=**+=====----=+=.    
      -==--------==++=----------:::::::::::::::::::::::::::----------=*+==--------==:     
       :==--------=++====----:::::::::::::::::::::::::::::::::----====++=--------==:      
        :=-------=++===----:::::::::::::...........:::::::::::::----===+=---------.       
         .------==++==----::::::::::...................::::::::::----==++=-------.        
          .-=--=++==-----:::::::::.......................:::::::::-----=++==---:          
            .-+++==-----:::::::::.........................:::::::::-----==+++-.           
               -==-----:::::::::...........................:::::::::-----==-              
              :===-----::::::::.............................::::::::-----===.             
             .===-----::::::::..............................:::::::::-----===.            
            .====-----::::::::..............................:::::::::-----====.           
           .=====----::::--::::.............................::::-::::-----=====           
           -====-----:-*#**%*-:::.........................:::=##**#+::----=====:          
          .=====----:-%%++++@%-:::......................:::-=@%++++@*::---======          
          -=====---::*@@@@@@@@+-:::....................::::-#@@@@@@@@-::---====+:         
         .======---:.%@@%%%@@@*-::::...................:::--#@@%%%%@@+.:---======         
         :+=====---:.#@%%%%%@@=-::::::::::::::::::::::::::--*@%%%%%%@=.:---=====+.        
         -+=====---::=@%%##%@#---:::::------===------:::::--=%%%##%%%:::---=====+:        
         =+=====----::+%@%%%*-------=======----========------=#%%%%#-::----=====+-        
         ++=====----::::---::----====----------------=====----:---:::::----====++-        
         +++====-----:::::::----=+=---------------------=+=---::::::::-----====++-        
         =+++====-----::::::---++===++======--=======+====+=---::::::-----====+++-        
         -++++===-------:-----=+==+%@@%+===========*%@@#===+=------------====++++:        
         .+++++===-----------=++==#@@@@*===========#@@@@+==++=----------====+++++         
          =+++++====--------==*+==*@%@%+===========*%%%%+==++==--------====++++*-         
          .*+++++====-------==**++=+*+==============+**+=++*+=--------====++++*+          
           -**+++++====------=+***+++++++++++++++++++++++***==------====++++***.          
            :***++++====-----==+*#**********************##*===-----===+++++***:           
             .+***++++====---====+*#####################*+====--=====++++***=.            
               =*****+++=======**+==+++*************++===+**======++++*****:              
                .+*****+++++===-=*##*+===============+*##+=-===++++******=                
                  :=*#*****+++++====+*###############*+====+++++*******-.                 
                     .-+*##*******+++++++++++++++++++++++*******##*+-.                    
                         .-=+*####***********************####*+=:.                        
                               ..:--==+++*********+++==-::..       
*/
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./PRBMathUD60x18.sol";

contract FenceGameContract is ERC20, Ownable, ReentrancyGuard {
    using PRBMathUD60x18 for uint256;
    uint256 public constant TOTAL_SUPPLY = 100_000_000 * 1e18;
    uint256 public constant BLOCK_INCREMENT = 10000;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    bool public limitsEnabled = true;
    bool public sniperTaxEnabled = true;
    bool public claimsEnabled = false;
    uint256 public tradeLimit;

    // block last buyer can sell tax free
    uint256 public freeBlock;
    address public lastBuyer;
    uint256 public threshold;
    uint256 public thresholdIncrement = 2;
    uint256 public passes;
    uint256 public passReward;
    uint256 public numberOfPassers = 0;

    // how many times min has been over
    uint256 public growthRate;
    uint256 public penalty;
    uint256 public passesVault;
    uint256 public winnersVault;
    error WalletLimitExceeded();
    event PenaltySet(uint256 penalty);
    event ChargePenalty(uint256 penalty, address from, address to);
    event SwapEvent(uint256 amount, address from, address to);
    event CrashFence();
    event SellTax(uint256 amount);

    mapping(address => bool) internal _exempt;
    mapping(address => uint256) public passedAddresses;
    mapping(address => uint256) public claimRequirements;

    constructor() ERC20("A Fence Game", "FENCE") {
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        lastBuyer = address(this);
        freeBlock = block.number + BLOCK_INCREMENT;
        passes = 0;
        growthRate = 1 * 1e18;
        threshold = thresholdIncrement;
        _mint(address(this), TOTAL_SUPPLY);
        tradeLimit = _applyBasisPoints(TOTAL_SUPPLY, 250); // 2.5%
        _exempt[owner()] = true;
        _exempt[address(this)] = true;
    }

    function openTrading() external onlyOwner {
        _approve(address(this), address(uniswapV2Router), TOTAL_SUPPLY);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(uniswapV2Pair).transfer(
            owner(),
            IERC20(uniswapV2Pair).balanceOf(address(this))
        );
        _exempt[address(uniswapV2Router)] = true;
    }

    //Limits will be removed once a certain amount of holders have been reached (~15 mins)
    function removeLimitsAndRenounce() external onlyOwner {
        limitsEnabled = false;
        renounceOwnership();
    }

    //Anti snipe tax will be up until official contract announcement is made on the main twitter acount. (~15 mins)
    function removeSniperTax() external onlyOwner {
        sniperTaxEnabled = false;
    }

    receive() external payable {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        emit SwapEvent(amount, from, to);
        if (
            to == uniswapV2Pair && block.number > freeBlock && from == lastBuyer
        ) {
            // RESET AND LAST BUYER GETS ALL THE TOKENS
            _reset();
            super._transfer(from, to, amount);
            return;
        }

        if (
            from == uniswapV2Pair &&
            amount >= _applyBasisPoints(TOTAL_SUPPLY, threshold)
        ) {
            _passedFence(to);
            _setPenalty();
        }
        super._transfer(from, to, _chargePenalty(from, to, amount));
    }

    function _passedFence(address _lastBuyer) internal {
        claimRequirements[_lastBuyer] += threshold;
        if (passedAddresses[_lastBuyer] == 0) {
            numberOfPassers += 1;
        }
        passes += 1;
        //update threshold
        threshold = thresholdIncrement * passes;
        freeBlock = block.number + BLOCK_INCREMENT;
        lastBuyer = _lastBuyer;
        passedAddresses[_lastBuyer] += 1;
    }

    function _setPenalty() internal {
        growthRate = growthRate.mul(1130000000000000000);
        if (growthRate / 1e18 > 100) {
            return;
        }
        penalty = growthRate / 1e18;
        emit PenaltySet(penalty);
    }

    function _reset() internal {
        emit CrashFence();
        penalty = 0;
        passes = 0;
    }

    function claim() external nonReentrant {
        require(block.number > freeBlock, "Round is not over");
        if (passedAddresses[msg.sender] > 0) {
            if (msg.sender == lastBuyer && !claimsEnabled) {
                _winnerClaim();
            }
            if (claimRequirements[msg.sender] > balanceOf(msg.sender)) {
                return;
            }
            uint256 addressPasses = passedAddresses[msg.sender];
            passedAddresses[msg.sender] = 0;
            super._transfer(
                address(this),
                lastBuyer,
                addressPasses * passReward
            );
        }
    }

    function _winnerClaim() internal {
        require(!claimsEnabled, "Winner already claimed");
        claimsEnabled = true;
        passesVault = balanceOf(address(this)) / 2;
        passReward = passesVault / passes;
        winnersVault = balanceOf(address(this)) / 2;
        super._transfer(address(this), lastBuyer, winnersVault);
    }

    function _applyBasisPoints(uint256 amount, uint256 basisPoints)
        internal
        pure
        returns (uint256)
    {
        return (amount * basisPoints) / 10_000;
    }

    function _chargePenalty(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (_exempt[from] || _exempt[to]) {
            return amount;
        }
        uint256 fees = _applyBasisPoints(amount, penalty * 100);
        //Buy penalty reduces to 1%
        if (from == address(uniswapV2Router)) {
            fees = _applyBasisPoints(amount, 100);
        }
        //Anti snipe tax penalty 25%%
        if (sniperTaxEnabled) {
            fees = _applyBasisPoints(amount, 2500);
        }
        //Limit to 2.5%
        if (limitsEnabled) {
            fees = _handleLimits(amount, fees);
        }
        emit ChargePenalty(fees, from, to);
        super._transfer(from, address(this), fees);

        return amount - fees;
    }

    function _handleLimits(uint256 amount, uint256 currentFees)
        internal
        view
        returns (uint256)
    {
        uint256 recieve = amount - currentFees;
        if (recieve > tradeLimit) {
            return recieve - tradeLimit + currentFees;
        }
        return currentFees;
    }
}
