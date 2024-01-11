// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./Address.sol";
import "./ERC721A.sol";

error ExceedsMaxPresaleMints();
error IncorrectValue();
error InsufficientSupply();
error InvalidSignature();
error NoContractMints();
error PublicSaleNotActive();
error FunctionLocked();

/**
 .:dkkkkkkkkkkkk; .lxkkkkkkkkkxo' ,xk:        ,xk:.:xo'       .ckd''dkkkkkkkkkkkxc. .cxkkkkkkkkkkkx,'dkkkkkkkkkkkxl.
 cNWKkxxxxxxxxxx,.kMNOxxxxxxxONMO'cNWo        :NMd,kMMXx,     .kMX;:XMXkxxxxxxx0WWd.oWW0xxxxxxxxxxd,;KMNOxxxxxxx0NMx.
 oWWo.           'OM0,       'OMK,cNWd        :NMd,kMWNWXx,   .kMX;:XMx.       :XMx'dMNc            ,KMO'       ;KMO.
 oWWXOOOOOOOOOOk;,OM0'       .OMK,cNWd        :NWd,kMXlc0WNx, .kMX;:XMx.       ;XMx'dMWKOOOOkOOOOkx,;KMN0kOOkkOO0WWx.
 oWWKxxxxxxxxxxd,'OM0'       .OMK,cNWd        :NMd,kMK, .c0WNxl0MX;:XMx.       ;XMk'dMW0xxxxxxxxxxd';KMNOkXWMWKkxdc.
 oWWl            '0M0,       'OMK,cNWd.       cNMd,kMK,   .c0WWWMX;:XMk.       :XMx'dMNc            ,KMO. 'dXWKo'
 oWWl            .xWW0OOOOOOO0NWk.;KMXOOOOOOOOKWNl'kMK,     .c0WMK;:XMN0OOOOOOOKWWo.lNWKOOOOOOOOOOx,;KMk.   'dXWXOOl.
 ;dd,             .cdxxxxxxxxxdc.  ,odxxxxxxxxdo;..cxl.       .:dc..oxxxxxxxxxxxo:. .:odxxxxxxxxxxo'.lxc.     'ldxxc.

 ;lll:.            .:lllllc.    ':llllllllllllllllllll;. .cllc'              .clll,  ,llllllllllllllllllllllc'
 .OMMMK,          'dXWMMMMMX:  ,kNMMMMMMMMMMMMMMMMMMMMM0' lWMMWo              :XMMMx..kMMMMMMMMMMMMMMMMMMMMMMMK,
 .kMMMK,        'dXMMMWNXXX0; .OMMMWXXXXXXXXXXXXXXXXXXXk. lWMMWo              :XMMMx..oXXXXXXXXXXXXXXXNMMMMMMNx.
 .kMMMK,     ':dXMMMW0c'....  ,KMMM0;...................  lWMMWo              :XMMMx. ..............,dXMMMMNk;
 .kMMMK;   'dXWMMMW0c.        ;KMMMk.                     lWMMWo              :NMMMx.             .;ONMMMNk;
 .kMMMNxclxXMMMMW0c.          ;KMMMKdcccccccccccccccccc;. lNMMWOlccccccccccccckWMMMx.           .;kNMMMNk;
 .OMMMMMMMMMMMMNo.            ;KMMMMMMMMMMMMMMMMMMMMMMM0' 'OWMMMMMMMMMMMMMMMMMMMMMMx.         .;kNMMMNk;
 .OMMMMNNNWMMMMNk;            ;KMMMWNNXNNNNNNNNNNNNNNNNk.  .lOXXNNNNNNNNNNNNNNNMMMMx.       .;kNMMMNk;
 .OMMMXl..:kNMMMMNk;          ,KMMM0;...................      ................oNMMMx.     .;kNMMMNk;
 .kMMMK,   .;kXNMMMNk;        ;KMMMk.                                         :XMMMx.    ;kNMMMNk;
 .kMMMK,     ..;kNMMMNklc::;. ,KMMMKo:::c:::::::::::::c,. .:c::::::::::::::::ckWMMMd.  ;kNMMMMW0oc:::::::::::c:.
 .kMMMK,        .;kNMMMMMMMX: .xWMMMMMMMMMMMMMMMMMMMMMM0' lWMMMMMMMMMMMMMMMMMMMMMMX:  lNMMMMMMMMMMMMMMMMMMMMMMNc
 .xNNN0,          .;kXNNNNNK;  .cOXNNNNNNNNNNNNNNNNNNNNO' cXNNNNNNNNNNNNNNNNNNNX0d,   :0NNNNNNNNNNNNNNNNNNNNNNXc
 ':::,.            .,:::::;.    .';:::::::::::::::::::,. .;:::::::::::::::::::,.      .;:::::::::::::::::::::;.

 * @title metaSKINZ founderKEYZ
 * @author bagelface.eth
 * @notice Learn more at https://www.metaskinz.io/
 */
