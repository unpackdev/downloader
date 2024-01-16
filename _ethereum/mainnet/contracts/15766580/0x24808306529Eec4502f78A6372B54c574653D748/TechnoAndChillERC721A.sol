// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./AggregatorV3Interface.sol";

contract TechnoAndChillERC721A is Ownable, ERC721A, ERC721AQueryable, PaymentSplitter {

    using Strings for uint;

    AggregatorV3Interface internal priceFeed;


    enum Step {
        Before,
        WhitelistSale,
        PublicSale,
        SoldOut,
        Reveal
    }

    Step public sellingStep;

    uint public constant MAX_SUPPLY = 9999;
    uint public maxWlSale = 3000;
    uint public maxPublicSale = 1777;


    uint public wlSalePriceUsd = uint(349);
    uint public publicSalePriceUsd = uint(399);


    uint public currentStepStartTime = 1653902507;
    uint public currentStepEndTime = 1685438507;


    bytes32 public merkleRoot;

    string public baseURI;

    mapping(address => uint) amountNFTperWalletWhitelistSale;
    mapping(address => uint) amountNFTperWalletPublicSale;

    uint public nftMintedInWhitelistSale = 0;
    uint public nftMintedInPublicSale = 0;
    uint public giftNFTsMinted = 0;

    uint public  maxPerAddressDuringWhitelistSale = 2;
    uint public  maxPerAddressDuringPublicSale = 10;

    bool public isPaused;

    uint private teamLength;

    address[] private _team = [
    0x75dfb9E4503c88668247F735266B301c7902e376,
    0xDBb283ea2E2e53B2f2A10cC0aa7F59214E81360C,
    0xE8eE5116Ba8e2FD67A6505A807Bf4DbB9174aa93,
    0xc604E51e78F80BB82cD2f0D1984839EB2d8f21ed,
    0x39900d1ddB07c1e42d9D7c4c4CBF34af7F3cdD68,
    0xFCE128Cfba83BC59A6cDF9ab42E0C5b2E3b1680a,
    0x3c150f7888eA19a3E99909F71A6C30ccFDd3e33F,
    0xa7d42996EE1F33C25651cc1A01CA4A4753642C63,
    0xE940d7CfD462A92019Fd139D1Ee40bE83327bD83,
    0x5a9523ACb27846D1A36a9694E069F147850F7d74,
    0x9D25Ee021D16F0e6ee0122E7FA930adE9CAc9103,
    0xE99CbF39524C405CdE163e198c445E7192D123C1,
    0x15A14D28B95B3f11D2cd1EADCB44d44ff1D06C34,
    0xC494A4Dd4747DA10b0691c57BC93D0934400Af04,
    0x85EE323436710c6B091f23b2D1101Ddd2d1Ca585
    ];

    uint[] private _teamShares = [
        2925,
        1800,
        1800,
        1100,
        750,
        600,
        300,
        200,
        150,
        150,
        125,
        25,
        25,
        25,
        25
    ];

    //Constructor
    constructor()
    ERC721A("Techno And Chill", "TACPass") 
    PaymentSplitter(_team, _teamShares) {
        teamLength = _team.length;
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);//mainnet

    }


    /**
    * @notice This contract can't be called by other contracts
    */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
    * @notice Mint function for the Whitelist Sale
    *
    * @param _account Account which will receive the NFT
    * @param _quantity Amount of NFTs ther user wants to mint
    * @param _proof The Merkle Proof
    **/
    function whitelistMint(address _account, uint _quantity, bytes32[] calldata _proof) external payable callerIsUser{
        require(!isPaused, "Contract is paused");
        require(sellingStep == Step.WhitelistSale, "Whitelist sale is not activated");
        require(currentTime() >= currentStepStartTime, "Whitelist sale is not started yet");
        require(currentTime() < currentStepEndTime, "Whitelist sale is finished");

        uint priceWlInEth = getWlPriceEth();

        require(priceWlInEth != 0, "Price is 0");
        require(isWhitelisted(msg.sender, _proof), "Not whitelisted");
        require(amountNFTperWalletWhitelistSale[msg.sender] + _quantity <= maxPerAddressDuringWhitelistSale, "You have reached the maximum number of NFTs minted for the whitelist sale");
        require(totalSupply() + _quantity <= maxWlSale, "Whitelist sale supply exceeded");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Total Supply exceeded");
        require(msg.value >= priceWlInEth * _quantity, "Not enougt funds");
        amountNFTperWalletWhitelistSale[msg.sender] += _quantity;
        nftMintedInWhitelistSale += _quantity;
        _safeMint(_account, _quantity);
    }

    /**
    * @notice Mint function for the Current Sale
    *
    * @param _account Account which will receive the NFT
    * @param _quantity Amount of NFTs ther user wants to mint
    **/
    function publicMint(address _account, uint _quantity) external payable callerIsUser {
        require(!isPaused, "Contract is paused");
        require(currentTime() >= currentStepStartTime, "Current sale step is not started yet");
        require(currentTime() < currentStepEndTime, "Current sale step is finished");
        require(sellingStep == Step.PublicSale, "Public sale is not activated");

        uint pricePublicInEth = getPublicPriceEth();

        require(pricePublicInEth != 0, "Price is 0");
        require(amountNFTperWalletPublicSale[msg.sender] + _quantity <= maxPerAddressDuringPublicSale, "You have reached the maximum number of NFTs minted for the public sale");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Total Supply exceeded");
        require(msg.value >= pricePublicInEth * _quantity, "Not enough funds");
        amountNFTperWalletPublicSale[msg.sender] += _quantity;
        nftMintedInPublicSale += _quantity;
        _safeMint(_account, _quantity);

    }

   
  
    /**
    * @notice Allows the owner to gift NFTs
    *
    * @param _to The address of the receiver
    * @param _quantity Amount of NFTs the owner wants to gift
    **/
    function gift(address _to, uint _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max supply");
        giftNFTsMinted += _quantity;
        _safeMint(_to, _quantity);
    }



    /**
    * @notice Get the token URI of an NFT by his ID
    *
    * @param _tokenId The ID of the NFT you want to have the URI of the metadatas
    *
    * @return the token URI of an NFT by his ID
    */
    function tokenURI(uint _tokenId) public view virtual override(ERC721A, IERC721Metadata) returns(string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }



    /**
    * @notice Allows to set the max per address during whitelist sale
    *
    * @param _maxPerAddressDuringWhitelistSale The new supply for the whitelist sale
    */
    function setMaxPerAddressDuringWhitelistSale(uint _maxPerAddressDuringWhitelistSale) external onlyOwner {
        maxPerAddressDuringWhitelistSale = _maxPerAddressDuringWhitelistSale;
    }

    /**
    * @notice Allows to set the max per address during the public sale
    *
    * @param _maxPerAddressDuringPublicSale The new supply for the whitelist sale
    */
    function setMaxPerAddressDuringPublicSale(uint _maxPerAddressDuringPublicSale) external onlyOwner {
        maxPerAddressDuringPublicSale = _maxPerAddressDuringPublicSale;
    }

    /**
    * @notice Allows to set the max whitelist supply
    *
    * @param _maxWlSale The new supply for the whitelist sale
    */
    function setMaxWlSupply(uint _maxWlSale) external onlyOwner {
        require(MAX_SUPPLY >= _maxWlSale + maxPublicSale, "MAX Supply is 9999");
        require(_maxWlSale >= nftMintedInWhitelistSale, "NFT minted in the whiteliste sale greater than the new limit");
        maxWlSale = _maxWlSale;
    }

    /**
    * @notice Allows to set the max public sale supply
    *
    * @param _maxPublicSale The new supply for the public sale
    */
    function setMaxPublicSaleSupply(uint _maxPublicSale) external onlyOwner {
        require(MAX_SUPPLY >= maxWlSale + _maxPublicSale, "MAX Supply is 9999");
        require(_maxPublicSale >= nftMintedInPublicSale, "NFT minted in the public sale greater than the new limit");
        maxPublicSale = _maxPublicSale;
    }

    /**
    * @notice Change the starting time (timestamp) of the current sale step
    *
    * @param _currentStepStartTime The new timestamp of the current start sale step
    */
    function setCurrentStepStartTime(uint _currentStepStartTime) external onlyOwner {
        currentStepStartTime = _currentStepStartTime;
    }

    /**
    * @notice Change the end time (timestamp) of the current sale step
    *
    * @param _currentStepEndTime The new timestamp of the current end sale step
    */
    function setCurrentStepEndTime(uint _currentStepEndTime) external onlyOwner {
        currentStepEndTime = _currentStepEndTime;
    }


    
    /**
    * @notice Allows to prepay price
    *
    * @param _wlSalePriceUsd the new prepay price 
    */
    function setWlSalePriceUsd(uint _wlSalePriceUsd) external onlyOwner {
        wlSalePriceUsd = _wlSalePriceUsd;
    }


     /**
    * @notice get prepay price
    *
    */
    function getWlPriceEth() public view  returns (uint){ 

        return  uint(wlSalePriceUsd * 10**26)/uint(getLatestPrice());
    }


    /**
    * @notice Allows to prepay price
    *
    * @param _publicSalePriceUsd the new prepay price 
    */
    function setPublicPriceUsd(uint _publicSalePriceUsd) external onlyOwner {
        publicSalePriceUsd = _publicSalePriceUsd;
    }


     /**
    * @notice get prepay price
    *
    */
    function getPublicPriceEth() public view  returns (uint){ 

        return  uint(publicSalePriceUsd * 10**26)/uint(getLatestPrice());
    }

   

    /**
    * @notice Get the current timestamp
    *
    * @return the current timestamp
    */
    function currentTime() internal view returns(uint) {
        return block.timestamp;
    }

    /**
    * @notice Change the step of the sale
    *
    * @param _step The new step of the sale
    */
    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    /**
    * @notice Pause or unpause the smart contract
    *
    * @param _isPaused true or false if we want to pause or unpause the contract
    */
    function setPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    /**
    * @notice Change the base URI of the NFTs
    *
    * @param _baseURI the new base URI of the NFTs
    */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
    * @notice Change the merkle root
    *
    * @param _merkleRoot the new MerkleRoot
    */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
    * @notice Hash an address
    *
    * @param _account The address to be hashed
    *
    * @return bytes32 The hashed address
    */
    function leaf(address _account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    /**
    * @notice Returns true if a leaf can be proved to be a part of a merkle tree defined by root
    *
    * @param _leaf The leaf
    * @param _proof The Merkle Proof
    *
    * @return True if a leaf can be proved to be a part of a merkle tree defined by root
    */
    function _verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns(bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    /**
    * @notice Check if an address is whitelisted or not
    *
    * @param _account The account checked
    * @param _proof The Merkle Proof
    *
    * @return bool return true if the address is whitelisted, false otherwise
    */
    function isWhitelisted(address _account, bytes32[] calldata _proof) internal view returns(bool) {
        return _verify(leaf(_account), _proof);
    }


    function getBalance() public view returns(uint){

        return address(this).balance;
    }
    /**
    * @notice Release the gains on every accounts
    */
    function releaseAll() external {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }


    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (uint) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return uint(price);
    }


    //Not allowing receiving ethers outside minting functions
    receive() override external payable {
        revert('Only if you mint');
    }

}