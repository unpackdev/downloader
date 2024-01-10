//SPDX-License-Identifier: MIT  
pragma solidity ^0.8.2; 
  
import "./Ownable.sol";  
import "./Strings.sol";
import "./ERC721.sol";
  
contract TheBigPicture is ERC721, Ownable { 
    using Strings for uint256;

    uint16 public MAX_SUPPLY = 1024; // Only 1,024 total nfts available. (32*32 to build a pixel 256x256 image)
    uint public constant DEV_MINT_FEE = 80; // Allows me to get 80% of the mint money. The rest is distributed to current holders at the time of mint. Directly added to devBalance.
    uint public constant DEV_MISC_FEE = 5; // Later used as 5% on all other in-game fees. Directly added to devBalance.
    uint public constant PUBLIC_MISC_FEE = 5; // 5% of all misc fees on direct transactions are given out to the rest of the holders. (updatePlot)
    uint16 public totalSupply = 0; // Keeps track of total supply. ERC721Enumerable was making gas fees WAY too high.

    bool lockMintPrice = false; // Used to block the contract owner from editing mint price.
    bool lockFees = false; // Used to block the contract owner from editing fees that users use on specific plots modification transactions.
    bool lockMaxLimitPeriod = false; // Only used to block the contract owner from editing the max limit period for a plot.

    uint256 public MINT_PRICE = 0.02 ether; // The mint price.
    uint256 public MODIFY_FEE = 0.005 ether; // The fee to modify a plot if there have been no modifications done prior.
    uint256 public LIMIT_FEE_PER_BLOCK = 0.000005 ether; // The fee per block that is used to limit a plot. Limiting blocks anyone but the owner from editing the plot.
    uint256 public MODIFY_INCREASE_RATE = 2; // Every time your plot is modified, the cost to modify again for external users is increased by this rate. Example: 1 edit is an increase of 2% of the initial MODIFY_FEE.

    uint256 public MAX_LIMIT_PERIOD = 25000; // The maximum length in blocks a plot can be limited for.

    uint256 d = 0xf000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff; //This value is the required minimum for creating a hex color code uint256 in a plot.
    uint256 devBalance = 0 ether; // Keeps track of all earnings for the developer.
    uint256 globalRewards = 0 ether; // Keeps track of all global rewards. It's not a direct indictator of how much has been made, but it is used to keep everyone aligned.

    string private baseTokenURI; // Stores the URL for getting the NFT's metadata.

    struct Plot {
        uint16 id; // Plot's Id
        uint32 timesModified; // The amount of times the plot has been modified both by the owner and by others.
        uint256 modifyRewards; // The pending rewards for a plot. This is earned only by modifications.
        uint256 claimedGlobalRewards; // This keeps the plot's global rewards compared to the overall rewards made. It helps calculate the amount that is due for the massively spread out amounts among all plots.
        uint256 limitBlock; // The block where, if enabled, a limit will expire. If the limit is below the current block, it isn't limited.
        uint256[7] pixels; // Stores 7 uint256s that are convertable into hex color codes to display on the site. This helps easily recreate and transfer designs around.
    }

    mapping(uint16 => Plot) public plotIdToPlot; // This is how the code reverses a tokenId into a plot object.
    
    // Initial constructor that sets the metadata URI and basic information.
    constructor(string memory newBaseURI) ERC721("The Big Picture", "PLOT") {
        baseTokenURI = newBaseURI;
    }

    /* Mint */

    // Mints an ERC721 token and builds a plot in storage.
    function mint(uint16 plotId) external payable {
        require(msg.value == MINT_PRICE, "Incorrect ether sent.");
        require(plotId < MAX_SUPPLY && plotId >= 0, "You're trying to mint outside the picture.");
        
        _safeMint(msg.sender, plotId);

        if (totalSupply > 0){
            // Gives the developer 80% of the mint value.
            devBalance += msg.value / 100 * DEV_MINT_FEE;

            // Sets the reward for any plot that has been minted to a higher value.
            globalRewards += (msg.value / 100 * (100-DEV_MINT_FEE)) / (totalSupply);
        }
        else{
            // Gives the developer 100% of the mint value since there are no other plots to reward yet.
            devBalance += msg.value;
        }

        // Increments total supply since we are manually tracking this.
        totalSupply += 1;

        // Initializes the plot for later use. This is why the gas price is so high... sorry...
        plotIdToPlot[plotId] = Plot(plotId, 0, 0 ether, globalRewards, block.number, [d,d,d,d,d,d,d]);

    }

    /* Plots */

    // Returns all variables for a given plot.
    function viewPlot(uint16 plotId) public view returns (Plot memory) {
        return plotIdToPlot[plotId];
    }

    // Returns a full list of plots and their variables. This is key in reproducing the map without doing 64 total requests per block. It's an intense query nonetheless.
    function viewPlots(uint16[] calldata plotIds) public view returns (Plot[] memory){
        Plot[] memory plots = new Plot[](plotIds.length);
        for(uint16 x = 0; x < plotIds.length; x++){
            Plot memory plot = viewPlot(plotIds[x]);
            plots[x] = plot;
        }
        return plots;
    }

    // Allows editing of a plot's pixel data. The input pixels is uint256s that can be decoded into hex strings that contain hex color codes. They must match a basic criteria so that all values can be read.
    function updateFullPlot(uint16 plotId, uint256[7] memory pixels) public payable {
        require((msg.value == (MODIFY_FEE*((100+((MODIFY_INCREASE_RATE*plotIdToPlot[plotId].timesModified)))))/100 && ownerOf(plotId) != msg.sender) || (ownerOf(plotId) == msg.sender && msg.value == 0 ether), "Incorrect ether sent.");
        require(plotIdToPlot[plotId].limitBlock < block.number || ownerOf(plotId) == msg.sender, "This plot is limited.");

        for(uint8 x = 0; x < 7; x++){
            require(pixels[x] >= d, "Upload does not meet standards."); // This prevents any entry into the pixel list that isn't going to create hex color codes.
        }

        // If the person doing the transaction is not the owner, it'll cost them money, but if they're the owner, we don't need to waste time with that logic below.
        if(msg.sender != ownerOf(plotId)){

            if(totalSupply-1 > 0){

                //Gives the developer 5% of the modification price.
                devBalance += msg.value / 100 * DEV_MISC_FEE;

                //Gives 5% of the modification price spread out to all plots EXCEPT the plot being edited.
                globalRewards += (msg.value / 100 * PUBLIC_MISC_FEE)/(totalSupply-1);
                plotIdToPlot[plotId].claimedGlobalRewards += (msg.value / 100 * PUBLIC_MISC_FEE)/(totalSupply-1);

                // Gives 90% of the modification price to the plot that's being edited's rewards.
                plotIdToPlot[plotId].modifyRewards += msg.value / 100 * (100-DEV_MISC_FEE-PUBLIC_MISC_FEE);
            }
            else{
                // Gives the developer 5% of the modification price.
                devBalance += msg.value / 100 * DEV_MISC_FEE;
               // Gives 95% of the modification price to the plot that's being edited's rewards. This is an edge case where there is only 1 plot and that plot is modified.
                plotIdToPlot[plotId].modifyRewards += msg.value / 100 * (100-DEV_MISC_FEE);
            }
        
        }
        
        // Replaces the array of pixels with new pixels.
        plotIdToPlot[plotId].pixels = pixels;
        // Increments the total times modified. This will increase the price to modify and will burn any pending transaction with the same modification price.
        plotIdToPlot[plotId].timesModified += 1;
    }

    // Allows a user to limit their plot to be only editable by the owner of the token for a certain number of blocks.
    function limitPlot(uint16 plotId, uint256 blocks) public payable {
        require(ownerOf(plotId) == msg.sender, "You cannot modify this plot.");
        require(msg.value == blocks*LIMIT_FEE_PER_BLOCK, "Incorrect ether sent.");
        require(blocks > 0, "You must increase by more than 0.");
        require(blocks <= MAX_LIMIT_PERIOD, "You cannot set your limitation this far.");
        require(plotIdToPlot[plotId].limitBlock+blocks <= block.number+MAX_LIMIT_PERIOD, "You cannot extend your limitations this far.");

        // If the plot currently has no limit, set the limit to the block that is the requested distance out.
        if(plotIdToPlot[plotId].limitBlock <= block.number){
            plotIdToPlot[plotId].limitBlock = block.number + blocks;
        }
        else{
            // If the plot has a limit, just add the new block count to the old limit.
            plotIdToPlot[plotId].limitBlock += blocks;
        }

        if (totalSupply-1 > 0){
            //Gives the developer 5% of the limit price.
            devBalance += (msg.value*(DEV_MISC_FEE/100));

            //Gives all holders, but the plot owner a reward that is 95% of the limit fee spread out over all supply.
            globalRewards += (msg.value / 100 * (100-DEV_MISC_FEE))/(totalSupply-1);
            plotIdToPlot[plotId].claimedGlobalRewards += (msg.value / 100 * (100-DEV_MISC_FEE))/(totalSupply-1);
        }
        else{
            // Gives the developer 100% of the limit fee. This is an edge case where there is only 1 plot and that plot is limited.
            devBalance += msg.value;
        }
    }

    // Resets the limit block for a plot. No refund given.
    function unlimitPlot(uint16 plotId) public {
        require(ownerOf(plotId) == msg.sender,"You don't own this plot.");
        require(plotIdToPlot[plotId].limitBlock > block.number,"This plot is not limited.");

        // Sets the limit block to the current block which resets it to be seen as not limited.
        plotIdToPlot[plotId].limitBlock = block.number;
    }

    /* Reward Claiming */

    // Returns the current balance of a plot.
    function viewRewards(uint16 plotId) public view returns (uint256) {

        // If the plot exists, return the values, if not, return 0.
        if(plotIdToPlot[plotId].limitBlock != 0){
            return (globalRewards-plotIdToPlot[plotId].claimedGlobalRewards) + plotIdToPlot[plotId].modifyRewards;
        }
        else{
            return 0;
        }
    }

    // Returns the current devBalance.
    function viewDevRewards() public view returns (uint256) {
        return devBalance;
    }

    // Allows a plot holder to claim rewards for their plot.
    function claimRewards(uint16 plotId) public {
        require(msg.sender == ownerOf(plotId), "You do not own this plot.");
        require(globalRewards-plotIdToPlot[plotId].claimedGlobalRewards > 0 || plotIdToPlot[plotId].modifyRewards > 0, "Plot has no rewards to claim.");

        // If the plot has pending rewards from limits or global rewards.
        if (globalRewards-plotIdToPlot[plotId].claimedGlobalRewards > 0){
            
            bool sent = payable(ownerOf(plotId)).send(globalRewards-plotIdToPlot[plotId].claimedGlobalRewards);
            require(sent, "Failed to send Ether");

            plotIdToPlot[plotId].claimedGlobalRewards = globalRewards;
        }

        // If the plot has pending rewards from modifications.
        if (plotIdToPlot[plotId].modifyRewards > 0){

            bool sentTwo = payable(ownerOf(plotId)).send(plotIdToPlot[plotId].modifyRewards);
            require(sentTwo, "Failed to send Ether");

            plotIdToPlot[plotId].modifyRewards = 0;
        }
    }

    // Allows the owner of the contract to claim the entire developer balance.
    function claimDevRewards() public onlyOwner {
        require(devBalance > 0 ether, "Developer balance is 0 ether.");

        bool sent = payable(msg.sender).send(devBalance);
        require(sent, "Failed to send Ether");

        devBalance = 0 ether;
    }

    /* Normal NFT Stuff */

    // Returns the link you'll use to view data. Mostly just used to cache information on OpenSea and similar.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = baseTokenURI;
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString())): "";
    }

    // Allows the owner of the contract to set the link for metadata.
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /* Price / Fee Changing */
    
    // Trust is needed on these. If I cannot be trusted, I will do the locking functions.

    //Allows me to only decrease the mint price. Obviously it's already cheap to mint, but I'd be able to set it to free, but never higher.
    function setMintPrice(uint256 newPrice) public onlyOwner {
        require(!lockMintPrice, "Owner is locked from editing the price.");
        require(newPrice < MINT_PRICE, "You cannot increase the mint price.");
        MINT_PRICE = newPrice;
    }

    // These values are the base fees. I will handle with care. Will change only on community vote. I'd mostly be using these functions to match floor prices and keep it fair to holders.

    // Sets the base modification fee for attempting to modify a plot that isn't theirs.
    function setModifyFee(uint256 newModifyFee) public onlyOwner {
        require(!lockFees, "Owner is locked from editing the fees.");
        MODIFY_FEE = newModifyFee;
    }

    // Sets the increase rate for when someone is attempting to modify a plot that isn't theirs. Only here just in case the starting prices are either too high or too little.
    function setModifyIncreaseRate(uint256 newModifyIncreaseRate) public onlyOwner {
        require(!lockFees, "Owner is locked from editing the rate.");
        MODIFY_INCREASE_RATE = newModifyIncreaseRate;
    }

    // Sets the fee per block when limiting a plot.
    function setLimitPerBlockFee(uint256 newLimitPerBlockFee) public onlyOwner {
        require(!lockFees, "Owner is locked from editing the fees.");
        LIMIT_FEE_PER_BLOCK = newLimitPerBlockFee;
    }

    // Sets the furthest block out you can lock a plot for.
    function setMaxLimitPeriod(uint256 newMaxLimitPeriod) public onlyOwner {
        require(!lockMaxLimitPeriod, "Owner is locked from editing the fees.");
        MAX_LIMIT_PERIOD = newMaxLimitPeriod;
    }


    /* Locking The Developer Mechanism */

    // I will go along with whatever the community votes for. Again, just trust me to do the right thing.

    function doLockFees() public onlyOwner {
        lockFees = true;
    }

    function doLockMintPrice() public onlyOwner {
        lockMintPrice = true;
    }

    function doLockMaxLimitPeriod() public onlyOwner {
        lockMaxLimitPeriod = true;
    }


    /* Rewards to holders from external sources. */

    // Possibly used later for a second collection to bridge earnings over from the other contract or I may return some secondary sales back to holders.
    // Just want the ability to add in ETH and disperse it to everyone if it ever comes up. <3
    // ANYONE CAN REWARD HOLDERS. IF YOU GET JUICED OFF THE MINT, SPREAD THE LOVE.

    function rewardHolders() public payable {
        require(msg.value >= 0.01 ether, "Reward must be greater than 0.01 ETH.");
        globalRewards += msg.value/totalSupply;
    }

    /* Other */ 

    // All variables listed here are explained above. This is just a nice way to store and return the information.
    struct GameData {
        uint16  MAX_SUPPLY;
        uint DEV_MINT_FEE;
        uint DEV_MISC_FEE;
        uint PUBLIC_MISC_FEE;
        uint16 totalSupply;
        bool lockMintPrice;
        bool lockFees;
        bool lockMaxLimitPeriod;
        uint256 MINT_PRICE;
        uint256 MODIFY_FEE;
        uint256 LIMIT_FEE_PER_BLOCK;
        uint256 MAX_LIMIT_PERIOD;
        uint256 MODIFY_INCREASE_RATE;
    }

    // This is used to keep the site up to date with the current variables. It's an eyesore, but many of these variables are important for the front end to see.
    function getGameVariables() public view returns (GameData memory){
        return GameData(MAX_SUPPLY, DEV_MINT_FEE, DEV_MISC_FEE, PUBLIC_MISC_FEE, totalSupply, lockMintPrice, lockFees, lockMaxLimitPeriod, MINT_PRICE, MODIFY_FEE, LIMIT_FEE_PER_BLOCK, MAX_LIMIT_PERIOD, MODIFY_INCREASE_RATE);
    }

}