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
        bytes3 color;
        uint64 numPurchases;
    }

    uint256 public constant numTotalPlots = 8840; // total plots 8840
    Plot[numTotalPlots] public plots;
    address public deployer;
    event PlotPurchased(uint256 indexed index, address indexed newOwner, bytes3 color, uint256 price);

    constructor() {
        deployer = msg.sender;
    }

    function calculateCost(uint64 numPurchases) public pure returns(uint256) {
        if(numPurchases == 0) {
            return 0;
        }
        return 0.01 ether * (7**(numPurchases - 1)) / 5**(numPurchases - 1);
    }

    function buyPlot(uint256 index, bytes3 _color) public payable nonReentrant {
        require(index < numTotalPlots, "Invalid plot index");
        Plot memory thisPlot = plots[index];
        uint256 currentPrice = calculateCost(thisPlot.numPurchases);
        uint256 previousPrice = 0;
        if(currentPrice != 0){
            previousPrice = calculateCost(thisPlot.numPurchases-1);
        }
        require(msg.value >= currentPrice, "Sent value must be at least the plot's price");
        
        address previousOwner = thisPlot.owner;
        emit PlotPurchased(index, msg.sender, _color, currentPrice);

        // New Plot
        Plot memory newPlot = Plot({
            owner: msg.sender,
            color: _color,
            numPurchases: thisPlot.numPurchases + 1
        });

        if (previousPrice == 0 && currentPrice != 0) {
            uint256 halfAmount = currentPrice / 2;
            (bool successToPreviousOwner, ) = payable(previousOwner).call{value: halfAmount}("");
            require(successToPreviousOwner, "Transfer to previous owner failed");
            (bool successToDeployer, ) = payable(deployer).call{value: halfAmount}("");
            require(successToDeployer, "Transfer to deployer failed");
        }

        if (previousPrice > 0) {
            uint256 amountToOwner = (previousPrice * 12) / 10; // pay previous owner 1.2x
            uint256 remainderToDeployer = currentPrice - amountToOwner; // 0.2x goes to deployer
            (bool successToPreviousOwner, ) = payable(previousOwner).call{value: amountToOwner}("");
            require(successToPreviousOwner, "Transfer to previous owner failed");
            (bool successToDeployer, ) = payable(deployer).call{value: remainderToDeployer}("");
            require(successToDeployer, "Transfer to deployer failed 2");
        }
        plots[index] = newPlot;
    }

    function buyMultiplePlots(uint256[] memory indices, bytes3[] memory colors) public payable {
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
            totalCost += calculateCost(plots[index].numPurchases);
        }
        require(msg.value >= totalCost, "Sent value must be at least the total plots' price");

        for (uint256 i = 0; i < indices.length; i++) {
            buyPlot(indices[i], colors[i]);
        }
    }

    function getPlotData(uint256 index) public view returns (address, bytes3, uint256) {
        require(index < numTotalPlots, "Invalid plot index");
        return (
            plots[index].owner,
            plots[index].color,
            calculateCost(plots[index].numPurchases)
        );
    }

    struct ExtendedPlot {
        address owner;
        bytes3 color;
        uint256 calculatedCost;
    }

    function batchGetPlotData(uint256 startIndex, uint256 endIndex) public view returns (ExtendedPlot[] memory){
        require(endIndex >= startIndex, "End index must be greater than or equal to start index");
        require(endIndex < numTotalPlots, "End index out of bounds");
        ExtendedPlot[] memory plotList = new ExtendedPlot[](endIndex - startIndex + 1);
        
        for (uint256 i = startIndex; i <= endIndex; i++) {
            plotList[i - startIndex] = ExtendedPlot(
                plots[i].owner,
                plots[i].color,
                calculateCost(plots[i].numPurchases)
            );
        }
        return plotList;
    }

    receive() external payable {
        payable(deployer).transfer(msg.value);
    }
}