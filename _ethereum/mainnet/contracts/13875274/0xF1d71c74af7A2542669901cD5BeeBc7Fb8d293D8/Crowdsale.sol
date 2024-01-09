pragma solidity ^0.8.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

interface IERC721 {
    function mint(address to, uint256 tokenId) external;
    function exists(uint256 tokenId) external view returns (bool);
}

interface ICLDSale {
    function rate() external view returns (uint256);
}

/**
 * @title Crowdsale
 * @dev Crowdsale contract allowing investors to purchase the cell token with our ERC20 land tokens.
 * This contract implements such functionality in its most fundamental form and can be extended 
 * to provide additional functionality and/or custom behavior.
 */
contract Crowdsale is Context, Ownable {
    using SafeMath for uint256;
    // The token being sold
    IERC721 private _cellToken;

    // The main token that you can buy cell with it
    IERC20 private _land;
    address private _tokenWallet;
    
    // The main sale contract that you can buy cld
    ICLDSale private _cldSale;

    // Address where your paid land tokens are collected
    address payable private _wallet;

    // Amount of land token raised
    uint256 private _tokenRaised;

    // Amount of token to be pay for one ERC721 token
    uint256 private _landPerToken;

    // Max token count to be sale
    uint256 private _maxTokenCount;

    mapping(uint256 => bool) private _alreadySold;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param tokenId uint256 ID of the token to be purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 tokenId);

    /**
     * @param wallet_ Address where collected tokens will be forwarded to
     * @param landToken_ Address of the Land token that you can buy with it
     * @param cellToken_ Address of the Cell token being sold
     * @param landPerToken_ tokens amount paid for purchase a Cell token
     */
    constructor (address payable wallet_, IERC20 landToken_, address tokenWallet_, IERC721 cellToken_, uint256 landPerToken_, uint256 maxTokenCoun_, ICLDSale cldSale_)
        public
    {
        require(wallet_ != address(0), "Crowdsale: wallet is the zero address");
        require(address(landToken_) != address(0), "Crowdsale: land token is the zero address");
        require(address(cellToken_) != address(0), "Crowdsale: cell token is the zero address");
        require(landPerToken_ > 0, "Crowdsale: token price must be greater than zero");
        require(maxTokenCoun_ > 0, "Crowdsale: max token count must be greater than zero");
        require(address(cldSale_) != address(0), "Crowdsale: CLDSale is the zero address");
        _wallet = wallet_;
        _land = landToken_;
        _tokenWallet = tokenWallet_;
        _cellToken = cellToken_;
        _landPerToken = landPerToken_;
        _maxTokenCount = maxTokenCoun_;
        _cldSale = cldSale_;
    }

    /**
     * @dev Fallback function revert your fund.
     * Only buy Cell token with Land token.
     */
    fallback() external payable {
        revert("Crowdsale: cannot accept any amount directly");
    }

    /**
     * @return The base token that you can buy with it
     */
    function land() public view returns (IERC20) {
        return _land;
    }

    /**
     * @return The token being sold.
     */
    function cellToken() public view returns (IERC721) {
        return _cellToken;
    }

    /**
     * @return Amount of Land token to be pay for a Cell token
     */
    function landPerToken() public view returns (uint256) {
        return _landPerToken;
    }

    /**
     * @return The address where tokens amounts are collected.
     */
    function wallet() public view returns (address) {
        return _wallet;
    }

    /**
     * @return The amount of Land token raised.
     */
    function tokenRaised() public view returns (uint256) {
        return _tokenRaised;
    }
    
    /**
     * @return The amount of Cell token can be sold.
     */
    function getMaxTokenCount() public view returns (uint256) {
        return _maxTokenCount;
    }

    /**
     * @dev Returns x and y where represent the position of the cell.
     * @param tokenId uint256 ID of the token
     */
    function cellById(uint256 tokenId) public pure returns (uint256 x, uint256 y){
        y = tokenId / 90;
        x = tokenId - (y * 90);
    }

    /**
     * @return The address where tokens amounts are collected.
     * @param tokenId uint256 ID of the token
     */
    function alreadySold(uint256 tokenId) public view returns (bool) {
        return _alreadySold[tokenId];
    }

    /**
     * @return The address where tokens amounts are collected.
     * @param tokenIds uint256 ID of the token
     */
    function setTokenSold(uint256[] memory tokenIds) public onlyOwner returns (bool) {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _alreadySold[tokenIds[i]] = true;
        }
        return true;
    }

    /**
     * @return The base token that you can buy with it
     */
    function cldSale() public view returns (ICLDSale) {
        return _cldSale;
    }

    /**
     * @return The base token that you can buy with it
     */
    function setCLDSale(ICLDSale cldsale_) public onlyOwner returns (bool) {
        _cldSale = cldsale_;
        return true;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _cldSale.rate();
        
    }

    /**
     * @dev token purchase with pay Land tokens
     * @param beneficiary Recipient of the token purchase
     * @param tokenId uint256 ID of the token to be purchase
     */
    function buyToken(address beneficiary, uint256 tokenId) public payable{
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(_landPerToken <= _land.allowance(_msgSender(), address(this)), "Crowdsale: Not enough CLD allowance");
        require(tokenId < getMaxTokenCount(), "Crowdsale: tokenId must be less than max token count");
        (uint256 x, uint256 y) = cellById(tokenId);
        require(x < 38 || x > 53 || y < 28 || y > 43, "Crowdsale: tokenId should not be in the unsold range");
        require(!alreadySold(tokenId), "Crowdsale: token already sold");
        require(!_cellToken.exists(tokenId), "Crowdsale: token already minted");
        uint256 balance = _land.balanceOf(_msgSender());
        if (_landPerToken <= balance){
            _land.transferFrom(_msgSender(), _wallet, _landPerToken);
        }
        else{
            require(msg.value > 0, "Crowdsale: Not enough CLD or ETH");
            uint256 newAmount = _getTokenAmount(msg.value);
            require(newAmount.add(balance) >= _landPerToken, "Crowdsale: Not enough CLD or ETH");
            _land.transferFrom(_tokenWallet, _msgSender(), newAmount);
            _land.transferFrom(_msgSender(), _wallet, _landPerToken);
            _wallet.transfer(msg.value);
        }
        _tokenRaised += _landPerToken;
        _cellToken.mint(beneficiary, tokenId);
        emit TokensPurchased(msg.sender, beneficiary, tokenId);
    }
    
    /**
     * @dev batch token purchase with pay our ERC20 tokens
     * @param beneficiary Recipient of the token purchase
     * @param tokenIds uint256 IDs of the token to be purchase
     */
    function buyBatchTokens(address beneficiary, uint256[] memory tokenIds) public payable{
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        uint256 tokenAmount = _landPerToken * tokenIds.length;
        require(tokenAmount <= _land.allowance(_msgSender(), address(this)), "Crowdsale: Not enough CLD allowance");
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            require(tokenIds[i] < getMaxTokenCount(), "Crowdsale: tokenId must be less than max token count");
            (uint256 x, uint256 y) = cellById(tokenIds[i]);
            require(x < 38 || x > 53 || y < 28 || y > 43, "Crowdsale: tokenId should not be in the unsold range");
            require(!alreadySold(tokenIds[i]), "Crowdsale: token already sold");
            require(!_cellToken.exists(tokenIds[i]), "Crowdsale: token already minted");
        }
        uint256 balance = _land.balanceOf(_msgSender());
        if (tokenAmount <= balance){
            _land.transferFrom(_msgSender(), _wallet, tokenAmount);
        }
        else{
            require(msg.value > 0, "Crowdsale: Not enough CLD or ETH");
            uint256 newAmount = _getTokenAmount(msg.value);
            require(newAmount.add(balance) >= tokenAmount, "Crowdsale: Not enough CLD or ETH");
            _land.transferFrom(_tokenWallet, _msgSender(), newAmount);
            _land.transferFrom(_msgSender(), _wallet, tokenAmount);
            _wallet.transfer(msg.value);
        }
        
        _tokenRaised += tokenAmount;
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _cellToken.mint(beneficiary, tokenIds[i]);
            emit TokensPurchased(msg.sender, beneficiary, tokenIds[i]);
        }
    }

    /**
     * @dev Overrides function in the Crowdsale contract to enable a custom phased distribution
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 amount = weiAmount.mul(rate());
        if (amount >= 500000 * 1e18) {
            return amount.mul(120).div(100);
        } else if (amount >= 200000 * 1e18) {
            return amount.mul(114).div(100);
        } else if (amount >= 70000 * 1e18) {
            return amount.mul(109).div(100);
        } else if (amount >= 30000 * 1e18) {
            return amount.mul(106).div(100);
        } else if (amount >= 10000 * 1e18) {
            return amount.mul(104).div(100);
        } else {
            return amount;
        }
    }
}
