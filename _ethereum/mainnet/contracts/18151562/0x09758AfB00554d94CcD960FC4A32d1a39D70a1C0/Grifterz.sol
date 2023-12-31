// SPDX-License-Identifier: MIT

//    $$$$$$\  $$$$$$$\  $$$$$$\ $$$$$$$$\ $$$$$$$$\ $$$$$$$$\ $$$$$$$\   $$$$$$\  
//   $$  __$$\ $$  __$$\ \_$$  _|$$  _____|\__$$  __|$$  _____|$$  __$$\ $$  __$$\ 
//   $$ /  \__|$$ |  $$ |  $$ |  $$ |         $$ |   $$ |      $$ |  $$ |$$ /  \__|
//   $$ |$$$$\ $$$$$$$  |  $$ |  $$$$$\       $$ |   $$$$$\    $$$$$$$  |\$$$$$$\  
//   $$ |\_$$ |$$  __$$<   $$ |  $$  __|      $$ |   $$  __|   $$  __$$<  \____$$\ 
//   $$ |  $$ |$$ |  $$ |  $$ |  $$ |         $$ |   $$ |      $$ |  $$ |$$\   $$ |
//   \$$$$$$  |$$ |  $$ |$$$$$$\ $$ |         $$ |   $$$$$$$$\ $$ |  $$ |\$$$$$$  |
//    \______/ \__|  \__|\______|\__|         \__|   \________|\__|  \__| \______/                                                                                                                


pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./DefaultOperatorFilterer.sol";
import "./ERC2981.sol";

