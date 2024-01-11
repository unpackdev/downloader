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
    
    string public constant SIGNING_DOMAIN = "TreasureHunt";
    string public constant SIGNATURE_VERSION = "1";
    uint256 private _mintingPrice;
    uint256 private _endTime;
    uint256 private _highestLevel;
    uint256 private _totalPrize;
    address private _treasureChestWinner;
    bool private _gameStarted;
    string internal _baseUri;
    mapping(address => bool) private _signers;
    mapping(address => bool) private _payments;
    mapping(address => uint) private _levels;
    mapping(uint => uint) private _levelItems;
    
    // Welcome to the Treasure Hunt. 50% of the mint ETH get locked into this contract until someone solves the final puzzle.
    //
    // How To Play:
    // 1) To start playing, mint your first puzzle NFT from https://treasurehunt.ooo
    // 2) The description of the NFT contains a puzzle to solve that will lead you to a free mint NFT for the next puzzle.  (5 in total)
    // 3) If you are the first person to solve the final puzzle, you win the ETH stored in the contract.
    //    When you solve the final puzzle, the ETH is automatically transferred to your wallet, and you will own the 1 of 1 Final Treasure Hunt NFT.
    // 4) All the puzzle NFT's are untransferrable until someone solves the final puzzle, or until the game period ends.  Check endTime() to see when the game forcefully ends.
    // 5) If the final puzzle is solved, all the NFT's immediately become transferrable, and can be bought and sold on the secondary market.
    // 6) If nobody solves the final puzzle by endTime(), the claimPrize() function can be activated by players at the highest level to claim their equal portion of the prize.
    //
    // There is no way for the owner of this contract to withdraw funds.  The only way all the funds can be released is by solving the final puzzle before endTime().
    constructor() 
        ERC721("Treasure Hunt", "TREASUREHUNT")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        _baseUri = "ipfs://";
        _treasureChestWinner = address(0);
        _gameStarted = false;
        _mintingPrice = 0.3 ether;
        _highestLevel = 0;
        _totalPrize = 0;
    }

    // The voucher that is used to mint an NFT for a level looks like this.
    // uri: This should be an IPFS CID
    // isTreasureChest: If this is "true", minting it will declare the minter the winner, and disburse funds to their wallet.  It will also end the game and make NFT's transferrable
    // level: This is the ID number for the level
    // signature: This is the secret code that must be found in order to "solve" the previous puzzle.  An incorrect signature is unmintable.
    struct NFTVoucher {
        string uri;
        bool isTreasureChest;
        uint256 level;
        bytes signature;
    }

    modifier whenRunning() {
        require(_gameStarted == true, "The game is not running");
        require(_treasureChestWinner == address(0), "Someone has already claimed the prize");
        require(_endTime > block.timestamp, "The game has ended.");
        _;
    }

    modifier whenEnded() {
        require(_treasureChestWinner != address(0) || _endTime <= block.timestamp, "The game has not ended yet.");
        _;
    }

    // When you solve a puzzle, this will be the function that gets called to either mint the next level, or to claim the prize.
    // The owner of this contract is not allowed to play.  For level 1, the contract requires payment equal to the mintPrice()
    // For all other levels, it's a free mint that doesn't need any payment -- gas fees still apply.
    function mint(NFTVoucher calldata voucher) public payable whenRunning returns (uint256) {
        address signer = _verify(voucher);
        require(voucher.level == 1 || _levels[msg.sender] == voucher.level - 1, "Your last NFT must be the previous level.");
        require(_signers[signer], "This was not signed by a valid signer.");
        require(owner() != msg.sender, "NFT's cannot be minted by the owner.");
        require(_signers[msg.sender] != true, "NFT's cannot be minted by a signer.");
        require(voucher.level != 1 || msg.value == _mintingPrice, "Incorrect amount of ETH sent");
        
        // keep track of how many players are on each level, and also which level each player is on.
        _levelItems[voucher.level] = _levelItems[voucher.level] + 1;
        _levels[msg.sender] = voucher.level;

        // keep track of the highest minted level so that players can claimPrize() if the game finishes without someone solving final puzzle
        if (_highestLevel < voucher.level) {
            _highestLevel = voucher.level;
        }

        _tokenIds.increment();
        _safeMint(msg.sender, _tokenIds.current());
        _setTokenURI(_tokenIds.current(), string(abi.encodePacked(voucher.uri, "/metadata.json?id=", string(abi.encodePacked(Strings.toString(_tokenIds.current()))))));
        
        // Leave 50% in the contract for the winner.
        // The additional 50% goes to the contract owner to fund this and future projects.
        _totalPrize += msg.value / 2;
        payable(owner()).transfer(msg.value / 2);
        
        // transfer contract balance to recipient if this is the treasure chest
        if (voucher.isTreasureChest) {
            _treasureChestWinner = msg.sender;
            payable(msg.sender).transfer(address(this).balance);
        }

        return _tokenIds.current();
    }

    // If the time runs out, you will can claim your portion of the eth that would have been given to the winner
    // call the claimPrize() function if you are in the highest level group.
    function claimPrize() external payable whenEnded {
        require(_levels[msg.sender] == _highestLevel, "Only players at the highest level qualify for payout.");
        require(_payments[msg.sender] != true, "You have already been paid out.");

        uint256 payout = _totalPrize / _levelItems[_highestLevel];
        
        _payments[msg.sender] = true;
        payable(msg.sender).transfer(payout);
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
        keccak256("NFTVoucher(string uri,bool isTreasureChest,uint256 level)"),
        keccak256(bytes(voucher.uri)),
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

    function endTime() external view returns (uint256) {
        return _endTime;
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
        return _levelItems[level];
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function isSigner(address signer) external view returns (bool) {
        return _signers[signer];
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

    function setSigner(address signer, bool canSign) external onlyOwner {
        _signers[signer] = canSign;
    }

    function setEndTime(uint256 endTimeToSet) external onlyOwner {
        require(endTimeToSet > 0, "Invalid end time.");
        _endTime = endTimeToSet;
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
