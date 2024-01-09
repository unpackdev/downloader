// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeCast.sol";
import "./OrderStatisticsTreeLib.sol";
import "./CryptoCocksLib.sol";

contract TokenInterface {
    // solhint-disable-next-line no-empty-blocks
    function balanceOf(address owner) external view returns (uint balance) {}
}

contract CryptoCocks is ERC721("CryptoCocks", "CC"), ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using OrderStatisticsTreeLib for OrderStatisticsTreeLib.Tree;

    struct Settings {
        bool publicSaleStatus; // true => active public sale
        bool freeMinting; // true => minting does not require fee
        bool initMint; // true => initMint was not yet executed
        uint8 percFee; // int only (e.g., 1/100)
        uint8 availRoyal; // available royal for community wallets (in percentage points)
        uint8 numContracts; // number of whitelisted contracts
        uint128 minFee; // in Wei
    }

    struct Balances {
        uint128 team; // tracking accumulated royalty fee
        uint128 donation; // tracking accumulated royalty fee
    }

    struct ListContract {
        uint8 percRoyal; // percentage royal fee for each contract
        uint16 maxSupply; // max NFTs for whitelisted owners
        uint16 minBalance; // min balance needed on whitelisted contracts
        uint16 tracker; // tracking number of minted NFTs per whitelisted contract
        uint128 balance;  // tracking accumulated royalty fee
        address cc; // community contract addresses
        address wallet; // community wallet addresses
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
    OrderStatisticsTreeLib.Tree public tree;

    Settings public set;
    Balances public bal;
    mapping(uint8 => ListContract) public list; // contract mapping that are whitelisted

    address payable public teamWallet;
    address payable public donationWallet;

    constructor() {
        set = Settings(false, true, true, 100, 20, 0, 0.02 ether);
        bal = Balances(0, 0);
        teamWallet = payable(0x5b1f57449Dd479e787FDF201a59d06D3Cb84F5Dc); //multisig address
        donationWallet = payable(0xb1019Eb5e90aD29C2FcE82AAB712325a1A3d5924); //enter giving block address
    }

    /**
     * Check balance of address on a another ERC721 contract
     */
    function queryBalance(address tokenAddress, address addressToQuery) public view returns (uint) {
        return TokenInterface(tokenAddress).balanceOf(addressToQuery);
    }

    /**
     * Mints new NFT, storing position in tree, constructs tokenURI and executes fee payment
     */
    function mint()
    external
    virtual
    payable
    {
        (bool wL, uint8 idx) = _checkListed(msg.sender);
        uint16 newTokenId = uint16(_tokenIdTracker.current() + 31);
        uint value = msg.value;

        // test conditions
        require((set.publicSaleStatus || wL), "LOCK");
        require(newTokenId <= uint16(10000), "TOTAL_SUPPLY_REACHED");
        require(balanceOf(msg.sender) == 0, "ONLY_ONE_NFT");

        uint balance = msg.sender.balance + value;

        if (!set.freeMinting) {
            require(value >= ((balance / set.percFee) < set.minFee ? set.minFee : (balance / set.percFee)), "INSUFFICIENT_FUNDS");
            balance = value * set.percFee;
        }

        _safeMint(msg.sender, uint(newTokenId));

        // create token URI
        _createTokenURI(newTokenId, tree.insertCock(newTokenId, balance));
        _tokenIdTracker.increment();
        emit Mint(newTokenId, balance);

        /**
         * Store fees in tracker variable
         */
        bal.team += SafeCast.toUint128(value / 2); // 50% to team
        bal.donation += SafeCast.toUint128((value * 30) / 100); // 30% donated

        /**
         * Deposit royalty fee in each community wallet
         * 20% to communities
         */
        for (uint8 i = 0; (i < set.numContracts); i++) {
            list[i].balance += uint128((value * list[i].percRoyal) / 100);
        }

        /**
         * Increase supply tracker of whitelisted contract, if applicable.
         */
        if (wL) {
            list[idx].tracker += 1;
        }

        /**
         * Execute fee transactions every 50th NFT.
         */
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
     * Add contract address to whitelisting with maxSupply
     * Allows token holders to mint NFTs before the Public Sale start
     */
    function addWhiteListing(address cc, address payable wallet, uint16 maxSupply, uint16 minBalance, uint8 percRoyal) external onlyOwner {
        require(set.availRoyal >= percRoyal, "FEE_TOO_HIGH");
        list[set.numContracts] = ListContract(percRoyal, maxSupply, minBalance, 0, 0, cc, wallet);
        set.availRoyal -= percRoyal;
        set.numContracts += 1;
    }

    /**
     * Transfer royalties from contract address to registered community wallet
     */
    function transferRoyalty() external {
        bool isCommunityWallet = false;
        uint8 idx = 0;
        for (uint8 i = 0; i < set.numContracts; i++) {
            if (list[i].wallet == msg.sender) {
                isCommunityWallet = true;
                idx = i;
                break;
            }
        }
        require(isCommunityWallet, "NO_COMMUNITY_WALLET");
        uint amount = list[idx].balance;
        list[idx].balance = 0;
        Address.sendValue(payable(msg.sender), amount);
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
     * Using ERC721Enumerable over ERC721 for supportsInterface()
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Using ERC721Enumerable over ERC721 for _beforeTokenTransfer()
     */
    function _beforeTokenTransfer(address from, address to, uint tokenId)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // slither-disable-next-line dead-code
    function _burn(uint tokenId)
    internal
    override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    /**
     * Checking whether an account holds enough tokens from a whitelisted contract
     * and maxSupply in this contract is not reached yet.
     */
    function _checkListed(address account) private view returns (bool, uint8) {
        for (uint8 i = 0; i < set.numContracts; i++) {
            if ((queryBalance(list[i].cc, account) >= list[i].minBalance) && (list[i].maxSupply > list[i].tracker)) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /**
    * Crate TokenURI during mint process
    */
    function _createTokenURI(uint16 _newTokenId, uint8 _length) private {
        string memory _tokenURI = string(abi.encodePacked(Strings.toString(_length), "_", Strings.toString(_newTokenId), ".json"));
        _setTokenURI(_newTokenId, _tokenURI);
        emit PermanentURI(_tokenURI, _newTokenId);
    }
}
