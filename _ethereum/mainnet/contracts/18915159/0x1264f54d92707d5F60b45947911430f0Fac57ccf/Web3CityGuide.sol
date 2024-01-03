// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./w3cg-base-721.sol";
import "./Ownable.sol";


contract Web3Cities is ERC721, Ownable {

    uint256 public currentTokenId = 0; // also represents total minted count
    uint256 public maxSupply = 1000;
    uint256 public priceInUSD = 180 * 1e8;
    string public tokenuri = "https://cryptonomads.org/Web3Cities.png";
    string public expiryuri = "https://cryptonomads.org/Web3Cities.expired.png";

    // hardcoded chainlink address
    address public feed; 

    constructor(address _feed) 
        ERC721("Web3CityGuide", "CNCW3CG") Ownable(msg.sender) {
        feed = _feed;
    }

    // Rate and Price related functions
    function getRate() public view returns (uint256){
        return uint256(PriceFeed(feed).latestAnswer());
    }

    function changeFeed(address _feed) external onlyOwner {
        feed = _feed;
    }

    // get Prices in ETH using current rate
    function price() public view returns (uint256) {
        return priceInUSD * 1e18 / getRate() ; // returns price in wei
    }
    // stores the token id to the corresponding expiry timestamp
    mapping(uint256 => uint256) public subscriptionExpiry;
    
    // Custom errors
    error InvalidCityGuide();
    error InvalidConfig();
    error InvalidSubscription();
    error SoldOut();
    error InsufficientBalance();

    // retrieves the uri of a specific token
    function tokenURI(uint256 id) public view override returns (string memory){
        if (id >= currentTokenId) {
          revert InvalidSubscription();
        }

        return subscriptionExpiry[id] < block.timestamp ? expiryuri : tokenuri;
    }

    // allows the owner to create or edit city guide info
    function editCityGuide(string calldata _uri, string calldata expiryUri, uint256 _maxSupply, uint256 _priceInUSD) external onlyOwner {

        // prevents setting up with wrong supply. 
        // supply must always be more than current minted
        if (_maxSupply < currentTokenId) {
            revert InvalidConfig();
        }

        tokenuri = _uri;
        expiryuri = expiryUri; 
        maxSupply = _maxSupply;
        priceInUSD = _priceInUSD;
    }


    // allows the owner to withdraw all ether stuck in the contract
    function withdrawAll() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // allows the owner to withdraw any erc20 stuck in the contract
    function withdraw(IERC20 erc20Address) onlyOwner external {

        uint256 currentERC20balance = IERC20(erc20Address).balanceOf(address(this));

        IERC20(erc20Address).transfer(msg.sender, currentERC20balance);  
     }

    // Mint function // 
    function mint(uint256 quantity) payable external {

        if (bytes(tokenuri).length == 0) {
            revert InvalidCityGuide();
        }

        if (currentTokenId + 1 > maxSupply) {
            revert SoldOut();
        }

        if (msg.value < price() * quantity) {
            revert InsufficientBalance();
        }

        // set subscription details against tokenId
        subscriptionExpiry[currentTokenId] = block.timestamp + 365 days;

        for (uint256 i = 0; i < quantity; i++) {
            _mint(msg.sender, currentTokenId);  
            unchecked {
                currentTokenId++;  
            }
        }
    }
}


abstract contract PriceFeed {
    function latestAnswer() virtual
        public
        view
        returns (int256 answer);
}