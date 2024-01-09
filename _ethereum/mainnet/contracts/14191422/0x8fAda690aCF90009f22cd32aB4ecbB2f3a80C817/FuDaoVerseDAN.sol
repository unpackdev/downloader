// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./console.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ECDSA.sol";

contract FuDaoVerseDAN is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    //NFT params
    string public baseURI;
    bool public revealed;
    string public notRevealedUri;
    IERC721 public OG;

    //sale stages:
    //stage 0: init(no minting)
    //stage 1: free-mint
    //stage 2: pre-sale, OGs are included in here
    //stage 2.5: whitelisted can mint an extra 2, increase presaleMintMax to 4
    //stage 3: public sale
    Counters.Counter public tokenSupply;
    uint8 public stage = 0;

    mapping(uint256 => bool) public isOGMinted;
    mapping(uint256 => uint8) public OGWhitelistMintCount;

    uint256 public VIP_PASSES = 888;
    uint256 public presaleSalePrice = 0.077 ether;
    uint256 public presaleSupply = 6666;
    uint256 public presaleMintMax = 2;
    mapping(address => uint8) public presaleMintCount;
    mapping(address => uint8) public vipMintCount; // For Whitelist Sale
    mapping(address => uint256) public publicMintCount;

    //public sale (stage=3)
    uint256 public publicSalePrice = 0.088 ether;
    uint256 public publicMintMax = 2;
    uint256 public totalSaleSupply = 8888;

    //others
    bool public paused = false;

    //sale holders
    address[2] public fundRecipients = [
        0xaDDfdc72494E29A131B1d4d6668184840f1Fc30C,
        0xcD7BCAc7Ee5c18d8cC1374B62F09cf67e6432a08
    ];

    uint256[] public receivePercentagePt = [7000]; //distribution in basis points

    // Off-chain whitelist
    address private signerAddress;
    mapping(bytes => bool) private _nonceUsed;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address _newOwner,
        address _signerAddress,
        address ogCollection
    ) ERC721(_name, _symbol) {
        setNotRevealedURI(_initBaseURI);
        signerAddress = _signerAddress;
        transferOwnership(_newOwner);

        OG = IERC721(ogCollection);
    }

    event VIPMint(address indexed to, uint256 tokenId);
    event WhitelistMint(address indexed to, uint256 tokenId);
    event PublicMint(address indexed to, uint256 mintAmount);
    event DevMint(uint256 count);
    event Airdrop(address indexed to, uint256 tokenId);

    /**
     * @notice Performs respective minting condition checks depending on stage of minting
     * @param tokenIds tokenIds of VIP Pass
     * @dev Stage 1: OG Mints, Free Claim for OG Pass Holders
     * @dev Each Pass can only be used once to claim
     * @dev Minter must be owner of OG pass to claim
     */
    function vipMint(uint256[] memory tokenIds) public {
        require(!paused, "FuDaoVerseDAN: Contract is paused");
        require(stage > 0, "FuDaoVerseDAN: Minting has not started");
        for (uint256 i; i < tokenIds.length; i++) {
            require(
                OG.ownerOf(tokenIds[i]) == msg.sender,
                "FuDaoVerseDAN: Claimant is not the owner!"
            );
            require(
                !isOGMinted[tokenIds[i]],
                "FuDaoVerseDAN: OG Token has already been used!"
            );
            _vipMint(tokenIds[i]);
        }
    }

    function _vipMint(uint256 tokenId) internal {
        tokenSupply.increment();
        _safeMint(msg.sender, tokenSupply.current());
        isOGMinted[tokenId] = true;
        VIP_PASSES--;

        emit VIPMint(msg.sender, tokenSupply.current());
    }

    /**
     * @notice VIP Whitelist Mint. VIPs are automatically whitelisted and can use their Mint pass to mint
     * @param _mintAmount Amount minted for vipWhitelistMint
     * @dev Stage 2: Presale Mints, VIP Automatically whitelisted
     * @dev 2 VIP Whitelist Mints at stage 2, another 2 VIP Whitelist Mints at stage 2.5
     * @dev Minter must hold an OG pass to VIP Whitelist Mint
     */
    function vipWhitelistMint(uint8 _mintAmount) public payable {
        require(!paused, "FuDaoVerseDAN: Contract is paused");
        require(stage == 2, "FuDaoVerseDAN: Private Sale Closed!");

        require(
            msg.value == _mintAmount * presaleSalePrice,
            "FuDaoVerseDAN: Insufficient ETH!"
        );

        require(
            tokenSupply.current() + _mintAmount <= presaleSupply,
            "FuDaoVerseDAN: Max Supply for Presale Mint Reached!"
        );

        require(
            OG.balanceOf(msg.sender) > 0,
            "FuDaoVerseDAN: Claimant does not own a mint pass"
        );

        require(
            presaleMintCount[msg.sender] + _mintAmount <= presaleMintMax,
            "FuDaoVerseDAN: Claimant has exceeded VIP Whitelist Mint Max!"
        );
        presaleMintCount[msg.sender] += _mintAmount;

        for (uint8 i; i < _mintAmount; i++) {
            _vipWhitelistMint();
        }
    }

    function _vipWhitelistMint() internal {
        tokenSupply.increment();
        _safeMint(msg.sender, tokenSupply.current());

        emit VIPMint(msg.sender, tokenSupply.current());
    }

    /**
     * @notice Performs respective minting condition checks depending on stage of minting
     * @param _mintAmount Amount that is minted
     * @param nonce Random bytes32 nonce
     * @param signature Signature generated off-chain
     * @dev Stage 1: OG Mints, Free Claim for OG Pass Holders
     * @dev Each Pass can only be used once to claim
     */
    function whitelistMint(
        uint8 _mintAmount,
        bytes memory signature,
        bytes memory nonce
    ) public payable {
        require(!paused, "FuDaoVerseDAN: Contract is paused");
        require(stage == 2, "FuDaoVerseDAN: Private Sale Closed!");

        require(!_nonceUsed[nonce], "FuDaoVerseDAN: Nonce already used");
        _nonceUsed[nonce] = true;

        require(
            whitelistSigned(msg.sender, nonce, signature),
            "FuDaoVerseDAN: Invalid signature!"
        );

        require(
            tokenSupply.current() + _mintAmount <= presaleSupply,
            "FuDaoVerseDAN: Max Supply for Presale Mint Reached!"
        );

        require(
            msg.value == _mintAmount * presaleSalePrice,
            "FuDaoVerseDAN: Insufficient ETH!"
        );

        require(
            presaleMintCount[msg.sender] + _mintAmount <= presaleMintMax,
            "FuDaoVerseDAN: Wallet has already minted Max Amount for Presale!"
        );

        presaleMintCount[msg.sender] += _mintAmount;

        for (uint256 i; i < _mintAmount; i++) {
            tokenSupply.increment();
            _safeMint(msg.sender, tokenSupply.current());
            emit WhitelistMint(msg.sender, tokenSupply.current());
        }
    }

    /**
     * @notice Public Mint
     * @param _mintAmount Amount that is minted
     * @dev Stage 3: Public Mint
     */
    function publicMint(uint8 _mintAmount) public payable {
        require(!paused, "FuDaoVerseDAN: Contract is paused");
        require(stage == 3, "FuDaoVerseDAN: Public Sale Closed!");

        require(
            msg.value == _mintAmount * publicSalePrice,
            "FuDaoVerseDAN: Insufficient ETH!"
        );

        require(
            tokenSupply.current() + _mintAmount <= totalSaleSupply - VIP_PASSES,
            "FuDaoVerseDAN: Max Supply for Public Mint Reached!"
        );

        require(
            publicMintCount[msg.sender] + _mintAmount <= publicMintMax,
            "FuDaoVerseDAN: Wallet has already minted Max Amount for Public!"
        );

        publicMintCount[msg.sender] += _mintAmount; // FIX: Gas Optimization

        for (uint256 i; i < _mintAmount; i++) {
            tokenSupply.increment();
            _safeMint(msg.sender, tokenSupply.current());
            emit PublicMint(msg.sender, tokenSupply.current());
        }
    }

    /**
     * @dev Mints NFTS to the owner's wallet
     * @param _mintAmount Amount to mint
     */
    function devMint(uint8 _mintAmount) public onlyOwner {
        require(
            tokenSupply.current() + _mintAmount <= totalSaleSupply,
            "FuDaoVerseDAN: Max Supply Reached!"
        );

        for (uint256 i; i < _mintAmount; i++) {
            tokenSupply.increment();
            _safeMint(msg.sender, tokenSupply.current());
        }
        emit DevMint(_mintAmount);
    }

    /**
     * @dev Airdrops NFTs to the list of addresses provided
     * @param addresses List of airdrop recepients
     */
    function airdrop(address[] memory addresses) public onlyOwner {
        require(
            tokenSupply.current() + addresses.length <= totalSaleSupply,
            "FuDaoVerseDAN: Max Supply Reached!"
        );

        for (uint256 i; i < addresses.length; i++) {
            tokenSupply.increment();
            _safeMint(addresses[i], tokenSupply.current());
            emit Airdrop(addresses[i], tokenSupply.current());
        }
    }

    /**
     * @dev Checks if the the signature is signed by a valid signer for whitelists
     * @param sender Address of minter
     * @param nonce Random bytes32 nonce
     * @param signature Signature generated off-chain
     */
    function whitelistSigned(
        address sender,
        bytes memory nonce,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, nonce));
        return signerAddress == hash.recover(signature);
    }

    // ------------------------- VIEW FUNCTIONS -----------------------------

    /**
     * @notice Returns metadata URI for sepecified token id
     * @param tokenId Token Id to retrieve metadata
     * @return Metadata URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
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
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    /**
     * @notice Total NFTs Minted
     */
    function totalSupply() public view returns (uint256) {
        return tokenSupply.current();
    }

    // ------------------------- ADMIN FUNCTIONS -----------------------------

    /**
     * @dev Set Mint Stage
     */
    function setStage(uint8 _stage) public onlyOwner {
        require(stage < 4, "FuDaoVerseDAN: Exceeded maximum number of stages");
        stage = _stage;
    }

    /**
     * @dev Set Revealed Metadata URI
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require(!revealed);
        baseURI = _newBaseURI;
    }

    /**
     * @dev Set Presale maximum amount of mints
     */
    function setPresaleMintMax(uint256 amount) public onlyOwner {
        presaleMintMax = amount;
    }

    /**
     * @dev Set the unrevealed URI
     * @param _notRevealedURI unrevealed URI for metadata
     */
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    /**
     * @dev Set Revealed state of NFT metadata
     */
    function reveal() public onlyOwner {
        revealed = true;
    }

    /**
     * @dev Switches pause state to `_state`
     * @param _state Pause State
     */
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    /**
     * @dev Emergency Function to withdraw any ETH deposited to this contract
     */
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    /**
     * @dev requires currentBalance of contract to have some amount
     * @dev withdraws with the fixed define distribution
     */
    function withdrawFund() public onlyOwner {
        uint256 currentBal = address(this).balance;
        require(currentBal > 0);
        for (uint256 i = 0; i < fundRecipients.length - 1; i++) {
            _withdraw(
                fundRecipients[i],
                (currentBal * receivePercentagePt[i]) / 10000
            );
        }
        //final address receives remainder to prevent ether dust
        _withdraw(
            fundRecipients[fundRecipients.length - 1],
            address(this).balance
        );
    }

    /**
     * @dev private function utilized by withdrawFund
     * @param _addr Address of receiver
     * @param _amt Amount to withdraw
     */
    function _withdraw(address _addr, uint256 _amt) private {
        (bool success, ) = _addr.call{value: _amt}("");
        require(success, "Transfer failed");
    }

    /**
     * @dev retrieve base URI internally
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
