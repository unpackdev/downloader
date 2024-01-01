// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// Import Uniswap interfaces directly
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

// import "./console.sol";



import "./IGardenBlokc.sol";
import "./IGardenerBlokc.sol";
import "./GardenerBlokc.sol";
import "./IERC20.sol";
import "./Counters.sol";


abstract contract GardenBlokc is GardenerBlokc, IGardenBlokc {
    mapping(address => Garden[]) public gardens;

    function getGardensByAddress(
        address _userAddress
    ) external view returns (Garden[] memory) {
        return gardens[_userAddress];
    }



function createGarden(
    uint256 _gardenerId,
    uint256 _amount,
    string memory _gardenName
  
) external {
    require(isGardenerRegistered[idToGardener[_gardenerId].gardenerAddress], "Gardener is not registered");
    require(_amount > 0, "Amount must be greater than 0");

    uint256 gardenId = gardens[msg.sender].length;
    _assignGardener(_gardenerId, gardenId, msg.sender);

    Gardener storage gardener = idToGardener[_gardenerId];
    GardenerStrategy memory selectedStrategy = selectStrategy(gardener, _amount);

    Garden storage garden = gardens[msg.sender].push();
    garden.id = gardenId;
    garden.gardenName = _gardenName;
    garden.owner = msg.sender; // User is the owner of the garden
    garden.gardenerId = _gardenerId;    
    garden.gardenerAddress = idToGardener[_gardenerId].gardenerAddress;
    garden.gardenerUsername = idToGardener[_gardenerId].username;
    // garden.composition = selectedStrategy.token;
    garden.createdAt = block.timestamp;
        TokenAmount storage tokenAmount = garden.composition.push();
        tokenAmount.token = selectedStrategy.cryptos;
        tokenAmount.amount = selectedStrategy.percentages;

     
    // address usdtToken = 0xda06447AD1dEA10D07c1c2E6C7853d3cbb2bC35e;  // USDT token address
    // address uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap router address
    // address wethToken = IUniswapV2Router02(uniswapRouter).WETH();

    // Swap USDT to ETH first

    // Try to swap USDT to ETH using Uniswap
    // try IERC20(usdtToken).approve(uniswapRouter, _amount) and IUniswapV2Router02(uniswapRouter).swapExactTokensForETH(
    //     _amount,
    //     0,
    //     new address[](0),
    //     address(this),
    //     block.timestamp
    // ) {
    //     // Do nothing on success
    // } catch Error(string memory reason) {
    //     // Revert the transaction if there is an error
    //     revert(reason);
    // }

    // Perform token swaps based on the strategy
    // for (uint256 i = 0; i < selectedStrategy.cryptos.length; i++) {
    //     address crypto = selectedStrategy.cryptos[i];
    //     uint8 percentage = selectedStrategy.percentages[i];

    //     uint256 allocationAmount = (_amount * percentage) / 100;

        // IUniswapV2Pair pair = IUniswapV2Pair(IUniswapV2Factory(IUniswapV2Router02(uniswapRouter).factory()).getPair(wethToken, crypto));

        // require(address(pair) != address(0), "Pair not found");

        // Try to swap ETH to 'crypto' and transfer tokens to user
        // try IERC20(wethToken).approve(uniswapRouter, allocationAmount) and IUniswapV2Router02(uniswapRouter).swapExactETHForTokens{value: allocationAmount}(
        //     0,
        //     new address[](0),
        //     msg.sender, // Transfer tokens to the user
        //     block.timestamp
        // ) {
        //     // Do nothing on success
        // } catch Error(string memory reason) {
        //     // Revert the transaction if there is an error
        //     revert(reason);
        // }
    }


function selectStrategy(Gardener storage gardener, uint256 _amount) internal view returns (GardenerStrategy memory) {
    for (uint256 i = 0; i < gardener.strategies.length; i++) {
        GardenerStrategy memory strategy = gardener.strategies[i];
        if (_amount >= strategy.minAmount && _amount <= strategy.maxAmount) {
            return strategy;
        }
    }
    
    // Return a default strategy or revert if none found
    revert("No matching strategy found");
}


    function _assignGardener(
        uint256 _gardenerId,
        uint256 _gardenId,
        address _userAddress
    ) internal {
        Gardener storage gardener = idToGardener[_gardenerId];
        require(
            isGardenerRegistered[gardener.gardenerAddress],
            "Gardener is not registered"
        );
        GardenersGardenData[] storage gardenersGardens = gardener.gardens;
        for (uint256 i = 0; i < gardenersGardens.length; i++) {
            require(
                !(gardenersGardens[i].id == _gardenId &&
                    gardenersGardens[i].userAddress == _userAddress),
                "Garden is already assigned to gardener"
            );
        }
        GardenersGardenData storage newGarden = gardenersGardens.push();
        newGarden.id = _gardenId;
        newGarden.userAddress = _userAddress;
    }

    function changeGardener(uint256 _gardenerId, uint256 _gardenId) external {
        _assignGardener(_gardenerId, _gardenId, msg.sender);
        Garden storage garden = gardens[msg.sender][_gardenId];
        garden.gardenerId = _gardenerId;
        garden.gardenerAddress = idToGardener[_gardenerId].gardenerAddress;
        garden.gardenerUsername = idToGardener[_gardenerId].username;
    }

    function changeGardenComposition(
        uint256 _idGarden,
        address _userAddress,
        TokenAmount[] memory composition
    ) external {
        Garden storage garden = gardens[_userAddress][_idGarden];
        delete garden.composition;
        for (uint256 i = 0; i < composition.length; i++) {
            garden.composition.push(composition[i]);
        }
    }
}
