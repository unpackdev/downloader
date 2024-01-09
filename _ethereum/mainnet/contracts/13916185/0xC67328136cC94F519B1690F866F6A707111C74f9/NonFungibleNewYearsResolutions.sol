pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//import "./console.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ECDSA.sol";
import "./Counters.sol";

//import "./Ownable.sol";
//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract NonFungibleNewYearsResolutions is ERC721, Ownable {
    event TransferPaused();
    event TransferUnpaused();
    event MintPaused();
    event MintUnpaused();
    event VerificationPaused();
    event VerificationUnpaused();
    event MaxPerAccountUpdated(uint256 newMaxPerAccount);
    event Verified(
        uint256 tokenId,
        bool completed,
        address owner,
        address partner
    );
    event Unverified(uint256 tokenId, address owner, address partner);
    event RedemptionContractUpdated(address _addr, bool _whitelisted);
    event IpfsSignerUpdated(address _addr, bool _whitelisted);

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bool internal _paused = false;
    bool mintPaused = false;
    bool verificationPaused = false;

    uint256 maxPerAccount = 3;

    string internal _baseURIextended;

    constructor(address owner)
        ERC721("Non-Fungible New Year's Resolutions", "NFNYR")
    {
        setBaseURI("https://ipfs.io/ipfs/");
        _transferOwnership(owner);
    }

    //signers of ipfs hash signatures
    mapping(address => bool) public ipfsSigners;

    //whitelisted recipient addresses to transfer to after challenge ends
    mapping(address => bool) public redemptionContracts;

    //this maps the tokenId to IPFS hash
    mapping(uint256 => string) public tokenIdToIpfsHash;
    //this lets you look up a token by the uri (assuming there is only one of each uri for now)
    mapping(bytes32 => uint256) public uriToTokenId;

    //mapping of accountability partners to list of tokenIds they own
    mapping(address => mapping(uint256 => uint256))
        public tokenIdsByAccountabilityPartner;
    //mapping of tokenIds to the address of the accountability partner
    mapping(uint256 => address) public tokenIdToAccountabilityPartner;
    //mapping of tokenIds to the address of the accountability partner
    mapping(address => uint256) public accountabilityPartnerBalance;

    // ids that have been verified
    mapping(uint256 => bool) public tokenIdVerificationValue;
    // ids that have been verified
    mapping(uint256 => bool) public tokenIdVerificationComplete;

    modifier whenNotPaused() {
        require(!_paused, "Transfers are paused.");
        _;
    }

    /**
     * Pause minting of new tokens
     * @dev owner only
     * @return success - true if successful
     */
    function pause() public onlyOwner returns (bool success) {
        _paused = true;
        emit TransferPaused();
        return true;
    }

    /**
     * Unpause minting of new tokens
     * @dev owner only
     * @return success - true if successful
     */
    function unpause() public onlyOwner returns (bool success) {
        _paused = false;
        emit TransferUnpaused();
        return true;
    }

    /**
     * Pause minting of new tokens
     * @dev owner only
     * @return success - true if successful
     */
    function pauseMint() public onlyOwner returns (bool success) {
        mintPaused = true;
        emit MintPaused();
        return true;
    }

    /**
     * Unpause minting of new tokens
     * @dev owner only
     * @return success - true if successful
     */
    function unpauseMint() public onlyOwner returns (bool success) {
        mintPaused = false;
        emit MintUnpaused();
        return true;
    }

    /**
     * Pause verification of new challenges
     * @dev owner only
     * @return success - true if successful
     */
    function pauseVerification() public onlyOwner returns (bool success) {
        verificationPaused = true;
        emit VerificationPaused();
        return true;
    }

    /**
     * Unpause verification of new challenges
     * @dev owner only
     * @return success - true if successful
     */
    function unpauseVerification() public onlyOwner returns (bool success) {
        verificationPaused = false;
        emit VerificationUnpaused();
        return true;
    }

    /**
     * Set verification of a users challenge
     * @param tokenId - the tokenId of the challenge
     * @param completed - true if the challenge has been verified
     * @return success - true if successful
     */
    function setVerify(uint256 tokenId, bool completed)
        public
        returns (bool success)
    {
        require(!verificationPaused, "Verification is paused");
        require(
            tokenIdVerificationComplete[tokenId] == false,
            "Token has already been verified"
        );
        require(
            tokenIdToAccountabilityPartner[tokenId] == msg.sender,
            "Only the accountability partner can verify"
        );

        tokenIdVerificationComplete[tokenId] = true;
        tokenIdVerificationValue[tokenId] = completed;

        emit Verified(
            tokenId,
            completed,
            ownerOf(tokenId),
            accountabilityPartnerOf(tokenId)
        );

        return true;
    }

    /**
     * Remove the verification status from the challenge
     * @param tokenId - the tokenId of the challenge
     * @return success - true if successful
     */
    function unverify(uint256 tokenId) public returns (bool success) {
        require(!verificationPaused, "Verification is paused");
        require(
            tokenIdVerificationComplete[tokenId] == true,
            "Token has not been verified"
        );
        require(
            tokenIdToAccountabilityPartner[tokenId] == msg.sender,
            "Only the accountability partner can unverify"
        );

        tokenIdVerificationComplete[tokenId] = false;
        tokenIdVerificationValue[tokenId] = false;

        emit Unverified(
            tokenId,
            ownerOf(tokenId),
            accountabilityPartnerOf(tokenId)
        );

        return true;
    }

    /*
     * Mint a new token
     * @param _tokenURI - the uri of the challenge
     * @param partner - the address of the accountability partner
     * @param signature - the signature of generated data
     * @return id - token id minted
     */
    function mintItem(
        string memory _tokenURI,
        address partner,
        // bytes memory signature
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable returns (uint256) {
        require(mintPaused == false, "Minting is paused");
        require(partner != msg.sender, "Cannot be your own partner");
        require(
            balanceOf(msg.sender) < maxPerAccount,
            "You have already reached the maximum number of items per account."
        );
        require(
            msg.value >= 0.06 ether,
            "You must send 0.06 ether to the contract."
        );

        bytes32 uriHash = keccak256(abi.encodePacked(_tokenURI));
        require(
            uriToTokenId[uriHash] == 0,
            "This URI has already been minted."
        );

        // see that the metadata is created from a valid authority
        bytes32 hash = ECDSA.toEthSignedMessageHash(uriHash);
        // address _addr = ECDSA.recover(hash, v, r, s);
        address _addr = ecrecover(hash, v, r, s);

        require(
            ipfsSigners[_addr] == true,
            string(
                abi.encodePacked(
                    "Not an IPFS signer",
                    toAsciiString(_addr),
                    "  ",
                    uriHash
                )
            )
        );

        // mint the nft
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _safeMint(msg.sender, id);
        _setTokenURI(id, _tokenURI);

        uriToTokenId[uriHash] = id;

        // set accountability partner
        uint256 index = accountabilityPartnerBalance[partner];
        accountabilityPartnerBalance[partner]++;
        tokenIdsByAccountabilityPartner[partner][index] = id;
        tokenIdToAccountabilityPartner[id] = partner;

        // transfer funds to owner for custody
        (bool success, ) = owner().call{value: msg.value}("");
        require(success, "Failed to transfer funds to owner");

        return id;
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    /**
     * Transfer token to redemption contract (will implement ERC721Recievable)
     * @param to - the address of the redemption contract
     * @param tokenId - the tokenId of the challenge
     */
    function transfer(address to, uint256 tokenId) public whenNotPaused {
        require(
            redemptionContracts[to] == true,
            "Recipient is not a whitelisted redemption contract."
        );
        _transfer(msg.sender, to, tokenId);
    }

    /**
     * Transfer token to redemption contract
     * @param from - the address of the holder
     * @param to - the address of the redemption contract
     * @param tokenId - the tokenId of the challenge
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override whenNotPaused {
        require(
            redemptionContracts[to] == true,
            "Recipient is not a whitelisted redemption contract."
        );
        _transfer(from, to, tokenId);
    }

    /**
     * Allow a redemption contract to burn the token after the challenge ends
     * @param tokenId - the tokenId of the challenge
     */
    function burn(uint256 tokenId) public whenNotPaused onlyOwner {
        require(
            redemptionContracts[msg.sender] == true,
            "You are not a whitelisted redemption contract."
        );
        _burn(tokenId);
    }

    /**
     * Whitelist a redemption contract address
     * @param _addr - the address to whitelist
     * @param _whitelisted - true if the address is whitelisted
     */
    function setRedemptionContract(address _addr, bool _whitelisted)
        public
        onlyOwner
    {
        redemptionContracts[_addr] = _whitelisted;

        emit RedemptionContractUpdated(_addr, _whitelisted);
    }

    /**
     * Whitelist a IPFS hash signer address
     * @param _addr - the address to whitelist
     * @param _whitelisted - true if the address is whitelisted
     */
    function setIpfsSigner(address _addr, bool _whitelisted) public onlyOwner {
        ipfsSigners[_addr] = _whitelisted;

        emit IpfsSignerUpdated(_addr, _whitelisted);
    }

    /**
     * Set the maximum number of items per account
     * @param _maxPerAccount - the maximum number of items per account
     */
    function setMaxPerAccount(uint256 _maxPerAccount) public onlyOwner {
        maxPerAccount = _maxPerAccount;

        emit MaxPerAccountUpdated(_maxPerAccount);
    }

    function accountabilityPartnerOf(uint256 tokenId)
        public
        view
        returns (address)
    {
        return tokenIdToAccountabilityPartner[tokenId];
    }

    /**
     * Withdraw the balance of the contract
     * @dev owner only
     * @param _to - the address to send the balance to
     * @param _amount - the amount to send
     * @return sent - true if successful
     * @return data - data from the call
     */
    function withdraw(address payable _to, uint256 _amount)
        external
        onlyOwner
        returns (bool sent, bytes memory data)
    {
        require(_amount < address(this).balance, "Not enough balance");
        require(_amount > 0, "Amount must be greater than 0");

        (sent, data) = _to.call{value: _amount}("");

        return (sent, data);
    }

    function isChallengeSuccess(uint256 tokenId) public view returns (bool) {
        return
            tokenIdVerificationComplete[tokenId] &&
            tokenIdVerificationValue[tokenId];
    }

    function isChallengeFail(uint256 tokenId) public view returns (bool) {
        return
            tokenIdVerificationComplete[tokenId] &&
            !tokenIdVerificationValue[tokenId];
    }

    function isChallengeIncomplete(uint256 tokenId) public view returns (bool) {
        return !tokenIdVerificationComplete[tokenId];
    }

    function paused(uint256 tokenId) public view returns (bool) {
        return !tokenIdVerificationComplete[tokenId];
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * Set base token URI for less storage
     * @param baseURI_ - the base URI
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURIextended = baseURI_;
    }

    /**
     * Set the URI of a token
     * @param tokenId - the tokenId of the token
     * @param _tokenURI - the uri of the token
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        tokenIdToIpfsHash[tokenId] = _tokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * Get the URI of a token
     * @param tokenId - the tokenId of the token
     * @return tokenURI - the uri of the token
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

        string memory _tokenURI = tokenIdToIpfsHash[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, return the base because this shouldn't happen
        return string(abi.encodePacked(base));
    }
}
