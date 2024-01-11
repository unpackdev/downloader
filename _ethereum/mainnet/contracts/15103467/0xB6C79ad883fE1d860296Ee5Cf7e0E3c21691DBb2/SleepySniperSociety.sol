//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract SleepySniperSociety is Ownable, ERC721A {
    /// @notice baseURI, usually represents ipfs gateway link
    string _baseURIVal;
    string constant _prerevealUri = "https://gateway.pinata.cloud/ipfs/QmWVBkMEo9FoR5T9Bvc8BXB78MPsaA1KnuRHcdrdrmdc9n";
    bool _revealed = false;
    bytes32 _allowListMerkleRoot;
    mapping(address => uint) _allowListMinted;


    enum CurrentSalePhase { NotStarted, Phase1_AllowList2, Phase2_AllowList3, PublicSale, Paused, Stopped } // allowlist 2 tokens, allowlist 3 tokens, public sale
    CurrentSalePhase public currentPhase = CurrentSalePhase.NotStarted;

    uint public constant AllowListMaxMintsFirstPhase = 2;
    uint public constant AllowListMaxMintsSecondPhase = 3;

    uint public constant AllowListPrice = 90000000000000000; // 0.09eth in wei
    uint public publicSalePrice = 120000000000000000; // 0.12eth in wei

    uint public constant TotalSupplyCap = 5000;

    constructor(string memory name, string memory symbol, bytes32 whiteListMerkleRoot, uint premintTokensNumber, address premintAddress) ERC721A(name, symbol){
        _allowListMerkleRoot = whiteListMerkleRoot;
        _safeMint(premintAddress, premintTokensNumber);
    }

    /// @notice sets current phase of sale (for now for simplicity and debugging)
    /// @param phase CurrentSalePhase  - current phase of sale
    function setCurrentPhase(CurrentSalePhase phase) external onlyOwner {
        require(!_revealed, "Can't change phase after reveal");
        currentPhase = phase;
    }

    /// @notice Sets allow list merkle root
    /// @param merkleRoot byte32
    function setAllowListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        require(currentPhase == CurrentSalePhase.NotStarted, "Can't change allowList on this phase");
        _allowListMerkleRoot = merkleRoot;
    }

    /// @notice Sets publicSalePrice
    /// @param publicSalePriceParam uint of new public sale price
    function setPublicSalePrice(uint publicSalePriceParam) external onlyOwner {
        publicSalePrice = publicSalePriceParam;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIVal;
    }

    function baseURI() external view virtual returns (string memory) {
        return _baseURI();
    }

    /// @notice Reveal
    /// @param URI String of new baseURI
    function reveal(string calldata URI) external onlyOwner {
        require(!_revealed, "Can't reveal after reveal");
        _revealed = true;
        _baseURIVal = URI;
        currentPhase = CurrentSalePhase.Stopped;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if(_revealed) {
            return super.tokenURI(tokenId);
        } else {
            return _prerevealUri;
        }
    }

    function _allowListTotalTokenAllowed() view internal returns (uint) {
        require(currentPhase == CurrentSalePhase.Phase1_AllowList2 || currentPhase == CurrentSalePhase.Phase2_AllowList3,  "AllowList mint are not allowed on this phase");
        if(currentPhase == CurrentSalePhase.Phase1_AllowList2) {
            return AllowListMaxMintsFirstPhase;
        } else {
            return AllowListMaxMintsSecondPhase;
        }
    }

    function mintAllowlist(uint numberTokensToMint, bytes32[] calldata merkleProof) external payable{
        require(currentPhase == CurrentSalePhase.Phase1_AllowList2 || currentPhase == CurrentSalePhase.Phase2_AllowList3,  "AllowList mint are not allowed on this phase");
        require(msg.value >= numberTokensToMint*AllowListPrice, "Insufficient funds provided");
        require(totalSupply() + numberTokensToMint < TotalSupplyCap, "maximum number of tokens to mint is reached");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, _allowListMerkleRoot, leaf), "invalid allowlist proof");

        require(_allowListMinted[msg.sender] + numberTokensToMint <= _allowListTotalTokenAllowed(), "Too many tokens required to be minted");

        _safeMint(msg.sender, numberTokensToMint);

        _allowListMinted[msg.sender] = _allowListMinted[msg.sender] + numberTokensToMint; // yep safemath is preferable here but we operate with 2-3 tokens so hopely don't need
    }

    function mint(uint numberTokensToMint) external payable {
        require(currentPhase == CurrentSalePhase.PublicSale,  "public mint is not allowed on this phase");
        require(msg.value >= numberTokensToMint*publicSalePrice, "Insufficient funds provided");

        require(totalSupply() + numberTokensToMint < TotalSupplyCap, "maximum number of tokens to mint is reached");

        _safeMint(msg.sender, numberTokensToMint);
    }

    function getCurrentBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawMoneyTo(address payable _to, uint amount) public  onlyOwner {
        require(amount <= getCurrentBalance(), "insufficient funds to withdraw");
        _to.transfer(amount);
    }

}
