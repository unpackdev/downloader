// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";


import "./IVeToken.sol";
import "./IMint.sol";

contract XBE2XB3Migrator is Pausable, Ownable, ReentrancyGuard {

    struct MigrateInfo {
        address account;
        uint256 xbeBalance;
        uint256 vsrStaked;
        uint256 vsrReward;
        uint256 bcStaked;
        uint256 bcReward;
        uint256 referralReward;
        uint256 vexbeLockedAmount;
        uint256 vexbeLockedEnd;
        uint256 sushiVaultEarned;
        uint256 fraxVaultEarned;
        uint256 crvCvxVaultEarned;
    }

    IERC20 public newToken;
    IVeToken public newVeToken;
    bytes32 public merkleRoot;
    address public ico;
    uint256 public feeBpsOnClaim;

    mapping(address => bool) public migrated;

    event Migrated(address user);

    constructor(
        address _ico,
        IERC20 _newToken,
        IVeToken _newVeToken,
        uint256 _feeBpsOnClaim,
        bytes32 _root
    ) {
        ico = _ico;
        newToken = _newToken;
        newVeToken = _newVeToken;
        _newToken.approve(address(_newVeToken), type(uint256).max);
        merkleRoot = _root;
        feeBpsOnClaim = _feeBpsOnClaim;

    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setNewToken(IERC20 _newToken) external onlyOwner {
        newToken = _newToken;
        _newToken.approve(address(newVeToken), type(uint256).max);
    }

    function setVeNewToken(IVeToken _newVeToken) external onlyOwner {
        newVeToken = _newVeToken;
        newToken.approve(address(_newVeToken), type(uint256).max);
    }

    function migrateForIco(uint256 _amount) external onlyOwner {
        address icoAddress = ico;
        require(!migrated[icoAddress], "already migrated");
        IMint(address(newToken)).mint(icoAddress, _amount);
        emit Migrated(icoAddress);
    }   

    function migrateForTreasury(address _treasury, uint256 _amount) external onlyOwner {
        IMint(address(newToken)).mint(_treasury, _amount);
        emit Migrated(_treasury);
    }  

    function migrate(
        MigrateInfo memory _info,
        bytes32[] memory _proof
    ) external whenNotPaused nonReentrant {
        require(!migrated[_info.account], "already migrated");   
        require(msg.sender == _info.account, "cannot migrate other account");    
        require(
            _verify(
                _leaf(
                    _info.account,
                    _info.xbeBalance,
                    _info.vsrStaked,
                    _info.vsrReward,
                    _info.bcStaked,
                    _info.bcReward,
                    _info.referralReward,
                    _info.vexbeLockedAmount,
                    _info.vexbeLockedEnd,
                    _info.sushiVaultEarned,
                    _info.fraxVaultEarned,
                    _info.crvCvxVaultEarned
                ), 
                _proof
            ),
             "incorrect proof"
        );

        address newTokenAddress = address(newToken);

        if (_info.vexbeLockedAmount != 0) IMint(newTokenAddress).mint(address(this), _info.vexbeLockedAmount);

        if (_info.bcStaked != 0) {  // if user is in the BC, lock for max time
            uint256 maxtime = newVeToken.MAXTIME();
            _lockFunds(_info.account, _info.bcStaked, block.timestamp + maxtime);
        }
        
        if (_info.vexbeLockedEnd != 0) { // if user has locked XBEs, lock for the same term
            _lockFunds(_info.account, _info.vexbeLockedAmount - _info.bcStaked, _info.vexbeLockedEnd);
        }

        uint256 fromVaults = 
            _info.sushiVaultEarned + 
            _info.fraxVaultEarned +
            _info.crvCvxVaultEarned;

        uint256 toMint = 
            _info.xbeBalance + 
            (_info.vsrStaked - _info.vexbeLockedAmount) + 
            _info.vsrReward + 
            _info.bcReward + 
            _info.referralReward + 
            fromVaults * (10000 - feeBpsOnClaim) / 10000;

        IMint(newTokenAddress).mint(_info.account, toMint);

        migrated[_info.account] = true;
        emit Migrated(_info.account);
    }

    function _lockFunds(
        address _account,
        uint256 _unlockAmount,
        uint256 _unlockTime
    ) internal {
        IVeToken newVeToken_ = newVeToken;

        uint256 newUnlockTime = newVeToken_.lockedEnd(_account);

        uint256 maxtime = newVeToken.MAXTIME();
        _unlockTime = _unlockTime <= block.timestamp ? block.timestamp + maxtime : _unlockTime; // if old lock is expired, lock for the max time
        if (newUnlockTime == 0) {   // if user hasn't locked XB3, just create lock
            newVeToken_.createLockFor(_account, _unlockAmount, _unlockTime);
        } else {
            require(newUnlockTime >= block.timestamp, "withdraw your lock first");  // if user has expired XB3 lock, he/she must withdraw it first
            if (newUnlockTime < _unlockTime) newVeToken_.increaseUnlockTimeFor(_account, _unlockTime);  // if the current XB3s lock time is less than old XBEs' one, increase the current XB3 lock time
            newVeToken_.increaseAmountFor(_account, _unlockAmount);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    /*
    * @dev Returns the leaf for Merkle tree
    * @param _account Address of the user
    * @param _userId ID of the user
    */
    function _leaf(
        address _account,
        uint256 xbeBalance,
        uint256 vsrStaked,
        uint256 vsrReward,
        uint256 bcStaked,
        uint256 bcReward,
        uint256 referralReward,
        uint256 vexbeLockedAmount,
        uint256 vexbeLockedEnd,
        uint256 sushiVaultEarned,
        uint256 fraxVaultEarned,
        uint256 crvCvxVaultEarned
    ) internal view returns (bytes32)
    {

        return keccak256(
            abi.encodePacked(
                _account,
                xbeBalance,
                vsrStaked,
                vsrReward,
                bcStaked,
                bcReward,
                referralReward,
                vexbeLockedAmount,
                vexbeLockedEnd,
                sushiVaultEarned,
                fraxVaultEarned,
                crvCvxVaultEarned
            )
        );
    }

    /*
    * @dev Verifies if the proof is valid or not
    * @param _leaf The leaf for the user
    * @param _proof Proof for the user
    */
    function _verify(bytes32 _leaf, bytes32[] memory _proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

}
