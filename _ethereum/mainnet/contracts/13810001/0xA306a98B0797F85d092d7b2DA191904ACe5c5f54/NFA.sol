// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

// NON FUNGIBLE ALIENS

// MMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxdolcc::::::cclodk0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMWKkdc;'.                   ..';lxOXWWWWWMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWKkl,.                                .;oOXWMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWXx:.                          .......       'ckXMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMWNkc.                      ...,;:cclloollc:;,..    'l0WMMMMMMMMMMMMM
// MMMMMMMMMMMXx,                      .,:lodddddddddddddddddl:,.   .:ONMMMMMMMMMMM
// MMMMMMMMMNx,                      .:oddddddddddddddddddddddddo:'.  .:OWMMMMMMMMM
// MMMMMMMWO;                      .:oddddddddddddddddddddddddddddoc'   .cKWMMMMMMM
// MMMMWMXo.                      ,lddddddddddddddddddddddddddddddddo:.   'xNMWWMMM
// MMMMWK:                      .;odddddddddddddddddddddddddddddddddddl.   .oXMMMMM
// MMMWO,                       ;odddddddddddddddddddddddddddddddddddddl'    cKMMMM
// MMM0'              .        'odddddddddddddddddddddddddddddddddddddddc.    :XMMM
// MMK,    .''..    .:lc.     .:dodddddddddddddddddddddddddddddddddddoood;     lNMM
// MNc     ,odol'  .:ddd,     .lc,..'',:loddddddddddddddddddddol:;,'''';oc.    .dWM
// Wx.     .;oddo;..cddl.     'll.      ..;clodddddddddddddol;..       ,oc.     ,0M
// X:       .,lddo,.cdd:.     .ld:.         .,ldddddddddddl,.         .ldc.      oW
// k.         .:odl;cdl'      .cdo,           .cddddddddoc.          .cdd:.      ;K
// o           .,ldoodl.       ,odo;.          .cdddddddc.          .cddl.       .k
// c          .:clddddoc,.     .:ddoc.          'odddddo'         .;oddo'        .d
// :        .:ldddddddddo,      .cdddo:'.       .cdddddc.      .':odddo,          o
// :        ;dddddddddddc.       .cdddddl:,,... .cdddddc.  ..,:loddddl,.          o
// l        'ldddddddddo,         .:odddddddooc:codddddoc:clodddddddl'           .d
// d.        ':odddddddo,           ,lddddddddddddddddddddddddddddo:.            .k
// 0'          .';coddddc.           'cddddddddddddddddddddddddddl'              ;0
// Nc              .;oddd:.           .,lddddddddddddddddddddddl;.              .oX
// M0'               ,lddo;.            .;oddddddddddddddddddl;.                ,ON
// MWd.               ;oddo;.             .,;ldddddddddddddl:.                 .dXN
// MMNl               .;oddoc.               .,codddddddoc,.                  .lKNW
// MMMXc               .:odddl,.                .;lddddc'.                   .c0NWM
// MMMMXl               .,lddddl;..            .':oddddl:.                  .l0XWWM
// MMMMMNd.               .:oddddolc;,,'''''',;coddddddddo:'..             .dKNWWMM
// MMMMMMWO;                .;coddddddddddddddddddddddddddddolc:,.        ;kXNWMMMM
// MMMMMMMMXd.                ..,;:loddodddddddddddddddddddddddddo;.    'dKNWWMMMMM
// MMMMMMMMMWKo.                   ...';ldddddddddddddddddddddddddo;. 'o0NNWMMMMMMM
// MMMMMMMMMMMWKo'                      ,odddddddddddddddddddddddddold0XNWMMMMMMMMM
// MMMMMMMMMMMMMMXk:.                   ,odddddddddddddddddddddddxO0XNWWWMMMMMMMMMM
// MMMMMMMMMMMMMMMMWKxc'               .:dddddddddddddddddddddxOKXNWWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWXOd:'.          'lddddddddddddddddxkO0XNWWWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMNKkdc;,.....;oddddddddxxkkO00XNWWWMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0kxdxOOOOOOO00KXNWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMM

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

