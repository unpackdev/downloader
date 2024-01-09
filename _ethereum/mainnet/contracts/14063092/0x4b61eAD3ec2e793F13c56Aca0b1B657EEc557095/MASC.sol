// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Masc is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAXSUPPLY = 3333;
    uint256 public constant MAX_SELF_MINT = 10;
    mapping(address => uint256) public addressCheck;
    address private signerAddress = 0x15Cb1351EaBEc1232DEE23c7dcf5406B44C56Dd1;
    address public mainAddress = 0xe653ee67c54F0649278c4e071Fb87f20A9473CfF;
    string public baseURI;
    bool public preSaleControl=false;
    bool public publicSaleControl=false;
    bool public saleFinishControl=false;
    constructor(
        string memory _initBaseURI
    ) ERC721("Masc", "Masc") {
        setBaseURI(_initBaseURI);
    }

    //GETTERS

    function publicSaleLimit() public pure returns (uint256) {
        return 3000;
    }

   function hashMessage(address sender) private pure returns (bytes32) {
        return keccak256(abi.encode(sender));
    }

   function isValidData(bytes32 message,bytes memory sig) private
        view returns (bool) {
        return (recoverSigner(message, sig) == signerAddress);
    }

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

   function splitSignature(bytes memory sig)
       public
       pure
       returns (uint8, bytes32, bytes32)
    {
       require(sig.length == 65);
       
       bytes32 r;
       bytes32 s;
       uint8 v;

       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }

       return (v, r, s);
    }


    function presaleMint(bytes32 messageHash, bytes calldata signature, uint256 ammount)
    external
    payable
    nonReentrant
    {

        require(preSaleControl == true, "Masc: Presale is not started yet!");
        require(ammount <= 1, "Masc: Presale mint is one token only.");
        require(addressCheck[msg.sender] < 1, "Masc: Presale mint is one token only.");
        require(hashMessage(msg.sender) == messageHash, "MESSAGE_INVALID");
        require(
            isValidData(messageHash, signature),
            "SIGNATURE_VALIDATION_FAILED"
        );
        addressCheck[msg.sender] += 1;
         _safeMint(msg.sender, totalSupply());
    }

    function publicSaleMint(uint256 ammount) public payable nonReentrant {
        uint256 price = 0.04 ether;
        uint256 supply = totalSupply();
        require(!saleFinishControl, "Masc: SOLD OUT!");
        require(publicSaleControl, "Masc: public sale is not started yet");
        require(msg.value >= price * ammount, "Masc: Insuficient funds");
        require(ammount <= 10, "Masc: You can only mint up to 10 token at once!");
        require(supply + ammount <= publicSaleLimit(), "Masc: Mint too large!");
        addressCheck[msg.sender] += ammount;
        for (uint256 i = 0; i < ammount; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }


    // Before All.

    function setUpPresale(bool newbool) external onlyOwner {
        preSaleControl = newbool;
    }

    function setUpSale(bool newbool) external onlyOwner {
        publicSaleControl = newbool;
    }
    function setUpFinish(bool newbool) external onlyOwner {
        saleFinishControl = newbool;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }


    function setSignerAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        signerAddress = _newAddress;
    }

  
     function withdrawAll() public payable onlyOwner {
        uint256 mainadress_balance = address(this).balance;
        require(payable(mainAddress).send(mainadress_balance));
    }
    function changeWallet(address _newwalladdress) external onlyOwner {
        mainAddress = _newwalladdress;
    }

    // FACTORY
  
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

}