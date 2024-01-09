// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "SafeMath.sol";
import "Strings.sol";

contract VentureVX is ERC721Enumerable, Ownable {
    enum VentureRank {Joe, Hank, Howard, Reptilian}

    using Strings for uint256;
    using SafeMath for uint256;

    enum MintStage {PAUSED, WHITELIST, PUBLIC}

    MintStage public stage = MintStage.PAUSED;

    mapping(address => bool) whitelisted;

    uint256 public MAX_PER_TX;
    uint256 public MAX_PER_WALLET;

    address public daoAddress;

    struct RankDetails {
        bool exists;
        uint256 current_index;
        uint256 starting_index;
        uint256 end_index;
        uint256 amount_available;
        uint256 price;
        uint256 whitelist_price;
    }

    string ventureURI;

    mapping(uint256 => RankDetails) public token_tracker;

    constructor (string memory _ventureURI, address _daoAddress) public ERC721 ("VentureVX", "VVX"){
        token_tracker[uint256(VentureRank.Reptilian)] = RankDetails(true, 1, 1, 8, 0, 99 ether, 99 ether);
        token_tracker[uint256(VentureRank.Howard)] = RankDetails(true, 9, 9, 508, 0, 0.2 ether, 0.08 ether);
        token_tracker[uint256(VentureRank.Hank)] = RankDetails(true, 509, 509, 3008, 0, 0.13 ether, 0.06 ether);
        token_tracker[uint256(VentureRank.Joe)] = RankDetails(true, 3009, 3009, 10000, 0, 0.09 ether, 0.04 ether);
        MAX_PER_TX = 5;
        MAX_PER_WALLET = 5;
        ventureURI = _ventureURI;
        daoAddress = _daoAddress;

        setRankAvailability(uint256(VentureRank.Howard), 5);
        setRankAvailability(uint256(VentureRank.Hank), 15);
        setRankAvailability(uint256(VentureRank.Joe), 130);

        setMintStage(MintStage.WHITELIST);
    }

    function setRankAvailability(uint256 mint_type, uint256 amount) public onlyOwner
    {
        require(amount > 0, "Amount must be bigger than 0");

        RankDetails storage rank = token_tracker[mint_type];
        require(rank.exists, "The token type provided does not exist!");

        rank.amount_available = amount;
    }

    function daoMint(uint256 mint_type, uint256 mint_amount, address to) public onlyOwner
    {
        RankDetails storage rank = token_tracker[mint_type];
        require(rank.exists, "The token type provided does not exist!");

        for(uint256 i=0; i<mint_amount; i++)
        {
            require(rank.amount_available > 0, "Rank is no longer available");
            rank.amount_available = rank.amount_available.sub(1);

            uint256 tokenId = rank.current_index;
            require(tokenId < rank.end_index, "Mint: Rank has reached maximum minting");
            rank.current_index = rank.current_index.add(1);
            ERC721._safeMint(to, tokenId);
        }
    }

    function mint(uint256 mint_type, uint256 mint_amount) external payable
    {
        require(stage != MintStage.PAUSED, "Contract is currently paused");
        require(mint_amount > 0 && mint_amount <= MAX_PER_TX, "Maximum mint amount per transaction reached!");

        RankDetails storage rank = token_tracker[mint_type];
        require(rank.exists, "The token type provided does not exist!");
        uint256 price = getPrice(mint_type);

        require((price).mul(mint_amount) == msg.value, "Ether received does not equal to the required ether");

        require(ERC721.balanceOf(msg.sender) + mint_amount < MAX_PER_WALLET, "You have reached the maximum you can mint!");

        if (stage == MintStage.WHITELIST)
        {
            require(isWhitelisted(msg.sender), "Your wallet is not whitelisted!");
        }

        for(uint256 i=0; i<mint_amount; i++)
        {
            require(rank.amount_available > 0, "Rank is no longer available");
            rank.amount_available = rank.amount_available.sub(1);

            uint256 tokenId = rank.current_index;
            require(tokenId < rank.end_index, "Mint: Rank has reached maximum minting");

            rank.current_index = rank.current_index.add(1);
            ERC721._safeMint(msg.sender, tokenId);
        }

        (bool sent, ) = payable(daoAddress).call{value: msg.value}("");
        require(sent, "Could not transfer funds to DAO");
    }

    function setMaxPerTX(uint256 _amount) external onlyOwner
    {
        require(_amount > 0, "Amount must be bigger than 0");
        MAX_PER_TX = _amount;
    }

    function setMaxPerWallet(uint256 _amount) external onlyOwner
    {
        require(_amount > 0, "Amount must be bigger than 0");
        MAX_PER_WALLET = _amount;
    }

    function getPrice(uint256 mint_type) public view returns (uint256)
    {
        require(stage != MintStage.PAUSED, "Cannot retrieve price - mint stage is PAUSED");
        RankDetails memory rank = token_tracker[mint_type];
        return stage == MintStage.WHITELIST ? rank.whitelist_price : rank.price;
    }

    function setPrice(uint256 mint_type, uint256 price, uint256 whitelist_price) external onlyOwner
    {
        RankDetails storage rank = token_tracker[mint_type];
        rank.price = price;
        rank.whitelist_price = whitelist_price;
    }

    function isWhitelisted(address wallet) public view returns (bool)
    {
        return whitelisted[wallet];
    }

    function setMintStage(MintStage _stage) public onlyOwner
    {
        stage = _stage;
    }

    function setDaoAddress(address _daoAddress) external onlyOwner
    {
        require(daoAddress != address(0), "DAO Address cannot be 0 address");
        daoAddress = _daoAddress;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner
    {
        ventureURI = _baseURI;
    }

    function addToWhitelist(address[] memory wallets) external onlyOwner
    {
        for (uint256 i=0; i<wallets.length; i++)
        {
            whitelisted[wallets[i]] = true;
        }
    }

    function removeFromWhitelist(address[] memory wallets) external onlyOwner
    {
        for (uint256 i=0; i<wallets.length; i++)
        {
            whitelisted[wallets[i]] = false;
        }
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return ventureURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "tokenURI: URI query for nonexistent token");

        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI(), "/", tokenId.toString(), ".json"));
    }

}