contract NFA is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    enum ListType { Whitelist, Raffle }

    // config
    uint constant MAX_SUPPLY = 8051; // big up to area 51
    uint constant PRICE = 15 ether / 100 ; // 0.15 ETH mint price
    uint constant MAX_MINT_PER_ADDRESS = 10;
    uint constant MAX_MINT_NOT_WHITELISTED = 5;
    uint constant PREMINE_AMOUNT = 6;
    string constant BEFORE_REVEAL_URI = "ipfs://QmTiDYiNtWeuNJs7UGB95B6e1Vuh1LWAcPF5gmQg9xwzvR/";
    address constant TEAM = 0x0fE45a7477AB12211909EDb7C2e1649A6978A034;
    
    bytes32 immutable private WHITELIST_ROOT;

    Counters.Counter private _tokenIdCounter;

    bytes32 private raffleRoot;
    mapping(address => bool) public isWhitelisted;
    mapping(address => uint) public nbOfNFAsMintedBy;
    bool public raffleStarted;
    bool public publicSaleStarted;
    bool public collectionHasBeenRevealed;
    string private baseURI;

    constructor(bytes32 root) ERC721("Non-Fungible Aliens", "NFA") {
        WHITELIST_ROOT = root;

        for (uint i = 0; i < PREMINE_AMOUNT; i++){
            _tokenIdCounter.increment();
            _mint(TEAM, _tokenIdCounter.current());
        }
    }

    // public methods

    /**
     * @dev mints `amount` of NFAs and transfers it to msg.sender in exchange of the price * amount in ETH
     *
     * Required `proof` a valid merkle proof that msg.sender is whitelisted
     * Provide an empty proof for the public sale
     *
     * Required `quantity` the amount of desired NFAs to buy
     *
     * `listType` if proof is not empty, which whitelist should be checked against sender address to register
     *  whitelisting.
     *
     * Emits a {Transfer} event.
     */
    function buy(uint quantity, bytes32[] calldata proof, ListType listType) payable public {
        uint userMintLimit = MAX_MINT_NOT_WHITELISTED;
        if (isWhitelisted[msg.sender]){
            userMintLimit = MAX_MINT_PER_ADDRESS;
        } else {
            if(checkWhitelisting(proof, listType)){
                userMintLimit = MAX_MINT_PER_ADDRESS;
            } else {
                require(publicSaleStarted, "The sale isn't public yet");
            }
        }
        
        require(nbOfNFAsMintedBy[msg.sender] + quantity <= userMintLimit, "Mint quantity exceeds allowance for this address");
	    require(_tokenIdCounter.current() < MAX_SUPPLY, "Max supply reached");
		require(_tokenIdCounter.current() + quantity <= MAX_SUPPLY, "Mint quantity exceeds max supply");
        require(msg.value >= PRICE * quantity, "Price not met");

        for (uint i = 0; i < quantity; i++){

            // _safeMint() not used to avoid reentrency
            // it is the responsibility of the caller not to call buy() from a contract where the tokens 
            // would be locked
            _tokenIdCounter.increment();
            nbOfNFAsMintedBy[msg.sender]++;
            _mint(msg.sender, _tokenIdCounter.current());
        }
    }

    // Admin methods

    function reveal(string calldata _baseUri) public onlyOwner {
        // Metadatas can't be modified
        require(!collectionHasBeenRevealed);
        collectionHasBeenRevealed = true;
        baseURI = _baseUri;
    }

    function startRaffle(bytes32 root) public onlyOwner {
        require(!raffleStarted, "Raffle whitelist can't be modified");
        raffleRoot = root;
        raffleStarted = true;
    }

    function startPublicSale() public onlyOwner {
        publicSaleStarted = true;
    }
	
	function withdraw() public {
        require(msg.sender == TEAM);
		(bool success, ) = msg.sender.call{value: address(this).balance}('');
		require(success, "Withdrawal failed");
	}

    // private methods

    function checkWhitelisting(bytes32[] calldata proof, ListType listType) private returns(bool){
        if(proof.length == 0) return false;

        bytes32 root = listType == ListType.Whitelist ? WHITELIST_ROOT : raffleRoot;
        
        if(MerkleProof.verify(proof, root, bytes32(abi.encodePacked(msg.sender)))){
            isWhitelisted[msg.sender] = true;
            return true;
        } else {
            return false;
        }
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory basePart = collectionHasBeenRevealed ? _baseURI() : BEFORE_REVEAL_URI;

        return string(abi.encodePacked(basePart, tokenId.toString()));
    }
    
    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}