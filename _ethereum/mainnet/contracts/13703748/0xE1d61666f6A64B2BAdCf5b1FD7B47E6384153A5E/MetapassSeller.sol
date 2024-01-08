// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ERC1155Receiver.sol";
import "./IUniswapV2Router01.sol";
import "./ILicenseProvider.sol";



contract MetapassSeller is ERC1155Receiver,Ownable{
    
    Router public sushiRouter = Router(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    Router public uniswapRouter = Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    ILicenseProvider public licenseProvider = ILicenseProvider(0xF180e8a747dE77469D5B9258106913D9719D7440);
    IERC1155 public MetaPassContract = IERC1155(0xEF7862d6cDf0e2Fb28374bCb32fA2e425FC8a8dF);

    mapping(address => mapping(uint256 => uint256)) public prices;

    fallback() external payable {
        // custom function code
    }

    receive() external payable {
        // custom function code
    }

    function withdrawERC1155(address contractAddress,uint256 tokenId,uint256 amount) external onlyOwner{
        IERC1155 assetContract = IERC1155(contractAddress);
        assetContract.safeTransferFrom(address(this), msg.sender, tokenId, amount,"");
    }

    function withdrawERC20(address contractAddress,uint256 amount) external onlyOwner{
        IERC20 assetContract = IERC20(contractAddress);
        assetContract.transferFrom(address(this), msg.sender, amount);
    }

    function withdrawETH(uint256 amount) external onlyOwner{
        payable(msg.sender).transfer(amount);
    }

    function addPaymentMethod(address contractAddr, uint256 price, uint256 subscriptionDays) public onlyOwner{
        prices[contractAddr][subscriptionDays]=price;
    }

    function collectAndSwap(address contractAddr, uint256 ethAmount, Router router) internal{
        address[] memory path = new address[](2);
        path[0]=address(contractAddr);
        path[1]=router.WETH();
        uint256 amount = router.getAmountsIn(ethAmount,path)[0];
        IERC20(contractAddr).transferFrom(msg.sender, address(this), amount);
        if(IERC20(contractAddr).allowance(address(this), address(router)) < amount){
            IERC20(contractAddr).approve(address(router), 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        }
        router.swapTokensForExactETH(ethAmount, amount, path, address(this), block.timestamp + 1);

    }

    function buyMetaPass(address contractAddr,bool sushi) external{        
        if(prices[contractAddr][0] == 0) revert("Pass not available");

        if(sushi){
           collectAndSwap(contractAddr, prices[contractAddr][0],sushiRouter); 
        }
        else{
            collectAndSwap(contractAddr, prices[contractAddr][0],uniswapRouter); 
        }

        MetaPassContract.safeTransferFrom(address(this), msg.sender, 8, 1, "");
    }   

    function buySubscription(address contractAddr, uint256 startDate,uint256 subscriptionDays, bool sushi) external {
        if(prices[contractAddr][subscriptionDays] == 0) revert("Subscription unavailable");

        if(sushi){
           collectAndSwap(contractAddr, prices[contractAddr][subscriptionDays],sushiRouter); 
        }
        else{
            collectAndSwap(contractAddr, prices[contractAddr][subscriptionDays],uniswapRouter); 
        }

        licenseProvider.setSubscription(msg.sender,startDate,subscriptionDays);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4){
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4){
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

}