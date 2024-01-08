// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/* solhint-disable */

// REMIX
// import "./Ownable.sol";
// import "./SafeMath.sol";
// import "./Address.sol";
// import "./ERC20.sol";
// import "./ERC721.sol";
// import "./AggregatorV3Interface.sol";

// TRUFFLE
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ERC20.sol";
import "./ERC721.sol";
import "./AggregatorV3Interface.sol";

/* solhint-enable */

// NFTSale SMART CONTRACT
contract NFTSale is Ownable {
    using Address for address;
    using SafeMath for uint256;

    address public nftAddress;

    // user address => admin? mapping
    mapping(address => bool) private _admins;
    mapping(uint256 => address) public _winners;
    mapping(uint256 => uint256) private _winnerCostsEuroCents;
    mapping(uint256 => address payable) private _winnerHolders;
    mapping(uint256 => bool) public _winnerPaid;

    event AdminAccessSet(address _admin, bool _enabled);
    event ArtworkReleased(uint256 _nftId, address _buyer, uint256 _timestamp);
    
    AggregatorV3Interface internal priceFeed_eth_usd;
    AggregatorV3Interface internal priceFeed_eur_usd;

    /**
     * Network: Rinkeby
     * Aggregator: ETH/USD
     * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
     */


    /**
     * Network: Rinkeby
     * Aggregator: EUR/USD
     * Address: 0x78F9e60608bF48a1155b4B2A5e31F32318a1d85F
     */


    /**
     * Network: Mainnet
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */
    address public constant eth_usd_feed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    /**
     * Network: Mainnet
     * Aggregator: EUR/USD
     * Address: 0xb49f677943BC038e9857d61E7d053CaA2C1734C1
     */
    address public constant eur_usd_feed = 0xb49f677943BC038e9857d61E7d053CaA2C1734C1;

    constructor(address _nftAddress) public {
        require(_nftAddress.isContract(), "_nftAddress must be a contract");
        nftAddress = _nftAddress;
        _admins[msg.sender] = true;
        priceFeed_eth_usd = AggregatorV3Interface(eth_usd_feed);
        priceFeed_eur_usd = AggregatorV3Interface(eur_usd_feed);
    }

    /**
     * Set Admin Access
     *
     * @param admin - Address of Minter
     * @param enabled - Enable/Disable Admin Access
     */
    function setAdmin(address admin, bool enabled) external onlyOwner {
        _admins[admin] = enabled;
        emit AdminAccessSet(admin, enabled);
    }

    /**
     * Check Admin Access
     *
     * @param admin - Address of Admin
     * @return whether minter has access
     */
    function isAdmin(address admin) public view returns (bool) {
        return _admins[admin];
    }
    
    /**
     * Check Payment Status
     *
     * @param nftId - nftId of the artwork
     * @return whether artwork was paid
     */
    function isArtworkPaid(uint256 nftId) public view returns (bool) {
        return _winnerPaid[nftId];
    }

    /**
     * Prepare release Artwork
     * Mark how won bid and must pay
     *
     * @param nftId - nftId of the artwork
     * @param to - address of the artwork winner of auction
     * @param priceEuroCents - how much must be paid
     * @param holder - who will be paid
     */
    function prepareReleaseArtwork(uint256 nftId, address to, uint256 priceEuroCents, address payable holder) public onlyAdmin {
        _winners[nftId] = to;
        _winnerCostsEuroCents[nftId] = priceEuroCents;
        _winnerHolders[nftId] = holder;
    }

    /**
     * As a winner, check price (wei) to pay for the artwork
     *
     * @param nftId - nftId of the artwork
     */
    function getArtworkPrice(uint nftId) public view returns (uint) {
        require(
            _winners[nftId] == msg.sender,
            "Caller does not have Winner Access"
        );
        uint eth_eur = getThePrice_eth_eur();
        uint wei2pay = 1e18 wei * _winnerCostsEuroCents[nftId] / ( eth_eur * 100 );
        return wei2pay;
    }

    /**
     * Buy release Artwork
     * Pay as winner
     *
     * @param nftId - nftId of the artwork
     */
    function buyReleaseArtwork(uint256 nftId) public payable {
        uint wei2pay = getArtworkPrice(nftId);
        require(
            wei2pay <= msg.value,
            "Caller does not pay enough"
        );
        uint clientsShare = wei2pay * 762 / 1000;
	require(
            clientsShare <= wei2pay,
            "Cannot compute client share correctly"
        );

        _winnerHolders[nftId].transfer(clientsShare);
        payOwnerFee(payable(Ownable.owner()), msg.value - clientsShare);
        _winnerPaid[nftId] = true;
        releaseBoughtArtwork(nftId, msg.sender);
    }


    /**
     * Pay Owner the share of Artwork sale
     *
     * @param recipient - owner of NFTSale
     * @param amount - amount to pay
     */
    function payOwnerFee (address payable recipient, uint amount) internal {
        recipient.transfer(amount);
    }

    /**
     * Release Artwork
     * Contract instance NFTSale must pass _isApprovedOrOwner of nftAddress for nftId
     * Must call setApprovalForAll(nftSaleAddress, true)
     *
     * @param nftId - nftId of the artwork
     * @param to - address of the artwork recipient
     */
    function releaseArtwork(uint256 nftId, address to) public onlyAdmin {
        _winnerPaid[nftId] = true;
        ERC721(nftAddress).transferFrom(ERC721(nftAddress).ownerOf(nftId), to, nftId);
        emit ArtworkReleased(nftId, to, block.timestamp);
    }

    /**
     * Release Artwork that was payed by winning bidder
     * Contract instance NFTSale must pass _isApprovedOrOwner of nftAddress for nftId
     * Must call setApprovalForAll(nftSaleAddress, true)
     *
     * @param nftId - nftId of the artwork
     * @param to - address of the artwork recipient
     */
    function releaseBoughtArtwork(uint256 nftId, address to) internal {
        require(
            _winners[nftId] == to,
            "Caller does not have Winner Access"
        );
        require(
            _winnerPaid[nftId],
            "Artwork is not paid yet"
        );
        ERC721(nftAddress).transferFrom(ERC721(nftAddress).ownerOf(nftId), to, nftId);
        emit ArtworkReleased(nftId, to, block.timestamp);
    }
    
    /**
     * Get latest ETH / EUR price
     */
    function getThePrice_eth_eur() public view returns (uint) {
        return uint(getThePrice_eth_usd() / getThePrice_eur_usd());
    }
    
    /**
     * Get latest ETH / USD price
     */
    function getThePrice_eth_usd() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed_eth_usd.latestRoundData();
        return price;
    }
    
    /**
     * Get latest EUR / USD price
     */
    function getThePrice_eur_usd() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed_eur_usd.latestRoundData();
        return price;
    }

    /**
     * Throws if called by any account other than the Admin.
     */
    modifier onlyAdmin() {
        require(
            _admins[msg.sender] || msg.sender == owner(),
            "Caller does not have Admin Access"
        );
        _;
    }
}
