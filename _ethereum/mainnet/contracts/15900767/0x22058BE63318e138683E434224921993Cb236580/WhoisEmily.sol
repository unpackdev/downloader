// ░██╗░░░░░░░██╗██╗░░██╗░█████╗░  ██╗░██████╗  ███████╗███╗░░░███╗██╗██╗░░░░░██╗░░░██╗░█████╗░
// ░██║░░██╗░░██║██║░░██║██╔══██╗  ██║██╔════╝  ██╔════╝████╗░████║██║██║░░░░░╚██╗░██╔╝██╔══██╗
// ░╚██╗████╗██╔╝███████║██║░░██║  ██║╚█████╗░  █████╗░░██╔████╔██║██║██║░░░░░░╚████╔╝░╚═╝███╔╝
// ░░████╔═████║░██╔══██║██║░░██║  ██║░╚═══██╗  ██╔══╝░░██║╚██╔╝██║██║██║░░░░░░░╚██╔╝░░░░░╚══╝░
// ░░╚██╔╝░╚██╔╝░██║░░██║╚█████╔╝  ██║██████╔╝  ███████╗██║░╚═╝░██║██║███████╗░░░██║░░░░░░██╗░░
// ░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝░╚════╝░  ╚═╝╚═════╝░  ╚══════╝╚═╝░░░░░╚═╝╚═╝╚══════╝░░░╚═╝░░░░░░╚═╝░░

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./ECDSA.sol";
import "./Ownable.sol";
import "./ERC721ACommon.sol";
import "./Strings.sol";

