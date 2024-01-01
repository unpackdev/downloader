// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";

contract  Kryptopoker_S1_PASS is Ownable, ERC721A {
    using Strings for uint256;
    // @notice Merkle root hash for whitelist addresses
    bytes32 public root;

    //State Variables
    /// @notice Is contract paused?
    bool public contractPaused;
    /// @notice Is metadata revealed?
    bool public revealed = false;
    /// @notice notRevealedUri URI of all NFTs on the contract
    string public notRevealedUri;
    /// @notice Base URI of all NFTs on the contract
    string public baseTokenURI;
    /// @notice Price of each public mint
    uint256 public publicPrice;
    /// @notice Price of each NFT
    uint256 public whitelistPrice;
    /// @notice team wallet
    address payable teamWallet;
    /// @notice Is royaltyForwarder receiver wallet
    address payable poolWallet;
    uint256 private teamShare;
    // Add a start time for your contract
    uint256 public startTime;

    // Events
    event Withdraw(uint256 amount, address indexed addr);

    // Constructor
    /// @dev Initializes the contract
    constructor(
        address payable _team,
        address payable _poolwallet,
        uint256 _publicPrice,
        uint256 _whitelistPrice,
        bytes32 _root
    ) ERC721A("kryptopoker S1 PASS", "KPCS1") {
        publicPrice = _publicPrice;
        whitelistPrice = _whitelistPrice;
        baseTokenURI = "";
        notRevealedUri = "ipfs://QmfJ8jMdZnwVnKtz7uSDnkbRmJ79tHdyVnsmWo8dCSuX8J";
        teamWallet = _team;
        poolWallet = _poolwallet;
        teamShare = 10;
        root = _root;
        startTime=  1698789600;
    
    }

    // Modifiers
    /// @notice Modifier to check supply and price
    /// @param _num The number of NFTs to mint
    /// @param _checkPrice True or False to check the price
    /// @param _value Value in ETH passed
    modifier whenNotPausedAndValid(
        uint256 _num,
        bool _checkPrice,
        uint256 _value,
        uint256 _price
    ) {
        require(!contractPaused, "contract Paused");
        if (_checkPrice) {
            require(block.timestamp >= startTime, "Contract is not yet active");
            require(
                _value >= _price * _num,
                "Not enough ETH sent, check price"
            );
        }
        _;
    }

    // External Functtions

    /// @notice Contract owner can NFTs to a specified wallet, non payable.
    /// @param _to Address of wallet to mint the NFT to
    /// @param _num The number of NFTs to mint
    function AdminMint(address _to, uint256 _num)
        external
        onlyOwner
        whenNotPausedAndValid(_num, false, 0, publicPrice)
    {
        _safeMint(_to, _num);
    }

    /// @notice whitelist mint only for allowlist user
    /// @param _to Address of wallet to mint the NFT to
    /// @param _num The number of NFTs to mint
    function whitelistMint(
        address _to,
        uint256 _num,
        bytes32[] calldata _Proof
    )
        external
        payable
        whenNotPausedAndValid(_num, true, msg.value, whitelistPrice)
    {
        require(verifyAddress(_Proof, msg.sender), "You are not in allowlist");
        _afterwhitelistTokenMint(msg.value);
        _safeMint(_to, _num);
    }

    /// @notice publicMint - any user can mint
    /// @param _to Address of wallet to mint the NFT to
    /// @param _num The number of NFTs to mint
    function publicMint(address _to, uint256 _num)
        external
        payable
        whenNotPausedAndValid(_num, true, msg.value, publicPrice)
    {
        _afterpublicTokenMint(msg.value);
        _safeMint(_to, _num);
    }

    // Hook to send payment to team wallet after whitelistMint mint
    function _afterpublicTokenMint(uint256 _value) internal {
        uint256 _teamShare = (_value * teamShare) / 100;
        uint256 poolShare = _value - _teamShare;
        (bool teamTransferSuccess, ) = teamWallet.call{value: _teamShare}("");
        (bool poolTransferSuccess, ) = poolWallet.call{value: poolShare}("");
        require(teamTransferSuccess && poolTransferSuccess, "transfer failed");
    }

    // Hook to send payment to team wallet after public mint
    function _afterwhitelistTokenMint(uint256 _value) internal {
        (bool poolTransferSuccess, ) = poolWallet.call{value: _value}("");
        require(poolTransferSuccess, "transfer failed");
    }

    /// @param _price for publicmint
    function changePublicMintPrice(uint256 _price) external onlyOwner {
        require(_price != 0, "can't be zero amount");
        publicPrice = _price;
    }

    /// @param _price whitelistmint
    function changewhitelistPrice(uint256 _price) external onlyOwner {
        require(_price != 0, "can't be zero amount");
        whitelistPrice = _price;
    }

    function ChangeWhitelistshare(uint256 _new) external onlyOwner {
        require(_new != 0, "can't be zero amount");
        teamShare = _new;
    }

    /// @notice Change the base URI of all NFTs on the contract
    /// @param _baseTokenURI New NFT base URI
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// @notice Allows contract owner to pause the contract
    function pauseContract() external onlyOwner {
        contractPaused = true;
    }

    /// @notice Allows contract owner to unpause the contract
    function unpauseContract() external onlyOwner {
        contractPaused = false;
    }

    /// @notice Allows contract owner to revealed/unrevealed the contract metadata
    function reveal(bool _isRevealed) public onlyOwner {
        revealed = _isRevealed;
    }

    /// @notice Allows contract owner to set new root
    function setRoot(bytes32 _root) public onlyOwner {
        root = _root;
    }

    /// @notice Allows contract owner to set notRevealedUri
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    /// @notice Allows owner to withdraw ETH balance
    function withdraw() external payable onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdraw failed.");

        emit Withdraw(amount, msg.sender);
    }

    /// @notice Change the teamWallet address
    /// @param _newteamWallet New address for teamWallet
    function changeteamWallet(address payable _newteamWallet)
        external
        onlyOwner
    {
        teamWallet = _newteamWallet;
    }

    /// @notice Verify merkle proof of the address
    function verifyAddress(bytes32[] calldata _merkleProof, address account)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(_merkleProof, root, leaf);
    }

    /// @notice Return both price
    function Price() public view returns (uint256 _whitelist, uint256 _public) {
        _whitelist = whitelistPrice;
        _public = publicPrice;
    }

    /// @notice Returns the URI of the NFT
    /// @param _tokenId ID of the NFT
    /// @dev Returns the URI of the token
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealed == false) {
            return notRevealedUri;
        } else {
            string memory currentBaseURI = _baseURI();
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            _tokenId.toString(),
                            ".json"
                        )
                    )
                    : "";
        }
    }

    /// @notice Returns royaltyInfo for NFT marketplace
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        return (teamWallet, calculateRoyalty(_salePrice));
    }

    function calculateRoyalty(uint256 _salePrice)
        public
        pure
        returns (uint256)
    {
        return (_salePrice / 10000) * 500;
    }

    // View Functions

    /// @notice Return the BaseURI of all NFTs on the contract
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @notice Internal function to start ID from 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
