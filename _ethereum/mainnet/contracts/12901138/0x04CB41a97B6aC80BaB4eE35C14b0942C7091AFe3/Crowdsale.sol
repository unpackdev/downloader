pragma solidity ^0.8.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

interface IERC721 {
    function mint(address to, uint256 tokenId) external;
    function exists(uint256 tokenId) external view returns (bool);
}

/**
 * @title Crowdsale
 * @dev Crowdsale contract allowing investors to purchase the cell token with our ERC20 land tokens.
 * This contract implements such functionality in its most fundamental form and can be extended 
 * to provide additional functionality and/or custom behavior.
 */
contract Crowdsale is Context {
    using SafeMath for uint256;
    // The token being sold
    IERC721 private _cellToken;

    // The main token that you can buy cell with it
    IERC20 private _land;
    address private _tokenWallet;

    // Address where your paid land tokens are collected
    address payable private _wallet;

    // Amount of land token raised
    uint256 private _tokenRaised;

    // Amount of token to be pay for one ERC721 token
    uint256 private _landPerToken;

    // Max token count to be sale
    uint256 private _maxTokenCount;

    uint256 constant private CLD_RATE_10000 = 50000;
    uint256 constant private CLD_RATE_10000_30000 = 52000;
    uint256 constant private CLD_RATE_30000_70000 = 53000;
    uint256 constant private CLD_RATE_70000_200000 = 54500;
    uint256 constant private CLD_RATE_200000_500000 = 57000;
    uint256 constant private CLD_RATE_500000_up = 60000;

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
    constructor (address payable wallet_, IERC20 landToken_, address tokenWallet_, IERC721 cellToken_, uint256 landPerToken_, uint256 maxTokenCoun_)
        public
    {
        require(wallet_ != address(0), "Crowdsale: wallet is the zero address");
        require(address(landToken_) != address(0), "Crowdsale: land token is the zero address");
        require(address(cellToken_) != address(0), "Crowdsale: cell token is the zero address");
        require(landPerToken_ > 0, "Crowdsale: token price must be greater than zero");
        require(maxTokenCoun_ > 0, "Crowdsale: max token count must be greater than zero");
        _wallet = wallet_;
        _land = landToken_;
        _tokenWallet = tokenWallet_;
        _cellToken = cellToken_;
        _landPerToken = landPerToken_;
        _maxTokenCount = maxTokenCoun_;
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
     */
    function cellById(uint256 tokenId) public pure returns (uint256 x, uint256 y){
        y = tokenId / 90;
        x = tokenId - (y * 90);
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
        if (weiAmount >= 10 * 1e18) {
            return weiAmount.mul(CLD_RATE_500000_up);
        } else if (weiAmount >= 4 * 1e18) {
            return weiAmount.mul(CLD_RATE_200000_500000);
        } else if (weiAmount >= 1400 * 1e15 ) {
            return weiAmount.mul(CLD_RATE_70000_200000);
        } else if (weiAmount >= 600 * 1e15) {
            return weiAmount.mul(CLD_RATE_30000_70000);
        } else if (weiAmount >= 200 * 1e15) {
            return weiAmount.mul(CLD_RATE_10000_30000);
        } else {
            return weiAmount.mul(CLD_RATE_10000);
        }
    }
}
