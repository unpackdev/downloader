// SPDX-License-Identifier: MIT

/******************************************
 *  Amendeded by Bearified Labs Devs      *
 *       Author: devAle𝕏.ᴱᵀᴴ|ᵍᵐ           *
 ******************************************/
//https://www.bearified.xyz/
//https://twitter.com/AlexDotEth
//https://www.pepeapeyachtclub.com/
//https://twitter.com/PepeApeYC
// @custom:security-contact alex@bearified.xyz

 /*                                                                                                      
@@@@@@@    @@@@@@   @@@ @@@   @@@@@@@      @@@@@@   @@@@@@@@  @@@@@@@   @@@  @@@  @@@@@@@@@@    @@@@@@   
@@@@@@@@  @@@@@@@@  @@@ @@@  @@@@@@@@     @@@@@@@   @@@@@@@@  @@@@@@@@  @@@  @@@  @@@@@@@@@@@  @@@@@@@   
@@!  @@@  @@!  @@@  @@! !@@  !@@          !@@       @@!       @@!  @@@  @@!  @@@  @@! @@! @@!  !@@       
!@!  @!@  !@!  @!@  !@! @!!  !@!          !@!       !@!       !@!  @!@  !@!  @!@  !@! !@! !@!  !@!       
@!@@!@!   @!@!@!@!   !@!@!   !@!          !!@@!!    @!!!:!    @!@!!@!   @!@  !@!  @!! !!@ @!@  !!@@!!    
!!@!!!    !!!@!!!!    @!!!   !!!           !!@!!!   !!!!!:    !!@!@!    !@!  !!!  !@!   ! !@!   !!@!!!   
!!:       !!:  !!!    !!:    :!!               !:!  !!:       !!: :!!   !!:  !!!  !!:     !!:       !:!  
:!:       :!:  !:!    :!:    :!:              !:!   :!:       :!:  !:!  :!:  !:!  :!:     :!:      !:!   
 ::       ::   :::     ::     ::: :::     :::: ::    :: ::::  ::   :::  ::::: ::  :::     ::   :::: ::   
 :         :   : :     :      :: :: :     :: : :    : :: ::    :   : :   : :  :    :      :    :: : :    
                                                                                                         
                                                                                                */

pragma solidity ^0.8.23;

import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC1155PausableUpgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC721.sol";

// Import $Sheesh contract
import "./ERC20Token.sol"; 

/// @custom:security-contact alex@bearified.xyz
contract PAYCSerums is Initializable, ERC1155Upgradeable, OwnableUpgradeable, ERC1155PausableUpgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable, UUPSUpgradeable {
    uint256 public costPerSerum; // Cost per serum, initialized in the initializer
    string private _contractURI;
    mapping(uint256 => uint256) public maxSupplyPerTokenId; // Max supply cap for each token ID

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) initializer public {
        __ERC1155_init("https://ipfs.io/ipfs/QmcbrRSmTN15uhVRyoE2E15uwAsP5N2AhfZaunEfkWM6tN/1.json");
        __Ownable_init(initialOwner);
        __ERC1155Pausable_init_unchained();
        __ERC1155Burnable_init_unchained();
        __ERC1155Supply_init_unchained();
        __UUPSUpgradeable_init();
        transferOwnership(initialOwner); // Transfer ownership to the initial owner

        // Initialize cost per serum here
        costPerSerum = 420000000 * (10**18); // This represents 420,000,000 Sheesh tokens
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updateCostPerSerum(uint256 newCostPerSerum) public onlyOwner {
        costPerSerum = newCostPerSerum;
    }

    function setMaxSupplyForTokenId(uint256 tokenId, uint256 maxSupply) public onlyOwner {
        maxSupplyPerTokenId[tokenId] = maxSupply;
    }

    function purchaseSerum(uint256 serumId, uint256 serumAmount) public {
        uint256 price = serumAmount * costPerSerum;
        AuraDropERC20 sheeshToken = AuraDropERC20(0xbB4f3aD7a2cf75d8EfFc4f6D7BD21d95F06165ca);
        require(sheeshToken.transferFrom(msg.sender, address(this), price), "Transfer failed");
        require(totalSupply(serumId) + serumAmount <= maxSupplyPerTokenId[serumId], "Exceeds max supply for token id");
        _mint(msg.sender, serumId, serumAmount, "");
    }

    function burnMutantsAndGetSerum(uint256[] memory mutantIds) public {
        require(mutantIds.length == 5, "Exactly 5 mutants required");
        IERC721 PAYCMutants = IERC721(0x0802f7a7c48426E972a30aAaB3C2f35c14a35Bc8);
        for (uint256 i = 0; i < mutantIds.length; i++) {
            require(PAYCMutants.ownerOf(mutantIds[i]) == msg.sender, "Caller does not own this mutant");
            PAYCMutants.safeTransferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), mutantIds[i]);
        }
        uint256 serumId = 1; // Mutant burn is only available for serum ID is 1
        require(totalSupply(serumId) + 1 <= maxSupplyPerTokenId[serumId], "Exceeds max supply for serum");
        _mint(msg.sender, serumId, 1, "");
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        require(totalSupply(id) + amount <= maxSupplyPerTokenId[id], "Exceeds max supply for token id");
        _mint(to, id, amount, data);
    }

    function batchMint(address[] memory to, uint256[] memory id, uint256[] memory amount, bytes memory data) public onlyOwner {
        require(to.length <= 1000, "PAYCSerums: Batch size exceeds limit"); // Setting a batch limit of 1000
        require(to.length == amount.length, "PAYCSerums: to and amount length mismatch");
        require(to.length == id.length, "PAYCSerums: to and id length mismatch");
        for (uint256 i = 0; i < to.length; ++i) {
            require(totalSupply(id[i]) + amount[i] <= maxSupplyPerTokenId[id[i]], "Exceeds max supply for token id");
            _mint(to[i], id[i], amount[i], data);
        }
    }

    function burn(address account, uint256 id, uint256 amount) public override {
        require(account == msg.sender || isApprovedForAll(account, msg.sender), "Caller is not owner nor approved");
        _burn(account, id, amount);
    }

    function withdrawTokens(address to, uint256 amount) public onlyOwner {
        AuraDropERC20 sheeshToken = AuraDropERC20(0xbB4f3aD7a2cf75d8EfFc4f6D7BD21d95F06165ca);
        require(sheeshToken.transfer(to, amount), "Transfer failed");
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setContractURI(string memory newContractURI) public onlyOwner {
        _contractURI = newContractURI;
    }

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    // The following functions are overrides required by Solidity.
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155Upgradeable, ERC1155PausableUpgradeable, ERC1155SupplyUpgradeable)
    {
        super._update(from, to, ids, values);
    }
}