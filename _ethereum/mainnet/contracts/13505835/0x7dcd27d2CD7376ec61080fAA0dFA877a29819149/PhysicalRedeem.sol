/*

 ___    _                                    _       ___               _                          
(  _`\ ( )                  _               (_ )    |  _`\            ( )                         
| |_) )| |__   _   _   ___ (_)   ___    _ _  | |    | (_) )   __     _| |   __     __    ___ ___  
| ,__/'|  _ `\( ) ( )/',__)| | /'___) /'_` ) | |    | ,  /  /'__`\ /'_` | /'__`\ /'__`\/' _ ` _ `\
| |    | | | || (_) |\__, \| |( (___ ( (_| | | |    | |\ \ (  ___/( (_| |(  ___/(  ___/| ( ) ( ) |
(_)    (_) (_)`\__, |(____/(_)`\____)`\__,_)(___)   (_) (_)`\____)`\__,_)`\____)`\____)(_) (_) (_)
              ( )_| |                                                                             
              `\___/'                                                                             

*/
// SPDX-License-Identifier: LGPL-3.0+
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./ECDSA.sol";
import "./ITraitRegistry.sol";
pragma solidity ^0.8.0;

contract PhysicalRedeem is Ownable {
    // Card related
    uint256 public claimCount = 0;
    IERC721 public dr_contract_address; //= IERC721(0x922A6ac0F4438Bf84B816987a6bBfee82Aa02073);
    ITraitRegistry public traitRegistry; // 0x4E6ed01C6d4C906aD5428223855865EF75261338
    // Events
    event setClaimStatus(uint256 __tokenID, bool _status);

    constructor(address _dr_contract_address, address _tr) {
        dr_contract_address = IERC721(_dr_contract_address);
        traitRegistry = ITraitRegistry(_tr);
    }

    // Set Card Property
    function getHash(
        bytes16 md5hash,
        uint64 rowID,
        uint64 timeLimit
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(md5hash, rowID, timeLimit));
    }

    function isInitialized() external view returns (bool) {
        // would be nice to be able to check rnd.isAuthorised()
        return traitRegistry.addressCanModifyTrait(address(this), 2);
    }

/*   function resultReturn(
        // Can delete. testing only.
        bytes16 md5hash, // 128 bits.
        uint64 rowID, //64 bits
        uint64 timeLimit, // 64bits
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(md5hash, rowID, timeLimit));
        hash = ECDSA.toEthSignedMessageHash(hash);
        address signer = ECDSA.recover(hash, v, r, s);
        return signer;
    }
*/
    function claimRedeemable(
        uint256 _tokenId,
        bytes16 md5hash,
        uint64 rowID,
        uint64 timeLimit,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(traitRegistry.hasTrait(2, uint16(_tokenId)), "SCRedeem: Trait not found");
        if (timeLimit < block.timestamp) {
            revert("Signature Expired");
        }
        // Validate.
        bytes32 hash = getHash(md5hash, rowID, timeLimit);
        hash = ECDSA.toEthSignedMessageHash(hash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer != address(0) && signer == msg.sender, "Invalid signature");
        require(dr_contract_address.ownerOf(_tokenId) == msg.sender, "Not Token ID owner.");

        // remove trait from token
        traitRegistry.setTrait(2,  uint16(_tokenId), false);
        emit setClaimStatus(_tokenId, true);
        claimCount++;
    }

    function getArtRedeemStatus(uint256 _tokenID) public view returns (bool) {
        return traitRegistry.hasTrait(2, uint16(_tokenID));
    }

    // Admin Ops
    receive() external payable {
        // React to receiving ether
    }

    function drain(IERC20 _token) external onlyOwner {
        if (address(_token) == 0x0000000000000000000000000000000000000000) {
            payable(owner()).transfer(address(this).balance);
        } else {
            _token.transfer(owner(), _token.balanceOf(address(this)));
        }
    }

    function retrieve721(address _tracker, uint256 _id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, _id);
    }
}
