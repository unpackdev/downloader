// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";


contract MXTN is ERC20, ERC20Burnable, Pausable, Ownable {
    AggregatorV3Interface internal ethPriceFeed; // Chainlink ETH/USD Price Feed contract
    AggregatorV3Interface internal auPriceFeed; // Chainlink Gold Price Feed contract
    AggregatorV3Interface internal cuPriceFeed; //Own Copper Imp
    AggregatorV3Interface internal grPriceFeed; //Own Graphite Imp

    constructor() ERC20("Mineral Token", "MXTK") {
        gasFeePercentage = 70; // Default to 70 bps (0.7%)
        ethPriceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        ); //ETH/USD address
        auPriceFeed = AggregatorV3Interface(
            0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6
        ); //XAU/USD address

        // Initialize mineralSymbols with default symbols
        mineralSymbols.push("CU");
        mineralSymbols.push("AU");
        mineralSymbols.push("GR");
    }

    // Gas fee percentage
    uint256 public gasFeePercentage;

    // Mapping of SKRs to their respective owners
    // Mapping of SKRs for each address using assetIpfsCID as the key
    mapping(address => mapping(string => SKR)) public skrs;

    // Struct to represent SKR details
    struct SKR {
        address owner;
        string assetIpfsCID;
        mapping(string => Mineral) minerals; // Mapping of minerals inside the SKR
    }

    // Struct to represent mineral details
    struct Mineral {
        string symbol;
        uint256 ounces;
    }

    // Add this array to keep track of mineral symbols
    string[] public mineralSymbols;

    // Mapping to associate mineral details with each minted token
    mapping(uint256 => Mineral) public mineralDetails;

    uint256 public totalAssetValue; // Total value of all assets in the contract

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function updateETHPriceOracle(address ethOracleAddress) external onlyOwner {
        require(ethOracleAddress != address(0), "Invalid address");
        ethPriceFeed = AggregatorV3Interface(ethOracleAddress);
    }

    function updateGoldPriceOracle(address goldOracleAddress) external onlyOwner {
        require(goldOracleAddress != address(0), "Invalid address");
        auPriceFeed = AggregatorV3Interface(goldOracleAddress);
    }

    function updateGraphitePriceOracle(address graphiteOracleAddress)
        external
        onlyOwner
    {
        require(graphiteOracleAddress != address(0), "Invalid address");
        grPriceFeed = AggregatorV3Interface(graphiteOracleAddress);
    }

    function updateCopperPriceOracle(address copperOracleAddress)
        external
        onlyOwner
    {
        require(copperOracleAddress != address(0), "Invalid address");
        cuPriceFeed = AggregatorV3Interface(copperOracleAddress);
    }

    // Function to add a new SKR
    function addSKR(address _skrOwner, string memory _assetIpfsCID)
        external
        onlyOwner
    {
        require(
            skrs[_skrOwner][_assetIpfsCID].owner == address(0),
            "SKR already exists"
        );

        // Create a new SKR struct
        SKR storage newSKR = skrs[_skrOwner][_assetIpfsCID];

        // Initialize the SKR struct with the provided data
        newSKR.assetIpfsCID = _assetIpfsCID;
        newSKR.owner = _skrOwner;
    }

    function addMineralToSKR(
        address skrOwner,
        string memory assetIpfsCID,
        string memory mineralSymbol,
        uint256 mineralOunces
    ) external onlyOwner {
        require(skrOwner != address(0), "SKR not found");
        require(bytes(assetIpfsCID).length > 0, "CID cannot be empty");
        require(mineralOunces > 0, "Oz must be greater than zero");
        require(bytes(mineralSymbol).length > 0, "Symbol cannot be empty");

        // Access a specific SKR for an address using assetIpfsCID
        SKR storage skr = skrs[skrOwner][assetIpfsCID];

        // Ensure that the SKR owner exists
        require(skr.owner != address(0), "SKR owner does not exist");

        // Check if the mineral already exists for this SKR
        require(
            skr.minerals[mineralSymbol].ounces == 0,
            "Mineral already exists"
        );

        // Add the mineral details to the SKR storage
        skr.minerals[mineralSymbol] = Mineral({
            symbol: mineralSymbol,
            ounces: mineralOunces
        });

        // Calculation logic

        uint256 mineralValueInWei = calculateMineralValueInWei(
            mineralSymbol,
            mineralOunces
        );

        // Calculate tokens to mint
        uint256 tokensToMintInWei = computeTokenToMintByWei(mineralValueInWei);

        // Calculate admin fee
        uint256 adminFeeInWei = calculateAdminFee(tokensToMintInWei);

        // Calculate amount to transfer to SKR owner in Wei
        uint256 amountToTransferToSKROwner = tokensToMintInWei - adminFeeInWei;

        // Ensure that the amount to mint is greater than zero
        require(tokensToMintInWei > 0, "Tokens to mint > zero");
        require(amountToTransferToSKROwner > 0, "Owner mint NOT > 0");
        require(adminFeeInWei > 0, "Admin fee NOT > 0");

        // Update totalAssetValue
        totalAssetValue += mineralValueInWei;

        // Mint tokens directly to the SKR owner's wallet
        _mint(skrOwner, amountToTransferToSKROwner);

        // Mint admin fee directly to the contract owner's wallet
        _mint(owner(), adminFeeInWei);

        addMineralSymbol(mineralSymbol);

        // Events, etc...
        emit MineralAdded(
            skrOwner,
            mineralSymbol,
            mineralOunces,
            mineralValueInWei,
            tokensToMintInWei,
            adminFeeInWei,
            amountToTransferToSKROwner
        );
    }

    // Function to add a mineral symbol to the array
    function addMineralSymbol(string memory mineralSymbol) public onlyOwner {
        bool symbolExists = false;
        for (uint256 i = 0; i < mineralSymbols.length; i++) {
            if (
                keccak256(bytes(mineralSymbols[i])) ==
                keccak256(bytes(mineralSymbol))
            ) {
                symbolExists = true;
                break;
            }
        }
        if (!symbolExists) {
            mineralSymbols.push(mineralSymbol);
        }
    }

    function computeTokenToMintByWei(uint256 weiAmount)
        public
        view
        returns (uint256)
    {
        require(weiAmount > 0, "Value must > zero");

        uint256 price = getETHPrice();

        require(price > 0, "ETH must > zero");

        // Calculate token to mint
        uint256 tokensToMintInWei = divide(weiAmount, price);

        return tokensToMintInWei;
    }

    function divide(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "division by zero will result in infinity.");
        return (a * 1e18) / b;
    }

    function calculateAdminFee(uint256 tokensToMintInWei)
        public
        pure
        returns (uint256)
    {
        require(tokensToMintInWei > 0, "Fee must > zero");
        return (tokensToMintInWei * 40) / 100;
    }

    // Function to calculate the value of a mineral based on its symbol and ounces
    function calculateMineralValueInWei(
        string memory mineralSymbol,
        uint256 mineralOunces
    ) public view returns (uint256) {
        // Call the appropriate oracle based on the mineral symbol
        if (keccak256(bytes(mineralSymbol)) == keccak256(bytes("CU"))) {
            return calculateCopperValue(mineralOunces);
        } else if (keccak256(bytes(mineralSymbol)) == keccak256(bytes("AU"))) {
            return calculateGoldValue(mineralOunces);
        } else if (keccak256(bytes(mineralSymbol)) == keccak256(bytes("GR"))) {
            return calculateGraphiteValue(mineralOunces);
        } else {
            revert("Unsupported mineral symbol");
        }
    }

    function getCopperPrice() public view returns (uint256) {
        // Access the copperPrice directly from the oracle contract
        (, int256 price, , , ) = cuPriceFeed.latestRoundData();
        require(price > 0, "Price feed error");

        return uint256(price);
    }

    // Function to calculate the value of Copper based on ounces from an oracle
    function calculateCopperValue(uint256 metalOunces)
        public
        view
        returns (uint256)
    {
        uint256 copperPricePerOunce = getCopperPrice();
        return metalOunces * copperPricePerOunce;
    }

    function getETHPrice() public view returns (uint256) {
        // Get the latest ETH/USD price from Chainlink in 8 decimal position
        (, int256 price, , , ) = ethPriceFeed.latestRoundData();
        require(price > 0, "Price feed error");

        return uint256(price);
    }

    function getGoldPrice() public view returns (uint256) {
        (, int256 price, , , ) = auPriceFeed.latestRoundData();
        require(price > 0, "Price feed error");

        return uint256(price);
    }

    // Function to calculate the value of Gold based on ounces from an oracle
    function calculateGoldValue(uint256 metalOunces)
        public
        view
        returns (uint256)
    {
        uint256 price = getGoldPrice();
        //Gold is returned in
        return metalOunces * price;
    }

    function getGraphitePrice() public view returns (uint256) {
        (, int256 price, , , ) = grPriceFeed.latestRoundData();
        require(price > 0, "Price feed error");

        return uint256(price);
    }

    // Function to calculate the value of Graphite based on ounces from an oracle
    function calculateGraphiteValue(uint256 metalOunces)
        public
        view
        returns (uint256)
    {
        uint256 graphitePricePerOunce = getGraphitePrice();
        // Calculate the value based on the retrieved graphitePrice and metal ounces
        return metalOunces * graphitePricePerOunce;
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Amount must > zero");

        // Get balance before transfer
        uint256 balanceBefore = balanceOf(msg.sender);

        // Calculate gas fee based on amount - gasFee
        // This avoids double charging fee on the fee
        uint256 gasFee = (amount * gasFeePercentage) / 10_000;

        // Check balance is sufficient before any transfer
        require(balanceBefore >= amount, "Insufficient balance");

        // Ensure that the calculated gasFee does not exceed the amount
        require(gasFee < amount, "Gas fee exceeds amount");

        // Transfer tokens minus gas fee
        super.transfer(to, amount - gasFee);

        // Transfer gas fee to owner
        super.transfer(owner(), gasFee);

        return true;
    }

    // Function to allow the SKR owner to "buy back" their SKR
    function buyBackSKR(string memory assetIpfsCID) external {
        // Ensure that the sender is the SKR owner
        SKR storage skr = skrs[msg.sender][assetIpfsCID];
        require(skr.owner == msg.sender, "Not the SKR owner");

        // Calculate the current value of the minerals in the SKR
        uint256 skrValueInWei = calculateSKRValueInWei(
            msg.sender,
            assetIpfsCID
        );

        // Ensure that the SKR value is greater than zero
        require(skrValueInWei > 0, "SKR has no value");

        // Calculate the number of tokens to burn based on SKR value
        uint256 tokensToBurn = computeTokenToBurnByWei(skrValueInWei);

        // Ensure that the SKR owner has enough tokens for the buyback
        require(
            balanceOf(msg.sender) >= tokensToBurn,
            "Insufficient tokens for buyback"
        );

        // Burn the tokens
        _burn(msg.sender, tokensToBurn);

        // Reset SKR details
        skr.owner = address(0);
        skr.assetIpfsCID = "";

        // Emit an event to log the SKR buyback
        emit SKRBuyback(msg.sender, tokensToBurn, skrValueInWei);
    }

    // Function to calculate the value of minerals in the SKR
    function calculateSKRValueInWei(
        address skrOwner,
        string memory assetIpfsCID
    ) public view returns (uint256) {
        SKR storage skr = skrs[skrOwner][assetIpfsCID];
        require(skr.owner != address(0), "SKR not found");

        uint256 totalSKRValue = 0;

        // Calculate the value of each mineral in the SKR
        for (uint256 i = 0; i < mineralSymbols.length; i++) {
            string memory mineralSymbol = mineralSymbols[i];
            Mineral storage mineral = skr.minerals[mineralSymbol];
            if (bytes(mineral.symbol).length > 0) {
                totalSKRValue += calculateMineralValueInWei(
                    mineral.symbol,
                    mineral.ounces
                );
            }
        }

        return totalSKRValue;
    }

    // Function to calculate the number of tokens to burn based on SKR value
    function computeTokenToBurnByWei(uint256 weiAmount)
        public
        view
        returns (uint256)
    {
        require(weiAmount > 0, "Value must > zero");

        uint256 price = getTokenValue();

        require(price > 0, "Token value must be > zero");

        // Calculate tokens to burn
        uint256 tokensToBurn = divide(weiAmount, price);

        return tokensToBurn;
    }

    // Function to update the gas fee percentage
    function setGasFeePercentage(uint256 _gasFeePercentage) external onlyOwner {
        gasFeePercentage = _gasFeePercentage;
    }

    function getTokenValue() public view returns (uint256) {
        if (totalSupply() == 0) {
            return 0; // Avoid division by zero if totalSupply is zero
        }
        return divide(totalAssetValue, totalSupply());
    }

    // Event to log SKR release
    event SKRBuyback(
        address indexed sender,
        uint256 tokensToBurn,
        uint256 skrValueInWei
    );

    // Event to log IPFS asset reference, mineral value, and mineral details
    event IPFSAssetReferenced(
        address indexed recipient,
        address indexed skrOwner,
        string ipfsHash,
        uint256 mineralValue,
        uint256 tokenId
    );

    event MineralAdded(
        address indexed skrOwner,
        string mineralSymbol,
        uint256 mineralOunces,
        uint256 mineralValue,
        uint256 tokensMinted,
        uint256 adminFee,
        uint256 amountTransferredToSKROwner
    );

    // Declare the event at the contract level
    event DebugLog(string message, uint256 value);
}