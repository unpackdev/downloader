// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";
import "./IRenaswapV1Pair.sol";
import "./IRenaswapV1Wrapper.sol";

/**
 * RenaswapV1Wrapper ERC1155 token with ERC20 mimicing abilities
 * ERC20 capabilities are working through linking a pair with a wrapped token
 * When the pair interacts with the wrapper, we know the token it's talking to
 * Wrapped tokens are sent on deposit to a configurable destination address
 */
contract RenaswapV1Wrapper is ERC1155Burnable, Ownable, IERC20, IRenaswapV1Wrapper {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    /// @dev Fired when a user deposits a token
    event Deposit(address indexed dst, address indexed token, uint indexed id);
    /// @dev Fired when a new token is wrapped and linked to a pair
    event TokenWrapped(address token, address pair, uint256 id);

    /// @dev Mapping of token addresses to Token ID
    mapping (address => uint256) public _token_ids;
    /// @dev Mapping pairs to token ids
    mapping (address => uint256) public _tokenid_lookup;
    /// @dev Mapping pairs to token addresses
    mapping (address => address) public _token_lookup;
    /// @dev Mapping token ids to unwrapping destinations
    mapping (address => address) public _destinations;
    /// @dev Used to generate unique ids for every new wrapped token
    uint256 public uniqueIds;
    /// @dev Mapping pairs to last halving.
    mapping( address => uint256) public _burns;
    /// @dev Minimum time between burns.
    uint256 public _burnDurations = 26 weeks;
    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) ERC1155(uri_) Ownable() {
    }

    /**
     * @dev Allows Owner to reduce rToken amount to avoid overflow.
     */
    function rBurn(address pair_, uint256 burnDivisor) external override onlyOwner {
        require(burnDivisor > 1, "Too much");
        require(_burns[pair_].add(_burnDurations) < block.timestamp, "Too soon");
        address token = _token_lookup[pair_];
        _burns[pair_] = block.timestamp;
        _burn(pair_, _token_ids[token], balanceFor(token, pair_).sub(balanceFor(token, pair_).div(burnDivisor)));
    }

    /**
     * @dev Wraps a new token and links it to its pair
     * @dev If the token is already wrapped, reuses it
     * @param token Address of the token to wrap
     * @param pair Address of the pair to link with the token
     * @return id Id of the wrapped token
     */
    function addWrappedToken(address token, address pair) external override returns (uint256 id) {
        require(tx.origin == owner(), "RenaswapV1: FORBIDDEN");
        require(token != address(this), "RenaswapV1: FORBIDDEN");
        require(token != address(0), "RenaswapV1: Invalid token");
        require(pair != address(0), "RenaswapV1: Invalid pair");

        if(_token_ids[token] == 0) {
            uniqueIds++;
            _token_ids[token] = uniqueIds;
        }
        id = _token_ids[token];
        _tokenid_lookup[pair] = id;
        _token_lookup[pair] = token;
        emit TokenWrapped(token, pair, id);
    }

    /**
     * @dev Set a wrapped token destination upon deposit
     * @dev Destination must be set in order to allow deposits
     * @param pair pair address
     * @param destination Address on which to send the token
     */
    function setDestination(address pair, address destination) external {
        require(tx.origin == owner(), "RenaswapV1: FORBIDDEN");
        _destinations[pair] = destination;
    }

    /**
     * @dev Extracts a token deposited without destination
     */
    function extract(address pair) external {
        address token = _token_lookup[pair];
        require(token != address(0), "RenaswapV1: Unknown pair");
        require(_destinations[pair] != address(0), "RenaswapV1: Destination not set");
        IERC20(token).safeTransferFrom(address(this), _destinations[pair], IERC20(token).balanceOf(address(this)));
    }

    /**
     * @dev Mimics erc20 token totalSupply function
     * @dev Looks up the correct token based on caller (pair)
     */
    function totalSupply() external view override returns (uint256) {
        uint256 id = _tokenid_lookup[msg.sender];
        require(id > 0, "RenaswapV1: Invalid caller");
        return IERC20(_token_lookup[msg.sender]).totalSupply();
    }

    /**
     * @dev Mimics erc20 token balanceOf function
     * @dev Looks up the correct token based on caller (pair)
     */
    function balanceOf(address account) external view override returns (uint256) {
        uint256 id = _tokenid_lookup[msg.sender];
        require(id > 0, "RenaswapV1: Invalid caller");
        return balanceOf(account, id);
    }

    function balanceFor(address token, address account) public view override returns (uint256) {
        uint256 id = _token_ids[token];
        return balanceOf(account, id);
    }
    /**
     * @dev erc20 transfers aren't allowed
     */
    function transfer(address /*recipient*/, uint256 /*amount*/) external override pure returns (bool) {
        revert("RenaswapV1: Transfers are one direction only");
        /*return false;*/
    }

    /**
     * @dev erc20 allowances aren't allowed
     */
    function allowance(address, address) external pure override returns (uint256) {
        return 0;
    }

    /**
     * @dev erc20 allowances aren't allowed
     */
    function approve(address, uint256) external pure override returns (bool) {
        return false;
    }

    /**
     * @dev Mimics erc20 token transferFrom function
     * @dev Looks up the correct token based on caller (pair)
     * @dev Transfer is internal, no real erc20 token is moved
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        uint256 id = _tokenid_lookup[msg.sender];
        if(id > 0) // caller is a pair
        {
            safeTransferFrom(sender, recipient, id, amount, "");
        } else {
            address token = _token_lookup[recipient];
            require(token != address(0), "RenaswapV1: Invalid caller");
            require(sender == msg.sender || IERC20(token).allowance(sender, address(this)) >= amount, "RenaswapV1: caller is not owner nor approved");
            // recipient is a pair
            if(_destinations[recipient] != address(0)) {
                /// @dev Transfer the token from the user to its destination
                IERC20(token).safeTransferFrom(sender, _destinations[recipient], amount);
                IRenaswapV1Pair(_destinations[recipient]).sync();
            }
            else {
                IERC20(token).safeTransferFrom(sender, address(this), amount);
            }

            require(token != address(0), "RenaswapV1: Unknown pair");            
            _mint(recipient, _token_ids[token], amount, "");
            emit Deposit(recipient, token, _token_ids[token]);            
        }
        return true;
    }

    receive() external payable {
        revert("RenaswapV1: Do not accept ether");
    }


}
