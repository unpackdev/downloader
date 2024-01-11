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

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract DroolAirdrop is Ownable {
    
    using SafeERC20 for IERC20;

    IERC20 public immutable drool;

    bytes32 public merkleRoot;
    mapping(address => bool) public hasClaimed;
    error AlreadyClaimed();
    error NotInMerkle();
    event Claim(address indexed to, uint256 amount);

    constructor(
        address _drool,
        bytes32 _merkleRoot
    ) {
        drool = IERC20(_drool);
        merkleRoot = _merkleRoot;
    }

    function claim(address to, uint256 amount, bytes32[] calldata proof) external {
        if (hasClaimed[to]) revert AlreadyClaimed();

        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        
        if (!isValidLeaf) revert NotInMerkle();
        
        hasClaimed[to] = true;
        drool.safeTransfer(to, amount);
        
        emit Claim(to, amount);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
}