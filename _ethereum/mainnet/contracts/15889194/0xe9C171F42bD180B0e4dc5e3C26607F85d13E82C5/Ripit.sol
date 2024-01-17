// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC165Checker.sol";
import "./ReentrancyGuard.sol";
import "./ERC721URIStorage.sol";

/*



RRRRRRRRRRRRRRRRR     iiii                             iiii           tttt
R::::::::::::::::R   i::::i                           i::::i       ttt:::t
R::::::RRRRRR:::::R   iiii                             iiii        t:::::t
RR:::::R     R:::::R                                               t:::::t
  R::::R     R:::::Riiiiiii ppppp   ppppppppp        iiiiiii ttttttt:::::ttttttt
  R::::R     R:::::Ri:::::i p::::ppp:::::::::p       i:::::i t:::::::::::::::::t
  R::::RRRRRR:::::R  i::::i p:::::::::::::::::p       i::::i t:::::::::::::::::t
  R:::::::::::::RR   i::::i pp::::::ppppp::::::p      i::::i tttttt:::::::tttttt
  R::::RRRRRR:::::R  i::::i  p:::::p     p:::::p      i::::i       t:::::t
  R::::R     R:::::R i::::i  p:::::p     p:::::p      i::::i       t:::::t
  R::::R     R:::::R i::::i  p:::::p     p:::::p      i::::i       t:::::t
  R::::R     R:::::R i::::i  p:::::p    p::::::p      i::::i       t:::::t    tttttt
RR:::::R     R:::::Ri::::::i p:::::ppppp:::::::p     i::::::i      t::::::tttt:::::t
R::::::R     R:::::Ri::::::i p::::::::::::::::p      i::::::i      tt::::::::::::::t
R::::::R     R:::::Ri::::::i p::::::::::::::pp       i::::::i        tt:::::::::::tt
RRRRRRRR     RRRRRRRiiiiiiii p::::::pppppppp         iiiiiiii          ttttttttttt
                             p:::::p
                             p:::::p
                            p:::::::p
                            p:::::::p
                            p:::::::p
                            ppppppppp


*/

contract Ripit is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard {

    // Tracks the RipId to the URI
    //mapping(uint => string) public transformations;

    // Contract address -> token id -> bool
    mapping(address => mapping(uint => bool)) public addressTokenRipped;
    mapping(uint256 => bool) public alreadyRipped;

    bytes4 private ERC721InterfaceId = 0x80ac58cd;
    bytes4 private ERC1155MetadataInterfaceId = 0x0e89341c;

    uint public price = 0.003 ether;
    uint public ripCount;
    uint public constant MAX_SUPPLY = 20000;
    uint256 public _royaltyFee = 1000;
    address private _owner;
    uint256 internal currentIndex = 1;

    string private ripEnabledURI = "https://lordcalder.com/ripit/token/";
    string private ripNotEnabledURI = "https://lordcalder.com/ripit/";
    string public _baseTokenURI = "https://lordcalder.com/ripit/";

    bool mintEnabled = true;
    bool ripEnabled = false;

    address public withdrawAddress = 0xa0270756B3a3E18AfA74dB7812367aF9E5e79BF3;

    // Events

    event Ripping(uint indexed ripId, address indexed usingContractNFT, uint indexed tokenId);

    // Constructor

    constructor() ERC721("RIPit by Lordcalder", "RIPit") {
        _owner = msg.sender;
        marketingMint(1);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Ripit :: Cannot be called by contracts!");
        _;
    }
    // Mint

    function mint(uint256 _numberToMint, uint256 _value) external payable callerIsUser nonReentrant {
        require(mintEnabled == true, "Mint is not enabled");
        require(totalSupply() + _numberToMint <= MAX_SUPPLY, "We have minted out");
        require(_value == (price * _numberToMint), string.concat("You have ",_value > (price * _numberToMint) ? "sent too much" : "not sent enough"," dosh! Expected: ", toString(3000000000000000 * _numberToMint)));
        for (uint256 i = 0; i < _numberToMint; ++i) {
            _safeMint(msg.sender, currentIndex);
            currentIndex += 1;
        }
    }

    function hasTargetBeenRipped(address _contractAddress, uint _tokenId) view public returns (bool){
        return addressTokenRipped[_contractAddress][_tokenId];
    }

    function ripIdHasBeenUsedAlready(uint256 _tokenId) view public returns (bool){
        return alreadyRipped[_tokenId];
    }

    // Only rip once
    function ripit(uint ripId, address usingContractNFT, uint usingTokenId) external {
        require(ripEnabled, "Ripping your NFTs is not enabled yet");
        require(_exists(ripId), "This RIP Token has not been minted yet!");
        // Prevents a token from being re-ripped
        require(hasTargetBeenRipped(usingContractNFT, usingTokenId) == false, "This nft has already been ripped!");
        require(ownerOf(ripId) == msg.sender, "Not your strip to rip!");
        require(ripIdHasBeenUsedAlready(ripId) == false, "This RIP Token has alread been used!");

        addressTokenRipped[usingContractNFT][usingTokenId] = true;
        alreadyRipped[ripId] = true;
        unchecked { ++ripCount; }

        emit Ripping(ripId, usingContractNFT, usingTokenId);

    }

    // Plucked from OpenZeppelin's Strings.sol
    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function marketingMint(uint256 _numberToMint) public payable callerIsUser onlyOwner nonReentrant {
        uint256 s = totalSupply();
        uint256 m = MAX_SUPPLY;
        require(_numberToMint > 0, "Cannot mint 0 Rips");
        require(s + _numberToMint <= m, "There are not enough strips to rip!");
        for (uint256 i = 0; i < _numberToMint; ++i) {
            _safeMint(msg.sender, currentIndex);
            currentIndex += 1;
        }
        delete m;
        delete s;
    }


    function totalSupply() public view returns (uint256) {
        return _totalSupply();
    }

    function _totalSupply() internal view returns (uint256) {
        return currentIndex - 1;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        // Just ensure the metadata 'value'... if this is traditional CDN with a json file, or a direct Link
        // update the currentBaseURI concatenation accordingly
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();

        return
        (ripEnabled == true)
        // REMEMBER TO CHECK THE METADATA CDN's
        ? ripIdHasBeenUsedAlready(tokenId) 
            ? string(abi.encodePacked(currentBaseURI, toString(tokenId), ".json"))
            : string(abi.encodePacked(ripNotEnabledURI, "readytorip.json"))
        : string(abi.encodePacked(ripNotEnabledURI, "waitingforrip.json"));
    }


    // Setters

    // Use this function to update a single nft's metadata
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external onlyOwner {
        require(_exists(_tokenId), "Token does not exist!");
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function setRipEnabledURI(string memory _ripEnabledURI) external onlyOwner {
        ripEnabledURI = _ripEnabledURI;
    }

    function setRipNotEnabledURI(string memory _ripNotEnabledURI) external onlyOwner {
        ripNotEnabledURI = _ripNotEnabledURI;
    }

    function setMintOpen(bool _val) external onlyOwner {
        mintEnabled = _val;
    }

    function setRipOpen(bool _val) external onlyOwner {
        ripEnabled = _val;
        if (_val == true) {
            _baseTokenURI = ripEnabledURI;
        }
    }

    function setPrice(uint _wei) external onlyOwner {
        price = _wei;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Withdraw

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function withdrawAny(uint256 _amount) public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success);
    }

    // Required as override as two inherited contracts have a burn function
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

}