contract Emily is Ownable,ERC721ACommon {
    using Strings for uint256;

    //amount of tokens that have been minted so far, in total and in presale
    uint256 public numberOfTotalTokens = 0;
    
    //declares the maximum amount of tokens that can be minted, total and in presale
    uint256 private maxTotalTokens;
    //limit of tokens to be sold in presale
    uint256 private maxTokensPresale;
    //limit of tokens in genesis sale
    uint256 private maxTokensGenesisSale;
    
    //initial part of the URI for the metadata
    string private _currentBaseURI;
        
    //cost of mints depending on state of sale    
    uint private constant mintCostGenesisSale = 0.075 ether;
    uint private mintCostPresale = 0.99 ether;
    uint private mintCostPublicSale = 0.2 ether;
    uint private constant mintIncrement = 0.1 ether;

    
    function setMintCostPresale(uint _cost) public onlyOwner{
        mintCostPresale = _cost;
    }

    function setMintCostPublicSale(uint _cost) public onlyOwner{
        mintCostPublicSale = _cost;
    }

    function getMintCostPresale() public view returns (uint){
        return mintCostPresale;
    }

    //maximum amount of mints allowed per person
    uint256 public maxMintPresale = 3;

    //maximum amount of mints allowed per person
    uint256 public maxMintGenesis = 1;
    
    //the amount of reserved mints that have currently been executed by creator and giveaways
    uint private _reservedMints = 0;
    
    //the maximum amount of reserved mints allowed for creator and giveaways
    uint private maxReservedMints = 500;
    
    //addresses of the different shareholders and owners
    address payable public daoWallet = payable(0x9801c97483fe6fEef931268dBD5E7c9c55393341);
    address payable public incubationWallet = payable(0xC7086517dEAd1157cBa2133288d68ABA7D5FD8Cc);
    address payable public marketingWallet = payable(0x76Ae9F430b82F8d0529d1fB22A9aFAfdc9268EfF);
    address payable public devWallet = payable(0x6C69B08b1cBDcA1051e481b35F2FF79D131d502b);
    address payable public teamWallet = payable(0xed9c25a67d3119F8c3240d97d3073d7531442Ba0);
    
    //dummy address that we use to sign the mint transaction to make sure it is valid
    address private signatureVerifier = 0xFe8A2eFF1B555FF0d5C61A0c80eE68b4DFb45633;

    address private variable = 0x02d274Ad889bf84E5431293B9DCE985A6C12703c;
    
    //marks the timestamp of when the respective sales open
    uint256 internal genesisLaunchTime;
    uint256 internal presaleLaunchTime;
    uint256 internal publicSaleLaunchTime;
    uint256 internal revealTime;

    //amount of mints that each address has executed
    mapping(address => uint256) public mintsPerAddress;
    mapping(bytes => bool) public signatureUsed;
    
    //current state os sale
    enum State {NoSale, GenesisSale, Presale, PublicSale}

    //defines the uri for when the NFTs have not been yet revealed
    string public unrevealedURI;

    constructor(
        uint96 royaltyBasisPoints
    ) ERC721ACommon("Who is Emily", "EMILY", teamWallet, royaltyBasisPoints){
        maxTotalTokens = 10000;
        maxTokensPresale = 1000;
        maxTokensGenesisSale = 100;
        _setDefaultRoyalty(teamWallet, royaltyBasisPoints);
        unrevealedURI = "ar://0wt6ZWanbUN4ajXy-fbQFeb4Tk2ak4KS6Js7eJk4j_I";
    }
    
    //in case somebody accidentaly sends funds or transaction to contract
    receive() payable external {}
    fallback() payable external {
        revert();
    }
    
    //visualize baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }
    
    //change baseURI in case needed for IPFS
    function changeBaseURI(string memory baseURI_) public onlyOwner {
        _currentBaseURI = baseURI_;
    }


    function changeUnrevealedURI(string memory unrevealedURI_) public onlyOwner {
        unrevealedURI = unrevealedURI_;
        changeBaseURI(unrevealedURI_);
        revealTime = block.timestamp;
    }

    function changeMaxMintGenesis(uint256 _number) public onlyOwner {
        maxMintGenesis = _number;
    }

    function changeMaxMintPresale(uint256 _number) public onlyOwner{
        maxMintPresale = _number;
    }

    function changeMintCostPublicSale(uint _cost) public onlyOwner {
        mintCostPublicSale = _cost;
    }

    function switchToGenesisSale() public onlyOwner {
        require(saleState() == State.NoSale, 'Sale is already Open!');
        genesisLaunchTime = block.timestamp;
    }

    function switchToPresale() public onlyOwner {
        require(saleState() == State.GenesisSale, 'Sale is already Open!');
        presaleLaunchTime = block.timestamp;
    }

    function switchToPublicSale() public onlyOwner {
        require(saleState() == State.Presale, 'Sale is already Open!');
        publicSaleLaunchTime = block.timestamp;
    }
 
    function recoverSigner(bytes32 hash, bytes memory signature) public pure returns (address) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32", 
                hash
            )
        );
        return ECDSA.recover(messageDigest, signature);
    }

    function ownerMint(uint256 number) public onlyOwner {
        _safeMint(msg.sender, number);
        numberOfTotalTokens += number;
    }

    //mint a @param number of NFTs in presale
    function genesisMint(uint256 number, bytes32 hash, bytes memory signature) public payable {
        require(saleState() == State.GenesisSale, "Not in Genesis Sale!");
        require(numberOfTotalTokens + number <= maxTokensGenesisSale, "Not enough NFTs left to mint..");
        require(mintsPerAddress[msg.sender] + number <= maxMintGenesis, "Maximum 1 Mint per Address allowed!");
        require(recoverSigner(hash, signature) == signatureVerifier, "Address is not allowlisted");
        require(msg.value >= mintCost() * number, "Not sufficient Ether to mint this amount of NFTs (Cost = 0.075 ether each NFT)");
        numberOfTotalTokens += number;
        _safeMint(msg.sender, number);
        mintsPerAddress[msg.sender] += number;
    }
    
    //mint a @param number of NFTs in presale
    function presaleMint(uint256 _number, bytes32 _hash, bytes memory _signature) public payable {
        require(saleState() == State.Presale, "Not in Presale!");
        require(numberOfTotalTokens + _number <= maxTokensPresale, "Not enough NFTs left to mint..");
        require(mintsPerAddress[msg.sender] + _number - maxMintGenesis <= maxMintPresale, "Maximum 3 Mints per Address allowed!");
        require(recoverSigner(_hash, _signature) == signatureVerifier, "Address is not allowlisted");
        require(msg.value >= mintCost() * _number, "Not sufficient Ether to mint this amount of NFTs (Cost = 0.1 ether each NFT)");
        numberOfTotalTokens += _number;
        _safeMint(msg.sender, _number);
        mintsPerAddress[msg.sender] += _number;
    }

    
    //mint a @param number of NFTs in public sale
    function publicSaleMint(uint256 number) payable public {
        require(saleState() == State.PublicSale, "Public Sale is not open yet!");
        require(numberOfTotalTokens + number <= maxTotalTokens - (maxReservedMints - _reservedMints), "Not enough NFTs left to mint..");
        require(msg.value >= mintCostPublicSale * number, "Not sufficient Ether to mint this amount of NFTs");
        _safeMint(msg.sender, number);
        mintsPerAddress[msg.sender] += number;
        numberOfTotalTokens += number;
        
    }
    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        //check to see that 24 hours have passed since beginning of publicsale launch
        if (revealTime == 0) {
            return unrevealedURI;
        }
        
        else {
            string memory baseURI = _baseURI();
            return string(abi.encodePacked(baseURI, "/", Strings.toString(_tokenId), ".json"));
        }    
    }
    
    //reserved NFTs for creator
    function reservedMint(uint number, address recipient) public {
        require(msg.sender == teamWallet, 'Only the Team Wallet can mint Reserved NFTs!');
        require(_reservedMints + number <= maxReservedMints, "Not enough Reserved NFTs left to mint..");
        _safeMint(recipient, number);
        mintsPerAddress[recipient] += 1;
        numberOfTotalTokens += 1;
        _reservedMints += 1;   
    }
    
    //burn the tokens that have not been sold yet
    function burnAllUnmintedTokens() public onlyOwner {
        maxTotalTokens = numberOfTotalTokens;
    }
    
    
    //see the current account balance
    function accountBalance() public onlyOwner view returns(uint) {
        return address(this).balance;
    }
    
    //retrieve all funds recieved from minting
    function withdraw() public onlyOwner {
        uint256 balance = accountBalance();
        require(balance > 0, 'No Funds to withdraw, Balance is 0');
        uint8 devShare = 20;
        uint8 marketingShare = 10;

        if(numberOfTotalTokens > 100){
            devShare = 15;
            marketingShare = 15;
        }

        _withdraw(payable(daoWallet), (balance * 25) / 100);
        _withdraw(payable(incubationWallet), (balance * 25) / 100);
        _withdraw(payable(marketingWallet), (balance * marketingShare) / 100);
        _withdraw(payable(devWallet), (balance * devShare) / 100);
        _withdraw(payable(teamWallet), (balance * 20) / 100);
    }
    
    //send the percentage of funds to a shareholder´s wallet
    function _withdraw(address payable account, uint256 amount) internal {
        (bool sent, ) = account.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
    
    //to see the total amount of reserved mints left 
    function reservedMintsLeft() public onlyOwner view returns(uint) {
        return maxReservedMints - _reservedMints;
    }
    
    //see current state of sale
    //see the current state of the sale
    function saleState() public view returns(State) {
        if (genesisLaunchTime == 0) {
            return State.NoSale;
        }
        else if (presaleLaunchTime == 0) {
            return State.GenesisSale;
        }
        else if (publicSaleLaunchTime == 0) {
            return State.Presale;
        }
        else {
            return State.PublicSale;
        }
    }
    
    //gets the cost of current mint
    function mintCost() public view returns(uint) {
        State saleState_ = saleState();
        if (saleState_ == State.NoSale || saleState_ == State.GenesisSale) {
            return mintCostGenesisSale;
        }
        else if (saleState_ == State.Presale) {
            return mintCostPresale;
        }
        else {
            return mintCostPublicSale;
        }
    }

    //see if the NFTs have been revealed
    function haveBeenRevealed() public view returns(bool) {
        if (revealTime == 0) {
            return false;
        }
        else {
            return true;
        }
    }


    //reveal the NFTs
    function reveal() public onlyOwner() {
        require(revealTime == 0, 'NFTs have already been revealed!');
        revealTime = block.timestamp;
    }
    
   
    function changeVariable(address newAddress) public onlyOwner {
        variable = newAddress;
    }

    function burn(uint tokenId_) public {
        _burn(tokenId_, true);
    }

        /**
    @dev tokenId to staking start time (0 = not staking).
     */
    mapping(uint256 => uint256) private stakingStarted;

    /**
    @dev Cumulative per-token staking, excluding the current period.
     */
    mapping(uint256 => uint256) private stakingTotal;

    /**
    @notice Returns the length of time, in seconds, that the Emily has
    been framed.
    @dev staking is tied to a specific Emily, not to the owner, so it doesn"t
    reset upon sale.
    @return staking Whether the Emily is currently staking. MAY be true with
    zero current staking if in the same block as staking began.
    @return current Zero if not currently staking, otherwise the length of time
    since the most recent staking began.
    @return total Total period of time for which the Emily has been framed across
    its life, including the current period.
     */
    function stakingPeriod(uint256 tokenId)
        external
        view
        returns (
            bool staking,
            uint256 current,
            uint256 total
        )
    {
        uint256 start = stakingStarted[tokenId];
        if (start != 0) {
            staking = true;
            current = block.timestamp - start;
        }
        total = current + stakingTotal[tokenId];
    }

    /**
    @dev MUST only be modified by safeTransferWhilestaking(); if set to 2 then
    the _beforeTokenTransfer() block while staking is disabled.
     */
    uint256 private stakingTransfer = 1;

    /**
    @notice Transfer a token between addresses while the Emily is minting,
    thus not resetting the staking period.
     */
    function safeTransferWhilestaking(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(ownerOf(tokenId) == _msgSender(), 'Emilies: Only owner');
        stakingTransfer = 2;
        safeTransferFrom(from, to, tokenId);
        stakingTransfer = 1;
    }

    /**
    @dev Block transfers while staking.
     */
    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            require(stakingStarted[tokenId] == 0 || stakingTransfer == 2, 'Emilies: staking');
        }
    }

    /**
    @dev Emitted when an Emily begins staking.
     */
    event Staked(uint256 indexed tokenId);

    /**
    @dev Emitted when an Emily stops staking; either through standard means or
    by expulsion.
     */
    event UnStaked(uint256 indexed tokenId);

    /**
    @dev Emitted when an Emily is expelled from her frame.
     */
    event Expelled(uint256 indexed tokenId);

    /**
    @notice Whether staking is currently allowed.
    @dev If false then staking is blocked, but unstaking is always allowed.
     */
    bool public stakingOpen = false;

    /**
    @notice Toggles the `stakingOpen` flag.
     */
    function setStakingOpen(bool open) external onlyOwner {
        stakingOpen = open;
    }

    /**
    @notice Changes the Emily's staking status.
    */
    function toggleStaking(uint256 tokenId) internal onlyApprovedOrOwner(tokenId) {
        uint256 start = stakingStarted[tokenId];
        if (start == 0) {
            require(stakingOpen, 'Emily: staking closed');
            stakingStarted[tokenId] = block.timestamp;
            emit Staked(tokenId);
        } else {
            stakingTotal[tokenId] += block.timestamp - start;
            stakingStarted[tokenId] = 0;
            emit UnStaked(tokenId);
        }
    }


    /**
    @notice Changes the Emily's staking status.
    @dev Changes the Emily's staking status (see @notice).
     */
    function toggleStaking(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleStaking(tokenIds[i]);
        }
    }

    /**
    @notice Admin-only ability to expel an Emily from her frame.
    @dev As most sales listings use off-chain signatures it"s impossible to
    detect someone who has framed and then deliberately undercuts the floor
    price in the knowledge that the sale can"t proceed. This function allows for
    monitoring of such practices and expulsion if abuse is detected, allowing
    the undercutting Emily to be sold on the open market. Since OpenSea uses
    isApprovedForAll() in its pre-listing checks, we can"t block by that means
    because staking would then be all-or-nothing for all of a particular owner"s
    Emilies.
     */
    function expelFromStaking(uint256 tokenId) external onlyOwner{
        require(stakingStarted[tokenId] != 0, 'Emily: not framed');
        stakingTotal[tokenId] += block.timestamp - stakingStarted[tokenId];
        stakingStarted[tokenId] = 0;
        emit Staked(tokenId);
        emit Expelled(tokenId);
    }

}