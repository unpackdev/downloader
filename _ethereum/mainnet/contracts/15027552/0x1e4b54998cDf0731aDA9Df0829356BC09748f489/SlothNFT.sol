// SPDX-License-Identifier: MIT
//
// Smart-contract SLOTH NFT for
// Groowers.io

pragma solidity ^0.8.13;

import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./IGroowersWallet.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SlothNFT is ERC721Enumerable, ReentrancyGuard, Ownable {

    using SafeMath for uint256;

    // TypeOf for mint stage settings
    struct StageConfig {
        IERC20 token;
        uint256 amount;
        uint256 start_time;
    }
    //
    // Vars
    string public baseURI;
    IGroowersWallet internal wallet;

    mapping(uint256 => StageConfig) stages;
    //

    constructor(address _wallet, string memory _URI) ERC721 ("Groowers", "SLOTH") {
        wallet = IGroowersWallet(_wallet);
        baseURI = _URI;
    }

    //
    // View, pure helpers functions
    // Base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    // Check wallet address for approwe your tokens before buySloth()
    function getWallet() public view returns(IGroowersWallet _id) {
        _id = wallet;
    }
    // Check terms for mint by stage id
    function getStageInfo(uint256 _id) public view returns(StageConfig memory _stage) {
        _stage = stages[_id];
    }
    // Check mint stage for Sloth id
    function _checkStage(uint256 _id) public pure returns (uint256) {
        if (_id <= 420) {
            return 1;
        } else if (_id <= 840) {
            return 2;
        } else if (_id <= 1260) {
            return 3;
        } else if (_id <= 1680) {
            return 4;
        } else if (_id <= 2100) {
            return 5;
        } else if (_id <= 2520) {
            return 6;
        } else if (_id <= 2940) {
            return 7;
        } else if (_id <= 3360) {
            return 8;
        } else if (_id <= 3780) {
            return 9;
        } else if (_id <= 4200) {
            return 10;
        } else {
            return 11;
        }
    }
    // Check available Sloths quantiity on current stage
    function _availableSloth() public view returns (uint256) {
        if (_currentStage() == 11) return 0;
        return (420 * _currentStage()) - totalSupply();
    }
    // Check current stage id
    function _currentStage() public view returns (uint256) {
        return _checkStage(totalSupply().add(1));
    }
    //

    //
    // Mint new Sloth ERC721
    function buySloth(uint256 quantity) external nonReentrant {
        require(quantity > 0 && quantity < 8, "Sloths countable");
        require(quantity <= _availableSloth(), "Sloths not enough");
        require(totalSupply().add(1) != 420, "It s time for core mint");
        require(_currentStage() < 11, "All Sloths sold");
        require(getStageInfo(_currentStage()).start_time != 0 && getStageInfo(_currentStage()).start_time <= block.timestamp, "Not time yet");
        for (uint256 i = 0; i < quantity; i++) {
          if (totalSupply().add(1) == 420) break;
          _stake(getStageInfo(_currentStage()).token, getStageInfo(_currentStage()).amount);
          _safeMint(_msgSender(), totalSupply().add(1));
        }
    }
    //

    //
    // Admin functions
    function setStage(uint256 _id, IERC20 _token, uint256 _amount, uint256 _start_time) external nonReentrant onlyOwner {
        require(_id < 11, "Only 10 stages");
        require(stages[_id].start_time == 0, "Stage already set");

        stages[_id].token = _token;
        stages[_id].amount = _amount;
        stages[_id].start_time = _start_time;
    }
    // Core mint 50 Sloth
    function coreSloth() external nonReentrant onlyOwner {
        require(totalSupply() == 419, "Function timeout");

        do {
          _safeMint(_msgSender(), totalSupply().add(1));
        } while (totalSupply() < 469);
    }
    //

    //
    // Internal functions
    function _stake(IERC20 _token, uint256 _amount) internal {
        wallet.Stake(_token, _amount, _msgSender());
    }
    //
}
