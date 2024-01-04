// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";

import "./PoolManager.sol";

interface ISpaceShipsMint {
    function ID_TO_MODEL() external view returns(uint8);
    function supply(uint256 model) external view returns(uint256);
    function nextId(uint256 model) external view returns(uint256);
    function mint(address to, uint256 model) external;
}

/**
 * @dev SpaceShipsPool deals with the rewards of an holder and mint some ERC721.
 */
contract SpaceShipsPool is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    event SpaceShipsAdded(uint256 model, uint256 price);
    event Redeemed(address user, uint256 model);

    ISpaceShipsMint private _spaceShips;
    PoolManager private _poolManager;
    EnumerableSet.UintSet private _availableModels;

    mapping(uint256 => uint256) public prices;

    constructor(address owner, address poolManager, address spaceShips) public {
        transferOwnership(owner);
        _poolManager = PoolManager(poolManager);
        _spaceShips = ISpaceShipsMint(spaceShips);
    }

    /**
     * @dev Make a spaceship model mintable.
     *
     * @param model Model ID to add.
     * @param price Reward price require to mint a new NFT of this model.
     *
     * Requirements:
     * - the caller must be the owner.
     */
    function addSpaceShips(uint256 model, uint256 price) external onlyOwner {
        require(_spaceShips.nextId(model) < _spaceShips.supply(model), "SpaceShipsPool: model sold out");
        prices[model] = price;
        _availableModels.add(model);
        SpaceShipsAdded(model, price);
    }

    /**
     * @dev Remove a spaceship model from the mintable.
     *
     * @param model Model ID to remove.
     *
     * Requirements:
     * - the caller must be the owner.
     */
    function removeSpaceShips(uint256 model) external onlyOwner {
        _removeSpaceShips(model);
    }

    /**
     * @dev Redeem a nft of the model.
     *
     * @param model Model ID to mint.
     *
     * Requirements:
     * - the caller must have enough reward.
     */
    function redeem(uint256 model) external {
        require(_availableModels.contains(model), "SpaceShipsPool: unknown model");
        _poolManager.burnRewards(msg.sender, prices[model]);
		_spaceShips.mint(msg.sender, model);
		Redeemed(msg.sender, model);
        if(_spaceShips.nextId(model) == _spaceShips.supply(model)) {
            _removeSpaceShips(model);
        }
    }

    /**
     * @dev List available models.
     */
    function availableModels() external view returns(uint256[] memory){
        uint256[] memory res = new uint256[](_availableModels.length());
        for(uint256 i = 0; i < _availableModels.length(); i++) {
            res[i] = _availableModels.at(i);
        }
        return res;
    }

    function _removeSpaceShips(uint256 model) internal {
        _availableModels.remove(model);
        prices[model] = 0;
    }
}
