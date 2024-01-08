// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./EnumerableSet.sol";
import "./IERC721Receiver.sol";

contract DunkVault is Ownable, Pausable, ReentrancyGuard, IERC721Receiver {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
        
    struct ERC721Asset {
        uint lock;
        uint recur;
        uint reward;
        mapping(address => EnumerableSet.UintSet) deposits;
        mapping(address => mapping(uint256 => uint256)) depositedAt;
        mapping(address => mapping(uint256 => uint256)) rewardsAccumulationStartAt;

    }

    uint private erc20Decimals = 18;
    address public erc20Address = 0x00E595D4060dcF65c9C5622aA02d6B999F7835db;
    mapping(address => ERC721Asset) private _assets;

    constructor() {
        _pause();
    }


    function pause() external onlyOwner {
        _pause();
    }


    function unpause() external onlyOwner {
        _unpause();
    }


    function setLock(address _asset, uint256 _seconds) external onlyOwner {
        _assets[_asset].lock = _seconds;
    }


    function setReward(address _asset, uint256 _reward) external onlyOwner {
        _assets[_asset].reward = _reward;
    }


    function setRecurrence(address _asset, uint256 _seconds) external onlyOwner {
        _assets[_asset].recur = _seconds;
    }


    function setAsset(address _asset, uint256 _reward, uint256 _lock, uint256 _recur) external {
        ERC721Asset storage asset = _assets[_asset];
        asset.lock   = _lock;
        asset.recur  = _recur;
        asset.reward = _reward;
    }


    function isDeposited(address _asset, uint256 _token) public view returns(bool) {
        return _assets[_asset].deposits[msg.sender].contains(_token);
    }


    function isReleased(address _asset, uint256 _token) public view returns(bool) {
        return duration(_asset, _token) >= _assets[_asset].lock;
    }


    function duration(address _asset, uint256 _token) public view returns(uint256) {
       if(!isDeposited(_asset, _token) || _assets[_asset].depositedAt[msg.sender][_token] == 0) return 0;
       return block.timestamp.sub(_assets[_asset].depositedAt[msg.sender][_token]);
    }


    function calculateReward(address _asset, uint256 _token) public view returns (uint256) {
        if(!isDeposited(_asset, _token)) return 0;
        return (block.timestamp.sub(_assets[_asset].rewardsAccumulationStartAt[msg.sender][_token])).mul(_assets[_asset].reward).div(_assets[_asset].recur);
    }


    function calculateRewards(address _asset, uint256[] calldata _tokens) public view returns (uint256[] memory rewards) {
        rewards = new uint256[](_tokens.length);
        for(uint256 token; token < _tokens.length; token++) {
             rewards[token] = calculateReward(_asset, _tokens[token]);
        }
        return rewards;
    }


    function claimRewards(address _asset, uint256[] calldata _tokens) public whenNotPaused nonReentrant() {
        uint256 rewards;
        for(uint256 token; token < _tokens.length; token++) {
            rewards += calculateReward(_asset, _tokens[token]);
            _assets[_asset].rewardsAccumulationStartAt[msg.sender][_tokens[token]] = block.timestamp;
        }

        if (rewards > 0) IERC20(erc20Address).transfer(msg.sender, rewards * 10 ** erc20Decimals);
    }


    function deposit(address _asset, uint256[] calldata _tokens) external whenNotPaused {
        require(_assets[_asset].reward > 0, "Staking: vault cannot receive this asset");

        for(uint256 token; token < _tokens.length; token++) {
            IERC721(_asset).safeTransferFrom(msg.sender, address(this), _tokens[token]);

            _assets[_asset].deposits[msg.sender].add(_tokens[token]);
            _assets[_asset].depositedAt[msg.sender][_tokens[token]] = block.timestamp;
            _assets[_asset].rewardsAccumulationStartAt[msg.sender][_tokens[token]] = block.timestamp;

        }
    }


    function withdraw(address _asset, uint256[] calldata _tokens) external whenNotPaused {
        claimRewards(_asset, _tokens);

        for(uint256 token; token < _tokens.length; token++) {
            require(isDeposited(_asset, _tokens[token]), "Staking: token not found in deposits");
            require(isReleased(_asset, _tokens[token]),  "Staking: token locked");

            _assets[_asset].deposits[msg.sender].remove(_tokens[token]);
            IERC721(_asset).safeTransferFrom(address(this), msg.sender, _tokens[token]);
        }
    }


    function withdrawERC20Supply() external onlyOwner {
        IERC20(erc20Address).transfer(msg.sender, IERC20(erc20Address).balanceOf(address(this)));
    }

    
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}