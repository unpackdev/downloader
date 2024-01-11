// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "./SafeMath.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SignerVerification.sol";
import "./ERC721ANonTradeable.sol";


contract Case is ERC721ANonTradeable {
    using Strings for uint256;
    using SafeMath for uint256;

    // Base URI
    string public baseURI = "ipfs://bafybeidv4fx6o4ssklfuwqcdgliiurgmw2zh43l7gxmfqsirqcfnzljxdm/case";

    // Token Supply
    uint256 public constant _totSupply = 8888;

    // Public sale start timestamp
//   uint public publicSaleStartTimestamp;

    // Date of release;
     uint public startPresaleTimestamp = 1655556900;

    struct Balances {
        address owner;
        uint256 balance;
    }

    event baseUriUpdated (
        string oldBaseUri,
        string newBaseUri
    );

    // Token Price
    uint256 public tokenPrice = 0.17 ether;
    uint256 public constant presalePrice = 0.15 ether;

    address[] public Buyers;

    mapping(address => Balances) private ownersNFT;

    // Contract Owner
    address private _signer;

    bool public preSaleActive = true;
    bool public publicSaleActive = false;

    constructor() ERC721ANonTradeable("Case", "CFT"){
        _signer = msg.sender;
    }

    function getCurrentPrice() public view returns (uint256) {
        require(preSaleActive||publicSaleActive, 'Sale is closed at this moment');
        return preSaleActive? presalePrice : tokenPrice;
    }

    function mintOnPresale(uint256 tokensNumber,bytes calldata signature)public payable{
        require(preSaleActive, "Sale is closed at this moment");
        require(block.timestamp>=startPresaleTimestamp, "Presale hasn't started yet");
        require(balanceOf(msg.sender)+tokensNumber <= 4, "You cannot purchase more than 4 tokens");
        require(SignerVerification.isMessageVerified(_signer, signature, _addressToString(msg.sender)), 'ECDSA: Invalid signature');

        _mint(tokensNumber, msg.sender);
    }

    function mintOnPublicsale(uint256 tokensNumber)public payable{
        require(publicSaleActive, "Sale is closed at this moment");
        require(balanceOf(msg.sender)+tokensNumber <= 10, "You cannot purchase more than 10 tokens");
        _mint(tokensNumber, msg.sender);
    }
    
    function _mint(uint256 tokensNumber, address buyer) internal{
        bool notInBuyerArray = true;

        require((tokensNumber.mul(getCurrentPrice())) == msg.value, "Received value doesnt match the requested tokens");
        require(totalSupply() + tokensNumber <= _totSupply, "You try to mint more tokens than totalSupply");

        _safeMint(buyer, tokensNumber);

        for(uint256 i=0; i<Buyers.length; i++){
            if(buyer==Buyers[i]){
                notInBuyerArray = false;
            }
        }

        ownersNFT[buyer] = Balances(buyer, _numberMinted(buyer));
        
        if(notInBuyerArray){
            Buyers.push(buyer);
        }
    }

    function getBuyers(uint256 start, uint256 end) public view returns(Balances[] memory tokens){
        uint256 actualEnd = end > Buyers.length? Buyers.length : end;
        
        Balances[] memory requestedTokens = new Balances[](actualEnd - start);

        uint256 counter;

        for(uint256 i = start; i < actualEnd; i++){
            requestedTokens[counter] = ownersNFT[Buyers[i]];
            counter++;
        }

        return requestedTokens;
    }

//    function setReleaseDate(uint _releaseTimestamp) public onlyOwner {
//        require(_releaseTimestamp > block.timestamp, 'timestamp should be greater than block timestamp');
//
//        releaseTimestamp = _releaseTimestamp;
//    }

    function togglePresale() public onlyOwner{
        require(!publicSaleActive, 'Public sale already active');

        preSaleActive = !preSaleActive;
    }

    function togglePublicSale() public onlyOwner {
        require(!preSaleActive, 'Deactivate pre-sale first');
        publicSaleActive = !publicSaleActive;
//        publicSaleStartTimestamp = block.timestamp;
    }

    function changeStartPresaleTimestamp(uint256 _startPresaleTimestamp) public onlyOwner {
        require(!publicSaleActive, "You can't change presale timestamp on public sale");
        startPresaleTimestamp = _startPresaleTimestamp;
    }

    function changeSignerAddress(address newSigner) public onlyOwner {
        _signer = newSigner;
    }

    function withdraw() public onlyOwner {
        uint256 value = address(this).balance;
        bool sent = payable(msg.sender).send(value);
        require(sent, 'Error during withdraw transfer');
    }

    function setBaseURI(string memory url) public onlyOwner {
        string memory currentURI = baseURI;
        baseURI = url;

        emit baseUriUpdated(currentURI, baseURI);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, ".json"));
    }

    function _addressToString(address _adr) internal pure returns (string memory) {
        bytes memory addressBytes = abi.encodePacked(_adr);

        bytes memory stringBytes = new bytes(42);

        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        for (uint256 i = 0; i < 20; i++) {
            uint8 leftValue = uint8(addressBytes[i]) / 16;
            uint8 rightValue = uint8(addressBytes[i]) - 16 * leftValue;

            bytes1 leftChar = leftValue < 10 ? bytes1(leftValue + 48) : bytes1(leftValue + 87);
            bytes1 rightChar = rightValue < 10 ? bytes1(rightValue + 48) : bytes1(rightValue + 87);

            stringBytes[2 * i + 3] = rightChar;
            stringBytes[2 * i + 2] = leftChar;
        }

        return string(stringBytes);
    }
}
