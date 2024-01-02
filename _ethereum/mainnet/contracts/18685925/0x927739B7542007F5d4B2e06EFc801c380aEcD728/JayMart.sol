//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./IERC1155Receiver.sol";

import "./IERC1155.sol";

import "./IERC721.sol";

import "./AggregatorV3Interface.sol";
import "./Ownable.sol";

import "./ReentrancyGuard.sol";

interface IJAY {
    function sell(uint256 value) external;

    function buy(address reciever) external payable;

    function burnFrom(address account, uint256 amount) external;

    function ETHtoJAY(uint256 value) external view returns (uint256);
}

contract JayMart is Ownable, ReentrancyGuard {
    // Define our price feed interface
    AggregatorV3Interface internal priceFeed;

    address public immutable JAYMART = 0x130F0002b4cF5E67ADf4C7147ac80aBEe7b3Fe0a;

    // Create variable to hold the team wallet address
    address payable private TEAM_WALLET;

    // Create variable to hold contract address
    address payable private immutable JAY_ADDRESS;

    // Define new IJAY interface
    IJAY private immutable JAY;

    // Define some constant variables
    uint256 private constant SELL_NFT_PAYOUT = 55;
    uint256 private constant SELL_NFT_FEE_VAULT = 20;
    uint256 private constant SELL_NFT_FEE_TEAM = 20;
    uint256 private constant SELL_NFT_REF = 5;
    

    uint256 private constant USD_PRICE_SELL = 2 * 10 ** 18;
   
    uint256 private sellNftFeeEth = 0.001 * 10 ** 18;

    mapping(address => string) refAddresses;
    mapping(string => address) refsTaken;
    mapping(address => uint) refBlanaces;
    mapping(address => address) refsLocked;

    // Create variable to hold when the next fee update can occur
    uint256 private nextFeeUpdate = block.timestamp + (7 days);

    // Constructor
    constructor() {
        JAY = IJAY(0xDA7C0810cE6F8329786160bb3d1734cf6661CA6E);
        JAY_ADDRESS = payable(0xDA7C0810cE6F8329786160bb3d1734cf6661CA6E);
        setTEAMWallet(0x985B6B9064212091B4b325F68746B77262801BcB);
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        ); //main
    }

    function setTEAMWallet(address _address) public onlyOwner {
        TEAM_WALLET = payable(_address);
    }

    function setRef(string memory ref) public {
        require(refsTaken[ref] == address(0), "this ref id is taken sorry");
        string memory usersCurrentRef = refAddresses[msg.sender];
        if(bytes(usersCurrentRef).length > 0){
            refsTaken[usersCurrentRef] = address(0);
        }
        refAddresses[msg.sender] = ref;
        refsTaken[ref] = msg.sender;
    }
    function isValidRef(string memory ref) public view returns (bool) {
        return refsTaken[ref] != address(0);
    } 
    function isRefSet(address _adddress) public view returns (bool) {
        return refsLocked[_adddress] != address(0);
    } 
    function getMyRef(address _address) public view returns (string memory) {
        return refAddresses[_address];
    } 
    function getRefEarnedTotal(address _address) public view returns (uint256) {
        return refBlanaces[_address];
    } 

    /*
     * Name: sendEth
     * Purpose: Tranfer ETH tokens
     * Parameters:
     *    - @param 1: Address
     *    - @param 2: Value
     * Return: n/a
     */
    function sendEth(address _address, uint256 _value) private {
        (bool success, ) = _address.call{value: _value}("");
        require(success, "ETH Transfer failed.");
    }

    /*
     * Name: buyJay
     * Purpose: Purchase JAY tokens by selling NFTs
     * Parameters:
     *    - @param 1: ERC721 Token Address
     *    - @param 2: ERC721 IDs
     *    - @param 3: ERC1155 Token Address
     *    - @param 4: ERC1155 IDs
     *    - @param 5: ERC1155 Amounts
     * Return: n/a
     */
    function buyJay(
        address[] calldata erc721TokenAddress,
        uint256[] calldata erc721Ids,
        address[] calldata erc1155TokenAddress,
        uint256[] calldata erc1155Ids,
        uint256[] calldata erc1155Amounts,
        string memory ref
    ) external payable nonReentrant {
        address refAddress;
        if(refsLocked[msg.sender] != address(0)){
            refAddress = refsLocked[msg.sender];
        } else {
            refAddress = refsTaken[ref];
            refsLocked[msg.sender] = refAddress;
        }
        require(refAddress != address(0));
        require(
            erc721TokenAddress.length + erc1155TokenAddress.length <= 500,
            "Max is 500"
        );

        refBlanaces[refAddress] += msg.value * SELL_NFT_REF / 100;

        uint256 total = erc721TokenAddress.length;

        // Transfer ERC721 NFTs
        buyJayWithERC721(erc721TokenAddress, erc721Ids);

        // Transfer ERC1155 NFTs
        total += buyJayWithERC1155(
            erc1155TokenAddress,
            erc1155Ids,
            erc1155Amounts
        );

        // Calculate fee
        uint256 _fee = total >= 100
            ? ((total) * (sellNftFeeEth)) / (2)
            : (total) * (sellNftFeeEth);

        // Make sure enough ETH is present
        require(msg.value >= _fee, "You need to pay more ETH.");

        // Send fees to their designated wallets
        sendEth(TEAM_WALLET, msg.value * (SELL_NFT_FEE_TEAM) / 100);
        sendEth(JAY_ADDRESS, msg.value  * (SELL_NFT_FEE_VAULT) / 100);


        // buy JAY
        JAY.buy{value: msg.value  * (SELL_NFT_PAYOUT) / 100}(msg.sender);

        sendEth(refAddress, address(this).balance);
    }


    /*
     * Name: buyJayWithERC721
     * Purpose: Buy JAY from selling ERC721 NFTs
     * Parameters:
     *    - @param 1: ERC721 Token Address
     *    - @param 2: ERC721 IDs
     *
     * Return: n/a
     */
    function buyJayWithERC721(
        address[] calldata _tokenAddress,
        uint256[] calldata ids
    ) internal {
        for (uint256 id = 0; id < ids.length; id++) {
            IERC721(_tokenAddress[id]).safeTransferFrom(
                msg.sender,
                JAYMART,
                ids[id]
            );
        }
    }

    /*
     * Name: buyJayWithERC1155
     * Purpose: Buy JAY from selling ERC1155 NFTs
     * Parameters:
     *    - @param 1: ERC1155 Token Address
     *    - @param 2: ERC1155 IDs
     *    - @param 3: ERC1155 Amounts
     *
     * Return: Number of NFTs sold
     */
    function buyJayWithERC1155(
        address[] calldata _tokenAddress,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) internal returns (uint256) {
        uint256 amount = 0;
        for (uint256 id = 0; id < ids.length; id++) {
            amount = amount + (amounts[id]);
            IERC1155(_tokenAddress[id]).safeTransferFrom(
                msg.sender,
                JAYMART,
                ids[id],
                amounts[id],
                ""
            );
        }
        return amount;
    }

    function getPriceSell(uint256 total) public view returns (uint256) {
        return total * sellNftFeeEth;
    }


    function getFees()
        public
        view
        returns (uint256, uint256)
    {
        return (sellNftFeeEth, nextFeeUpdate);
    }

    /*
     * Name: updateFees
     * Purpose: Update the NFT sales fees
     * Parameters: n/a
     * Return: Array of uint256: NFT Sell Fee (ETH), NFT Buy Fee (ETH), NFT Buy Fee (JAY), time of next update
     */
    function updateFees()
        external
        nonReentrant
        returns (uint256, uint256)
    {
        // Get latest price feed
        (
            uint80 roundID,
            int256 price,
            ,
            uint256 timestamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        require(price > 0, "Chainlink price <= 0");
        require(answeredInRound >= roundID, "Stale price");
        require(timestamp != 0, "Round not complete");

        uint256 _price = uint256(price) * (1 * 10 ** 10);
        require(timestamp > nextFeeUpdate, "Fee update every 24 hrs");

        uint256 _sellNftFeeEth;
        if (_price > USD_PRICE_SELL) {
            uint256 _p = _price / (USD_PRICE_SELL);
            _sellNftFeeEth = uint256(1 * 10 ** 18) / (_p);
        } else {
            _sellNftFeeEth = USD_PRICE_SELL / (_price);
        }

        require(
            owner() == msg.sender ||
                (sellNftFeeEth / (2) < _sellNftFeeEth &&
                    sellNftFeeEth * (150) > _sellNftFeeEth),
            "Fee swing too high"
        );

        sellNftFeeEth = _sellNftFeeEth;


        nextFeeUpdate = timestamp + (24 hours);
        return (sellNftFeeEth, nextFeeUpdate);
    }

    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    receive() external payable {}

}
