// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract GunkedGoblinTown is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public MAX_PUBLIC_MINT = 20;
    uint256 public MAX_FREE_MINT = 1;
    uint256 public PUBLIC_SALE_PRICE = 0.01 ether;
    uint256 public constant FREE_MINT_PRICE = 0 ether;
    uint256 public TOTAL_FREE_MINTS = 1000;

    string private  baseTokenUri;
    string public   placeholderTokenUri;

    //deploy smart contract, toggle pause, reveal in 2 days.
    bool public isRevealed;
    bool public publicSale;
    bool public freeMintSale;
    bool public pause = true;



    mapping(address => uint256) public totalPublicMint;


    constructor() ERC721A("GunkedGoblintown.wtf", "GUNKGOB", "https://gunkedgoblintown.wtf/nftdata/unrevealed.json", "https://gunkedgoblintown.wtf/nftdata/"){
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Gunkedgoblintown.wtf :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        if(TOTAL_FREE_MINTS != 0) {
            require(!pause, "Gunkedgoblintown.wtf :: Minting is on Pause");
            require(_quantity <= MAX_FREE_MINT, "Gunkedgoblintown.wtf :: Cannot mint more than 1 free token ");
            require((totalPublicMint[msg.sender] + _quantity) <= MAX_FREE_MINT, "Gunkedgoblintown.wtf :: 1 FrEe ToKeen AlLReeDy MiNteEd tO thIIs ADdResSSss");
            totalPublicMint[msg.sender] += _quantity;
            _safeMint(msg.sender, _quantity);
            TOTAL_FREE_MINTS - _quantity;
        } else {
            require(!pause, "Gunkedgoblintown.wtf :: Minting is on Pause");
            require((totalSupply() + _quantity) <= MAX_SUPPLY, "Gunkedgoblintown.wtf :: Beyond Max Supply");
            require(_quantity <= MAX_PUBLIC_MINT, "Gunkedgoblintown.wtf :: Cannot mint more than 20 tokens at a time..");
            require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "Gunkedgoblintown.wtf :: Payment is below the price");
            _safeMint(msg.sender, _quantity);
        }

    }

    function airdropTokens(address _to, uint256 _tokenAmount) public payable onlyOwner {
        uint256 supply = totalSupply();

        require(!pause, "Gunkedgoblintown.wtf :: Minting is on Pause");
        require(_tokenAmount > 0, "Gunkedgoblintown.wtf :: No Tokens To Airdrop..");
        require(supply + _tokenAmount <= MAX_SUPPLY, "Gunkedgoblintown.wtf :: Trying to mint Beyond Max Supply..");

        for (uint256 i = 1; i <= _tokenAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function initialMint() external onlyOwner {
        _safeMint(msg.sender, 1);
    }

    function reserveMint() external onlyOwner {
        require((totalSupply() <= 7887), "Gunkedgoblintown.wtf :: TotalSupply Not less than 7888 tokens.. Be patient young padwhan..");
        _safeMint(msg.sender, 888);
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return placeholderTokenUri;
        }
        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    /// @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns(uint256[] memory){
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for(uint256 index = 0; index < numberOfOwnedNFT; index++){
            ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }
	
    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner{
        placeholderTokenUri = _placeholderTokenUri;
    }

    function setTotalFreeMints(uint256 _TOTAL_FREE_MINTS) external onlyOwner{
        TOTAL_FREE_MINTS = _TOTAL_FREE_MINTS;
    }

    function setPublicSalePrice(uint256 _PUBLIC_SALE_PRICE) external onlyOwner{
        PUBLIC_SALE_PRICE = _PUBLIC_SALE_PRICE;
    }

    function setMaxFreeMintAmount(uint256 _MAX_FREE_MINT) external onlyOwner{
        MAX_FREE_MINT = _MAX_FREE_MINT;
    }
    
    function setMaxPublicMintAmount(uint256 _MAX_PUBLIC_MINT) external onlyOwner{
        MAX_PUBLIC_MINT = _MAX_PUBLIC_MINT;
    }

    function togglePause() external onlyOwner{
        pause = !pause;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function toggleFreeMintSale() external onlyOwner{
        freeMintSale = !freeMintSale;
    }

    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed; 
    }

    function withdraw() public payable onlyOwner {
    // This will payout the owner 100% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}