contract Grifterz is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer,
    ERC2981
{
    string public baseURI;
    string public notRevealedUri;
    uint256 public cost = 0.0059 ether;
    uint256 public wlcost = 0.0059 ether;
    uint256 public maxSupply = 5000;
    uint256 public WlSupply = 5000;
    uint256 public MaxperWallet = 10;
    uint256 public MaxperWalletWl = 5;
    uint256 private rakePercentage = 20;
    bool public paused = false;
    bool public revealed = false;
    bool public preSale = true;
    bytes32 public merkleRoot =
        0x52f942a0f56e29382309e9af0ad49f70bc89a060bb6f2e49a00e5a7564bb3e20;
    bytes32 public RefRoot =
        0xe72386fa0da46bb5bb4ebf0fa588a2c784b4d8a516780d0a673853c176c94557;
    mapping(address => uint256) public PublicMintofUser;
    mapping(address => uint256) public WhitelistedMintofUser;

    struct Referrer {
        uint256 totaluser;
        uint256 totalminted;
        uint256 totalamount;
    }

    mapping(address => Referrer) public UserRefs;

    constructor() ERC721A("Grifterz", "GRIFTERZ") {}

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @dev Public mint
    function mint(uint256 tokens) public payable nonReentrant {
        require(!paused, "GRIFTERZ: Sale is paused");
        require(!preSale, "GRIFTERZ: Public Sale Hasn't started yet");
        require(
            tokens <= MaxperWallet,
            "GRIFTERZ: max mint amount per tx exceeded"
        );
        require(totalSupply() + tokens <= maxSupply, "GRIFTERZ: Soldout");
        require(
            PublicMintofUser[_msgSenderERC721A()] + tokens <= MaxperWallet,
            "GRIFTERZ: Max NFT Per Wallet exceeded"
        );
        require(msg.value >= cost * tokens, "GRIFTERZ: insufficient funds");

        PublicMintofUser[_msgSenderERC721A()] += tokens;
        _safeMint(_msgSenderERC721A(), tokens);
    }

    /// @dev presale mint for whitelisted users
    function presalemint(uint256 tokens, bytes32[] calldata merkleProof)
        public
        payable
        nonReentrant
    {
        require(!paused, "GRIFTERZ: Sale is paused");
        require(preSale, "GRIFTERZ: Presale Hasn't started yet");
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "GRIFTERZ: You are not Whitelisted"
        );
        require(
            WhitelistedMintofUser[_msgSenderERC721A()] + tokens <=
                MaxperWalletWl,
            "GRIFTERZ: Max NFT Per Wallet exceeded"
        );
        require(tokens <= MaxperWalletWl, "GRIFTERZ: max mint per Tx exceeded");
        require(
            totalSupply() + tokens <= WlSupply,
            "GRIFTERZ: Whitelist MaxSupply exceeded"
        );
        require(msg.value >= wlcost * tokens, "GRIFTERZ: insufficient funds");

        WhitelistedMintofUser[_msgSenderERC721A()] += tokens;
        _safeMint(_msgSenderERC721A(), tokens);
    }

    /// @dev presale mint for users with referrer code
    function referrermint(
        uint256 tokens,
        bytes32[] calldata merkleProof,
        bytes32[] calldata RefProof,
        address _ref,
        string calldata refcode
    ) public payable nonReentrant {
        Referrer storage refs = UserRefs[_ref];
        require(!paused, "GRIFTERZ: Sale is paused");
        require(preSale, "GRIFTERZ: Presale Hasn't started yet");
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(_ref))
            ),
            "GRIFTERZ: Wrong Referrer Address"
        );
        require(
            MerkleProof.verify(
                RefProof,
                RefRoot,
                keccak256(abi.encodePacked(refcode))
            ),
            "GRIFTERZ: Wrong Referrer Code"
        );
        require(
            WhitelistedMintofUser[_msgSenderERC721A()] + tokens <=
                MaxperWalletWl,
            "GRIFTERZ: Max NFT Per Wallet exceeded"
        );
        require(tokens <= MaxperWalletWl, "GRIFTERZ: max mint per Tx exceeded");
        require(
            totalSupply() + tokens <= WlSupply,
            "GRIFTERZ: Whitelist MaxSupply exceeded"
        );
        require(msg.value >= wlcost * tokens, "GRIFTERZ: insufficient funds");

        refs.totalminted += tokens;
        refs.totaluser += 1;
        refs.totalamount += (msg.value * rakePercentage) / 100;
        WhitelistedMintofUser[_msgSenderERC721A()] += tokens;
        _safeMint(_msgSenderERC721A(), tokens);
    }

    /// @dev use it for giveaway and team mint
    function airdrop(uint256 _mintAmount, address[] calldata destination)
        public
        onlyOwner
        nonReentrant
    {
        uint256 totalnft = _mintAmount * destination.length;
        require(
            totalSupply() + totalnft <= maxSupply,
            "max NFT limit exceeded"
        );
        for (uint256 i = 0; i < destination.length; i++) {
            _safeMint(destination[i], _mintAmount);
        }
    }

    /// @notice returns metadata link of tokenid
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721AMetadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    /// @notice return the total number minted by an address
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /// @notice return all tokens owned by an address
    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != tokenIdsLength;
                ++i
            ) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    /// @dev to reveal collection, true for reveal
    function reveal(bool _state) public onlyOwner {
        revealed = _state;
    }

    /// @dev change the merkle root for the whitelist phase
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /// @dev change the merkle root for the referrer mint
    function setRefRoot(bytes32 _merkleRoot) external onlyOwner {
        RefRoot = _merkleRoot;
    }

    /// @dev change the public max per wallet
    function setMaxPerWallet(uint256 _limit) public onlyOwner {
        MaxperWallet = _limit;
    }

    /// @dev change the whitelist max per wallet
    function setWlMaxPerWallet(uint256 _limit) public onlyOwner {
        MaxperWalletWl = _limit;
    }

    /// @dev change the public price(amount need to be in wei)
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    /// @dev change the whitelist price(amount need to be in wei)
    function setWlCost(uint256 _newWlCost) public onlyOwner {
        wlcost = _newWlCost;
    }

    /// @dev cut the supply if we dont sold out
    function setMaxsupply(uint256 _newsupply) public onlyOwner {
        maxSupply = _newsupply;
    }

    /// @dev cut the whitelist supply if we dont sold out
    function setwlsupply(uint256 _newsupply) public onlyOwner {
        WlSupply = _newsupply;
    }

    /// @dev set your baseuri
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /// @dev set hidden uri
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    /// @dev to pause and unpause your contract(use booleans true or false)
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    /// @dev activate whitelist sale(use booleans true or false)
    function togglepreSale(bool _state) external onlyOwner {
        preSale = _state;
    }

     /// @dev change ref %
    function setRakePercentage(uint256 _new) public onlyOwner {
        rakePercentage = _new;
    }

    /// @dev withdraw referrer rewards
    function claimRakReward(bytes32[] calldata merkleProof)
        public
        nonReentrant
    {
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "GRIFTERZ: You are not Allowed"
        );
        Referrer storage refs = UserRefs[_msgSenderERC721A()];
        uint256 balance = refs.totalamount;
        require(balance > 0, "GRIFTERZ: You dont have any reward to claim");
        require(
            address(this).balance >= balance,
            "GRIFTERZ: there is no funds remains to claim, check back later"
        );
        payable(_msgSenderERC721A()).transfer(balance);
        refs.totalamount = 0;
    }

    /// @dev withdraw funds from contract
    function withdraw() public payable onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(_msgSenderERC721A()).transfer(balance);
    }

    // ERC2981 functions
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /// @dev set royalty %, eg. 500 = 5%
    function setRoyaltyInfo(address _receiver, uint96 _feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function deleteRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /// Opensea Royalties

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
