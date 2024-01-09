// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./Ownable.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./EnumerableSet.sol";
import "./IERC721Receiver.sol";

contract Fridge is Ownable, IERC721Receiver, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    EnumerableSet.UintSet internal stakedTokens;
    mapping(address => EnumerableSet.UintSet) stakedTokensByAddress;
    mapping(address => mapping(uint => uint)) stakedTokensLastClaimByAddress;

    uint public interval = 1 days;
    uint public rewardPerInterval = 8 * 10**18;

    address public erc20Address;
    address public erc721Address;

    constructor(address _erc721Address, address _erc20Address) {
       _pause();
       
        erc20Address = _erc20Address;
        erc721Address = _erc721Address;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setERC721Contract(address _erc721Address) external onlyOwner {
        erc721Address = _erc721Address;
    }

    function setERC20Contract(address _erc20Address) external onlyOwner {
        erc20Address = _erc20Address;
    }

    function setInterval(uint _seconds) external onlyOwner {
        interval = _seconds;
    }

    function setReward(uint _reward) external onlyOwner {
        rewardPerInterval = _reward * 10**18;
    }

    function ownedBySender(uint _token) public view returns (bool) {
        return stakedTokensByAddress[msg.sender].contains(_token);
    }

    function stake(uint[] calldata _tokens) external whenNotPaused {
        for(uint i = 0; i < _tokens.length; i++) {
            stakedTokens.add(_tokens[i]);
            stakedTokensByAddress[msg.sender].add(_tokens[i]);
            stakedTokensLastClaimByAddress[msg.sender][_tokens[i]] = block.timestamp;

            IERC721(erc721Address).safeTransferFrom(msg.sender, address(this), _tokens[i]);
        }
    }

    function unstake(uint[] calldata _tokens) external whenNotPaused {
        claim(_tokens);

        for(uint i = 0; i < _tokens.length; i++) {
            require(ownedBySender(_tokens[i]), "You don't own the token you're trying to unstake!");

            stakedTokens.remove(_tokens[i]);
            stakedTokensByAddress[msg.sender].remove(_tokens[i]);
            IERC721(erc721Address).safeTransferFrom(address(this), msg.sender, _tokens[i]);
        }
    }

    function claim(uint[] calldata _tokens) public whenNotPaused nonReentrant {
        uint rewards = 0;

        for(uint i = 0; i < _tokens.length; i++) {
            require(ownedBySender(_tokens[i]), "You don't own the token you're trying to claim the rewards for!");
            
            rewards += calculateReward(_tokens[i]);
            stakedTokensLastClaimByAddress[msg.sender][_tokens[i]] = block.timestamp;
        }

        if (rewards > 0) IERC20(erc20Address).transfer(msg.sender, rewards);
    }

    function calculateReward(uint _token) public view returns (uint) {
        return block.timestamp.sub(stakedTokensLastClaimByAddress[msg.sender][_token]).mul(rewardPerInterval).div(interval);
    }

    function calculateRewards(uint[] calldata _tokens) public view returns (uint) {
        uint rewards = 0;
        for(uint i = 0; i < _tokens.length; i++) {
            rewards += calculateReward(_tokens[i]);
        }
        return rewards;
    }

    function tokensStaked(address _wallet) public view returns (uint[] memory _tokens) {
        uint tokensNumber = stakedTokensByAddress[_wallet].length();
        uint[] memory tokens = new uint[](tokensNumber);

        for(uint i = 0; i < tokensNumber; i++) {
            tokens[i] = stakedTokensByAddress[_wallet].at(i);
        }

        return tokens;
    }

    function withdrawERC20Supply() external onlyOwner {
        IERC20(erc20Address).transfer(msg.sender, IERC20(erc20Address).balanceOf(address(this)));
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }


    /* ---- Emergency functions if something goes wrong ----- */ 


    function emergencyUnstakeToOwnerAddress(address _ownerAddress) external onlyOwner {
        uint[] memory tokens = tokensStaked(_ownerAddress);

        for(uint i = 0; i < tokens.length; i++) {
            stakedTokens.remove(tokens[i]);
            stakedTokensByAddress[_ownerAddress].remove(tokens[i]);
            IERC721(erc721Address).safeTransferFrom(address(this), _ownerAddress, tokens[i]);
        }
    }

    function EMERGENCY_UNSTAKE_SPECIFIED_TOKENS_TO_CONTRACT_OWNER_WALLET(bool approved, uint[] memory tokenIds) external onlyOwner {
        require(approved, "You have to approve this action! After that, the owner won't be able to stake this or other tokens. Require wallet change to fix.");
        for(uint i = 0; i < tokenIds.length; i++) {
            IERC721(erc721Address).safeTransferFrom(address(this), msg.sender, stakedTokens.at(i));
            stakedTokens.remove(tokenIds[i]);
        }
    }

    function __EMERGENCY_UNSTAKE_ALL_TO_CONTRACT_OWNER_WALLET__(bool approved) external onlyOwner {
        require(approved, "You have to approve this action! After it, you will have to deploy a new contract.");
        for(uint i = 0; i < stakedTokens.length(); i++) {
            IERC721(erc721Address).safeTransferFrom(address(this), msg.sender, stakedTokens.at(i));
        }
    }
}