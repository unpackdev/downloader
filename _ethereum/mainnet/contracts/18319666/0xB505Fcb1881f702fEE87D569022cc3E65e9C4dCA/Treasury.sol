//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IAddressContract.sol";
import "./IUniswap.sol";
 
interface ScarabToken is IERC20Upgradeable {
    function burn(uint amount) external;
}

interface IERC721  {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract Treasury is OwnableUpgradeable, ReentrancyGuardUpgradeable {
 
    // state vars
    ScarabToken public scarab;
    IERC721 public nft;
    IUniswapV2Router public router;
    
    uint public deitiesProfit;
    uint public buyBackandBurn;
    uint public communityProfit;

    uint public pendingProfitDeities;

    uint public totalBuyBackAndBurn;
    uint public totalCommunityProfit;

    uint public totalProfitDeities;
    uint public totalAmountAllocated;
    uint public totalAmountRefunded;

    mapping (uint => uint) public pendingProfitDeity;

    address public weth;
    address public dao;
    address public barac;


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
        deitiesProfit = 3000;
        buyBackandBurn = 500;
        communityProfit = 4000;
    }

    receive() external payable {}

    function setContractAddresses(IAddressContract _contractFactory) external onlyOwner {
        scarab =  ScarabToken(_contractFactory.getScarab());
        weth = router.WETH();
        scarab.approve(address(router), type(uint256).max);
        dao = _contractFactory.getDao();
        barac = _contractFactory.getBarac();
        nft = IERC721(_contractFactory.getScarabNFT());
    }

    function distributeProfit(uint256 proposalId, uint256 deityId, uint256 _lendingAmount, uint256 _refundAmount) external payable onlyDao {
        
        totalAmountRefunded = totalAmountRefunded + msg.value;

        if (_refundAmount > _lendingAmount) {     
            uint profit = _refundAmount - _lendingAmount; // 0.012 - 0.005
            uint beforeSwapBal = scarab.balanceOf(address(this));
            swapEthforTokens(profit);
            uint afterSwapBal = scarab.balanceOf(address(this));
            uint tokenBal = afterSwapBal - beforeSwapBal;

            uint deityProfit = (tokenBal * deitiesProfit) / 10000;
            uint communityTokens = (tokenBal * communityProfit) / 10000;
            uint burnBal = (tokenBal * buyBackandBurn) / 10000;
            totalBuyBackAndBurn += burnBal;
            totalCommunityProfit += communityTokens;
            pendingProfitDeities += deityProfit;
            pendingProfitDeity[deityId] += deityProfit;

            scarab.burn(burnBal);
            require(scarab.transfer(barac, communityTokens), "distributeProfit:: Tokens transfer failed");
            emit DistributeProft(proposalId, profit);
        }

        // swap remaining tokens to eth 
        uint remainingTokens = scarab.balanceOf(address(this)) - pendingProfitDeities;
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

    function settleDeitiesProfit(uint _deityId) external {
        require(nft.ownerOf(_deityId) == msg.sender, "settleDeitiesProfit:: Unauthorized!");
        uint amount = pendingProfitDeity[_deityId];
        totalProfitDeities = totalProfitDeities + amount;
        pendingProfitDeities = pendingProfitDeities - amount;
        pendingProfitDeity[_deityId] = 0;
        require(scarab.transfer(msg.sender, amount), "settleDeitiesProfit:: Tokens transfer failed");
    }

    function changeProfitShares(uint _buybackAndburnShare, uint _communityShare, uint _deitiesShare) external onlyOwner {

        if (_buybackAndburnShare + _communityShare + _deitiesShare <= 10_000) {
            revert("changeProfitShares:: wrong shares");
        } 

        deitiesProfit = _deitiesShare; 
        buyBackandBurn = _buybackAndburnShare; 
        communityProfit = _communityShare;
    }

    function swapScarab() external onlyOwner {
        uint remainingTokens = scarab.balanceOf(address(this)) - pendingProfitDeities;
        if (remainingTokens > 0) {
            swapTokensforEth(remainingTokens);
        }
    }

    function getExpectedScrabToken(uint _amount) external view returns(uint) {
        address pairAddress =  IUniswapV2Factory(router.factory()).getPair(address(scarab), weth);
        address token0 = IUniswapV2Pair(pairAddress).token0();

        address[] memory _path = new address[](2);

        if (token0 == weth) {
            _path[0] = weth;
            _path[1] = address(scarab);
            uint[] memory amount = router.getAmountsOut(_amount, _path);
            return amount[1];
        }
        else {
            _path[0] = address(scarab);
            _path[1] = weth;
            uint[] memory amount = router.getAmountsIn(_amount, _path);
            return amount[0];
        }    
    }

    function getExpectedEth(uint _amount) external view returns(uint) {
        address pairAddress =  IUniswapV2Factory(router.factory()).getPair(address(scarab), weth);
        address token0 = IUniswapV2Pair(pairAddress).token0();

        address[] memory _path = new address[](2);

        if (token0 == weth) {
            _path[0] = address(scarab);
            _path[1] = weth;
            uint[] memory amount = router.getAmountsOut(_amount, _path);
            return amount[1];
        }
        else {
            _path[0] = weth;
            _path[1] = address(scarab);
            uint[] memory amount = router.getAmountsIn(_amount, _path);
            return amount[0];
        }    
    }

    function swapTokensforEth(uint _amount) internal  {
        address[] memory path = new address[](2);
        path[0] = address(scarab);
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
        path[1] = address(scarab);
        path[0] = weth;

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amount}(
            0,
            path,
            address(this),
            block.timestamp + 300
        );
    }

}
