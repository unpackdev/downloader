// SPDX-License-Identifier: MIT

/*
⢸⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⡷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠢⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠈⠑⢦⡀⠀⠀⠀⠀⠀
⢸⠀⠀⠀⠀⢀⠖⠒⠒⠒⢤⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠙⢦⡀⠀⠀⠀⠀
⢸⠀⠀⣀⢤⣼⣀⡠⠤⠤⠼⠤⡄⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠙⢄⠀⠀⠀⠀
⢸⠀⠀⠑⡤⠤⡒⠒⠒⡊⠙⡏⠀⢀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠑⠢⡄⠀
⢸⠀⠀⠀⠇⠀⣀⣀⣀⣀⢀⠧⠟⠁⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀
⢸⠀⠀⠀⠸⣀⠀⠀⠈⢉⠟⠓⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸
⢸⠀⠀⠀⠀⠈⢱⡖⠋⠁⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸
⢸⠀⠀⠀⠀⣠⢺⠧⢄⣀⠀⠀⣀⣀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸
⢸⠀⠀⠀⣠⠃⢸⠀⠀⠈⠉⡽⠿⠯⡆⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸
⢸⠀⠀⣰⠁⠀⢸⠀⠀⠀⠀⠉⠉⠉⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸
⢸⠀⠀⠣⠀⠀⢸⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸
⢸⠀⠀⠀⠀⠀⢸⠀⢇⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸
⢸⠀⠀⠀⠀⠀⡌⠀⠈⡆⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸
⢸⠀⠀⠀⠀⢠⠃⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸
⢸⠀⠀⠀⠀⢸⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠷
*/       
                                                           
pragma solidity ^0.8.0;
interface nftInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";

/**
 * @title DadMfers contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract DadMfers is ERC721, ERC721Enumerable, Ownable {

    string public PROVENANCE;

    bool public mintIsActive = false;
    bool public publicMint = false;
    uint256 public publicTokenPrice = 0.0269 ether;
    uint256 public constant maxTokens = 10033;
    uint256 public constant freeMintNumber = 1000;
    uint256 public constant mferFreeMintNumber = 250;
    uint256 public constant maxMintsPerTx = 20;

    bool public burnAllRemainingSupplyForever = false;

    uint256 public tokenCount=1;

    string private _baseURIextended;
    address payable public immutable shareholderAddress;

    // The actual goat
    address payable public immutable sartoshiAddress = payable(0xF7DcF798971452737f1E6196D36Dd215b43b428D);

    // Mfers NFT Contract
    address public nftAddress = 0x79FCDEF22feeD20eDDacbB2587640e45491b757f;

    bool public devMintLocked = false;

    nftInterface nftContract = nftInterface(nftAddress);

    // -------------------------------------------------

    constructor(address payable shareholderAddress_) ERC721("dadmfers", "DADMFERS") {
        require(shareholderAddress_ != address(0));
        shareholderAddress = shareholderAddress_;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    //Overrides
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    //Set Base URI
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function isMintActive() external view returns (bool) {
        return mintIsActive;
    }

    function isPublicMint() external view returns (bool) {
        return publicMint;
    }

    function setMintState(bool newState) public onlyOwner {
        mintIsActive = newState;
    }

    function setPublicMint(bool newState) public onlyOwner {
        publicMint = newState;
    }

    function updatePublicPrice(uint256 newPrice) public onlyOwner {
        publicTokenPrice = newPrice;
    }

    // SELLING

    //Private sale minting (reserved for mfers)
    function mintWithMfer(uint256 nftId) external payable {
        require(!burnAllRemainingSupplyForever, "Remaining supply has been burned");

        require(mintIsActive, "Dadmfers must be active to mint");
        require(!publicMint, "Dadmfers must be in mfer-only mint phase");

        require(tokenCount - 1 + 1 <= mferFreeMintNumber, "Minting would exceed free mints for mfers");

        require(nftContract.ownerOf(nftId) == msg.sender, "Not the owner of this Mfer!");

        tokenCount++;

        require(!_exists(nftId), "This Mfer has already been used.");

        _safeMint(msg.sender, nftId);
    }

    //Private sale minting (reserved for mfers)
    function mintAllDadMfers() external payable {
        require(!burnAllRemainingSupplyForever, "Remaining supply has been burned");

        require(mintIsActive, "Dadmfers must be active to mint");
        require(!publicMint, "Dadmfers must be in mfer-only mint phase");
        
        uint256 balance = nftContract.balanceOf(msg.sender);

        require(tokenCount - 1 + balance <= mferFreeMintNumber, "Minting would exceed free mints for mfers");
        
        for (uint i = 0; i < balance; i++) {
            uint256 ownedToken = nftContract.tokenOfOwnerByIndex(msg.sender, i);
            require(nftContract.ownerOf(ownedToken) == msg.sender, "Not the owner of this Mfer");
            if(_exists(ownedToken)) {
                continue;
            } else {
                _mint(msg.sender, ownedToken);
                tokenCount++;
            }
        }
    }

    // this is to mint 1/1s to airdrop to holders
    function mintSpecial(uint256 [] memory specialId) external onlyOwner {        
        require (!devMintLocked, "Dev Mint Permanently Locked");
        for (uint256 i = 0; i < specialId.length; i++) {
            require (specialId[i]!=0);
            _mint(msg.sender, specialId[i]);
        }
    }

    function lockDevMint() public onlyOwner {
        devMintLocked = true;
    }

    function setBurnAllRemainingSupplyForever() public onlyOwner {
        burnAllRemainingSupplyForever = true;
    }

    function mintPublic(uint256 quantity) external payable {
        require(!burnAllRemainingSupplyForever, "Remaining supply has been burned");

        require(mintIsActive, "Dadmfers must be active to mint");
        require(publicMint, "minting is not open to the public yet!");

        require(quantity <= maxMintsPerTx, "trying to mint too many at a time!");
        require(tokenCount - 1 + quantity <= maxTokens, "minting this many would exceed supply");

        if(tokenCount - 1 + quantity > freeMintNumber) {
            require(msg.value >= publicTokenPrice * quantity, "not enough ether sent!");
        }

        uint256 i = 0;
        for (uint256 j = 1; j < maxTokens + 1; j++) {
            if (i == quantity) {
                break;
            }
            else {
                if (!_exists(j) && i < quantity) {
                    _safeMint(msg.sender, j);
                    i++;
                    tokenCount++;
                }
            }
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(sartoshiAddress, ((balance * 1) / 10));
        Address.sendValue(shareholderAddress, ((balance * 9) / 10));
    }

}