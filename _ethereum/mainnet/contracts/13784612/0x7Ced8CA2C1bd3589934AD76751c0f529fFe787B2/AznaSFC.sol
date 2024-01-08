//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC165.sol";
import "./ERC165.sol";
import "./ERC165.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./Address.sol";
import "./IERC721Receiver.sol";

contract AZNASFC2 is ERC721, ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public maxSupply = 10000;
    uint256 public maxReserve = 150;
    uint256 public maxMintPerTx = 5;
    uint256 public commandoPrice = 80000000000000000; //0.08 ETH

    bool public saleActive = false;
    bool public reserveActive = false;
    string public _setBaseURI;
    string public baseExtension = ".json";
    mapping (address => mapping(uint256 => uint8)) public promotionWinners;
    address trustedPublicKey = 0x0deDa54Ac34c6ea809efEb6bd0331662e53b6E4B;

    constructor() ERC721("AZNA-Special Forces Commandos", "AZNA-SFC") {}

    // RETRIEVE BASEURI
    function _baseURI() internal view virtual override returns (string memory) {
        return _setBaseURI;
    }

    // SET BASEURI
    function setBaseURI(string memory baseURI) public onlyOwner {   
        _setBaseURI = baseURI;
    }

    // SET BASEEXTENSION
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)) : "";
    }

    // // MINT COMMANDOS FOR PUBLIC
    function mintCommando(uint256 amount) external payable {
        require(
            saleActive,
            "Sale is not yet active."
        );
        require(amount > 0, "Amount must be greater than 0.");
        require(
            amount <= maxMintPerTx,
            "Only 5 Commados can be minted per transaction."
        );
        // Cannot mint more than (maxSupply - maxReserve)
        require(
            totalSupply().add(amount) <= maxSupply.sub(maxReserve),
            "No more commandos left to mint."
        );
        require(
            msg.value >= commandoPrice.mul(amount),
            "The amount of ether sent was incorrect."
        );

        for (uint256 i = 1; i <= amount; i++) {
            uint256 tokenId = totalSupply();
            if (tokenId <= maxSupply) {
                _safeMint(msg.sender, tokenId + 1);
            }
        }
    }


    // SET COMMANDO MINT PRICE
    function setCommandoPrice(uint256 price) public onlyOwner {
        commandoPrice = price;
    }

    // TOGGLE SALE STATE ON/OFF
    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    // TOGGLE RESERVE STATE ON/OFF
    function toggleReserve() public onlyOwner {
        reserveActive = !reserveActive;
    }

    // WITHDRAW FUNDS FROM SMART CONTRACT
    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
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

    // GET reserveActive STATE
    function getResearcState() public view onlyOwner returns (bool) {
        return reserveActive;
    }

    // Takes a signed message (signature) and return r, s and v
    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

    // Takes a hashed-message AND signed message (signature) and return the public key of the signer of message
    function recoverSigner(bytes32 message, bytes memory sig)
        public
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    //_mintPrice in wei
    function promotionalMint(uint8 _number, uint256 _mintPrice, bytes memory signature)
        external
        payable
    {
        require(reserveActive, "Reserve state is not active.");
        require(_number <= maxMintPerTx, "Only 5 Commandos can be minted at a time.");
        require(
            _number <= maxReserve,
            "There are no more promotional commandos left to be minted."
        );

        // Check  promotional mint request is valid
        bool isValid = isValidData(_number, _mintPrice, msg.sender, signature);
        require(isValid, "This promotioanl request is not valid");
        require(
            msg.value >= _mintPrice.mul(_number),
            "The amount of ether sent was incorrect."
        );

        // Given that the promotional mint request is valid, has user already redeemed the promotion?
        require(winnerCanMint(msg.sender, _mintPrice), "Promotion has already been redeemed");

        for (uint256 i = 1; i <= _number; i++) {
            uint256 tokenId = totalSupply();
            if (tokenId < maxSupply) {
                _safeMint(msg.sender, tokenId + 1);
            }
        }

        maxReserve = maxReserve.sub(_number);
        upDatePromotionWinners(msg.sender, _mintPrice);
    }

    // isValidData must be called before this function is called
    // Checks if user has already redeemed promotion
    function winnerCanMint(address _addrs, uint256 _mintPrice) public view returns (bool) {
        if (promotionWinners[_addrs][_mintPrice] == 0){ // mint count is zero
            // User has not minted this promotional price of _mintPrice
            return true;
        }else{
            return false;
        }
    }


    function upDatePromotionWinners(address _addrs, uint256 _mintPrice) private {
        promotionWinners[_addrs][_mintPrice] = 1;
    }

    // Returns the promotional mint price and number of nfts minted at this price
    function getPromotionalWinners(address _addrs, uint256 _mintPrice) public view returns (uint256, uint8){
        return (_mintPrice, promotionWinners[_addrs][_mintPrice]);
    }

     // _mintPrice is in wei
     // _address is the human readable string
    function isValidData(uint8 _number, uint256 _mintPrice, address _address, bytes memory sig) public view returns(bool){
        bytes32 hashedAddress = keccak256(abi.encodePacked(_number, _mintPrice, _address));
        return (recoverSigner(hashedAddress, sig) == trustedPublicKey);
    }


}
