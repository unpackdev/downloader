// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./Controllable.sol";
import "./NFTGemPool.sol";
import "./Create2.sol";
import "./INFTGemPoolFactory.sol";

contract NFTGemPoolFactory is Controllable, INFTGemPoolFactory {
    address private operator;

    mapping(uint256 => address) private _getNFTGemPool;
    address[] private _allNFTGemPools;

    constructor() {
        _addController(msg.sender);
    }

    /**
     * @dev get the quantized token for this
     */
    function getNFTGemPool(uint256 _symbolHash) external view override returns (address gemPool) {
        gemPool = _getNFTGemPool[_symbolHash];
    }

    /**
     * @dev get the quantized token for this
     */
    function allNFTGemPools(uint256 idx) external view override returns (address gemPool) {
        gemPool = _allNFTGemPools[idx];
    }

    /**
     * @dev number of quantized addresses
     */
    function allNFTGemPoolsLength() external view override returns (uint256) {
        return _allNFTGemPools.length;
    }

    /**
     * @dev deploy a new erc20 token using create2
     */
    function createNFTGemPool(
        string memory gemSymbol,
        string memory gemName,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxMint,
        address allowedToken
    ) external override onlyController returns (address payable gemPool) {
        bytes32 salt = keccak256(abi.encodePacked(gemSymbol));
        require(_getNFTGemPool[uint256(salt)] == address(0), "GEMPOOL_EXISTS"); // single check is sufficient

        // validation checks to make sure values are sane
        require(ethPrice != 0, "INVALID_PRICE");
        require(minTime != 0, "INVALID_MIN_TIME");
        require(diffstep != 0, "INVALID_DIFFICULTY_STEP");

        // create the quantized erc20 token using create2, which lets us determine the
        // quantized erc20 address of a token without interacting with the contract itself
        bytes memory bytecode = type(NFTGemPool).creationCode;

        // use create2 to deploy the quantized erc20 contract
        gemPool = payable(Create2.deploy(0, salt, bytecode));

        // initialize the erc20 contract with the relevant addresses which it proxies
        NFTGemPool(gemPool).initialize(gemSymbol, gemName, ethPrice, minTime, maxTime, diffstep, maxMint, allowedToken);

        // insert the erc20 contract address into lists - one that maps source to quantized,
        _getNFTGemPool[uint256(salt)] = gemPool;
        _allNFTGemPools.push(gemPool);

        // emit an event about the new pool being created
        emit NFTGemPoolCreated(gemSymbol, gemName, ethPrice, minTime, maxTime, diffstep, maxMint, allowedToken);
    }
}
