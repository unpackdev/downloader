// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./IERC20.sol";

import "./IOptionsPool.sol";
import "./IOptionsProvider.sol";
// import "./IOptionsExerciser.sol";
import "./IPriceProvider.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

contract OptionsPool is Ownable, IOptionsPool {
    IPriceProvider public priceProvider; 
    IOptionsProvider public override optionsProvider;
    address public optionsManager;

    bool public stopChanges;

    mapping(uint => uint) public override paidPremiums; // tokenId => premium
    
    constructor(IOptionsProvider op, IPriceProvider pp) public {
        _setOptionsProvider(op);
        _setPriceProvider(pp);
    }

    receive() external payable{}

    function stopChangesForever() external onlyOwner {
        stopChanges = true;
    }

    function setOptionsManager(address manager, bool approved) external onlyOwner {
        require(!stopChanges, "!stopChanges");
        _setOptionsManager(manager, approved);
    }

    function setOptionsProvider(IOptionsProvider op) external onlyOwner {
        require(!stopChanges, "!stopChanges");
        _setOptionsProvider(op);
    }

    function takeOptionFrom(address from, uint tokenId) external override onlyOptionsManager {
        optionsProvider.safeTransferFrom(from, address(this), tokenId);
    }

    function sendOptionTo(address to, uint tokenId) external override onlyOptionsManager {
        optionsProvider.safeTransferFrom(address(this), to, tokenId);
    }

    function depositOption(uint tokenId, uint premium) external override onlyOptionsManager {
        require(optionsProvider.ownerOf(tokenId) == address(this), "2ndary::OptionsPool::registerOption::token-not-owned-by-pool");
        paidPremiums[tokenId] = premium;

        emit RegisterOption(tokenId, premium);
    }

    function exerciseOption(uint tokenId) external override onlyOptionsManager returns (uint profit) {
        profit = optionsProvider.exerciseOption(tokenId);
        if(profit>0) payable(msg.sender).transfer(profit);
    }

    function exercisableOption(uint tokenId) external view override returns (bool) {
        (IHegicOptions.State state, , uint strike, , , , uint expiration , IHegicOptions.OptionType optionType) = optionsProvider.getUnderlyingOptionParams(tokenId);

        if(state != IHegicOptions.State.Active || expiration < block.timestamp) {
            return false;
        }

        (, int256 latestPrice, , , ) = priceProvider.latestRoundData();
        uint currentPrice = uint(latestPrice);

        if(optionType == IHegicOptions.OptionType.Call) {
            return currentPrice > strike;
        } else if (optionType == IHegicOptions.OptionType.Put) {
            return currentPrice < strike;
        }
    }

    function isActiveOption(uint tokenId) external view override returns (bool) {
        (IHegicOptions.State state, , , , , , uint expiration ,) = optionsProvider.getUnderlyingOptionParams(tokenId);
        return (state == IHegicOptions.State.Active && expiration > block.timestamp);
    }

    function unlockOption(uint tokenId) external override onlyOptionsManager {
        delete paidPremiums[tokenId];
    }

    function getActiveOptionsInPool() external view returns (uint[] memory activeOptions) {
        uint balance = optionsProvider.balanceOf(address(this));
        uint[] memory allOptions = new uint[](balance);
        uint activeOptionsCounter = 0;
        for(uint i = 0; i < balance; i++){
            uint tokenId = optionsProvider.tokenOfOwnerByIndex(address(this), i);
            (IHegicOptions.State state, , , , , , uint expiration , ) = optionsProvider.getUnderlyingOptionParams(tokenId);
            if(state == IHegicOptions.State.Active && expiration > block.timestamp){
                allOptions[i]=tokenId;
                activeOptionsCounter++;
            } else {
                allOptions[i]=0;
            }
        }
        uint index = 0;
        activeOptions = new uint[](activeOptionsCounter);
        for(uint i = 0; i < balance; i++){
            if(allOptions[i] != 0) {
                activeOptions[index] = allOptions[i];
                index++;
            }
        }
    }

    function onERC721Received(address , address , uint , bytes calldata ) public override virtual returns (bytes4){
        return this.onERC721Received.selector;
    }

    function _setOptionsManager(address manager, bool approved) internal {
        if(approved) {
            optionsManager = manager;
        } 
        optionsProvider.setApprovalForAll(address(manager), approved);
    }

    function _setPriceProvider(IPriceProvider pp) internal {
        priceProvider = pp;
    }

    function _setOptionsProvider(IOptionsProvider op) internal {
        optionsProvider = op;
    }

    modifier onlyOptionsManager {
        require(optionsProvider.isApprovedForAll(address(this), msg.sender), "2ndary::OptionsPool::onlyOptionManager");
        _;
    }   
}