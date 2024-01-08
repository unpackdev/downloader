// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./Controllable.sol";
import "./NFTGemPool.sol";
import "./Create2.sol";
import "./ERC20.sol";
import "./ERC20WrappedGem.sol";
import "./IERC20.sol";
import "./IERC20GemTokenFactory.sol";
import "./IERC20WrappedGem.sol";

contract ERC20GemTokenFactory is Controllable, IERC20GemTokenFactory {
    address private operator;

    mapping(uint256 => address) private _getItem;
    address[] private _allItems;

    constructor() {
        _addController(msg.sender);
    }

    /**
     * @dev get the quantized token for this
     */
    function getItem(uint256 _symbolHash) external view override returns (address gemPool) {
        gemPool = _getItem[_symbolHash];
    }

    /**
     * @dev get the quantized token for this
     */
    function allItems(uint256 idx) external view override returns (address gemPool) {
        gemPool = _allItems[idx];
    }

    /**
     * @dev number of quantized addresses
     */
    function allItemsLength() external view override returns (uint256) {
        return _allItems.length;
    }

    /**
     * @dev deploy a new erc20 token using create2
     */
    function createItem(
        string memory tokenSymbol,
        string memory tokenName,
        address poolAddress,
        address tokenAddress,
        uint8 decimals
    ) external override onlyController returns (address payable gemToken) {
        bytes32 salt = keccak256(abi.encodePacked(tokenSymbol));
        require(_getItem[uint256(salt)] == address(0), "GEMTOKEN_EXISTS"); // single check is sufficient
        require(poolAddress != address(0), "INVALID_POOL");

        // create the quantized erc20 token using create2, which lets us determine the
        // quantized erc20 address of a token without interacting with the contract itself
        bytes memory bytecode = type(ERC20WrappedGem).creationCode;

        // use create2 to deploy the quantized erc20 contract
        gemToken = payable(Create2.deploy(0, salt, bytecode));

        // initialize the erc20 contract with the relevant addresses which it proxies
        IERC20WrappedGem(gemToken).initialize(tokenSymbol, tokenName, poolAddress, tokenAddress, decimals);

        // insert the erc20 contract address into lists - one that maps source to quantized,
        _getItem[uint256(salt)] = gemToken;
        _allItems.push(gemToken);

        // emit an event about the new pool being created
        emit ERC20GemTokenCreated(gemToken, poolAddress, tokenSymbol, ERC20(gemToken).symbol());
    }
}
