// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "ERC721.sol";
import "ECDSA.sol";
import "Ownable.sol";
import "Strings.sol";
import "Address.sol";
import "ReentrancyGuard.sol";
import "JackpotNFT.sol";


contract ChocoNFT is ERC721, JackpotNFT, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using Strings for uint256;
    using Address for address payable;

    struct MintOption {
        uint256 price;
        uint256 amount;
    }

    mapping(uint256 => MintOption) options;

    uint256 constant BAR_ID_START = 0;
    uint256 constant ART_ID_START = 100_000;
    uint256 constant public GOLDEN_TICKET_ID_START = 1_000_000;

    // prefix to the IPFS folder (ipfs:///xxxx/)
    string barURI;
    string artURI;
    string ticketURI;

    uint256 numBars;
    uint256 numMinted = 0;
    uint256 numOpened = 0;
    uint256 numTicketsFound = 0;
    uint256 numTicketsTotal;
    bool uriLocked = false;

    uint256 pricePerOne;

    // for checking signatures
    address signer;
    // contract where we want to forward % of sales for final jackpot
    address payable public jackpot;
    // address for the sales proceeds
    address payable public sales;

    uint256 notBefore;

    constructor (string memory _name, string memory _symbol, uint256 _numBars, address _signer, string memory _baseURI, uint256 _notBefore, uint256 _numTickets, uint256 _price, address payable _sales) ERC721(_name, _symbol) {
        require(_numBars < (ART_ID_START - 10), "numBars is too high");

        numBars = _numBars;
        signer = _signer;
        barURI = _baseURI;
        notBefore = _notBefore;
        numTicketsTotal = _numTickets;
        sales = _sales;
        pricePerOne = _price;
    }

    function setJackpot(address payable _to) external onlyOwner {
        require(jackpot == address(0), "Jackpot already set");
        jackpot = _to;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        pricePerOne = _newPrice;
    }

    /**
     * To mint the chocolates in exchange for ETH.
     */
    function mintPackage(uint256 _option) payable external nonReentrant returns (uint256) {
        require(jackpot != address(0), "Jackpot not set yet. Minting not started");

        MintOption storage opt = options[_option];
        require(opt.amount > 0, "Invalid option");

        return _doMinting(opt.amount, opt.price);
    }

    function mintSingle(uint256  _count) payable external nonReentrant returns (uint256) {
        require(jackpot != address(0), "Jackpot not set yet. Minting not started");
        require(_count <= 20, "Too many items to mint");

        return _doMinting(_count, _count * pricePerOne);
    }

    function _doMinting(uint256 _count, uint256 _price) internal returns (uint256) {
        // make sure we have enough bars left
        require((numBars - numMinted) >= _count, "ChocoNFT#1");
          // make sure user sent enough ether to pay for those bars
        require(msg.value >= _price, "ChocoNFT#2");

        uint256 toJackpot = getJackpotCut(_price);
        assert (msg.value >= 0);
        uint256 ethLeft = msg.value - _price;

        uint256 startId = numMinted + 1;
        numMinted += _count;
        // safe mint will make an NFT transfer and call method on the receiving address
        // so we can't modify anything after this point, otherwise we expose ourselves
        // to reentrancy attacks. Also if the NFT already exists it will revert.
        for (uint256 i = 0; i < _count; i++) {
            _safeMint(_msgSender(), startId + i);
        }

        // transfer part of the buy to the jackpot
        jackpot.sendValue(toJackpot);
        // transfer the rest to the sales to the sales address
        sales.sendValue(_price - toJackpot);
        // if there is any eth left after all of that - send it back
        if (ethLeft > 0) {
            (payable(_msgSender())).sendValue(ethLeft);
        }

        return startId;
    }

    function setOption(uint256 _id, uint256 price, uint256 amount) onlyOwner external {
        require(price > 0, "ChocoNFT###");
        require(amount > 0, "ChocoNFT###");

        options[_id] = MintOption(price, amount);
    }

    function delOption(uint256 _id) onlyOwner external {
        delete options[_id];
    }

    /**
     * To open the chocolate.
     */
    function open(uint256 _id, bool _hasTicket, bytes memory _signature) openingBegan nonReentrant external {
        require(_exists(_id), "ChocoNFT#404");
        require(isBar(_id), "ChocoNFT#NOT-BAR");
        address owner = ownerOf(_id);
        require(owner == _msgSender(), "ChocoNFT#NOT-YOURS");
        verifyOpenSignature(_id, _hasTicket, _signature);

        // burn doesn't call any contracts under the hood, safe!
        _burn(_id);
        numOpened += 1;
        _safeMint(owner, ART_ID_START + _id);

        if (_hasTicket) {
            require(numTicketsFound < totalGoldenTickets(), "ChocoNFT#TOO-MANY-TICKETS");
            _safeMint(owner, GOLDEN_TICKET_ID_START + numTicketsFound);
            numTicketsFound += 1;
        }
    }

    // this is left here as a failsafe but in general
    // no ether is stored on this contract
    function withdraw(address payable _recipient) onlyOwner external {
        require(_recipient != address(0), "ChocoNFT#40");
        uint256 amount = address(this).balance;

        _recipient.sendValue(amount);
    }

    /** How many chocolate bars there are left to mint. */
    function barsLeft() external view returns (uint256) {
        return (numBars - numMinted);
    }

    /** How many bars have been opened by peple. */
    function barsOpened() external view returns (uint256) {
        return numOpened;
    }

    /** How many bars there are in total (does not take burns into account, 
      * imply returns how many it was configured with). */
    function totalBars() external view returns (uint256) {
        return numBars;
    }

    /** How many golden tickets were found. */
    function goldenTicketsFound() external view returns (uint256 num) {
        return numTicketsFound;
    }

    /** How many golden tickets there are in total (initial config value, burn not taken into account). */
    function totalGoldenTickets() public view returns (uint256) {
        return numTicketsTotal;
    }

    /** Checks if given token exists, needed by Jackpot contract. */
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    // utilities
    modifier openingBegan() {
        require(block.timestamp >= notBefore, "ChocoNFT#50");
        _;
    }

    function isBar(uint256 _id) internal pure returns (bool) {
        return _id >= BAR_ID_START && _id < ART_ID_START;
    }

    function isArt(uint256 _id) internal pure returns (bool) {
        return _id >= ART_ID_START && _id < GOLDEN_TICKET_ID_START;
    }

    function isGoldenTicket(uint256  _id) public pure returns (bool) {
        return _id >= GOLDEN_TICKET_ID_START;
    }

    function getJackpotCut(uint256 price) internal returns (uint256) {
        return (price / 100) * 30;  // ~30%
    }

    function verifyOpenSignature(uint256 _id, bool _hasTicket, bytes memory _signature) internal {
        // 1. chainid is used in order to prevent accidental replay attack opportunities by copying
        //    transactions from a test chain
        // 2. do not use encodePacked() here. While in this situation it would be safe (at the time of
        //    writing), it could lead to multiple arguments resulting in the same hash, which could
        //    be used for an attack. https://swcregistry.io/docs/SWC-133
        // 3. Replay attacks on signature are not possible because tokens are burned (thus replying
        //    the same action is not possible). https://swcregistry.io/docs/SWC-121
        // 4. Front-running attacks are not possible because this action can be executed only
        //    by the owner.
        bytes32 hashed = keccak256(abi.encode("CHID:", block.chainid, "\nGLD:", _hasTicket, "\nTID:", _id));
        (address _signedBy,) = hashed.tryRecover(_signature);
        require(_signedBy != address(0), "ChocoNFT#INVALID-SIGN-1");
        require(_signedBy == signer, "ChocoNFT#INVALID-SIGN-2");
    }

    function setArtURI(string memory uri) external onlyOwner uriUnlocked {
        artURI = uri;
    }

    function setTicketURI(string memory uri) external onlyOwner uriUnlocked {
        ticketURI = uri;
    }

    function setBarURI(string memory uri) external onlyOwner uriUnlocked {
        barURI = uri;
    }

    function lockURI() external onlyOwner uriUnlocked {
        uriLocked = true;
    }

    modifier uriUnlocked() {
        require(!uriLocked, "Can't change metadata anymore");
        _;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ChocoNFT#3");

        if (isBar(tokenId)) {
            return string(abi.encodePacked(barURI, tokenId.toString(), ".json"));
        }
        if (isArt(tokenId)) {
            return string(abi.encodePacked(artURI, tokenId.toString(), ".json"));
        }
        if (isGoldenTicket(tokenId)) {
            return string(abi.encodePacked(ticketURI, tokenId.toString(), ".json"));
        }
        revert("unknown nft type");
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}