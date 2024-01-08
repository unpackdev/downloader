// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./AccessControl.sol";

import "./Uniswap.sol";
import "./UniMexPool.sol";
import "./ISwapPathCreator.sol";

contract SwapPathCreator is ISwapPathCreator, AccessControl {

    bytes32 public constant PATH_SETTER_ROLE = keccak256("PATH_SETTER_ROLE");
    address public uniswapFactory;

    mapping(address => mapping(address => address[])) public paths;

    event OnPathChange(address indexed baseToken, address indexed quoteToken);

    constructor(address _uniswapFactory) public {
        require(_uniswapFactory != address(0), "ZERO ADDRESS");
        uniswapFactory = _uniswapFactory;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(PATH_SETTER_ROLE, msg.sender);
    }

    function setPath(address baseToken, address quoteToken, address[] calldata path) public {
        require(hasRole(PATH_SETTER_ROLE, msg.sender), "NOT PATH SETTER");
        require(path.length >= 2, "WRONG PATH");
        require(path[0] == baseToken, "WRONG BASE TOKEN");
        require(path[path.length - 1] == quoteToken, "WRONG QUOTE TOKEN");
        paths[baseToken][quoteToken] = path;
        emit OnPathChange(baseToken, quoteToken);
    }

    function getPath(address baseToken, address quoteToken) public override view returns(address[] memory) {
        if(paths[baseToken][quoteToken].length > 0) {
            return paths[baseToken][quoteToken];
        } else {
            address[] memory path = new address[](2);
            path[0] = baseToken;
            path[1] = quoteToken;
            return path;
        }
    }

    function calculateConvertedValue(address baseToken, address quoteToken, uint256 amount) external override view returns (uint256) {
        address[] memory path = getPath(baseToken, quoteToken);
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(uniswapFactory, amount, path);
        return amounts[amounts.length - 1];
    }

}