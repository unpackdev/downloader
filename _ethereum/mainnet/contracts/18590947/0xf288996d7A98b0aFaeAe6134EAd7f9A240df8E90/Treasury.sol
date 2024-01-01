//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IAddressContract.sol";
import "./IUniswap.sol";
 
interface PirateToken is IERC20Upgradeable {
    function burn(uint amount) external;
}

interface IERC721  {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract Treasury is OwnableUpgradeable, ReentrancyGuardUpgradeable {
 
    // state vars
    PirateToken public pirate;
    IERC721 public nft;
    IUniswapV2Router public router;
    
    uint public piratesProfit;
    uint public buyBackandBurn;
    uint public communityProfit;

    uint public pendingProfitPirates;

    uint public totalBuyBackAndBurn;
    uint public totalCommunityProfit;

    uint public totalProfitPirates;
    uint public totalAmountAllocated;
    uint public totalAmountRefunded;

    mapping (uint => uint) public pendingProfitPirate;

    address public weth;
    address public dao;
    address public bounty;


    // events
    event DistributeProft(uint256 proposalId, uint256 profit);
    event FundsTransfer(uint256 proposalId, uint amount, address receiver);

    // modifiers
    modifier onlyDao() {
        require(msg.sender == dao, "Unauthorised:: not dao");
        _;
    }

    function initialize() external initializer {
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        piratesProfit = 2000;       //20%
        buyBackandBurn = 500;       //5%
        communityProfit = 4000;     //40%
    }

    receive() external payable {}

    function setContractAddresses(IAddressContract _contractFactory) external onlyOwner {
        pirate =  PirateToken(_contractFactory.getPirate());
        weth = router.WETH();
        pirate.approve(address(router), type(uint256).max);
        dao = _contractFactory.getDao();
        bounty = _contractFactory.getBounty();
        nft = IERC721(_contractFactory.getPirateNFT());
    }

    function distributeProfit(uint256 proposalId, uint256 pirateId, uint256 _lendingAmount, uint256 _refundAmount) external payable onlyDao {
        
        totalAmountRefunded = totalAmountRefunded + msg.value;

        if (_refundAmount > _lendingAmount) {     
            uint profit = _refundAmount - _lendingAmount; // 0.012 - 0.005
            uint beforeSwapBal = pirate.balanceOf(address(this));
            swapEthforTokens(profit);
            uint afterSwapBal = pirate.balanceOf(address(this));
            uint tokenBal = afterSwapBal - beforeSwapBal;

            uint pirateProfit = (tokenBal * piratesProfit) / 10000;
            uint communityTokens = (tokenBal * communityProfit) / 10000;
            uint burnBal = (tokenBal * buyBackandBurn) / 10000;
            totalBuyBackAndBurn += burnBal;
            totalCommunityProfit += communityTokens;
            pendingProfitPirates += pirateProfit;
            pendingProfitPirate[pirateId] += pirateProfit;

            pirate.burn(burnBal);
            require(pirate.transfer(bounty, communityTokens), "distributeProfit:: Tokens transfer failed");
            emit DistributeProft(proposalId, profit);
        }

        // swap remaining tokens to eth 
        uint remainingTokens = pirate.balanceOf(address(this)) - pendingProfitPirates;
        if (remainingTokens > 0) {
            swapTokensforEth(remainingTokens);
        }
    }

    function fundTransfer(uint256 _proposalId, address _proposeeAdd, uint256 ethAmount) external onlyDao nonReentrant {
        uint256 balance = address(this).balance;
        totalAmountAllocated = totalAmountAllocated + ethAmount;
        
        if (ethAmount <  balance) {
            (bool sent, ) = address(_proposeeAdd).call{value: ethAmount}("");
            require(sent, "fundTransfer:: Failed to send funds");
            emit FundsTransfer(_proposalId, ethAmount, _proposeeAdd);
        } else {
            revert("fundTransfer:: Insufficient Treasury Fund");
        }
    }

    function settlePiratesProfit(uint _pirateId) external {
        require(nft.ownerOf(_pirateId) == msg.sender, "settlePiratesProfit:: Unauthorized!");
        uint amount = pendingProfitPirate[_pirateId];
        totalProfitPirates = totalProfitPirates + amount;
        pendingProfitPirates = pendingProfitPirates - amount;
        pendingProfitPirate[_pirateId] = 0;
        require(pirate.transfer(msg.sender, amount), "settlePiratesProfit:: Tokens transfer failed");
    }

    function changeProfitShares(uint _buybackAndburnShare, uint _communityShare, uint _piratesShare) external onlyOwner {

        if (_buybackAndburnShare + _communityShare + _piratesShare <= 10_000) {
            revert("changeProfitShares:: wrong shares");
        } 

        piratesProfit = _piratesShare; 
        buyBackandBurn = _buybackAndburnShare; 
        communityProfit = _communityShare;
    }

    function swapPirate() external onlyOwner {
        uint remainingTokens = pirate.balanceOf(address(this)) - pendingProfitPirates;
        if (remainingTokens > 0) {
            swapTokensforEth(remainingTokens);
        }
    }

    function getExpectedPirateToken(uint _amount) external view returns(uint) {
        address pairAddress =  IUniswapV2Factory(router.factory()).getPair(address(pirate), weth);
        address token0 = IUniswapV2Pair(pairAddress).token0();

        address[] memory _path = new address[](2);

        if (token0 == weth) {
            _path[0] = weth;
            _path[1] = address(pirate);
            uint[] memory amount = router.getAmountsOut(_amount, _path);
            return amount[1];
        }
        else {
            _path[0] = address(pirate);
            _path[1] = weth;
            uint[] memory amount = router.getAmountsIn(_amount, _path);
            return amount[0];
        }    
    }

    function getExpectedEth(uint _amount) external view returns(uint) {
        address pairAddress =  IUniswapV2Factory(router.factory()).getPair(address(pirate), weth);
        address token0 = IUniswapV2Pair(pairAddress).token0();

        address[] memory _path = new address[](2);

        if (token0 == weth) {
            _path[0] = address(pirate);
            _path[1] = weth;
            uint[] memory amount = router.getAmountsOut(_amount, _path);
            return amount[1];
        }
        else {
            _path[0] = weth;
            _path[1] = address(pirate);
            uint[] memory amount = router.getAmountsIn(_amount, _path);
            return amount[0];
        }    
    }

    function swapTokensforEth(uint _amount) internal  {
        address[] memory path = new address[](2);
        path[0] = address(pirate);
        path[1] = weth;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
           _amount,
            10,
            path,
            address(this),
            block.timestamp + 300
        );
    }

    function swapEthforTokens(uint _amount) internal  {
        address[] memory path = new address[](2);
        path[1] = address(pirate);
        path[0] = weth;

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amount}(
            0,
            path,
            address(this),
            block.timestamp + 300
        );
    }

    function extractFunds(address payable _receiver) external onlyOwner {
        uint ethAmount = address(this).balance;
        (bool sent, ) = address(_receiver).call{value: ethAmount}("");
        require(sent, "extractFunds:: Failed to send funds");
    }

}
