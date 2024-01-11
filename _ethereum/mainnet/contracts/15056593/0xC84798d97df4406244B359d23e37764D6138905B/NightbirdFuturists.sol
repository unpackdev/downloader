// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


import "./Ownable.sol";
import "./IERC20.sol";
import "./MerkleProof.sol";

import "./ERC721A.sol";

import "./BaseRoyalties.sol";

contract NightbirdFuturists is ERC721A, Ownable, BaseRoyalties {

    ///@dev merkleRoot for allowlists.
    bytes32 public merkleRoot; 

    ///@dev all comparisons will be strictly less than.
    uint256 constant public MAX_SUPPLY = 5556; //5555
    uint256 constant public  MAX_TOKENS_PER_WALLET = 11; //10
    string public _baseTokenURI;

    //Free Mint Stage
    uint256 constant public MAX_FREE_MINT_SUPPLY = 201; //200
    uint256 constant public FREE_MINT_PRICE = 0 ether;

    //Pre Mint Stage
    uint256 constant public MAX_PRE_MINT_SUPPLY = 801; //800
    uint256 constant public PRE_MINT_PRICE = 0.15 ether;

    //Public Mint
    uint256 constant public PUBLIC_MINT_PRICE = 0.22 ether;
    uint256 constant public MAX_PUBLIC_MINT_SUPPLY_PHASE_1 = 1001; //1000
    uint256 constant public MAX_PUBLIC_MINT_SUPPLY_PHASE_2 = 1001; //1000
    uint256 constant public MAX_PUBLIC_MINT_SUPPLY_PHASE_3 = 1001; //1000

    //Reserved Mints
    uint256 constant public MAX_RESERVED_MINTS = 1501; //1500
    uint256 reservedTokensMinted;

    //Boolean to control public sale
    bool private publicSaleIsOpen = false;

    
    uint256 public mintingPhase; 
    
    //Mappings to control minting phases
    mapping(uint256 =>uint256) tokensLimitPerPhase;
    mapping(uint256 => uint256) tokensMintedPerPhase; 
    mapping(uint256 => uint256) pricePerMintingPhase; 

    uint256 constant ROYALTIES_POINTS = 500; //5%

    //amount of tokens that each address has executed
    mapping(address => uint256) mintsPerAddress;

    //modifier to ensure that the contract is only called by EOA
    modifier callerIsUser {
        require(tx.origin == msg.sender, "Caller is not a human");
        _;
    }

    event nftMinted(uint256, uint256, address);
    event newPhaseInitiated(uint256);

    constructor (string memory _unrevealedBaseTokenUri) ERC721A("NightBirdFuturists", "NBF"){
        _baseTokenURI = _unrevealedBaseTokenUri;
        setRoyalties(owner(), ROYALTIES_POINTS);
        tokensLimitPerPhase[1] = MAX_FREE_MINT_SUPPLY;
        tokensLimitPerPhase[2] = MAX_PRE_MINT_SUPPLY;
        tokensLimitPerPhase[3] = MAX_PUBLIC_MINT_SUPPLY_PHASE_1;
        tokensLimitPerPhase[4] = MAX_PUBLIC_MINT_SUPPLY_PHASE_2;
        tokensLimitPerPhase[5] = MAX_PUBLIC_MINT_SUPPLY_PHASE_3;
        pricePerMintingPhase[1] = FREE_MINT_PRICE;
        pricePerMintingPhase[2] = PRE_MINT_PRICE;
        pricePerMintingPhase[3] = PUBLIC_MINT_PRICE;
        pricePerMintingPhase[4] = PUBLIC_MINT_PRICE;
        pricePerMintingPhase[5] = PUBLIC_MINT_PRICE;
    }

    ///@dev We override default function from ERC721A which starts in 0, we match it with our starting index.
    function _startTokenId() internal view override returns(uint256){
        return 1;
    }

    function activateNextMintingPhase() external onlyOwner {
        require(mintingPhase < 6, "No more minting Phases");
        mintingPhase += 1;

        emit newPhaseInitiated(mintingPhase);
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function openPublicSale() external onlyOwner {
        require(publicSaleIsOpen == false, 'Sale is already Open!');
        publicSaleIsOpen = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }


    /// @dev changes BaseURI and set it to the true URI for collection
    /// @param revealedTokenURI new token URI. Format required ipfs://CID/
    function reveal(string memory revealedTokenURI) public onlyOwner {
        _baseTokenURI = revealedTokenURI;
    }

    /// @dev reserved NFTs for Team and Keyholders
    /// @param _number number of NFTs to be minted
    /// @param _to address to mint the NFTs to
    function reservedMint(uint256 _number, address _to) external onlyOwner {
        require(reservedTokensMinted + _number < MAX_RESERVED_MINTS, "Not enough Reserved NFTs left");

        _mint(_to, _number);
        unchecked {
            reservedTokensMinted += _number;
        }

        emit nftMinted(_number, totalSupply(), _to);
        
    }

    /// @dev mint @param _number of NFTs in one batch. Used to sell to the public outside allowlist.
    function opensaleMint(uint256 _number) external payable callerIsUser {
        require(publicSaleIsOpen == true, "Public sale is not Open");
        require(totalSupply() + _number < MAX_SUPPLY - MAX_RESERVED_MINTS, "Not enough NFTs left in collection");
        require(mintsPerAddress[msg.sender] + _number < MAX_TOKENS_PER_WALLET, "Cannot mint more than 10 NFTs per wallet");
        require(msg.value == PUBLIC_MINT_PRICE * _number , "Not enough/too much ether sent");
        unchecked{
             mintsPerAddress[msg.sender] += _number;
        }
       
        _mint(msg.sender, _number);

        emit nftMinted(_number, totalSupply(), msg.sender);
    }

    ///@notice main function for minting
    function allowlistMint(uint256 _number, bytes32[] calldata _merkleProof) external payable callerIsUser{
        require(mintingPhase > 0, "Sale not open");
        require(tokensMintedPerPhase[mintingPhase] + _number < tokensLimitPerPhase[mintingPhase], "Not enought NFTS left to mint");
        if(mintingPhase == 1 || mintingPhase == 2){
            require(mintsPerAddress[msg.sender] + _number < 2, "Cannot mint more than 1 NFTs per wallet");
        } else {
            require(mintsPerAddress[msg.sender] + _number < MAX_TOKENS_PER_WALLET, "Cannot mint more than 10 NFTs per wallet");
        }
        
        require(msg.value == pricePerMintingPhase[mintingPhase] * _number, "Not enough/too much ether sent");
        
        //veryfy the provided Merkle Proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Proof");
        
        //Mint
        unchecked{
        mintsPerAddress[msg.sender] += _number;
        tokensMintedPerPhase[mintingPhase] += _number;
            }

        _mint(msg.sender, _number);
        
        emit nftMinted(_number, totalSupply(), msg.sender);
    }

    
    function supportsInterface(bytes4 interfaceId) public view virtual override (BaseRoyalties, ERC721A)
        returns(bool){
            
        bytes4 _ERC165_ = 0x01ffc9a7;
        bytes4 _ERC721_ = 0x80ac58cd;
        bytes4 _ERC2981_ = 0x2a55205a;
        bytes4 _ERC721Metadata_ = 0x5b5e139f;

        return interfaceId == _ERC165_ 
            || interfaceId == _ERC721_
            || interfaceId == _ERC2981_
            || interfaceId == _ERC721Metadata_;
    }

    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        _setRoyalties(recipient, value);
    }

    ///@notice retrieve funds obtained during minting (ETH)
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds left to withdraw");

        (bool sent, ) = payable(owner()).call{value: balance}("");
        require(sent, "Failed to send Ether");

    }

    ///@notice allows to withdraw ERC20 sent to the contract
    function withdrawERC20(IERC20 _erc20Token) external onlyOwner {
        _erc20Token.transfer(owner(), _erc20Token.balanceOf(address(this)));
    }

    /// @dev reverts transaction if someone accidentally send ETH to the contract 
    receive() payable external {
        revert();
    }

}