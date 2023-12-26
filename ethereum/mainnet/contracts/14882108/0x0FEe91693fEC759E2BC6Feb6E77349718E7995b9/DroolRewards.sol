// SPDX-License-Identifier: MIT

/* 
                                     
@@@@@@@   @@@@@@@    @@@@@@    @@@@@@   @@@       
@@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@@@@@  @@@       
@@!  @@@  @@!  @@@  @@!  @@@  @@!  @@@  @@!       
!@!  @!@  !@!  @!@  !@!  @!@  !@!  @!@  !@!       
@!@  !@!  @!@!!@!   @!@  !@!  @!@  !@!  @!!       
!@!  !!!  !!@!@!    !@!  !!!  !@!  !!!  !!!       
!!:  !!!  !!: :!!   !!:  !!!  !!:  !!!  !!:       
:!:  !:!  :!:  !:!  :!:  !:!  :!:  !:!   :!:      
 :::: ::  ::   :::  ::::: ::  ::::: ::   :: ::::  
:: :  :    :   : :   : :  :    : :  :   : :: : :                                   
                 
*/

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC721Holder.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

abstract contract APMFER {
  function burn(uint256 tokenId) public virtual;
  function ownerOf(uint256 tokenId) public virtual returns (address);
}

contract DroolRewards is ERC721Holder, ReentrancyGuard, Ownable, Pausable {
    
    using SafeERC20 for IERC20;

    IERC20 public immutable drool;
    IERC721 public immutable apt;

    // Burning
    APMFER public immutable apmfer;
    uint public immutable DROOL_PER_SACRIFICE = 420 ether;
    
    // Staking
    uint256 public immutable DROOL_PER_SECOND = 79861111100000; // 6.9 drool per day
    uint256 public totalSupply;
    mapping(address => uint) public lastClaim;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public balances;
    mapping(uint256 => address) public stakedAssets;
    event Staked(address indexed user, uint256 amount, uint256[] tokenIds);
    event Withdrawn(address indexed user, uint256 amount, uint256[] tokenIds);
    event RewardPaid(address indexed user, uint256 reward);
    
    // Airdrop
    bytes32 public immutable merkleRoot;
    mapping(address => bool) public hasClaimed;
    error AlreadyClaimed();
    error NotInMerkle();
    event Claim(address indexed to, uint256 amount);

    constructor(
        address _apt,
        address _apmfer,
        address _drool,
        bytes32 _merkleRoot
    ) {
        apt = IERC721(_apt);
        apmfer = APMFER(_apmfer);
        drool = IERC20(_drool);
        merkleRoot = _merkleRoot;
    }

    // Airdrop Functions
    function claim(address to, uint256 amount, bytes32[] calldata proof) external {
        if (hasClaimed[to]) revert AlreadyClaimed();

        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        
        if (!isValidLeaf) revert NotInMerkle();
        
        hasClaimed[to] = true;
        drool.safeTransfer(to, amount);
        
        emit Claim(to, amount);
    }

    // Burning Functions
    function sacrificeMfers(uint[] memory tokenIds) external {
        for(uint x = 0; x < tokenIds.length; x++) {
            require(apmfer.ownerOf(tokenIds[x]) == msg.sender, "You don't own this mfer");
            apmfer.burn(tokenIds[x]);
        }
        drool.safeTransfer(msg.sender, DROOL_PER_SACRIFICE * tokenIds.length);
    }

    function sacrificeMfer(uint tokenId) external {
        require(apmfer.ownerOf(tokenId) == msg.sender, "You don't own this mfer");
        apmfer.burn(tokenId);
        drool.safeTransfer(msg.sender, DROOL_PER_SACRIFICE);
    }

    // Staking Functions 
    function stake(uint256[] memory tokenIds) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(tokenIds.length != 0, "Staking: No tokenIds provided");

        uint256 amount;
        for (uint256 i = 0; i < tokenIds.length; i += 1) {
            apt.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
            amount += 1;
            stakedAssets[tokenIds[i]] = msg.sender;
        }
        _stake(amount);
        emit Staked(msg.sender, amount, tokenIds);
    }

    function withdraw(uint256[] memory tokenIds) public nonReentrant updateReward(msg.sender) {
        require(tokenIds.length != 0, "Staking: No tokenIds provided");

        uint256 amount;
        for (uint256 i = 0; i < tokenIds.length; i += 1) {
            require(
                stakedAssets[tokenIds[i]] == msg.sender,
                "Staking: Not the staker of the token"
            );
            apt.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
            amount += 1;
            stakedAssets[tokenIds[i]] = address(0);
        }
        _withdraw(amount);

        emit Withdrawn(msg.sender, amount, tokenIds);
    }
    
    function earned(address account) public view returns (uint256) {
        uint claimed = lastClaim[account];
        return (block.timestamp - claimed) * DROOL_PER_SECOND * balances[account];
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            drool.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit(uint256[] memory tokenIds) external {
        withdraw(tokenIds);
        getReward();
    }

    function _stake(uint256 _amount) internal {
        totalSupply += _amount;
        balances[msg.sender] += _amount;
    }

    function _withdraw(uint256 _amount) internal {
        totalSupply -= _amount;
        balances[msg.sender] -= _amount;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    modifier updateReward(address account) {
        uint total = (block.timestamp - lastClaim[account]) * DROOL_PER_SECOND * balances[account];
        if (account != address(0)) {
            rewards[account] += earned(account);
            lastClaim[account] = block.timestamp;
        }
        _;
    }
}