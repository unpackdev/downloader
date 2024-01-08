pragma solidity ^0.8.0;

import "./Context.sol";
import "./IERC20.sol";

interface IERC721 {
    function mint(address to, uint256 tokenId) external;
    function exists(uint256 tokenId) external view returns (bool);
}

/**
 * @title Presale
 * @dev Presale contract allowing investors to purchase the cell token.
 * This contract implements such functionality in its most fundamental form and can be extended 
 * to provide additional functionality and/or custom behavior.
 */
contract Presale is Context {
    // The token being sold
    IERC721 private _cellToken;

    // Address where fund are collected
    address payable private _wallet;

    // Amount of wei raised
    uint256 private _weiRaised;

    // Amount of token to be pay for one ERC721 token
    uint256 private _weiPerToken;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param tokenId uint256 ID of the token to be purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 tokenId);

    /**
     * @param wallet_ Address where collected tokens will be forwarded to
     * @param cellToken_ Address of the Cell token being sold
     * @param weiPerToken_ tokens amount paid for purchase a Cell token
     */
    constructor (address payable wallet_, IERC721 cellToken_, uint256 weiPerToken_)
        public
    {
        require(wallet_ != address(0), "Presale: wallet is the zero address");
        require(address(cellToken_) != address(0), "Presale: cell token is the zero address");
        require(weiPerToken_ > 0, "Presale: token price must be greater than zero");
        _wallet = wallet_;
        _cellToken = cellToken_;
        _weiPerToken = weiPerToken_;
    }

    /**
     * @dev Fallback function revert your fund.
     * Only buy Cell token with the buyToken function.
     */
    fallback() external payable {
        revert("Presale: cannot accept any amount directly");
    }

    /**
     * @return The token being sold.
     */
    function cellToken() public view returns (IERC721) {
        return _cellToken;
    }

    /**
     * @return Amount of wei to be pay for a Cell token
     */
    function weiPerToken() public view returns (uint256) {
        return _weiPerToken;
    }

    /**
     * @return The address where tokens amounts are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @dev Returns x and y where represent the position of the cell.
     */
    function cellById(uint256 tokenId) public pure returns (uint256 x, uint256 y){
        x = tokenId / 90;
        y = tokenId - (x * 90);
    }

    /**
     * @dev token purchase with pay Land tokens
     * @param beneficiary Recipient of the token purchase
     * @param tokenId uint256 ID of the token to be purchase
     */
    function buyToken(address beneficiary, uint256 tokenId) public payable{
        require(beneficiary != address(0), "Presale: beneficiary is the zero address");
        require(weiPerToken() == msg.value, "Presale: Not enough Eth");
        require(!_cellToken.exists(tokenId), "Presale: token already minted");
        require(tokenId < 11520, "Presale: tokenId must be less than max token count");
        (uint256 x, uint256 y) = cellById(tokenId);
        require(x < 38 || x > 53 || y < 28 || y > 43, "Presale: tokenId should not be in the unsold range");
        _wallet.transfer(msg.value);
        _cellToken.mint(beneficiary, tokenId);
        emit TokensPurchased(msg.sender, beneficiary, tokenId);
    }
    
    /**
     * @dev batch token purchase with pay our ERC20 tokens
     * @param beneficiary Recipient of the token purchase
     * @param tokenIds uint256 IDs of the token to be purchase
     */
    function buyBatchTokens(address beneficiary, uint256[] memory tokenIds) public payable{
        require(beneficiary != address(0), "Presale: beneficiary is the zero address");
        uint256 weiAmount = weiPerToken() * tokenIds.length;
        require(weiAmount == msg.value, "Presale: Not enough Eth");
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            require(!_cellToken.exists(tokenIds[i]), "Presale: token already minted");
            require(tokenIds[i] < 11520, "Presale: tokenId must be less than max token count");
            (uint256 x, uint256 y) = cellById(tokenIds[i]);
            require(x < 38 || x > 53 || y < 28 || y > 43, "Presale: tokenId should not be in the unsold range");
        }
        _wallet.transfer(msg.value);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _cellToken.mint(beneficiary, tokenIds[i]);
            emit TokensPurchased(msg.sender, beneficiary, tokenIds[i]);
        }
    }
}
