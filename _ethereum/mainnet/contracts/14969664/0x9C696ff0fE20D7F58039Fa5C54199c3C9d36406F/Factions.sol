//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./AdminsControllerUpgradeable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./ECDSA.sol";
import "./draft-EIP712Upgradeable.sol";
import "./IFaction.sol";
import "./IERC721A.sol";

contract Factions is Initializable, PausableUpgradeable, ReentrancyGuardUpgradeable, AdminsControllerUpgradeable, EIP712Upgradeable {
    mapping (uint256 => IFaction) private _tokenToFaction;
    mapping (uint256 => IFaction) private _faction;
    address public signer;
    IERC721A public nft;

    function initialize(IAdmins admins, IFaction[] memory factions, address _signer, IERC721A _nft) public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __AdminController_init(admins);
        __EIP712_init("ZooverseFactions", "0.1.0");
        signer = _signer;
        nft = _nft;

        _faction[1] = factions[0];
        _faction[2] = factions[1];
        _faction[3] = factions[2];
        _faction[4] = factions[3];
        _faction[5] = factions[4];
        _faction[6] = factions[5];
        _faction[7] = factions[6];
        _faction[8] = factions[7];
        _faction[9] = factions[8];
        _faction[10] = factions[9];
        _faction[11] = factions[10];
        _faction[12] = factions[11];
        _faction[13] = factions[12];
        _faction[14] = factions[13];
        _faction[15] = factions[14];
        _faction[16] = factions[15];
        _faction[17] = factions[16];
        _faction[18] = factions[17];
        _faction[19] = factions[18];
        _faction[20] = factions[19];
    }

    struct Request {
        uint256[] ids;
        uint256[] factions;
    }

    function mint(Request calldata request, bytes calldata signature)
        external 
        whenNotPaused 
        nonReentrant 
    {        
        require(verify(request, signature), "Invalid signature");
        uint256 i = 0;        
        uint256 length = request.ids.length;
        require(request.factions.length == length, "Mistmatch length");        
        for(i; i < length;) {
            uint256 current = request.ids[i];
            require(_tokenToFaction[current] == IFaction(address(0)), "Already claimed");
            require(nft.ownerOf(current) == msg.sender, "Not owner");            
            uint256 factionId = request.factions[i];
            IFaction factionAddress = _faction[factionId];
            factionAddress.mint(msg.sender, 1 ether);
            _tokenToFaction[current] = factionAddress;
            unchecked {
                ++i;
            }
        }
    }

    function verify(Request calldata request, bytes calldata signature)
        public
        view
        returns (bool)
    {   
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(
                keccak256("Request(uint256[] ids,uint256[] factions)"), 
                keccak256(abi.encodePacked(request.ids)),
                keccak256(abi.encodePacked(request.factions))
            ))
        );
        address signer_ = ECDSA.recover(digest, signature);
        return signer_ == signer;
    }

    function isMinted(uint256 id) public view returns (bool) {
        return address(getFaction(id)) != address(0);
    }

    function getFaction(uint256 id) public view returns (IFaction) {
        return _tokenToFaction[id];
    }

    function updateFaction(uint256 id, address tokenAddress) external onlyAdmins {
        _faction[id] = IFaction(tokenAddress);
    }

    function setSigner(address _signer) external onlyAdmins {
        signer = _signer;
    }

    function setNFT(IERC721A _nft) external onlyAdmins {
        nft = _nft;
    }
}
