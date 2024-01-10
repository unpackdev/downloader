// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IQuantumKeyRing.sol";
import "./Auth.sol";
import "./ReentrancyGuard.sol";
import "./SafeTransferLib.sol";
import "./BitMaps.sol";
import "./MerkleProof.sol";

                                                  
//                                                   
//                                                   
//                                  XXXXXXX          
//                               X XXXX XXXXXX       
//                             XXSXSXXXXXX XXXXX     
//                             XXXXX XX  XXXXXSXX    
//                           XXXX  XXXS SSXX XXXX    
//                           XXX XXXX     XXXXXX X   
//                          XXXXXXX X      XXX XXX  
//                          XXXXXXXX       XXXXXXX   
//                           SXX XXXXX    XXXSXXSX   
//                           XXXXXXXXX XXXXXXXXXX    
//                          SXXX X XX XXXXXX XXX  
//                       XXXXXX X XXX X X XSXX
//                      SXXXXX X XXSXXXXS XX     
//                    XSXSX  XXXXXX            
//                   SXXX XXX XXXXX                  
//                 XXXXX SXXXXXX                     
//                SXXS  X XXXXX                      
//              XXXXXX X XSX X                       
//            XSXXX XX XXXXX                         
//          XXSXSSX XXXXXX                        
//        XSXXXSXXXXXXXXX                       
//        XXXXX XXXXXX                                                                                   

/// @title The Quantum Key Maker. It orders keys for you, and sends them to you.
/// @author exp.table
contract QuantumKeyMaker is Auth, ReentrancyGuard {
    using BitMaps for BitMaps.BitMap;

    /// >>>>>>>>>>>>>>>>>>>>>>>  EVENTS  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    event Ordered(uint256 indexed id, address indexed to, uint256 amount);


    /// >>>>>>>>>>>>>>>>>>>>>>>  STATE  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    IQuantumKeyRing private _keyRing;
    /// @notice _hasClaimed[keyId][merkleRoot] tracking of claims
    mapping (uint256 => mapping (bytes32 => BitMaps.BitMap)) private _hasClaimed;
    /// @notice valid roots - avoid spoofing when buying a key
    mapping (uint256 => mapping (bytes32 => bool)) private _validRoots;
    mapping (uint256 => uint256) public available;

    /// >>>>>>>>>>>>>>>>>>>>>  CONSTRUCTOR  <<<<<<<<<<<<<<<<<<<<<< ///

	/// @notice Deploys QuantumKeyMaker
    /// @dev Initiates the Auth module with no authority and the sender as the owner
    /// @param keyRing The address of QuantumKeyRing
    /// @param owner owner of the contract
    /// @param authority address of deployed authority
    constructor(address keyRing, address owner, address authority) Auth(owner, Authority(authority)) {
        _keyRing = IQuantumKeyRing(keyRing);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  RESTRICTED  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Mints keys to an address
    /// @param to address of recipient
    /// @param id id of the key
    /// @param amount amount to mint
    function preorder(address to, uint256 id, uint256 amount) public requiresAuth {
        _keyRing.make(to, id, amount);
    }

    /// @notice Set at once all the data necessary for a key drop
    /// @param id id of the token
    /// @param availability the number of keys available
    /// @param roots The list of roots to be used 
    function setKeyMold(
        uint256 id,
        uint256 availability,
        bytes32[] calldata roots
    ) requiresAuth public {
        for(uint256 i = 0; i < roots.length; i++) {
            _validRoots[id][roots[i]] = true;
        }
        available[id] = availability;
    }
    
    /// @notice Change a serie of roots for a particular id
    /// @dev if validate is set to false, it will invalidate them
    /// @param id id of the token
    /// @param roots The list of roots to be changed
    /// @param validate Whether to validate the roots or invalidate them
    function changeRoots(
        uint256 id,
        bytes32[] calldata roots,
        bool validate
    ) requiresAuth public {
        for(uint256 i = 0; i < roots.length; i++) {
            _validRoots[id][roots[i]] = validate;
        }
    }

    /// @notice Change a single root for a particular id
    /// @dev if validate is set to false, it will invalidate it
    /// @param id id of the token
    /// @param root The root to be changed
    /// @param validate Whether to validate the root or invalidate it
    function changeSingleRoot(
        uint256 id,
        bytes32 root,
        bool validate
    ) requiresAuth public {
        _validRoots[id][root] = validate;
    }

    /// @notice Set the amount of tokens available to be minted
    /// @param id id of the token
    /// @param amount The amount of tokens to be minted
    function setAvailability(uint256 id, uint256 amount) requiresAuth public {
        available[id] = amount;
    }

    /// @notice Withdraws the ETH held by the contract
    /// @param recipient recipient of the funds
    function withdraw(address recipient) requiresAuth public {
        SafeTransferLib.safeTransferETH(recipient, address(this).balance);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  EXTERNAL  <<<<<<<<<<<<<<<<<<<<<< ///


    /// @notice Buys a key
    /// @param id The id of the key to buy
    /// @param amount The id of the key to buy
    /// @param index index of the user in the merkle tree
    /// @param price price of the key
    /// @param start starting time associated with the merkle tree
    /// @param limited if the sale is limited to 1 item per address per root
    /// @param root merkle root
    /// @param proof The merkle proof
    function order(
        uint256 id,
        uint256 amount,
        uint256 index,
        uint256 price,
        uint256 start,
        bool limited,
        bytes32 root,
        bytes32[] calldata proof
    ) nonReentrant public payable {
        require(available[id] != 0, "MINTED_OUT");
        require(block.timestamp >= start, "TOO_EARLY");
        require((amount == 1 && limited) || !limited, "OVER_LIMIT");
        require(msg.value == price * amount, "WRONG_PRICE");
        if (limited) {
            // lose efficiency if public && limited
            uint256 idx = proof.length != 0 ? index : a2u(msg.sender);
            require(!_hasClaimed[id][root].get(idx), "ALREADY_CLAIMED");
            _hasClaimed[id][root].set(idx);
        }
        require(_validRoots[id][root], "INVALID_ROOT");
        // Assume if there is a proof, then it's not a public sale
        address user = proof.length != 0 ? msg.sender : address(0);
        bytes32 node = keccak256(abi.encodePacked(user, id, b2u(limited), index, price, start));
        require(MerkleProof.verify(proof, root, node), "INVALID_PROOF");
        available[id] -= amount;
        _keyRing.make(msg.sender, id, amount);
        emit Ordered(id, msg.sender, amount);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  VIEW/PURE  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice gets claim status of [id, root, index]
    /// @param id id of the drop/token
    /// @param root merkle root
    /// @param index index of the user in the merkle tree
    /// @param user address of the user
    /// @return bool if the user has claimed
    function hasClaimed(uint256 id, bytes32 root, uint256 index, address user) public view returns (bool) {
        return _hasClaimed[id][root].get(index) || _hasClaimed[id][root].get(a2u(user));
    }

    /// @notice converts a bool to uint256
    /// @param x bool to be converted
    /// @return r uint256 representation of the bool
    function b2u(bool x) pure internal returns (uint r) {
        assembly { r := x }
    }

    /// @notice converts an address to uint256
    /// @param addy address to be converted
    /// @return r uint256 representation of the address
    function a2u(address addy) pure internal returns (uint r) {
        assembly {r := addy}
    }
}