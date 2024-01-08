// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./UUPSUpgradeable.sol";

contract RA is Initializable, ERC20Upgradeable, PausableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    bytes32 public root;
    mapping(uint256 => uint256) public claimedBitMap;
   
    event ClaimTokens(uint256 index, address account, uint256 amount);
    event AdminMint(address account, uint256 amount);
    event UpdateRoot(bytes32 merkleroot);
    
    function initialize(string memory name, string memory symbol, address admin,  address pauser, address updater) public initializer {

        // init all
         __ERC20_init(name, symbol);
         __Pausable_init();
         __AccessControl_init();
         __ReentrancyGuard_init();

        // roles
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(PAUSER_ROLE, pauser);
        _setupRole(UPDATER_ROLE, updater);

        // set contract state to "paused" to prevent ERC20 "mint()" and "transfer()" functions
        _pause();
    }


    // 
    // user balance check
    // 
    function verifyBalance(uint256 index, address account, uint256 amount, bytes32[] calldata proof) external view returns (bool valid){
        return _verify(_leaf(index, account, amount), proof);
    }
    
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    // 
    // Claim tokens
    // 
    function claimTokens(uint256 index, address account, uint256 amount, bytes32[] calldata proof)
    external whenNotPaused nonReentrant
    {        
        // check valid merkle proof
        require(_verify(_leaf(index, account, amount), proof), "Invalid merkle proof");
        
        // check if already claimed
        require(!isClaimed(index), 'Already claimed');
        _setClaimed(index);

        // claim
        _mint(account, amount);

        emit ClaimTokens(index, account, amount);
    }

    // 
    // Update Merkle Root
    // 
    function updateRoot(bytes32 merkleroot) external whenPaused onlyRole(UPDATER_ROLE) {
        root = merkleroot;
        emit UpdateRoot(merkleroot);
    }
    
    // 
    // Pausable functions
    // 
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
    // ERC20 hook to implement pausable
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    // 
    // Admin mint
    // 
    function adminMint(address account, uint256 amount)
    external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant
    {        
        _mint(account, amount);

        emit AdminMint(account, amount);
    }

    // 
    // Upgrade
    // 
    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // 
    // Internal
    // 
    function _leaf(uint256 index, address account, uint256 amount)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(index, account, amount));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProofUpgradeable.verify(proof, root, leaf);
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }    
}