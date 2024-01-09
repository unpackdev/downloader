// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeCast.sol";
import "./OrderStatisticsTreeLib.sol";
import "./CryptoCocksWhitelistingLib.sol";
import "./CryptoCocksLib.sol";

/**
 * CryptoCocks is a decentralized generative art project where the rarity of the
 * unique digital collectibles (ERC721 NFTs) not only is determined by
 * pseudo-randomly assigned traits of varying frequency but also how someone's
 * wallet balance at the time of minting compares with the wallet balance of
 * previous minters at the time they minted their token. CryptoCocks tokens
 * are fair-priced meaning that the cost for minting will always be 1% of that
 * minter's wallet balance and is primarily decisive for the rarity of the minted NFT.
 * The total supply of CryptoCocks is limited to 10000 unique tokens and each image
 * is stored decentralized on IPFS and Filecoin forever.
 */
contract CryptoCocks is ERC721("CryptoCocks", "CC"), ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using OrderStatisticsTreeLib for OrderStatisticsTreeLib.Tree;
    using CryptoCocksWhitelistingLib for CryptoCocksWhitelistingLib.Whitelist;

    struct Settings {
        // true => active public sale
        bool publicSaleStatus;

        // true => minting does not require fee
        bool freeMinting;

        // true => initMint was not yet executed
        bool initMint;

        // true => whitelist checks are executed
        bool isWhitelistingEnabled;

        // Percentages of the minter's wallet balance to be sent
        // to the contract as ether value when minting.
        uint8 percFee;

        // Minimum of sent Ether value in Wei required when minting
        uint128 minFee;
    }

    struct Balances {
        uint128 team; // tracking accumulated royalty fee
        uint128 donation; // tracking accumulated royalty fee
    }

    /**
     * Event for minting a new NFT
     */
    event Mint(
        uint16 indexed id,
        uint balance
    );

    /**
     * Event to show OpenSea that URI cannot be changed
     */
    event PermanentURI(
        string _value,
        uint256 indexed _id
    );

    Counters.Counter private _tokenIdTracker;
    OrderStatisticsTreeLib.Tree private tree;
    CryptoCocksWhitelistingLib.Whitelist private whitelist;

    Settings public set;
    Balances public bal; // Tracks collected ether for team and donation wallet

    address payable public teamWallet; // Receives 50% of revenue
    address payable public donationWallet; // Receives 30% of revenue

    constructor() {
        set = Settings(false, true, true, true, 100, 0.02 ether); // Set default settings
        bal = Balances(0, 0);

        // Multisig team wallet address
        teamWallet = payable(0x5b1f57449Dd479e787FDF201a59d06D3Cb84F5Dc);

        // The Giving Block donation address ('Trees for the Future' reforestation project)
        donationWallet = payable(0xb1019Eb5e90aD29C2FcE82AAB712325a1A3d5924);
    }

    /**
     * - Mints new NFT.
     * - Stores balance in tree.
     * - Calculates cock length.
     * - Constructs token.
     * - Transfers collected revenue every 50th mint.
     */
    function mint() external virtual payable {
        uint16 newTokenId = uint16(_tokenIdTracker.current() + 31); // 30 initial mints + 1 (tokenIDs should begin with 1)
        uint value = msg.value;
        (bool wL, uint8 idx) = set.isWhitelistingEnabled ? whitelist.checkListed(msg.sender) : (false, 0);

        // Test conditions
        require((set.publicSaleStatus || wL), "LOCK");
        require(newTokenId <= uint16(10000), "TOTAL_SUPPLY_REACHED");
        require(balanceOf(msg.sender) == 0, "ONLY_ONE_NFT");

        // Calculate balance
        uint balance = msg.sender.balance + value;
        if (!set.freeMinting) {
            require(value >= ((balance / set.percFee) < set.minFee ? set.minFee : (balance / set.percFee)), "INSUFFICIENT_FUNDS");
            balance = value * set.percFee;
        }

        // Internal function to safely mint a new token.
        // Reverts if the given token ID already exists.
        _safeMint(msg.sender, uint(newTokenId));

        // Create tokenURI
        _createTokenURI(newTokenId, tree.insertCock(newTokenId, balance));
        _tokenIdTracker.increment();
        emit Mint(newTokenId, balance);

        // Store fees in tracker variable
        bal.team += SafeCast.toUint128(value / 2); // 50% to team
        bal.donation += SafeCast.toUint128((value * 30) / 100); // 30% donated

        // Deposit royalty fee in each community wallet 20% to communities
        whitelist.depositRoyalties(SafeCast.toUint128(value));

        // Increase supply tracker of whitelisted contract, if applicable.
        if (wL) {
            whitelist.increaseSupply(idx);
        }

        // Execute fee transactions every 50th NFT.
        if (newTokenId % 50 == 0) {
            uint teamAmount = bal.team;
            uint donationAmount = bal.donation;
            bal.team = 0;
            bal.donation = 0;
            Address.sendValue(payable(teamWallet), teamAmount);
            Address.sendValue(payable(donationWallet), donationAmount);
        }
    }

    /**
     * Initialize minting process with 30 auto-minted NFTs for the contract owner
     */
    function initMint() external onlyOwner {
        require(set.initMint, "ONLY_ONCE");
        for (uint i = 0; i < 30; i++) {
            _safeMint(msg.sender, uint16(i+1));
            uint8 length = SafeCast.toUint8(i > 9 ? (i % 10) + 1: 11);
            _createTokenURI(uint16(i+1), length);
            set.initMint = false;
        }
    }

    /**
     * Add community contract to whitelist
     *
     * Allows token holders to mint NFTs before public sale starts.
     * 20% of the collected ether value on mints is distributed to the registered communities
     */
    function addWhiteListing(
        uint8 id, // unique identifier of a ListContract instance
        bool erc1155, // true if contract implements IERC11555 otherwise IERC20/IERC721
        address cc, // community contract addresses
        address payable wallet, // community wallet addresses
        uint16 maxSupply, // max NFTs for whitelisted owners
        uint16 minBalance, // min balance needed on whitelisted contracts
        uint8 percRoyal, // percentage royal fee for each contract
        uint erc1155Id // optional: erc1155 token type id
    ) external onlyOwner {
        whitelist.addContract(id, erc1155, cc, wallet, maxSupply, minBalance, percRoyal, erc1155Id);
    }

    /**
     * Remove whitelisted community contract
     */
    function removeWhitelisting(uint8 lcId) external onlyOwner {
        whitelist.removeContract(lcId);
    }

    /**
     * Transfer royalties from contract to registered community wallet
     */
    function transferRoyalty() external {
        Address.sendValue(payable(msg.sender), whitelist.popRoyalties(msg.sender));
    }

    /**
     * Changes fee settings of contract
     */
    function changeFeeSettings(bool status, uint8 percFee, uint128 minFee) external onlyOwner {
        require(status || percFee > 0, "DIVIDE_BY_ZERO");
        set.freeMinting = status; // true => minting does not require a fee
        set.percFee = percFee; // percFee, denoted as denominator (i.e., 1/percFee)
        set.minFee = minFee; // minFee, denoted in Wei
    }

    /**
     * Enable or disable whitelisting functionality
     */
    function changeWhitelistingSettings(bool enabled) external onlyOwner {
        set.isWhitelistingEnabled = enabled;
    }

    /**
     * Get whitelisted community contract information by identifier
     */
    function getListContract(uint8 lcId) external view returns (CryptoCocksWhitelistingLib.ListContract memory lc) {
        return whitelist.getListContract(lcId);
    }

    /**
     * Query token balance of an account from the community token specified by list index
     */
    function queryBalance(uint8 listIndex, address addressToQuery) external view returns (uint) {
        return whitelist.queryBalance(listIndex, addressToQuery);
    }

    /**
     * Changes status of publicSaleStatus (true => active public sale)
     */
    function changePublicSaleStatus(bool newStatus) external onlyOwner {
        set.publicSaleStatus = newStatus;
    }

    /**
     * Using ERC721URIStorage over ERC721 for tokenURI()
     */
    function tokenURI(uint tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return string(abi.encodePacked(CryptoCocksLib.getCid(tokenId), super.tokenURI(tokenId)));
    }

    /**
     * Gets the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256) {
        return set.initMint ? _tokenIdTracker.current() : _tokenIdTracker.current() + 30;
    }

    /**
    * Crate TokenURI during mint process
    */
    function _createTokenURI(uint16 _newTokenId, uint8 _length) private {
        string memory _tokenURI = string(abi.encodePacked(Strings.toString(_length), "_", Strings.toString(_newTokenId), ".json"));
        _setTokenURI(_newTokenId, _tokenURI);
        emit PermanentURI(_tokenURI, _newTokenId);
    }

    // slither-disable-next-line dead-code
    function _burn(uint tokenId)
    internal
    override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }
}
