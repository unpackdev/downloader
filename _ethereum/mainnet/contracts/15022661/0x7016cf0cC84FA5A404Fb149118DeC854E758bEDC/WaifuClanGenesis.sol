//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./ERC2981.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

contract WaifuClanGenesis is ERC721A, ERC2981, Ownable, Pausable {
    using Strings for uint256;
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant FREE_MINT_LIMIT = 2;

    mapping(address => uint256) public freeMintedCount;
    string public baseUri;
    string public oddBaseUri;
    string public evenBaseUri;

    address private _treasuryAccount = 0x6f51f5715f72E9c2200Ec6A6fe9942023fBE7BC3;
    bool public revealState;
    bool public canUserMint;
    constructor() ERC721A("WaifuClan Genesis", "WCG"){
        _setDefaultRoyalty(_treasuryAccount, 1000);
        baseUri = "https://ipfs.io/ipfs/QmUewiSqpiDFqKimcLYmM3yXPJLoAKdvtHRpuCS3pnvgCE/"; // latest uri
        oddBaseUri = "https://ipfs.io/ipfs/QmcW3bW4Le8sWkEgHLxXvcQxFu2nf85nT4MQonZVroupit/";
        evenBaseUri = "https://ipfs.io/ipfs/QmfCTZ5MkFLg264ZuVfYX662TaAPkctujsZa4paoUCrbF4/";
        _pause();
    }

    modifier onlyPossibleMint(uint256 quantity) {
        require(quantity > 0, "Invalid amount");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceed amount");
        require(freeMintedCount[msg.sender] + quantity <= FREE_MINT_LIMIT, "Already Minted");
        require(canUserMint, "You can't mint now");
        _;
    }

    modifier onlyPossibleReveal() {
        require(!revealState, "You have already revealed");
        _;
    }

    modifier onlyPossibleAirdrop(address user, uint256 quantity) {
        require(canUserMint, "Can't airdrop for user now");
        require(freeMintedCount[user] + quantity <= FREE_MINT_LIMIT && quantity > 0, "Can't airdrop for user");
        _;
    }

    function changeMintingStatus() external onlyOwner {
        bool _canUserMint = canUserMint;
        _canUserMint ? _pause() : _unpause();
        canUserMint = !_canUserMint;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function getNextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }

    function mint(uint256 quantity) external onlyPossibleMint(quantity) {
        _mint(msg.sender, quantity);
        freeMintedCount[msg.sender] += quantity;
    }

    function mintForAdmin(uint256 quantity) external onlyOwner{
        require(canUserMint, "Should change Mint status");
        _mint(msg.sender, quantity);
        freeMintedCount[msg.sender] += quantity;
    }

    function mintFor(address user, uint256 quantity) external onlyOwner onlyPossibleAirdrop(user, quantity) {
        _mint(user, quantity);
        freeMintedCount[user] += quantity;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function setEvenBaseUri(string memory _baseUri) external onlyOwner {
        evenBaseUri = _baseUri;
    }

    function setOddBaseUri(string memory _baseUri) external onlyOwner {
        oddBaseUri = _baseUri;
    }

    function reveal() external onlyOwner onlyPossibleReveal {
        revealState = true;
    }

    function setRoyaltiesWalletAddress(address _royaltyWallet) external onlyOwner {
        _setDefaultRoyalty(_royaltyWallet, 1000);
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        require(_exists(tokenId), "Token Does Not Exist");
        string memory _tokenUri = tokenId % 2 == 0 ? evenBaseUri : oddBaseUri;
        return revealState ? _tokenUri : baseUri;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
