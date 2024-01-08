// SPDX-License-Identifier: MIT
// Developer: @Brougkr

pragma solidity ^0.8.4;
import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155Burnable.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract SpiritSeed is ERC1155, Ownable, Pausable, ERC1155Burnable
{
    using SafeMath for uint256;

    //Initialization
    string public constant name = "SpiritSeed";
    string public constant symbol = "SEED";
    string public _BASE_URI = "https://ipfs.io/ipfs/QmXXAE5fQmPkx7Jkeoj1Kq6ANWSqVov5mCzgmAwf8Fmcxs/";
    
    //Token Amounts
    uint256 public _SEEDS_MINTED = 0;
    uint256 public _MAX_SEEDS = 100;
    uint256 public _MAX_SEEDS_PURCHASE = 5;
    
    //Price
    uint256 public _SEED_PRICE = 0.55 ether;

    //Sale State
    bool public _SALE_IS_ACTIVE = false;
    bool public _ALLOW_MULTIPLE_PURCHASES = false;

    //Mint Mapping
    mapping (address => bool) private minted;

    //Constructor
    constructor() ERC1155("https://ipfs.io/ipfs/QmXXAE5fQmPkx7Jkeoj1Kq6ANWSqVov5mCzgmAwf8Fmcxs/{id}.json") { }

    //URI for decoding storage of tokenIDs
    function uri(uint256 tokenId) override public view returns (string memory) { return(string(abi.encodePacked(_BASE_URI, Strings.toString(tokenId), ".json"))); }

    //Mints SpiritSeed Seeds
    function SpiritSeedMint(uint numberOfTokens) public payable
    {
        require(_SALE_IS_ACTIVE, "Sale must be active to mint Seeds");
        require(numberOfTokens <= _MAX_SEEDS_PURCHASE, "Can only mint 5 Seeds at a time");
        require(_SEEDS_MINTED.add(numberOfTokens) <= _MAX_SEEDS, "Purchase would exceed max supply of Seeds");
        require(_SEED_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct. 0.55 ETH Per Seed | 550000000000000000 WEI");
        if(!_ALLOW_MULTIPLE_PURCHASES) { require(!minted[msg.sender], "Address Has Already Minted"); }

        //Mints Seeds
        for(uint i = 0; i < numberOfTokens; i++) 
        {
            if (_SEEDS_MINTED < _MAX_SEEDS) 
            {
                _mint(msg.sender, _SEEDS_MINTED, 1, "");
                _SEEDS_MINTED += 1;
            }
        }
        minted[msg.sender] = true;
    }
    
    //Conforms to ERC-1155 Standard
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal whenNotPaused override 
    { 
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data); 
    }

    //Batch Transfers Tokens
    function __batchTransfer(address[] memory recipients, uint256[] memory tokenIDs, uint256[] memory amounts) public onlyOwner 
    { 
        for(uint i=0; i < recipients.length; i++) 
        { 
            _safeTransferFrom(msg.sender, recipients[i], tokenIDs[i], amounts[i], ""); 
        }
    }

    //Reserves Seeds
    function __reserveSeeds(uint256 amt) public onlyOwner
    {
        for(uint i=0; i<amt; i++) 
        { 
            _mint(msg.sender, i, 1, ""); 
            _SEEDS_MINTED += 1;
        }
    }

    //Sets Base URI For .json hosting
    function __setBaseURI(string memory BASE_URI) public onlyOwner { _BASE_URI = BASE_URI; }

    //Sets Max Seeds for future Seed Expansion Packs
    function __setMaxSeeds(uint256 MAX_SEEDS) public onlyOwner { _MAX_SEEDS = MAX_SEEDS; }

    //Sets Max Seeds Purchaseable by Wallet
    function __setMaxSeedsPurchase(uint256 MAX_SEEDS_PURCHASE) public onlyOwner { _MAX_SEEDS_PURCHASE = MAX_SEEDS_PURCHASE; }

    //Sets Future Seed Price
    function __setSeedPrice(uint256 SEED_PRICE) public onlyOwner { _SEED_PRICE = SEED_PRICE; }

    //Flips Allowing Multiple Purchases for future Seed Expansion Packs
    function __flip_allowMultiplePurchases() public onlyOwner { _ALLOW_MULTIPLE_PURCHASES = !_ALLOW_MULTIPLE_PURCHASES; }
    
    //Flips Sale State
    function __flip_saleState() public onlyOwner { _SALE_IS_ACTIVE = !_SALE_IS_ACTIVE; }

    //Withdraws Ether from Contract
    function __withdraw() public onlyOwner { payable(msg.sender).transfer(address(this).balance); }

    //Pauses Contract
    function __pause() public onlyOwner { _pause(); }

    //Unpauses Contract
    function __unpause() public onlyOwner { _unpause(); }
}