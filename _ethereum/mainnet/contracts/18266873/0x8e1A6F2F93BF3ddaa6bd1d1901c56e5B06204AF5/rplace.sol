// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.0;
import "./console.sol";
import "./ReentrancyGuard.sol";

//               88            oooo                                
//              .8'            `888                                
// oooo d8b    .8'  oo.ooooo.   888   .oooo.    .ooooo.   .ooooo.  
// `888""8P   .8'    888' `88b  888  `P  )88b  d88' `"Y8 d88' `88b 
//  888      .8'     888   888  888   .oP"888  888       888ooo888 
//  888     .8'      888   888  888  d8(  888  888   .o8 888    .o 
// d888b    88       888bod8P' o888o `Y888""8o `Y8bod8P' `Y8bod8P' 
//                   888                                           
//                  o888o     

contract DecentralizedRPlace is ReentrancyGuard {
    struct Plot {
        address owner;
        string color;
        uint256 currentPrice;
        uint256 previousPrice;
        bool minted;
    }

    uint256 public constant numTotalPlots = 8840; // total plots 8840
    Plot[numTotalPlots] public plots;
    address public deployer;
    event PlotPurchased(uint256 indexed index, address indexed newOwner, string color, uint256 price);

    constructor() {
        deployer = msg.sender;
    }

    function buyPlot(uint256 index, string memory _color) public payable nonReentrant {
        require(index < numTotalPlots, "Invalid plot index");
        require(bytes(_color).length == 6, "Color should be 6 characters long");
        require(msg.value >= plots[index].currentPrice, "Sent value must be at least the plot's price");

        for (uint256 i = 0; i < 6; i++) {
            bytes1 char = bytes(_color)[i];
            require((char >= bytes1('0') && char <= bytes1('9')) ||
                    (char >= bytes1('a') && char <= bytes1('f')) ||
                    (char >= bytes1('A') && char <= bytes1('F')), 
                    "Invalid hex character");
        }
        
        address previousOwner = plots[index].owner;
        uint256 previousPlotPrice = plots[index].previousPrice;
        emit PlotPurchased(index, msg.sender, _color, plots[index].currentPrice);

        // first mint                                            
        if (!plots[index].minted) {            
            plots[index].previousPrice = plots[index].currentPrice;
            plots[index].color = _color;
            plots[index].owner = msg.sender;
            plots[index].minted = true;
            plots[index].previousPrice = 0;
            plots[index].currentPrice = 0.01 ether;  // free mint, then 0.01 ETH.
        }
        // normal buy
        else { 
            uint256 newPrice = plots[index].currentPrice * 14 / 10; // increase price 1.4x
            plots[index].previousPrice = plots[index].currentPrice;
            plots[index].color = _color;
            plots[index].owner = msg.sender;
            plots[index].currentPrice = newPrice;

            if (previousPlotPrice == 0) {
                uint256 halfAmount = plots[index].previousPrice / 2; // calculate half of the plot's current price
                (bool successToPreviousOwner, ) = payable(previousOwner).call{value: halfAmount}("");
                require(successToPreviousOwner, "Transfer to previous owner failed");
                (bool successToDeployer, ) = payable(deployer).call{value: halfAmount}("");
                require(successToDeployer, "Transfer to deployer failed");
            }

            if (previousPlotPrice > 0) {
                uint256 amountToOwner = (previousPlotPrice * 12) / 10; // pay previous owner 1.2x
                uint256 remainderToDeployer = plots[index].previousPrice - amountToOwner; // 0.2x goes to deployer
                (bool successToPreviousOwner, ) = payable(previousOwner).call{value: amountToOwner}("");
                require(successToPreviousOwner, "Transfer to previous owner failed");
                (bool successToDeployer, ) = payable(deployer).call{value: remainderToDeployer}("");
                require(successToDeployer, "Transfer to deployer failed");
            }
        }
    }

    function buyMultiplePlots(uint256[] memory indices, string[] memory colors) public payable {
        require(indices.length == colors.length, "Indices and colors length mismatch");
        uint256 totalCost = 0;

        uint256[] memory usedIndices = new uint256[](indices.length);

        for (uint256 i = 0; i < indices.length; i++) {
            uint256 index = indices[i];
            require(index < numTotalPlots, "Invalid plot index");
            for(uint256 j = 0; j < i; j++) { 
                require(usedIndices[j] != index, "Index used multiple times in a single transaction");
            }
            usedIndices[i] = index;
            totalCost += plots[index].currentPrice;
        }
        require(msg.value >= totalCost, "Sent value must be at least the total plots' price");

        for (uint256 i = 0; i < indices.length; i++) {
            buyPlot(indices[i], colors[i]);
        }
    }

    function getPlotData(uint256 index) public view returns (address, string memory, uint256, uint256, bool) {
        require(index < numTotalPlots, "Invalid plot index");
        return (plots[index].owner, plots[index].color, plots[index].currentPrice, plots[index].previousPrice, plots[index].minted);
    }

    function batchGetPlotData(uint256 startIndex, uint256 endIndex) public view returns (Plot[] memory){
        require(endIndex >= startIndex, "End index must be greater than or equal to start index");
        require(endIndex < numTotalPlots, "End index out of bounds");
        Plot[] memory plotList = new Plot[](endIndex - startIndex + 1);
        
        for (uint256 i = startIndex; i <= endIndex; i++) {
            plotList[i - startIndex] = plots[i];
        }
        return plotList;
    }

    receive() external payable {
        payable(deployer).transfer(msg.value);
    }
}