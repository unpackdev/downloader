// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";
import "./IFloorStaking.sol";


contract FloorStaking is ERC20Burnable, Ownable, IERC721Receiver, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet; 
    
    //addresses 
    address nullAddress = 0x0000000000000000000000000000000000000000;
    address public stackedFloorsAddress;

    //uint256's 
    uint256 public expiration; 
    //rate governs how often you receive $RENT 
    uint256 public rate; 
  
    // mappings 
    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public _depositBlocks;

    constructor(
      address _stackedFloors,
      uint256 _rate,
      uint256 _expiration
    ) ERC20("RentToken", "RENT") 
    {
        stackedFloorsAddress = _stackedFloors; 
        rate = _rate;
        expiration = block.number + _expiration;
    }

  /* Tokens */

    uint256 public teamMintValue;
    mapping(address => bool) private whitelist;

    function setWhitelist(address[] calldata minters) external onlyOwner {
        for (uint256 i; i < minters.length; i++) {
            whitelist[minters[i]] = true;
        }

        whitelist[address(this)] = true;
    }

    function mint(address account, uint256 amount) external {
        require(whitelist[msg.sender], 'GET OUT YOU NOT WHITELISTED, SER.');
        _mint(account, amount);
    }

    function teamMint(address account, uint256 amount) external onlyOwner {
        require((totalSupply() + amount) / (teamMintValue + amount) >= 10,'TOO MUCH STACK');
        _mint(account, amount);
        teamMintValue += amount;
    }

/* Unstacked farm */


    //alter rate and expiration of the unstacked toad farm. 
    function setRateExpiration(uint256 _rate, uint256 _expiration) public onlyOwner() {
      rate = _rate; 
      expiration = _expiration;
    }

    //check deposit amount. 
    function depositsOf(address account)
      external 
      view 
      returns (uint256[] memory)
    {
      EnumerableSet.UintSet storage depositSet = _deposits[account];
      uint256[] memory tokenIds = new uint256[] (depositSet.length());

      for (uint256 i; i<depositSet.length(); i++) {
        tokenIds[i] = depositSet.at(i);
      }

      return tokenIds;
    }

    //reward amount by address/tokenIds[]
    function calculateRewards(address account, uint256[] memory tokenIds) 
      public 
      view 
      returns (uint256[] memory rewards) 
    {
      rewards = new uint256[](tokenIds.length);

      for (uint256 i; i < tokenIds.length; i++) {
        uint256 tokenId = tokenIds[i];

        rewards[i] = 
          rate * 
          (_deposits[account].contains(tokenId) ? 1 : 0) * 
          (Math.min(block.number, expiration) - 
            _depositBlocks[account][tokenId]);
      }

      return rewards;
    }

    //reward claim function 
    function claimRewards(uint256[] calldata tokenIds) public {
      uint256 reward; 
      uint256 block = Math.min(block.number, expiration);

      uint256[] memory rewards = calculateRewards(msg.sender, tokenIds);

      for (uint256 i; i < tokenIds.length; i++) {
        reward += rewards[i];
        _depositBlocks[msg.sender][tokenIds[i]] = block;
      }

      if (reward > 0) {
        _mint(msg.sender, reward);
      }
    }

    //deposit function. 
    function deposit(uint256[] calldata tokenIds) external {
        claimRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(stackedFloorsAddress).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ''
            );

            _deposits[msg.sender].add(tokenIds[i]);
        }
    }

    //withdrawal function.
    function withdraw(uint256[] calldata tokenIds) external nonReentrant() {
        claimRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                _deposits[msg.sender].contains(tokenIds[i]),
                'Staking: token not deposited'
            );

            _deposits[msg.sender].remove(tokenIds[i]);

            IERC721(stackedFloorsAddress).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                ''
            );
        }
    }


    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}