contract FounderKEYZ is ERC721A, Ownable {
    using Address for address;
    using ECDSA for bytes32;

    uint256 public constant MAX_SUPPLY = 555;
    uint256 public maxPresaleMints = 2;
    uint256 public price = 0.2 ether;

    address public signer;
    bool public revealed;
    bool public publicSale;
    string public placeholderURI;
    mapping(address => uint256) public addressMinted;
    mapping(bytes4 => bool) public functionLocked;
    string internal _baseTokenURI;

    constructor() ERC721A("founderKEYZ", "KEYZ") {}

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
        if (functionLocked[msg.sig]) revert FunctionLocked();
        _;
    }

    /**
     * @notice Override ERC721 _baseURI function to use base URI pattern
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Return token metadata
     * @param tokenId Token to return metadata for
     * @return token URI for the specified token
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return revealed ? ERC721A.tokenURI(tokenId) : placeholderURI;
    }

    /**
     * @notice Flip public sale active
     */
    function flipPublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    /**
     * @notice Set placeholder token URI
     * @param uri Placeholder metadata returned before reveal
     */
    function setPlaceholderURI(string memory uri) external onlyOwner {
        placeholderURI = uri;
    }

    /**
     * @notice Set signature signing address
     * @param _signer Address of account used to create mint signatures
     */
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /**
     * @notice Set mint price
     * @param _price New mint price
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * @notice Set maximum presale mints per address
     * @param maxMints New maximum presale mints
     */
    function setMaxPresaleMints(uint256 maxMints) external onlyOwner {
        maxPresaleMints = maxMints;
    }

    /**
     * @notice Set base token URI
     * @param uri Base metadata URI to be prepended to token ID
     */
    function setBaseTokenURI(string memory uri) external lockable onlyOwner {
        _baseTokenURI = uri;
    }

    /**
     * @notice Flip token metadata to revealed
     */
    function flipRevealed() external lockable onlyOwner {
        revealed = !revealed;
    }

    /**
     * @notice Airdrop tokens to a list of specified receivers
     * @param receivers Addresses of receivers of the airdrop
     */
    function airdrop(address[] calldata receivers) external lockable onlyOwner {
        uint256 receiversCount = receivers.length;
        for (uint256 i; i < receiversCount;) {
            _mint(receivers[i], 1);
            unchecked { ++i; }
        }
    }

    /**
     * @notice Mint a specified amount of KEYZ
     * @param amount Amount of KEYZ to mint
     * @param signature Message signed by designated signer account
     */
    function presaleMint(uint256 amount, bytes memory signature) external payable {
        if (signer != ECDSA.recover(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_msgSender()))),
            signature
        )) revert InvalidSignature();

        addressMinted[_msgSender()] += amount;

        if (addressMinted[_msgSender()] > maxPresaleMints) revert ExceedsMaxPresaleMints();

        __mint(amount);
    }

    /**
     * @notice Mint a specified amount of KEYZ
     * @param amount Amount of KEYZ to mint
     */
    function publicMint(uint256 amount) external payable {
        if (_msgSender() != tx.origin) revert NoContractMints();
        if (!publicSale) revert PublicSaleNotActive();

        __mint(amount);
    }

    /**
     * @notice Mint a specified amount of KEYZ
     * @param amount Amount of tokens to mint
     */
    function __mint(uint256 amount) internal {
        if (_totalMinted() + amount > MAX_SUPPLY) revert InsufficientSupply();
        if (msg.value != price * amount) revert IncorrectValue();

        _mint(_msgSender(), amount);
    }

    /**
     * @notice Withdraw all ETH transferred to the contract
     */
    function withdraw() external onlyOwner {
        Address.sendValue(payable(_msgSender()), address(this).balance);
    }

    /**
     * @notice Lock individual functions that are no longer needed
     * @dev Only affects functions with the lockable modifier
     * @param id First 4 bytes of the calldata (i.e. function identifier)
     */
    function lockFunction(bytes4 id) external onlyOwner {
        functionLocked[id] = true;
    }
}