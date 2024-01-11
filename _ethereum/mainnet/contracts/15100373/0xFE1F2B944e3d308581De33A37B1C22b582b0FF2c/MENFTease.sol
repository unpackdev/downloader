// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

/**
                            __  __________   __   ______   ______
                           /  |/  / ____/ | / /  / ____/  /_  __/__  ____ _________
                          / /|_/ / __/ /  |/ /  / /_       / / / _ \/ __ `/ ___/ _ \
                         / /  / / /___/ /|  /  / __/      / / /  __/ /_/ (__  )  __/
                        /_/  /_/_____/_/ |_/  /_/        /_/  \___/\__,_/____/\___/

kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxooooloxkkkkkkkkkkkkkkkkxxxxxxkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxkkkdl:,,;;;:clllloodxkkkxxxxkkxxxxkkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkdlcoxdcc:;,,,,;,,;,,,,,;:lolc:clodxkkkkkkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxo;;cll:;;;;,''',,,,,,,,,,,'''',;::clodxkkkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkxdoddxkxolc:::;,,;:;;,,'';;;,',,;;;,'',;;,',,;;;;,;;coxkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkddo:;:cc:;;,,,,,,,,''...':l:;,......''',,'..'',,,'',;coxkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkxlcc;,,,''''..','......'',,........................,:::lddoxkkkkkkkkkkkkkkkkkkk
kxxxkkkkkkkkkkkkkkkkkkd:,,'............................  ..............';:;,';:cdkkkkkkkkkkkkkkkkkkk
xxxxxkkkkkkkkkkkkkkxolc,,'..............  ...........''..........'''','',,,..',:cclxkkkkkkkkkkkkkkkk
xxxxxxkkkkkkkkxxkxdo;...........'.....   ...........',,...,;::'...','........',;;,;:lxkkkkkkkkkkkkkk
xxxxddxkkkkkkxdol:;,'................       ................'.................'',;::lxxkkkkkkkkkkkkk
kkkxxddxkkkxdc:;,,..,'...... ......                 ....................,;,.......,;:lodxkkkkkkkkkkx
kkkkkkxxkkkdc::::;'.'......      .  ........         .....  .....''......''.....'....,:lodxkkkkkkkxk
kkkkkkkkkkkxl::;,..'..... .  ....... ......''..              ............'''....','...',;cdkkkkkkxkk
kkkkkkkkkxxl;,,'..'',;'..... ...'..........''''..  .....  .....  ................''...';;:clddxxxkkk
kkkkkkkkkkdc,'... ...'...................';::::lc'....... ......           ......'....',;;,,:looxkkk
kkkkkkkkkxoc:;'... ...... .',.....';::cc:;codxdddl:;'..'........           ......,'...''',,;cdkkkkkk
kkkkkkkkxolc:,'.....''..........,:loodddlcldkOOkkkkxdoc:,,'''.....     ..........',...',,'',cxkkkkkk
kkkkkkxol::;''';,............';ldxkkkkkkxddkO0000000OOOxolc:;,..... ........''...','''.',,,,ckkkkkkk
kkkkkkdloc,''',;,...........,lxkOOO00000OOO00KKKKKKKK000Okxdol:;,'...........''...','....',;:ldkkkkk
kkkkkkxxdc:;'.............':okOOO000000000000KKKKKKKKKK000OOkxdlc,...... ............ ...';:cldkkkkk
kkkkkkkkxoc;,............;cdkOOOO0000000000KKKKKKKKK00000000OOkxo:......        ..    ...',,:::lldkk
kkkkkkkkdlc,'.....    .':oxkOO0000000KKKKKXXXNNXXXXXXKK00000OOOkko;.............        ...,lolllxkk
kkkkkkkkdoc;'''....  ..;loooodxkO0KKKKKXXKK00OOkkxxxxkkO00000OOOOko:'.   ..,'...        ..,cdkkxxkkk
kkkkkkkkkko:;,''.......,:c:;,,;coxO00KKK0OkxolccclodkkkkOO0000OOOOkd:..  ...''..        .';lxkkkkkkk
kkkkkkkkkkd:,;;;;,'....cdddxdolcclodkO00OkxdooodxkkOOOOOOOOO000000Oko;......','.  .  ....',:odkkkkkk
kkkkkkkkkkxolc:::;,,,.'co::llldxdolcok0000OxdolllcclldxoldxkO000000Oxl;;;;;:col,......:ccloodxkkkkkk
kkkkkkkkkkkkd:;;,'',,''cl:lkxok0kxdooOKKKK00kdoxOOkO0XKxdkO00K00000OkdododdxkOkl.......':oxkkkkkkkkk
kkkkkkkkkkkxl:;''''',,'coodxxkkOkxdox0KKK0K00OkxkkkO00000KKKKK00000OkxxxxkkkO00o...''..':oxkkkkkkkkk
kkkkkkkkkkkxdoc,',....'lxxxxxxkkkxddkKKK0000KKKKKK0KKXXXXXKKKK0000OOOkkkO0K0O0Kx'...,,,,;cdkkkkkkkkk
kkkkkkkkkkkkkkkd:'..  'dkkkOOOOOkxdxOKKK0000KKKXXXXXXXXXXXXKKK000OOOOkkO00KK00Oc.....,:odxkkkkkkkkkk
kkkkkkkkkkkkkkkxo;... .oOkOOOOOOkxkO000000000KXXXXXXXXXXXXKKK000OOOkkkkO00000Oo,....'ldxkkkkkkkkkkkk
kkkkkkkkkkkkkkko:,'....:kkOOOOOOkkk000000OOO0KKXXXXXXKKKKKKK000OOOkkkxkO0000x:.....',cdkkkkkkkkkkkkk
kkkkkkkkkkkkkkdlc:;,,..'okkOOOOOkkO0KKK000OO0KKKKXKKKKKKKKK000OOOkkkxxk0Okkl......';coxkkkkkkkkkkkkk
kkkkkkkkkkkkkkxdodol:'..:xkkOOkkkkO0000OOOOOO0KKKKKKKKKKK0000OOOOkkkxdkOxl;......'cdkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkxc,'''ckkkkkkkxdxxxxxdxxkOKKKKKKKKKKK0000OOOOOkkkddkdc,...':lloxkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkdlc:;,:dkkkkkxxddxkkkkkkO0KKKKKKKKKK00000OOOOOkkkddkx::l:..:dxkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkxdxxkkkkxxxxdxkkkkkkkOOO0KKKKKKK000000OOOOkkkxdxko:dKO:'coxkkkkxkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkxxddollodxxxdddxkkOOO00KKK0000000OOOkkkddkOdlO0dcoxkkkkkkxdxxxxkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkxdlc:cccc:ccllllloxkOO00KK00OOOOOOOkkkdoxOOOxddooxkkkkkkkkxddddxxxxxkkkk
xkkkkkkkkkkkkkkkkkkkkkkkkkkkkxolldxxxxxkkkxdooxkOOO000OOOOOOOOkkxdoxOOOOOo;cxkkkkkkkkkkxddddddddxxxx
xxkkkkkkkkkkkkkkkkkkkkkkkkkkkxdocloxxkkkxxdoodxkOOOOOOOkkkkkkkdoodxOOOOOkc..ckkkkkkkkkkkxxddddddxxxx
xxxkkkkkkkkkkkkkkkkkkkkkkkkkkkxdc:;;::::::cloxkOOOOOOOOOkkkxdoloxOOOOOxo;'.'ckkkkkkkkkkkkkxxdddddddd
xxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdolcccclodxkO0000OOOOOOkdoolloxkO000xc,....'ckkkkkkkkkkkkkkxxxdddodd
xxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxkkO00000OOOOkxolclodxkO000xc'.......,cdxkkkkkkkkkkkkkxxxxddd
kxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkxddxxxxxxkOOOOOOkxxdlcclodxkO000xc'..........''':oxkkkkkkkkkkkkkxxxx
kkxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkddoooodddxxxxxdlcccclodxxkO0Oxc'................':okkkkkkkkkkkkkkxx
kkkkkxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdolllllllllccllllodxkkxol;..................''',:okkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkc'.',;:cccccc::ccc::;'......................''''',:dkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkx,     ............    .....................'''''''',:oxkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxoclc.                  .......................''''''''''',;clodxkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkxo:'...                  .........................''''''''''''...'',;:cl
kkkkkkkkkkkkkkkkkkkkkkkkkkdc,.....                  .........................'''''''''''''..'.......
kkkkkkkkkkkkkkkkkkkkkkxdl,.....  .                 ....................... ..''''''''''''...........
kkkkkkkkkkkkkkkkkkkxdlc;.... ... .               .......................  ....'''''.................
kkkkkkkkkkkkkkkkdl:'........ .....               ......................  ...........................
kkkkkkkkkkkxdlc;'........... .....               .....................  ............................
kkkkkkkxoc;,......... .....  .....               ...................    ........................''''
kkkkkxl;.........  .........  .....              ................      .............................
*/
contract MENFTease is ERC721A, ERC721AQueryable, ERC2981, Ownable, ReentrancyGuard {
    uint96 immutable public royaltyBasis = 500; // 5%
    uint256 immutable public cost = 0.069 ether;
    uint256 immutable public presaleCost = 0.05 ether;
    uint256 immutable public maxSupply;

    bytes32 public merkleRoot;

    string public baseURIPrefix = "";
    string public baseURISuffix = ".json";
    string public hiddenMetadataURI;
    string public contractUri;

    uint256 public maxPresaleMintAmount;
    uint256 public maxMintAmountPerTx;

    bool public presaleEnabled = false;
    bool public saleEnabled = false;
    bool public revealed = false;

    constructor(
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx,
        uint256 _maxPresaleMintAmount,
        string memory _hiddenMetadataURI,
        string memory _contractUri
    ) ERC721A("MENFTease", "MEN") {
        maxSupply = _maxSupply;
        maxMintAmountPerTx = _maxMintAmountPerTx;
        maxPresaleMintAmount = _maxPresaleMintAmount;
        setHiddenMetadataURI(_hiddenMetadataURI);
        setContractURI(_contractUri);
        setRoyaltyRecipient(_msgSender());
    }

    modifier mintCheck(uint8 _quantity, uint256 _txnValue, uint256 _txnCost) {
        require(_quantity > 0, "Must mint at least one token.");
        require(_totalMinted() + _quantity <= maxSupply, "Cannot mint more than maxSupply allows.");
        require(_quantity <= maxMintAmountPerTx, "Attempted to mint more than the allowed amount per mint.");
        require(_txnValue == _txnCost * _quantity, "Transaction value does not equal mint price.");
        _;
    }

    modifier mintCheckAdmin(uint16 _quantity) {
        require(_quantity > 0, "Must mint at least one token.");
        require(_totalMinted() + _quantity <= maxSupply, "Cannot mint more than maxSupply allows.");
        _;
    }

    /**
     * Execute presale mint
     */
    function presaleMint(bytes32[] calldata _merkleProof, uint8 _quantity) public payable mintCheck(_quantity, msg.value, presaleCost) {
        require(presaleEnabled, "The presale is not active.");

        require(_getAux(_msgSender()) + _quantity <= maxPresaleMintAmount, "Attempted to mint more than the allowed amount in the presale.");
        require(MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(_msgSender()))), "Could not verify presale eligibility.");

        _safeMint(_msgSender(), _quantity);
        _setAux(_msgSender(), _getAux(_msgSender()) + _quantity);
    }

    /**
     * Execute public mint
     */
    function mint(uint8 _quantity) public payable mintCheck(_quantity, msg.value, cost) {
        require(saleEnabled, "The main sale is not active.");

        _safeMint(_msgSender(), _quantity);
    }

    /**
     * Admin - Airdrop tokens to address
     */
    function mintForAddressAdmin(address _receiver, uint16 _quantity) public mintCheckAdmin(_quantity) onlyOwner {
        _safeMint(_receiver, _quantity);
    }

    /**
     * Admin - Airdrop tokens to addresses
     */
    function mintForAddressesAdmin(address[] calldata _receivers, uint16[] calldata _quantities) public onlyOwner {
        for (uint i = 0; i < _receivers.length; i++) {
            mintForAddressAdmin(_receivers[i], _quantities[i]);
        }
    }

    /**
     * View a specified token's metadata link
     */
    function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory)
    {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
        if (revealed == false) {
            return hiddenMetadataURI;
        }

        return bytes(baseURIPrefix).length != 0 ? string(abi.encodePacked(baseURIPrefix, _toString(_tokenId), baseURISuffix)) : '';
    }

    /**
     * OpenSea contract-level metadata
     */
    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    /**
     * Admin - Set token metadata reveal flag
     */
    function setRevealed(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    /**
     * Admin - Set contract metadata URI
     */
    function setContractURI(string memory _contractUri) public onlyOwner {
        contractUri = _contractUri;
    }

    /**
     * Admin - Set royalty recipient
     */
    function setRoyaltyRecipient(address receiver) public onlyOwner {
        _setDefaultRoyalty(receiver, royaltyBasis);
    }

    /**
     * Admin - Set hidden metadata URI
     */
    function setHiddenMetadataURI(string memory _hiddenMetadataURI) public onlyOwner {
        hiddenMetadataURI = _hiddenMetadataURI;
    }

    /**
     * Admin - Set metadata link
     */
    function setBaseURIPrefix(string memory _baseURIPrefix) public onlyOwner {
        baseURIPrefix = _baseURIPrefix;
    }

    /**
     * Admin - Set metadata link suffix
     */
    function setBaseURISuffix(string memory _baseURISuffix) public onlyOwner {
        baseURISuffix = _baseURISuffix;
    }

    /**
     * Admin - Set presale flag
     */
    function setPresaleEnabled(bool _presaleEnabled) public onlyOwner {
        presaleEnabled = _presaleEnabled;
    }

    /**
     * Admin - Set main sale flag
     */
    function setSaleEnabled(bool _saleEnabled) public onlyOwner {
        saleEnabled = _saleEnabled;
    }

    /**
     * Admin - Set merkle root for presale allowlist
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * Admin - Withdraw ETH from contract
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
        ERC721A.supportsInterface(interfaceId) ||
        ERC2981.supportsInterface(interfaceId);
    }
}
