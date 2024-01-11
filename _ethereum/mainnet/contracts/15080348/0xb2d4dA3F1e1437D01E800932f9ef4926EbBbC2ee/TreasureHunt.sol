//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./ERC721URIStorage.sol";

contract TreasureHunt is ERC721, ERC721URIStorage, EIP712, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    string public constant SIGNING_DOMAIN = "VerifiedGold";
    string public constant SIGNATURE_VERSION = "1";
    uint256 private _mintingPrice;
    address private _treasureChestWinner;
    bool private _gameStarted;
    string internal _baseUri;
    mapping(address => uint) private levels;
    mapping(uint => uint) private levelItems;

    // Welcome to the Verified Gold treasure hunt. 50% of the mint profits get locked into this contract until
    // someone solves the final puzzle.
    //
    // How To Play:
    // 1) To start playing, mint your level 1 NFT from https://verified.gold
    // 2) The description of the NFT contains a puzzle to solve that will lead you to a free mnt NFT for the next level. (There are 5 levels)
    // 3) If you are the first person to successfully mint an NFT from each level, you win the ETH stored in the contract.  It's automatically transfers to your wallet when you win.
    // 4) If nobody has won the treasure hunt yet, all the verified gold NFT's are untransferrable.
    // 5) When the final puzzle is solved, funds are automatically disbursed to winner's wallet, all minting is stopped, and NFT's become transferrable.
    //
    // There is no way for the owner of this contract to withdraw the funds.  The only way the funds can be released is by solving the final puzzle.
    constructor() 
        ERC721("Verifid Gold", "VGOLD")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        _baseUri = "https://verified.gold/token/";
        _treasureChestWinner = address(0);
        _gameStarted = false;
        _mintingPrice = 0.3 ether;
    }

    // The voucher that is used to mint an NFT for a level looks like this.
    // isTreasureChest: If this is "true", minting it will declare the minter the winner, and disburse funds to their wallet.  It will also end the game and make NFT's transferrable
    // level: This is the ID number for the level
    // signature: This is the secret code that must be found in order to "solve" the previous puzzle.  An incorrect signature is unmintable.
    struct NFTVoucher {
        bool isTreasureChest;
        uint256 level;
        bytes signature;
    }

    // When you solve a puzzle, this will be the function that gets called to either mint the next level, or to claim the prize.
    // The owner of this contract is not allowed to play.
    function mintNFT(NFTVoucher calldata voucher) public payable returns (uint256) {
        address signer = _verify(voucher);
        require(voucher.level == 1 || levels[msg.sender] == voucher.level - 1, "Your last NFT must be the previous level.");
        require(owner() == signer, "This was not signed by a valid signer.");
        require(owner() != msg.sender, "NFT's cannot be minted by the owner.");
        require(_gameStarted == true, "The game has not running.");
        require(_treasureChestWinner == address(0), "The game has already ended");
        require(voucher.level != 1 || msg.value == _mintingPrice, "Incorrect amount of ETH sent");
        
        // keep track of how many players are on each level, and also which level each player is on.
        levelItems[voucher.level] = levelItems[voucher.level] + 1;
        levels[msg.sender] = voucher.level;

        _tokenIds.increment();
        _safeMint(msg.sender, _tokenIds.current());
        _setTokenURI(_tokenIds.current(), string(abi.encodePacked(Strings.toString(voucher.level), "/metadata?id=", string(abi.encodePacked(Strings.toString(_tokenIds.current()))))));
        
        // Leave 50% in the contract for the winner.
        // The additional 50% goes to the contract owner to fund this and future projects.
        payable(owner()).transfer(msg.value / 2);
        
        // transfer contract balance to recipient if this is the treasure chest
        if (voucher.isTreasureChest) {
            _treasureChestWinner = msg.sender;
            payable(msg.sender).transfer(address(this).balance);
        }

        return _tokenIds.current();
    }

    /// NFT's in this collection cannot be traded on the secondary market until the game finishes.
    /// Once the game is done (ie. someone claims the treasure chest), the winnings are sent to the winner,
    /// and all NFT's in this collection become tradable.  Minting new NFT's will end at that moment also.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        require(_treasureChestWinner != address(0) || from == address(0), "Transfers are not allowed until someone has unlocked the treasure chest.");
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    /// Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher to hash.
    function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
        keccak256("NFTVoucher(bool isTreasureChest,uint256 level)"),
        voucher.isTreasureChest,
        voucher.level
        )));
    }

    /// Verifies the signature for a given NFTVoucher, returning the address of the signer.
    /// Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An NFTVoucher describing an unminted NFT.
    function _verify(NFTVoucher calldata voucher) internal view returns (address) {
        return ECDSA.recover(_hash(voucher), voucher.signature);
    }

    /// Returns the chain id of the current blockchain.
    /// This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
    /// the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /// Functions to read smart contract state.
    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    function gameStarted() external view returns (bool) {
        return _gameStarted;
    }

    function mintPrice() external view returns (uint256) {
        return _mintingPrice;
    }

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function getLevelItems(uint level) external view returns (uint) {
        return levelItems[level];
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// Functions to set smart contract state.
    function setMintPrice(uint256 mintingPriceToSet) external onlyOwner {
        _mintingPrice = mintingPriceToSet;
    }

    function setTokenURI(uint256 tokenId, string memory uri) external onlyOwner {
        require(tokenId > 0, "TokenID must be greater than 0");
        require(tokenId < _tokenIds.current(), "Invalid TokenID");
        _setTokenURI(tokenId, uri);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseUri = baseURI;
    }

    function setGameStarted(bool started) external onlyOwner {
        require(_treasureChestWinner == address(0), "The game has already ended.");
        _gameStarted = started;
    }

    // The following functions are overrides required by Solidity.
    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }
}
